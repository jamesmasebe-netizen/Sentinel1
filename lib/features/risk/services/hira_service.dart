import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/safety_models.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/tenant_firestore_extension.dart';

final hiraServiceProvider = Provider<HiraService>((ref) {
  return HiraService(
    ref.watch(firestoreProvider),
    ref.watch(firestoreServiceProvider),
    ref.watch(currentTenantIdProvider) ?? '',
  );
});

/// Live-streams this tenant's HIRA register, newest first — mirrors `HiraScreen`'s previous
/// inline query exactly (siteId filter, createdAt desc, limit 50).
final hiraAssessmentsProvider =
    StreamProvider.autoDispose<List<RiskAssessment>>((ref) {
      return ref.watch(hiraServiceProvider).streamAssessments();
    });

/// Live-streams every HIRA record in the tenant collection, unfiltered — feeds
/// `RiskMatrixWidget`'s heatmap bucketing (mirrors its previous inline unfiltered query).
final hiraAllAssessmentsProvider =
    StreamProvider.autoDispose<List<RiskAssessment>>((ref) {
      return ref.watch(hiraServiceProvider).streamAllAssessments();
    });

class HiraService {
  final FirebaseFirestore _db;
  final FirestoreService _firestoreService;
  final String _tenantId;

  HiraService(this._db, this._firestoreService, this._tenantId);

  CollectionReference<Map<String, dynamic>> get _hiraRef =>
      _db.tenantCollection(_tenantId, 'risk_assessments');

  /// Routes through FirestoreService.createDocument (not a direct write) so this preserves
  /// hira_form.dart's original offline-queue + audit-log behavior — see FirestoreService's own
  /// doc comment ("All writes go through OfflineSyncService") and AuditLogService.logAction, and
  /// ComplianceService.createDocument (this module's reference pattern) for the same fix.
  Future<void> createAssessment(RiskAssessment assessment) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'risk_assessments',
      data: assessment.toFirestore(),
    );
  }

  Stream<List<RiskAssessment>> streamAssessments() {
    return _hiraRef
        .where('siteId', isEqualTo: _tenantId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => RiskAssessment.fromFirestore(d.data(), d.id))
                  .toList(),
        );
  }

  Stream<List<RiskAssessment>> streamAllAssessments() {
    return _hiraRef.snapshots().map(
      (snap) =>
          snap.docs
              .map((d) => RiskAssessment.fromFirestore(d.data(), d.id))
              .toList(),
    );
  }
}
