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
}
