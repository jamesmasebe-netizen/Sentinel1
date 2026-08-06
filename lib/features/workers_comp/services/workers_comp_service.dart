import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/tenant_firestore_extension.dart';
import '../models/workers_comp_claim.dart';
import '../models/compliance_checklist_item.dart';

final workersCompServiceProvider = Provider<WorkersCompService>((ref) {
  return WorkersCompService(
    ref.watch(firestoreProvider),
    ref.watch(currentTenantIdProvider) ?? '',
  );
});

/// Live-streams every `coida_claims` document for the current tenant, newest first, mirroring
/// `ClaimsTab`'s previous inline query exactly (`siteId` filter, `createdAt` desc, capped at 50).
final workersCompClaimsProvider = StreamProvider.autoDispose<List<WorkersCompClaim>>((ref) {
  return ref.watch(workersCompServiceProvider).streamClaims();
});

/// Live-streams `coida_claims` whose `status` isn't `Closed`, mirroring `RtwTab`'s previous
/// inline query exactly.
final activeRtwCasesProvider = StreamProvider.autoDispose<List<WorkersCompClaim>>((ref) {
  return ref.watch(workersCompServiceProvider).streamActiveRtwCases();
});

/// Live-streams the tenant's `coida_compliance_checklist`, ordered by `order`, mirroring
/// `ComplianceTab`'s previous inline query exactly.
final complianceChecklistProvider =
    StreamProvider.autoDispose<List<ComplianceChecklistItem>>((ref) {
  return ref.watch(workersCompServiceProvider).streamComplianceChecklist();
});

class WorkersCompService {
  final FirebaseFirestore _db;
  final String _tenantId;

  WorkersCompService(this._db, this._tenantId);

  CollectionReference<Map<String, dynamic>> get _claimsRef =>
      _db.tenantCollection(_tenantId, 'coida_claims');

  CollectionReference<Map<String, dynamic>> get _checklistRef =>
      _db.tenantCollection(_tenantId, 'coida_compliance_checklist');

  /// The fixed 10-item COIDA checklist previously hardcoded as `ComplianceTab._defaultItems`.
  static const List<String> defaultChecklistLabels = [
    'Register with COIDA Fund (RAF)',
    'Annual Return of Earnings submitted',
    'W.CL.2 form filed within 7 days of incident',
    'Medical reports obtained from treating doctor',
    'Employee notified of claim status',
    'Return-to-work plan documented',
    'COIDA claim file retained for 3 years',
    'Compensation Commissioner correspondence filed',
    'Section 56 investigation if applicable',
    'Death benefit notifications processed',
  ];

  Future<void> createClaim(WorkersCompClaim claim) async {
    await _claimsRef.add(claim.toFirestore());
  }

  Stream<List<WorkersCompClaim>> streamClaims() {
    return _claimsRef
        .where('siteId', isEqualTo: _tenantId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WorkersCompClaim.fromFirestore(d.data(), d.id))
            .toList());
  }

  Stream<List<WorkersCompClaim>> streamActiveRtwCases() {
    return _claimsRef
        .where('siteId', isEqualTo: _tenantId)
        .where('status', isNotEqualTo: 'Closed')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WorkersCompClaim.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// Updates only the claim's `status` field — never touches `rtwStatus`.
  Future<void> updateClaimStatus(String claimId, String status) {
    return _claimsRef.doc(claimId).update({'status': status});
  }

  /// Updates only the claim's `rtwStatus` field — never touches `status`.
  Future<void> updateClaimRtwStatus(String claimId, String rtwStatus) {
    return _claimsRef.doc(claimId).update({'rtwStatus': rtwStatus});
  }

  /// Batch-creates the 10 fixed-id (`item_0`..`item_9`) default checklist documents, mirroring
  /// `ComplianceTab._seedDefaults` exactly — idempotent, since `batch.set` on a fixed id
  /// overwrites rather than duplicates.
  Future<void> seedComplianceChecklist() async {
    final batch = _db.batch();
    for (var i = 0; i < defaultChecklistLabels.length; i++) {
      batch.set(_checklistRef.doc('item_$i'), {
        'label': defaultChecklistLabels[i],
        'done': false,
        'order': i,
      });
    }
    await batch.commit();
  }

  Future<void> toggleComplianceItem(String itemId, bool done) {
    return _checklistRef.doc(itemId).update({'done': done});
  }

  Stream<List<ComplianceChecklistItem>> streamComplianceChecklist() {
    return _checklistRef
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ComplianceChecklistItem.fromFirestore(d.data(), d.id))
            .toList());
  }
}
