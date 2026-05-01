import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Safety Analytics — KPI cards, incident trend chart, and risk zone assessment.
/// Mirrors React SafetyAnalytics: risk score, monthly aggregation, predicted high-risk zones.
class SafetyAnalyticsScreen extends ConsumerWidget {
  const SafetyAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);

    if (siteId == null) return const Center(child: Text('No site assigned'));

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('incidents')
          .where('siteId', isEqualTo: siteId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final incidents = docs.map((d) => d.data() as Map<String, dynamic>).toList();

        // Compute KPIs
        final total = incidents.length;
        final openCount = incidents.where((i) => i['status'] == 'Open').length;
        final criticalCount = incidents.where((i) => i['severity'] == 'Critical' || i['severity'] == 'Major').length;

        // Risk score: recent 30-day incidents × 15 (capped at 100)
        final recent30 = incidents.where((i) {
          try {
            return DateTime.parse(i['createdAt']).isAfter(DateTime.now().subtract(const Duration(days: 30)));
          } catch (_) {
            return false;
          }
        }).length;
        final riskScore = (recent30 * 15).clamp(0, 100);

        // Monthly aggregation
        final monthlyData = <String, int>{};
        for (final i in incidents) {
          try {
            final dt = DateTime.parse(i['createdAt']);
            final key = _monthLabel(dt.month);
            monthlyData[key] = (monthlyData[key] ?? 0) + 1;
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
          final s = i['severity']?.toString() ?? 'Unknown';
          sevBreakdown[s] = (sevBreakdown[s] ?? 0) + 1;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Predictive Safety Analytics', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),

              // ─── KPI Cards ───
              Row(
                children: [
                  _KPICard(
                    icon: Icons.shield,
                    label: 'Risk Score',
                    value: '$riskScore/100',
                    color: riskScore > 50 ? XMTheme.error : XMTheme.success,
                  ),
                  _KPICard(icon: Icons.trending_up, label: 'Total YTD', value: '$total', color: XMTheme.info),
                  _KPICard(icon: Icons.error_outline, label: 'Open', value: '$openCount', color: XMTheme.statusOpen),
                  _KPICard(icon: Icons.warning, label: 'Critical', value: '$criticalCount', color: XMTheme.severityCritical),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Incident Trend (bar chart using CustomPaint) ───
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up, color: XMTheme.info, size: 18),
                          const SizedBox(width: 8),
                          Text('Monthly Incident Trend', style: Theme.of(context).textTheme.titleSmall),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (monthlyData.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No data to display')))
                      else
                        SizedBox(
                          height: 180,
                          child: _BarChart(data: monthlyData),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Type & Severity Breakdown ───
              Row(
                children: [
                  Expanded(child: _BreakdownCard(title: 'By Type', data: typeBreakdown, colors: _typeColors)),
                  const SizedBox(width: 12),
                  Expanded(child: _BreakdownCard(title: 'By Severity', data: sevBreakdown, colors: _sevColors)),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Predicted High-Risk Zones (mock) ───
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber, color: XMTheme.warning, size: 18),
                          const SizedBox(width: 8),
                          Text('Predicted High-Risk Zones', style: Theme.of(context).textTheme.titleSmall),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _RiskZone(name: 'Zone B — Heavy Machinery', desc: 'High probability of equipment incidents', risk: 85, color: XMTheme.error),
                      _RiskZone(name: 'Zone A — Scaffolding', desc: 'Elevated risk due to weather conditions', risk: 60, color: XMTheme.warning),
                      _RiskZone(name: 'Zone C — Loading Dock', desc: 'Normal operations, continue monitoring', risk: 15, color: XMTheme.info),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
    'Critical': XMTheme.severityCritical,
    'Major': XMTheme.severityMajor,
    'Moderate': XMTheme.severityModerate,
    'Minor': XMTheme.severityMinor,
  };
}

// ─── Reusable sub-widgets ───

class _KPICard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _KPICard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
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
    final maxVal = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);
    final entries = data.entries.toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: entries.map((e) {
        final height = maxVal > 0 ? (e.value / maxVal) * 140 : 0.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${e.value}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [XMTheme.error.withValues(alpha: 0.8), XMTheme.error.withValues(alpha: 0.3)],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(e.key, style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
  const _BreakdownCard({required this.title, required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final total = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            if (data.isEmpty)
              const Text('No data', style: TextStyle(fontSize: 12))
            else
              ...data.entries.map((e) {
                final pct = (e.value / total * 100).round();
                final color = colors[e.key] ?? XMTheme.statusDraft;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: const TextStyle(fontSize: 12)),
                          Text('${e.value} ($pct%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _RiskZone extends StatelessWidget {
  final String name;
  final String desc;
  final int risk;
  final Color color;
  const _RiskZone({required this.name, required this.desc, required this.risk, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
                Text(desc, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$risk%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}
