import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../services/environment_service.dart';

class EnvironmentalAnalyticsTab extends ConsumerWidget {
  const EnvironmentalAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

    final spillsAsync = ref.watch(allEnvironmentalSpillsProvider);
    final wasteAsync = ref.watch(allWasteManifestsProvider);
    final esgAsync = ref.watch(allEsgMetricsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Environmental Analytics',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          GSpacing.vSm,
          Text(
            'Performance overview for $siteId',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          GSpacing.vLg,

          // ─── Spill KPIs ───
          Text(
            'Spill Response',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          GSpacing.vMd,
          spillsAsync.when(
            data: (spills) {
              final total = spills.length;
              final contained = spills.where((s) => s.contained).length;
              final uncontained = total - contained;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _AnalyticsKpiCard(
                      label: 'Total Spills',
                      value: '$total',
                      icon: Icons.water_drop,
                      color: XMTheme.info,
                    ),
                    GSpacing.hMd,
                    _AnalyticsKpiCard(
                      label: 'Contained',
                      value: '$contained',
                      icon: Icons.check_circle,
                      color: XMTheme.success,
                    ),
                    GSpacing.hMd,
                    _AnalyticsKpiCard(
                      label: 'Uncontained',
                      value: '$uncontained',
                      icon: Icons.cancel,
                      color: XMTheme.error,
                    ),
                    GSpacing.hMd,
                    _AnalyticsKpiCard(
                      label: 'Containment %',
                      value:
                          total > 0
                              ? '${(contained / total * 100).toStringAsFixed(0)}%'
                              : '—',
                      icon: Icons.percent,
                      color: XMTheme.primary,
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error: $e'),
          ),
          GSpacing.vLg,

          // ─── Waste Distribution ───
          Text(
            'Waste Distribution',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          GSpacing.vMd,
          wasteAsync.when(
            data: (manifests) {
              final byType = <String, int>{};
              for (final m in manifests) {
                final t = m.wasteType.isNotEmpty ? m.wasteType : 'Other';
                byType[t] = (byType[t] ?? 0) + 1;
              }
              if (byType.isEmpty) {
                return const GCard(
                  child: Center(child: Text('No waste data available')),
                );
              }
              final total = byType.values.reduce((a, b) => a + b);
              return GCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children:
                      byType.entries.map((e) {
                        final pct = e.value / total;
                        final color =
                            e.key == 'Hazardous'
                                ? XMTheme.error
                                : (e.key == 'Recyclable'
                                    ? XMTheme.success
                                    : (e.key == 'General'
                                        ? XMTheme.info
                                        : XMTheme.warning));
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    e.key,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                              GSpacing.vSm,
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 10,
                                  backgroundColor: color.withValues(alpha: 0.1),
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error: $e'),
          ),
          GSpacing.vLg,

          // ─── ESG Scorecard ───
          Text(
            'ESG Scorecard',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          GSpacing.vMd,
          esgAsync.when(
            data: (metrics) {
              if (metrics.isEmpty) {
                return const GCard(
                  child: Center(child: Text('No ESG metrics available')),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: metrics.length,
                itemBuilder: (ctx, i) {
                  final m = metrics[i];
                  return GCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          m.category.isNotEmpty ? m.category : 'Metric',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        GSpacing.vSm,
                        Text(
                          '${m.value} ${m.unit}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsKpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _AnalyticsKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => GCard(
    width: 150,
    color: color.withValues(alpha: 0.05),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        GSpacing.vMd,
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        GSpacing.vSm,
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}
