import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/tenant_firestore_extension.dart';
import '../models/strategic_risk.dart';

final strategicRiskServiceProvider = Provider<StrategicRiskService>((ref) {
  return StrategicRiskService(
    ref.watch(firestoreProvider),
    ref.watch(firestoreServiceProvider),
    ref.watch(currentTenantIdProvider) ?? '',
  );
});

/// Live-streams this tenant's strategic risk register, newest first, limit 50 — mirrors
/// `StrategicRiskRegisterScreen`'s previous inline query.
final strategicRisksProvider =
    StreamProvider.autoDispose<List<StrategicRisk>>((ref) {
      return ref.watch(strategicRiskServiceProvider).streamRisks();
    });

/// Live-streams every strategic risk in the tenant collection, unfiltered — feeds
/// `RiskMatrixWidget`'s heatmap bucketing (mirrors its previous inline unfiltered query).
final strategicRiskAllProvider =
    StreamProvider.autoDispose<List<StrategicRisk>>((ref) {
      return ref.watch(strategicRiskServiceProvider).streamAllRisks();
    });

class StrategicRiskService {
  final FirebaseFirestore _db;
  final FirestoreService _firestoreService;
  final String _tenantId;

  StrategicRiskService(this._db, this._firestoreService, this._tenantId);

  CollectionReference<Map<String, dynamic>> get _risksRef =>
      _db.tenantCollection(_tenantId, 'strategic_risks');

  /// Routes through FirestoreService.createDocument (not a direct write) so this preserves
  /// strategic_risk_form.dart's original offline-queue + audit-log behavior — see
  /// ComplianceService's matching fix (this module's reference pattern).
  Future<void> createRisk(StrategicRisk risk) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'strategic_risks',
      data: risk.toFirestore(),
    );
  }

  Stream<List<StrategicRisk>> streamRisks() {
    return _risksRef
        .where('siteId', isEqualTo: _tenantId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => StrategicRisk.fromFirestore(d.data(), d.id))
                  .toList(),
        );
  }

  Stream<List<StrategicRisk>> streamAllRisks() {
    return _risksRef.snapshots().map(
      (snap) =>
          snap.docs
              .map((d) => StrategicRisk.fromFirestore(d.data(), d.id))
              .toList(),
    );
  }
}
