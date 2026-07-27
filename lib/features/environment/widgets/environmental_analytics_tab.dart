import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class EnvironmentalAnalyticsTab extends ConsumerWidget {
  const EnvironmentalAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

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
          StreamBuilder<QuerySnapshot>(
            stream:
                fs
                    .tenantCollection(
                      ref.watch(currentTenantIdProvider) ?? "",
                      'environmental_spills',
                    )
                    .where('siteId', isEqualTo: siteId)
                    .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              int total = docs.length, contained = 0, uncontained = 0;
              for (final doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                if (d['contained'] == true) {
                  contained++;
                } else {
                  uncontained++;
                }
              }
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
          StreamBuilder<QuerySnapshot>(
            stream:
                fs
                    .tenantCollection(
                      ref.watch(currentTenantIdProvider) ?? "",
                      'waste_manifests',
                    )
                    .where('siteId', isEqualTo: siteId)
                    .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              final byType = <String, int>{};
              for (final doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                final t = (d['wasteType'] ?? 'Other').toString();
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
          StreamBuilder<QuerySnapshot>(
            stream:
                fs
                    .tenantCollection(
                      ref.watch(currentTenantIdProvider) ?? "",
                      'esg_metrics',
                    )
                    .where('siteId', isEqualTo: siteId)
                    .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
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
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return GCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          d['category'] ?? 'Metric',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        GSpacing.vSm,
                        Text(
                          '${d['value']} ${d['unit']}',
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
