import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';

class WellbeingTab extends StatelessWidget {
  const WellbeingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wellbeing Hub',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Mental resilience and health initiatives',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          GSpacing.vLg,
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.8,
            children: const [
              WellbeingCard(
                title: 'Mental Health Support',
                subtitle: 'EAP available 24/7 for counseling',
                icon: Icons.psychology_rounded,
                color: XMTheme.primary,
              ),
              WellbeingCard(
                title: 'Fatigue Management',
                subtitle: 'Monitoring rest period compliance',
                icon: Icons.bedtime_rounded,
                color: XMTheme.secondary,
              ),
              WellbeingCard(
                title: 'Substance Awareness',
                subtitle: 'Training schedule and support',
                icon: Icons.local_bar_rounded,
                color: XMTheme.warning,
              ),
              WellbeingCard(
                title: 'Wellness Campaigns',
                subtitle: 'Monthly screening drives',
                icon: Icons.favorite_rounded,
                color: XMTheme.error,
              ),
            ],
          ),
          GSpacing.vLg,
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  XMTheme.success.withValues(alpha: 0.1),
                  XMTheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: XMTheme.success.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: XMTheme.success.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.tips_and_updates,
                        color: XMTheme.success,
                        size: 20,
                      ),
                    ),
                    GSpacing.hMd,
                    const Text(
                      'EAP Helpline',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                GSpacing.vSm,
                const Text(
                  '0800 611 655 — Confidential, free, 24/7 counselling and support services available to all employees.',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WellbeingCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;

  const WellbeingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          GSpacing.hLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GSpacing.vXs,
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
