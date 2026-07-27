import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';

class HRService {
  final FirebaseFirestore _firestore;

  HRService(this._firestore);

  Stream<Map<String, dynamic>?> getEmployeeStream(String employeeId) {
    return _firestore.collection('employees').doc(employeeId).snapshots().map((
      snap,
    ) {
      if (!snap.exists) return null;
      return {'id': snap.id, ...?snap.data()};
    });
  }

  Stream<List<Map<String, dynamic>>> getLeaveRequests(String employeeId) {
    return _firestore
        .collection('leave_requests')
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getPerformanceReviews(String employeeId) {
    return _firestore
        .collection('performance_reviews')
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('reviewDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getBenefits(String employeeId) {
    return _firestore
        .collection('benefits')
        .where('employeeId', isEqualTo: employeeId)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Stream<Map<String, dynamic>?> getLeaveRequestStream(String requestId) {
    return _firestore
        .collection('leave_requests')
        .doc(requestId)
        .snapshots()
        .map((snap) {
          if (!snap.exists) return null;
          return {'id': snap.id, ...?snap.data()};
        });
  }
}

final hrServiceProvider = Provider<HRService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return HRService(firestore);
});

final employeeDetailProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, employeeId) {
      return ref.watch(hrServiceProvider).getEmployeeStream(employeeId);
    });

final employeeLeaveRequestsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      employeeId,
    ) {
      return ref.watch(hrServiceProvider).getLeaveRequests(employeeId);
    });

final employeePerformanceReviewsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      employeeId,
    ) {
      return ref.watch(hrServiceProvider).getPerformanceReviews(employeeId);
    });

final employeeBenefitsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      employeeId,
    ) {
      return ref.watch(hrServiceProvider).getBenefits(employeeId);
    });

final leaveRequestDetailProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, requestId) {
      return ref.watch(hrServiceProvider).getLeaveRequestStream(requestId);
    });
