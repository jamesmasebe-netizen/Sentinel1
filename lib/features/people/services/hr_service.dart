import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hr_models.dart';
import '../../../core/providers/app_providers.dart';

final hrServiceProvider = Provider<HRService>((ref) {
  return HRService(ref.watch(tenantDocProvider));
});

class HRService {
  final DocumentReference _tenantDoc;

  HRService(this._tenantDoc);

  // --- Department ---
  Future<void> createDepartment(Department dept) async {
    final docRef = _tenantDoc.collection('departments').doc();
    final data = dept.toFirestore();
    data['siteId'] = _tenantDoc.id; // ensure siteId matches tenant
    await docRef.set(data);
  }

  Future<void> updateDepartment(String deptId, Map<String, dynamic> data) async {
    await _tenantDoc.collection('departments').doc(deptId).update(data);
  }

  Future<void> deleteDepartment(String deptId) async {
    await _tenantDoc.collection('departments').doc(deptId).delete();
  }

  // --- JobRole ---
  Future<void> createJobRole(JobRole role) async {
    final docRef = _tenantDoc.collection('job_roles').doc();
    final data = role.toFirestore();
    data['siteId'] = _tenantDoc.id; // ensure siteId matches tenant
    await docRef.set(data);
  }

  Future<void> updateJobRole(String roleId, Map<String, dynamic> data) async {
    await _tenantDoc.collection('job_roles').doc(roleId).update(data);
  }

  Future<void> deleteJobRole(String roleId) async {
    await _tenantDoc.collection('job_roles').doc(roleId).delete();
  }

  // --- OhsRole ---
  Future<void> createOhsRole(OhsRole role) async {
    final docRef = _tenantDoc.collection('ohs_roles').doc();
    final data = role.toFirestore();
    data['siteId'] = _tenantDoc.id; // ensure siteId matches tenant
    await docRef.set(data);
  }

  Future<void> updateOhsRole(String roleId, Map<String, dynamic> data) async {
    await _tenantDoc.collection('ohs_roles').doc(roleId).update(data);
  }

  Future<void> deleteOhsRole(String roleId) async {
    await _tenantDoc.collection('ohs_roles').doc(roleId).delete();
  }

  Future<void> seedOhsRolesIfEmpty() async {
    final query = await _tenantDoc.collection('ohs_roles').limit(1).get();
    if (query.docs.isEmpty) {
      final roles = [
        OhsRole(title: 'Fire Warden', description: 'Responsible for evacuation during a fire emergency'),
        OhsRole(title: 'First Aider', description: 'Provides medical assistance and first aid'),
        OhsRole(title: 'Health & Safety Rep', description: 'Health and Safety Representative'),
        OhsRole(title: 'Evacuation Marshal', description: 'Coordinates orderly evacuation'),
      ];
      for (var role in roles) {
        await createOhsRole(role);
      }
    }
  }

