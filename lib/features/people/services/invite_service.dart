import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../models/invite_model.dart';

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

final inviteServiceProvider = Provider<InviteService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final functions = ref.watch(firebaseFunctionsProvider);
  final tenantId = ref.watch(currentTenantIdProvider);

  return InviteService(firestore, functions, tenantId);
});

final pendingInvitesStreamProvider =
    StreamProvider.autoDispose<List<InviteModel>>((ref) {
      final inviteService = ref.watch(inviteServiceProvider);
      return inviteService.streamPendingInvites();
    });

class InviteService {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final String? _tenantId;

  InviteService(this._firestore, this._functions, this._tenantId);

  Stream<List<InviteModel>> streamPendingInvites() {
    if (_tenantId == null || _tenantId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('invites')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => InviteModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> createInvite({
    required String email,
    required String role,
  }) async {
    if (_tenantId == null || _tenantId.isEmpty) {
      throw Exception('No active tenant found.');
    }

    try {
      final callable = _functions.httpsCallable('createInvite');
      await callable.call({
        'email': email,
        'role': role,
        'tenantId': _tenantId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Failed to send invite: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
