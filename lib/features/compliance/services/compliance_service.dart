import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/tenant_firestore_extension.dart';
import '../models/compliance_document.dart';

final complianceServiceProvider = Provider<ComplianceService>((ref) {
  return ComplianceService(
    ref.watch(firestoreProvider),
    ref.watch(currentTenantIdProvider) ?? '',
  );
});

/// Live-streams every `compliance_docs` document for the current tenant, newest first,
/// mirroring `RegisterTab`'s previous inline query exactly (search filtering stays client-side
/// in the widget, same as before).
final complianceDocumentsProvider = StreamProvider.autoDispose<List<ComplianceDocument>>((ref) {
  return ref.watch(complianceServiceProvider).streamAllDocuments();
});

/// Live-streams `compliance_docs` expiring within the next 90 days, soonest first.
final complianceExpiringDocumentsProvider =
    StreamProvider.autoDispose<List<ComplianceDocument>>((ref) {
  return ref.watch(complianceServiceProvider).streamExpiringDocuments();
});

class ComplianceService {
  final FirebaseFirestore _db;
  final String _tenantId;

  ComplianceService(this._db, this._tenantId);

  CollectionReference<Map<String, dynamic>> get _docsRef =>
      _db.tenantCollection(_tenantId, 'compliance_docs');

  Future<void> createDocument(ComplianceDocument document) async {
    await _docsRef.add(document.toFirestore());
  }

  Stream<List<ComplianceDocument>> streamAllDocuments() {
    return _docsRef
        .where('siteId', isEqualTo: _tenantId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ComplianceDocument.fromFirestore(d.data(), d.id))
            .toList());
  }

  Stream<List<ComplianceDocument>> streamExpiringDocuments() {
    final cutoff = DateTime.now().add(const Duration(days: 90)).toIso8601String();
    return _docsRef
        .where('siteId', isEqualTo: _tenantId)
        .where('expiryDate', isLessThanOrEqualTo: cutoff)
        .orderBy('expiryDate')
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ComplianceDocument.fromFirestore(d.data(), d.id))
            .toList());
  }
}