  // --- EmployeeProfile ---
  Future<List<EmployeeProfile>> getEmployees() async {
    final snapshot = await _tenantDoc.collection('employees').get();
    return snapshot.docs
        .map((doc) => EmployeeProfile.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<EmployeeProfile?> getEmployee(String employeeId) async {
    final doc = await _tenantDoc.collection('employees').doc(employeeId).get();
    if (!doc.exists || doc.data() == null) return null;
    return EmployeeProfile.fromJson(doc.data()!, doc.id);
  }

  Future<void> createEmployee(EmployeeProfile employee) async {
    await _tenantDoc.firestore
        .collection('employees')
        .doc(employee.id)
        .set(employee.toJson());
  }

  Future<void> updateEmployee(
    String employeeId,
    Map<String, dynamic> data,
  ) async {
    await _tenantDoc.collection('employees').doc(employeeId).update(data);
  }

  Future<void> deleteEmployee(String employeeId) async {
    await _tenantDoc.collection('employees').doc(employeeId).delete();
  }

  // --- LeaveRequest ---
  Future<List<LeaveRequest>> getLeaveRequests(String employeeId) async {
    final snapshot =
        await _tenantDoc.firestore
            .collection('employees')
            .doc(employeeId)
            .collection('leave_requests')
            .get();
    return snapshot.docs
        .map((doc) => LeaveRequest.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> createLeaveRequest(
    String employeeId,
    LeaveRequest request,
  ) async {
    await _tenantDoc.firestore
        .collection('employees')
        .doc(employeeId)
        .collection('leave_requests')
        .doc(request.id)
        .set(request.toJson());
  }

  Future<void> updateLeaveRequest(
    String employeeId,
    String requestId,
    Map<String, dynamic> data,
  ) async {
    await _tenantDoc.firestore
        .collection('employees')
        .doc(employeeId)
        .collection('leave_requests')
        .doc(requestId)
        .update(data);
  }

  Future<void> deleteLeaveRequest(String employeeId, String requestId) async {
    await _tenantDoc.firestore
        .collection('employees')
        .doc(employeeId)
        .collection('leave_requests')
        .doc(requestId)
        .delete();
  }

  // --- CompensationPlan ---
  Future<List<CompensationPlan>> getCompensationPlans() async {
    final snapshot = await _tenantDoc.collection('compensation_plans').get();
    return snapshot.docs
        .map((doc) => CompensationPlan.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> createCompensationPlan(CompensationPlan plan) async {
    await _tenantDoc.firestore
        .collection('compensation_plans')
        .doc(plan.id)
        .set(plan.toJson());
  }

  Future<void> updateCompensationPlan(
    String planId,
    Map<String, dynamic> data,
  ) async {
    await _tenantDoc.collection('compensation_plans').doc(planId).update(data);
  }

  Future<void> deleteCompensationPlan(String planId) async {
    await _tenantDoc.collection('compensation_plans').doc(planId).delete();
  }

  // --- BenefitEnrollment ---
  Future<List<BenefitEnrollment>> getBenefitEnrollments(
    String employeeId,
  ) async {
    final snapshot =
        await _tenantDoc.firestore
            .collection('employees')
            .doc(employeeId)
            .collection('benefit_enrollments')
            .get();
    return snapshot.docs
        .map((doc) => BenefitEnrollment.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> createBenefitEnrollment(
    String employeeId,
    BenefitEnrollment enrollment,
  ) async {
    await _tenantDoc.firestore
        .collection('employees')
        .doc(employeeId)
        .collection('benefit_enrollments')
        .doc(enrollment.id)
        .set(enrollment.toJson());
  }

  Future<void> updateBenefitEnrollment(
    String employeeId,
    String enrollmentId,
    Map<String, dynamic> data,
  ) async {
    await _tenantDoc.firestore
        .collection('employees')
        .doc(employeeId)
        .collection('benefit_enrollments')
        .doc(enrollmentId)
        .update(data);
  }

  Future<void> deleteBenefitEnrollment(
    String employeeId,
    String enrollmentId,
  ) async {
    await _tenantDoc.firestore
        .collection('employees')
        .doc(employeeId)
        .collection('benefit_enrollments')
        .doc(enrollmentId)
        .delete();
  }

  // --- PerformanceReview ---
  Future<List<PerformanceReview>> getPerformanceReviews(
    String employeeId,
  ) async {
    final snapshot =
        await _tenantDoc.firestore
            .collection('employees')
            .doc(employeeId)
            .collection('performance_reviews')
            .get();
    return snapshot.docs
        .map((doc) => PerformanceReview.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> createPerformanceReview(
    String employeeId,
    PerformanceReview review,
  ) async {
    await _tenantDoc.firestore
        .collection('employees')
        .doc(employeeId)
        .collection('performance_reviews')
        .doc(review.id)
        .set(review.toJson());
  }

  Future<void> updatePerformanceReview(
    String employeeId,
    String reviewId,
    Map<String, dynamic> data,
  ) async {
    await _tenantDoc.firestore
        .collection('employees')
        .doc(employeeId)
        .collection('performance_reviews')
        .doc(reviewId)
        .update(data);
  }

  Future<void> deletePerformanceReview(
    String employeeId,
    String reviewId,
  ) async {
    await _tenantDoc.firestore
        .collection('employees')
        .doc(employeeId)
        .collection('performance_reviews')
        .doc(reviewId)
        .delete();
  }

  // --- Recruitment: job_applications -> candidates bridge ---

  /// Streams the raw external applications for one requisition (`job_applications.jobId ==
  /// requisitionId`) — the "inbox" a recruiter reviews before deciding to convert someone into the
  /// tracked ATS pipeline. See RecruitmentDashboardScreen's Applications Inbox tab.
  Stream<List<JobApplication>> streamJobApplications(String requisitionId) {
    return _tenantDoc
        .collection('job_applications')
        .where('jobId', isEqualTo: requisitionId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => JobApplication.fromFirestore(d)).toList());
  }

  /// Promotes a raw application into a real Candidate in the ATS pipeline, and marks the source
  /// application Converted so it stops showing as an open inbox item (mirrors
  /// ScmService.markMrpSuggestionConverted's "mark it acted-on" shape from the supply_chain
  /// module). Deliberately two separate writes, not a transaction: job_applications and candidates
  /// are independent collections with no shared document a transaction would need to guard, and a
  /// recruiter re-clicking Convert on an already-converted application is a harmless duplicate
  /// candidate, not a correctness bug worth the extra complexity to prevent server-side.
  Future<void> convertApplicationToCandidate(
    JobApplication application, {
    required String requisitionId,
    required String department,
  }) async {
    final candidate = Candidate(
      id: '',
      requisitionId: requisitionId,
      name: application.applicantName,
      title: application.jobTitle,
      email: application.email,
      department: department,
      stage: 'Applied',
      resumeUrl: application.resumeLink,
      appliedDate: application.appliedAt,
    );
    await _tenantDoc.collection('candidates').add(candidate.toFirestore());
    await _tenantDoc.collection('job_applications').doc(application.id).update({
      'status': 'Converted',
    });
  }

  // --- Public careers page setup ---

  /// Claims a public URL slug (`/careers/{slug}`) for this tenant, so the public careers page can
  /// resolve it — see PublicCareersService.resolveTenantId. A direct write to the root
  /// `public_tenant_directory` collection, not routed through FirestoreService: that collection is
  /// outside any tenant subcollection, matching PublicCareersService's own established precedent
  /// for this exact collection (it also writes/reads it directly). firestore.rules only allows
  /// `create` on a not-yet-existing slug and `update`/`delete` on one this tenant already owns, so
  /// this can't accidentally hijack a different tenant's claimed slug.
  Future<void> claimTenantSlug(String slug) async {
    await _tenantDoc.firestore.collection('public_tenant_directory').doc(slug).set({
      'tenantId': _tenantDoc.id,
    });
  }

  /// The slug currently claimed for this tenant, if any — a reverse lookup since
  /// `public_tenant_directory` is keyed by slug, not tenantId. Used by the Settings screen to show
  /// what's already claimed. `limit(1)` since exactly one slug should ever map to a tenant in
  /// practice, though rules don't strictly enforce that.
  Future<String?> getClaimedSlugForTenant() async {
    final snap = await _tenantDoc.firestore
        .collection('public_tenant_directory')
        .where('tenantId', isEqualTo: _tenantDoc.id)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first.id;
  }
}
