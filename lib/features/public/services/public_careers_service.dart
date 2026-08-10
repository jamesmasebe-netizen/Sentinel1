import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/tenant_firestore_extension.dart';
import '../../people/models/hr_models.dart';

final publicCareersServiceProvider = Provider<PublicCareersService>((ref) {
  return PublicCareersService(ref.watch(firestoreProvider));
});

/// Service layer for the unauthenticated public careers portal (`/careers/:tenantSlug`). Unlike
/// every other module's service, this one deliberately does NOT depend on
/// `currentTenantIdProvider` or route writes through `FirestoreService` — there is no signed-in
/// user here (job applicants aren't authenticated), and `FirestoreService.createDocument` writes
/// an audit-log entry first via `AuditLogService`, whose Firestore rule requires
/// `belongsToTenant(tenantId)` — an anonymous visitor can never satisfy that, so routing through
/// it would throw and silently break every real application submission. `submitApplication`
/// writes directly to Firestore instead, matching `job_applications`' own rule (`allow create: if
/// true`, see firestore.rules and firebase/functions/test/rules/zzz_unauthenticated_access.test.ts).
class PublicCareersService {
  final FirebaseFirestore _db;

  PublicCareersService(this._db);

  /// Resolves a public URL slug (e.g. `/careers/acme-corp`) to its real tenantId. Only readable
  /// from client code — writing an entry (an admin "claiming" their tenant's slug) goes through
  /// `HRService.claimTenantSlug`, not this service, since it needs an authenticated admin context
  /// this unauthenticated-portal service deliberately doesn't have.
  Future<String?> resolveTenantId(String tenantSlug) async {
    final doc = await _db.collection('public_tenant_directory').doc(tenantSlug).get();
    if (!doc.exists) return null;
    return doc.data()?['tenantId'] as String?;
  }

  Stream<List<JobRequisition>> streamPublishedJobs(String tenantId) {
    return _db
        .tenantCollection(tenantId, 'job_requisitions')
        .where('status', isEqualTo: 'Published')
        .snapshots()
        .map((snap) => snap.docs.map((d) => JobRequisition.fromFirestore(d)).toList());
  }

  Future<void> submitApplication({
    required String tenantId,
    required String jobId,
    required String jobTitle,
    required String applicantName,
    required String email,
    required String phone,
    required String resumeLink,
  }) async {
    await _db.tenantCollection(tenantId, 'job_applications').add({
      'jobId': jobId,
      'jobTitle': jobTitle,
      'applicantName': applicantName,
      'email': email,
      'phone': phone,
      'resumeLink': resumeLink,
      'status': 'New',
      'appliedAt': FieldValue.serverTimestamp(),
      'isExternal': true,
    });
  }
}
