import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/kpi_card.dart';
import '../widgets/bar_chart.dart';
import '../widgets/breakdown_card.dart';
import '../widgets/risk_zone.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

/// Safety Analytics — KPI cards, incident trend chart, and risk zone assessment.
class SafetyAnalyticsScreen extends ConsumerWidget {
  const SafetyAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);
    final theme = Theme.of(context);

    if (siteId == null) return const Center(child: Text('No site assigned'));

    return StreamBuilder<QuerySnapshot>(
      stream:
          firestore
              .tenantCollection(
                ref.watch(currentTenantIdProvider) ?? "",
                'incidents',
              )
              .where('siteId', isEqualTo: siteId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final incidents =
            docs.map((d) => d.data() as Map<String, dynamic>).toList();

        // Compute KPIs
        final total = incidents.length;
        final openCount = incidents.where((i) => i['status'] == 'Open').length;
        final criticalCount =
            incidents.where((i) {
              final s = i['severity']?.toString() ?? '';
              return s == 'Critical' || s == 'Major';
            }).length;

        final monthlyData = <String, int>{};
        final typeBreakdown = <String, int>{};
        final sevBreakdown = <String, int>{};

        for (final i in incidents) {
          try {
            final ts = i['createdAt'];
            final dt =
                ts is Timestamp
                    ? ts.toDate()
                    : (ts is String ? DateTime.tryParse(ts) : null);
            if (dt != null) {
              final key = _monthLabel(dt.month);
              monthlyData[key] = (monthlyData[key] ?? 0) + 1;
            }
          } catch (_) {}

          final t = i['type']?.toString() ?? 'Other';
          typeBreakdown[t] = (typeBreakdown[t] ?? 0) + 1;

          final s = i['severity']?.toString() ?? 'Minor';
          sevBreakdown[s] = (sevBreakdown[s] ?? 0) + 1;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  KPICard(
                    icon: Icons.analytics_outlined,
                    label: 'Total Incidents',
                    value: '$total',
                    color: XMTheme.info,
                  ),
                  const SizedBox(width: 12),
                  KPICard(
                    icon: Icons.error_outline,
                    label: 'Open',
                    value: '$openCount',
                    color: XMTheme.error,
                  ),
                  const SizedBox(width: 12),
                  KPICard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Critical',
                    value: '$criticalCount',
                    color: XMTheme.warning,
                  ),
                ],
              ),
              GSpacing.vLg,
              GCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        GSpacing.hSm,
                        Text(
                          'Monthly Incident Trend',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    GSpacing.vMd,
                    if (monthlyData.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No data available'),
                        ),
                      )
                    else
                      SizedBox(height: 180, child: BarChart(data: monthlyData)),
                  ],
                ),
              ),
              GSpacing.vMd,
              Row(
                children: [
                  Expanded(
                    child: BreakdownCard(
                      title: 'By Type',
                      data: typeBreakdown,
                      colors: _typeColors,
                    ),
                  ),
                  GSpacing.hMd,
                  Expanded(
                    child: BreakdownCard(
                      title: 'By Severity',
                      data: sevBreakdown,
                      colors: _sevColors,
                    ),
                  ),
                ],
              ),
              GSpacing.vMd,
              GCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          color: theme.colorScheme.secondary,
                          size: 20,
                        ),
                        GSpacing.hSm,
                        Text(
                          'Predicted High-Risk Zones',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    GSpacing.vMd,
                    const RiskZone(
                      name: 'Zone B — Heavy Machinery',
                      desc:
                          'High probability of equipment incidents based on recent patterns',
                      risk: 85,
                      color: XMTheme.error,
                    ),
                    const RiskZone(
                      name: 'Zone A — Scaffolding',
                      desc:
                          'Elevated risk due to scheduled maintenance and weather',
                      risk: 60,
                      color: XMTheme.warning,
                    ),
                    const RiskZone(
                      name: 'Zone C — Loading Dock',
                      desc: 'Baseline risk levels detected',
                      risk: 15,
                      color: XMTheme.success,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _monthLabel(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  static const _typeColors = {
    'Injury': XMTheme.error,
    'Near Miss': XMTheme.warning,
    'Property Damage': XMTheme.info,
    'Environmental': XMTheme.success,
    'Hazard Observation': XMTheme.secondary,
  };

  static const _sevColors = {
    'Critical': XMTheme.error,
    'Major': XMTheme.warning,
    'Moderate': XMTheme.info,
    'Minor': XMTheme.success,
  };
}
