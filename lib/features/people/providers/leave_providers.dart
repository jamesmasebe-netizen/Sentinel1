import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../models/leave_request.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

final leaveRequestsCollectionProvider = Provider<CollectionReference<LeaveRequest>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'leaveRequests').withConverter<LeaveRequest>(
        fromFirestore: (snapshot, _) => LeaveRequest.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (request, _) => request.toMap(),
      );
});

final leaveRequestsProvider = StreamProvider<List<LeaveRequest>>((ref) {
  final collection = ref.watch(leaveRequestsCollectionProvider);
  return collection.orderBy('startDate', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

class LeaveService {
  final FirebaseFirestore _firestore;
  final String _tenantId;

  LeaveService(this._firestore, this._tenantId);

  Future<void> updateLeaveRequest(LeaveRequest request) async {
    await _firestore.tenantCollection(_tenantId, 'leaveRequests').doc(request.id).set(
          request.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<String> createLeaveRequest(LeaveRequest request) async {
    final ref = _firestore.tenantCollection(_tenantId, 'leaveRequests').doc();
    final newRequest = request.copyWith(id: ref.id);
    await ref.set(newRequest.toMap());
    return ref.id;
  }
}

final leaveServiceProvider = Provider<LeaveService>((ref) {
  return LeaveService(ref.watch(firestoreProvider), ref.watch(currentTenantIdProvider) ?? '');
});
