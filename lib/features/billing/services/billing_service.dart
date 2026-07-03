import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../models/subscription_models.dart';

class BillingService {
  final FirebaseFirestore _firestore;

  BillingService(this._firestore);

  Stream<TenantSubscription?> streamSubscription(String tenantId) {
    if (tenantId.isEmpty) return Stream.value(null);

    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('billing')
        .doc('subscription')
        .snapshots()
        .map(
          (doc) => doc.exists ? TenantSubscription.fromFirestore(doc) : null,
        );
  }

  Future<TenantSubscription?> getSubscription(String tenantId) async {
    if (tenantId.isEmpty) return null;

    final doc =
        await _firestore
            .collection('tenants')
            .doc(tenantId)
            .collection('billing')
            .doc('subscription')
            .get();

    if (!doc.exists) return null;
    return TenantSubscription.fromFirestore(doc);
  }
}

final billingServiceProvider = Provider<BillingService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return BillingService(firestore);
});

final currentTenantSubscriptionProvider = StreamProvider<TenantSubscription?>((
  ref,
) {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null || tenantId.isEmpty) {
    return Stream.value(null);
  }

  final billingService = ref.watch(billingServiceProvider);
  return billingService.streamSubscription(tenantId);
});
