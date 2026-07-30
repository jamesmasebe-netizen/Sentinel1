import 'package:flutter/material.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../services/billing_service.dart';

class BillingPortalScreen extends ConsumerWidget {
  const BillingPortalScreen({super.key});

  // Theme palette
  static const _bgDeep = Color(0xFF050D1A);
  static const _navyDark = Color(0xFF0A1628);
  static const _navy = Color(0xFF0D2137);
  static const _blueGlow = Color(0xFF1E6FD9);
  static const _emerald = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);
  static const _premiumPurple = Color(0xFF8B5CF6);
  static const _enterpriseGold = Color(0xFFFBBF24);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(currentTenantIdProvider);
    
    if (tenantId == null) {
      return const Scaffold(
        backgroundColor: _bgDeep,
        body: Center(
          child: Text('No active tenant context.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    final subscriptionAsync = ref.watch(subscriptionStreamProvider(tenantId));

    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: AppBar(
        backgroundColor: _navyDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _blueGlow.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.credit_card_rounded, color: _blueGlow, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'Billing & Subscriptions',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: subscriptionAsync.when(
        data: (subscription) {
          final isPremium = subscription?.tier.name == 'premium';
          final isEnterprise = subscription?.tier.name == 'enterprise';
          final isFree = subscription?.tier.name == 'free' || subscription == null;
          
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Current Status Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _navy,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _blueGlow.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: _blueGlow.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CURRENT PLAN',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isEnterprise ? 'Enterprise' : (isPremium ? 'Premium' : 'Free Tier'),
                                  style: TextStyle(
                                    color: isEnterprise ? _enterpriseGold : (isPremium ? _premiumPurple : Colors.white),
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (subscription != null && subscription.status == 'active')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: _emerald.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _emerald.withValues(alpha: 0.3)),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(color: _emerald, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  )
                                else if (subscription != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: _amber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _amber.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      subscription.status.toUpperCase(),
                                      style: const TextStyle(color: _amber, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (subscription != null && subscription.currentPeriodEnd != null)
                              Row(
                                children: [
                                  const Icon(Icons.event_rounded, color: Colors.white54, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Period ends: ${subscription.currentPeriodEnd!.toLocal().toString().split(" ")[0]}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              )
                            else
                              const Text('No active paid subscription.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      const Text(
                        'Available Plans',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Plans Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 800;
                          final children = [
                            _PlanCard(
                              title: 'Free Tier',
                              price: '\$0',
                              period: '/month',
                              color: Colors.white,
                              features: const ['Core platform features', 'Up to 5 users', 'Community support'],
                              isCurrent: isFree,
                              buttonText: isFree ? 'Current Plan' : 'Downgrade to Free',
                              onPressed: isFree ? null : () async {
                                final billingService = ref.read(billingServiceProvider);
                                try {
                                  await billingService.openBillingPortal(tenantId);
                                } catch (e) {
                                  if (context.mounted) {
                                    UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
                                  }
                                }
                              },
                            ),
                            _PlanCard(
                              title: 'Premium',
                              price: '\$99',
                              period: '/month',
                              color: _premiumPurple,
                              features: const ['Everything in Free', 'Unlimited users', 'Priority support', 'Advanced Analytics'],
                              isCurrent: isPremium,
                              isPopular: true,
                              buttonText: isPremium ? 'Current Plan' : 'Upgrade to Premium',
                              onPressed: isPremium ? null : () async {
                                final billingService = ref.read(billingServiceProvider);
                                try {
                                  await billingService.createStripeCheckoutSession(tenantId);
                                } catch (e) {
                                  if (context.mounted) {
                                    UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
                                  }
                                }
                              },
                            ),
                            _PlanCard(
                              title: 'Enterprise',
                              price: 'Custom',
                              period: '',
                              color: _enterpriseGold,
                              features: const ['Everything in Premium', 'Dedicated Account Manager', 'SSO & Advanced Security', 'Custom Integrations'],
                              isCurrent: isEnterprise,
                              buttonText: isEnterprise ? 'Current Plan' : 'Contact Sales',
                              onPressed: isEnterprise ? null : () async {
                                final billingService = ref.read(billingServiceProvider);
                                try {
                                  await billingService.createStripeCheckoutSession(tenantId, priceId: 'price_enterprise_mock');
                                } catch (e) {
                                  if (context.mounted) {
                                    UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
                                  }
                                }
                              },
                            ),
                          ];
                          
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: children.map((c) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: c == children.last ? 0 : 16.0),
                                  child: c,
                                ),
                              )).toList(),
                            );
                          } else {
                            return Column(
                              children: children.map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: c,
                              )).toList(),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final Color color;
  final List<String> features;
  final bool isCurrent;
  final bool isPopular;
  final String buttonText;
  final VoidCallback? onPressed;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.color,
    required this.features,
    required this.isCurrent,
    this.isPopular = false,
    required this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BillingPortalScreen._navy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? color : (isPopular ? color.withValues(alpha: 0.5) : BillingPortalScreen._navyDark),
          width: isCurrent || isPopular ? 2 : 1,
        ),
        boxShadow: isCurrent || isPopular ? [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          )
        ] : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isPopular && !isCurrent)
            Positioned(
              top: -12,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            ),
            
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    if (period.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        period,
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                
                // Features
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: color, size: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          f,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
                
                const SizedBox(height: 24),
                
                // Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent ? Colors.transparent : color,
                      foregroundColor: isCurrent ? color : Colors.white,
                      elevation: 0,
                      side: isCurrent ? BorderSide(color: color.withValues(alpha: 0.5)) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
