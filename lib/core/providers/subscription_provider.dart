import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/billing/services/billing_service.dart';
import '../../features/billing/models/subscription_models.dart';
import 'app_providers.dart';

final isPremiumProvider = Provider<bool>((ref) {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null) return false;

  final subscription =
      ref.watch(subscriptionStreamProvider(tenantId)).valueOrNull;
  if (subscription == null) return false;

  return subscription.tier == SubscriptionTier.premium || 
         subscription.tier == SubscriptionTier.enterprise;
});
