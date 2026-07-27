import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/subscription_provider.dart';
import '../services/billing_service.dart';

class BillingPortalScreen extends ConsumerWidget {
  const BillingPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(currentTenantIdProvider);
    final isPremium = ref.watch(isPremiumProvider);

    final subscriptionAsync =
        tenantId != null
            ? ref.watch(subscriptionStreamProvider(tenantId))
            : const AsyncValue.data(null);

    return Scaffold(
      appBar: AppBar(title: const Text('Billing & Subscriptions')),
      body:
          tenantId == null
              ? const Center(child: Text('No active tenant context.'))
              : subscriptionAsync.when(
                data: (subscription) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Status: ${isPremium ? "Premium/Enterprise" : "Free Tier"}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                if (subscription != null) ...[
                                  Text('Tier: ${subscription.tier}'),
                                  Text('Status: ${subscription.status}'),
                                  Text(
                                    'Period Ends: ${subscription.currentPeriodEnd.toLocal()}',
                                  ),
                                ] else
                                  const Text('No active subscription.'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!isPremium) ...[
                          Text(
                            'Upgrade your plan',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          Card(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Premium Tier',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Unlock all advanced features for Sentinel1.',
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final billingService = ref.read(
                                        billingServiceProvider,
                                      );
                                      try {
                                        await billingService
                                            .createStripeCheckoutSession(
                                              tenantId,
                                            );
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('Upgrade to Premium'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
    );
  }
}
