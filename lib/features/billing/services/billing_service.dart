import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/subscription_model.dart';

class BillingService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createStripeCheckoutSession(String tenantId) async {
    try {
      final callable = _functions.httpsCallable('createStripeCheckoutSession');
      final result = await callable.call({'tenantId': tenantId});
      final String? url = result.data['url'] as String?;
      if (url != null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          throw Exception('Could not launch $url');
        }
      }
    } catch (e) {
      throw Exception('Failed to create checkout session: $e');
    }
  }

  Stream<TenantSubscription?> getSubscriptionStream(String tenantId) {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('subscription')
        .doc('status')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return TenantSubscription.fromJson(snapshot.data()!);
          }
          return null;
        });
  }
}

final billingServiceProvider = Provider<BillingService>((ref) {
  return BillingService();
});

final subscriptionStreamProvider =
    StreamProvider.family<TenantSubscription?, String>((ref, tenantId) {
      final billingService = ref.read(billingServiceProvider);
      return billingService.getSubscriptionStream(tenantId);
    });
