import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/tenant_firestore_extension.dart';
import '../models/dynamic_risk_assessment.dart';

final draServiceProvider = Provider<DraService>((ref) {
  return DraService(
    ref.watch(firestoreProvider),
    ref.watch(firestoreServiceProvider),
    ref.watch(currentTenantIdProvider) ?? '',
  );
});

/// Live-streams this tenant's DRA list, newest first, limit 50 — mirrors
/// `DynamicRiskAssessmentScreen`'s previous inline query.
final draAssessmentsProvider =
    StreamProvider.autoDispose<List<DynamicRiskAssessment>>((ref) {
      return ref.watch(draServiceProvider).streamSiteAssessments();
    });

/// Same query, capped to 10 — feeds `RiskCommandCenterScreen`'s "Recent Assessments" list.
final draRecentAssessmentsProvider =
    StreamProvider.autoDispose<List<DynamicRiskAssessment>>((ref) {
      return ref.watch(draServiceProvider).streamSiteAssessments(limit: 10);
    });

/// The tenant's whole DRA collection, unfiltered by order/limit — feeds 3 separate aggregations
/// across 2 screens (`RiskCommandCenterScreen`'s KPI grid, `RiskHubScreen`'s "Open Assessments"/
/// "Control Strength" metric cards). Riverpod's provider caching means all 3 watchers share one
/// real Firestore listener.
final draAllSiteAssessmentsProvider =
    StreamProvider.autoDispose<List<DynamicRiskAssessment>>((ref) {
      return ref.watch(draServiceProvider).streamAllSiteAssessments();
    });

/// KPI-grid counts derived from [draAllSiteAssessmentsProvider] — mirrors
/// `RiskCommandCenterScreen`'s previous inline `switch` over `riskLevel` plus its `approved`
/// count exactly. Kept as a provider rather than local `setState`/inline `build()` math per
/// AGENTS.md §2 ("derivations must happen within the Riverpod providers").
final draKpiCountsProvider = Provider.autoDispose<AsyncValue<DraKpiCounts>>((
  ref,
) {
  return ref.watch(draAllSiteAssessmentsProvider).whenData(DraKpiCounts.fromList);
});

/// "Open Assessments" metric — count of DRAs not (yet) `status == 'Approved'`. In practice this
/// is always the full count today: no write path in this app ever sets that status (F-306,
/// unresolved) — preserved as-is, not fixed as part of this extraction. Exposed as both a
/// `StreamProvider` (for `AsyncValue`-style consumers) and, via `DraService.streamOpenAssessmentsCount`,
/// a plain `Stream<String>` — `RiskHubScreen`'s `StreamMetricCard` needs the latter (a raw
/// `Stream<String>` constructor param); watching a `StreamProvider`'s now-deprecated `.stream`
/// accessor was avoided in favor of calling the service method directly, same as every other
/// widget in this module.
final draOpenAssessmentsCountProvider = StreamProvider.autoDispose<String>((
  ref,
) {
  return ref.watch(draServiceProvider).streamOpenAssessmentsCount();
});

/// "Control Strength" metric — % of DRAs approved, floored at the empty-collection default of
/// `80%`. Mirrors `RiskHubScreen`'s previous inline calc exactly.
final draControlStrengthProvider = StreamProvider.autoDispose<String>((ref) {
  return ref.watch(draServiceProvider).streamControlStrength();
});

/// Value object for the risk-level/approval KPI grid — see [draKpiCountsProvider].
class DraKpiCounts {
  final int total;
  final int extreme;
  final int high;
  final int medium;
  final int low;
  final int unapproved;

  const DraKpiCounts({
    required this.total,
    required this.extreme,
    required this.high,
    required this.medium,
    required this.low,
    required this.unapproved,
  });

  factory DraKpiCounts.fromList(List<DynamicRiskAssessment> list) {
    int extreme = 0, high = 0, medium = 0, low = 0, unapproved = 0;
    for (final a in list) {
      switch (a.riskLevel) {
        case 'Extreme':
          extreme++;
        case 'High':
          high++;
        case 'Medium':
          medium++;
        case 'Low':
          low++;
      }
      if (!a.approved) unapproved++;
    }
    return DraKpiCounts(
      total: list.length,
      extreme: extreme,
      high: high,
      medium: medium,
      low: low,
      unapproved: unapproved,
    );
  }
}

class DraService {
  final FirebaseFirestore _db;
  final FirestoreService _firestoreService;
  final String _tenantId;

  DraService(this._db, this._firestoreService, this._tenantId);

  CollectionReference<Map<String, dynamic>> get _draRef =>
      _db.tenantCollection(_tenantId, 'dynamic_risk_assessments');

  /// Routes through FirestoreService.createDocument (not a direct write) so this preserves
  /// dra_form.dart's original offline-queue + audit-log behavior — see ComplianceService's
  /// matching fix (this module's reference pattern).
  Future<void> createAssessment(DynamicRiskAssessment assessment) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'dynamic_risk_assessments',
      data: assessment.toFirestore(),
    );
  }

  Stream<List<DynamicRiskAssessment>> streamSiteAssessments({
    int limit = 50,
  }) {
    return _draRef
        .where('siteId', isEqualTo: _tenantId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map(
                    (d) =>
                        DynamicRiskAssessment.fromFirestore(d.data(), d.id),
                  )
                  .toList(),
        );
  }

  Stream<List<DynamicRiskAssessment>> streamAllSiteAssessments() {
    return _draRef.where('siteId', isEqualTo: _tenantId).snapshots().map(
      (snap) =>
          snap.docs
              .map((d) => DynamicRiskAssessment.fromFirestore(d.data(), d.id))
              .toList(),
    );
  }

  /// "Open Assessments" metric as a plain `Stream<String>` — see [draOpenAssessmentsCountProvider].
  Stream<String> streamOpenAssessmentsCount() {
    return streamAllSiteAssessments().map(
      (list) =>
          list.where((a) => a.status != 'Approved').length.toString(),
    );
  }

  /// "Control Strength" metric as a plain `Stream<String>` — see [draControlStrengthProvider].
  Stream<String> streamControlStrength() {
    return streamAllSiteAssessments().map((list) {
      if (list.isEmpty) return '80%';
      final approved = list.where((a) => a.status == 'Approved').length;
      return '${((approved / list.length) * 100).round()}%';
    });
  }
}
