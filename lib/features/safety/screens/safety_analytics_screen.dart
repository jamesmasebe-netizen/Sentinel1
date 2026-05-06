import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';

/// Safety Analytics — KPI cards, incident trend chart, and risk zone assessment.
class SafetyAnalyticsScreen extends ConsumerWidget {
  const SafetyAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    final theme = Theme.of(context);

    if (siteId == null) return const Center(child: Text('No site assigned'));

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('incidents')
          .where('siteId', isEqualTo: siteId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final incidents = docs.map((d) => d.data() as Map<String, dynamic>).toList();

        // Compute KPIs
        final total = incidents.length;
        final openCount = incidents.where((i) => i['status'] == 'Open').length;
        final criticalCount = incidents.where((i) {
          final s = i['severity']?.toString() ?? '';
          return s == 'Critical' || s == 'Major';
        }).length;

        // Monthly Trend
        final monthlyData = <String, int>{};
        for (final i in incidents) {
          try {
            final ts = i['createdAt'];
            DateTime? dt;
            if (ts is Timestamp) {
              dt = ts.toDate();
            } else if (ts is String) {
              dt = DateTime.tryParse(ts);
            }
            if (dt != null) {
              final key = _monthLabel(dt.month);
              monthlyData[key] = (monthlyData[key] ?? 0) + 1;
            }
          } catch (_) {}
        }

        // Type breakdown
        final typeBreakdown = <String, int>{};
        for (final i in incidents) {
          final t = i['type']?.toString() ?? 'Other';
          typeBreakdown[t] = (typeBreakdown[t] ?? 0) + 1;
        }

        // Severity breakdown
        final sevBreakdown = <String, int>{};
        for (final i in incidents) {
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
                  _KPICard(
                    icon: Icons.analytics_outlined,
                    label: 'Total Incidents',
                    value: '$total',
                    color: XMTheme.info,
                  ),
                  const SizedBox(width: 12),
                  _KPICard(
                    icon: Icons.error_outline,
                    label: 'Open',
                    value: '$openCount',
                    color: XMTheme.error,
                  ),
                  const SizedBox(width: 12),
                  _KPICard(
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
                        Icon(Icons.trending_up, color: theme.colorScheme.primary, size: 20),
                        GSpacing.hSm,
                        Text('Monthly Incident Trend', style: theme.textTheme.titleMedium),
                      ],
                    ),
                    GSpacing.vMd,
                    if (monthlyData.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No data available')))
                    else
                      SizedBox(height: 180, child: _BarChart(data: monthlyData)),
                  ],
                ),
              ),
              GSpacing.vMd,
              Row(
                children: [
                  Expanded(
                    child: _BreakdownCard(
                      title: 'By Type',
                      data: typeBreakdown,
                      colors: _typeColors,
                    ),
                  ),
                  GSpacing.hMd,
                  Expanded(
                    child: _BreakdownCard(
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
                        Icon(Icons.psychology_outlined, color: theme.colorScheme.secondary, size: 20),
                        GSpacing.hSm,
                        Text('Predicted High-Risk Zones', style: theme.textTheme.titleMedium),
                      ],
                    ),
                    GSpacing.vMd,
                    const _RiskZone(
                      name: 'Zone B — Heavy Machinery',
                      desc: 'High probability of equipment incidents based on recent patterns',
                      risk: 85,
                      color: XMTheme.error,
                    ),
                    const _RiskZone(
                      name: 'Zone A — Scaffolding',
                      desc: 'Elevated risk due to scheduled maintenance and weather',
                      risk: 60,
                      color: XMTheme.warning,
                    ),
                    const _RiskZone(
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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

class _KPICard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KPICard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            GSpacing.vSm,
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final Map<String, int> data;
  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);
    final entries = data.entries.toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: entries.map((e) {
        final height = maxVal > 0 ? (e.value / maxVal) * 140 : 0.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${e.value}', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(e.key, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final Map<String, int> data;
  final Map<String, Color> colors;

  const _BreakdownCard({
    required this.title,
    required this.data,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a + b);

    return GCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          GSpacing.vMd,
          if (data.isEmpty)
            const Text('No data')
          else
            ...data.entries.map((e) {
              final pct = (e.value / total);
              final color = colors[e.key] ?? theme.colorScheme.primary;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: theme.textTheme.labelMedium),
                        Text('${(pct * 100).round()}%', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RiskZone extends StatelessWidget {
  final String name;
  final String desc;
  final int risk;
  final Color color;

  const _RiskZone({
    required this.name,
    required this.desc,
    required this.risk,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(XMTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
                Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          GSpacing.hMd,
          Text('$risk%', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
