import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Risk Command Center — KPI cards + risk distribution overview.
class RiskCommandCenterScreen extends ConsumerWidget {
  const RiskCommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);

    if (siteId == null) return const Center(child: Text('No site assigned'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Risk Command Center', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Live risk posture for $siteId', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),

          // ─── KPI Row ───
          StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('dynamic_risk_assessments').where('siteId', isEqualTo: siteId).snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              int extreme = 0, high = 0, medium = 0, low = 0, unapproved = 0;
              for (final doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                switch (d['riskLevel']) {
                  case 'Extreme': extreme++;
                  case 'High': high++;
                  case 'Medium': medium++;
                  case 'Low': low++;
                }
                if (d['approved'] != true) unapproved++;
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _KpiCard(label: 'Total Risks', value: '${docs.length}', icon: Icons.shield, color: XMTheme.primary),
                  _KpiCard(label: 'Extreme', value: '$extreme', icon: Icons.warning, color: XMTheme.riskExtreme),
                  _KpiCard(label: 'High', value: '$high', icon: Icons.priority_high, color: XMTheme.riskHigh),
                  _KpiCard(label: 'Medium', value: '$medium', icon: Icons.remove_circle, color: XMTheme.riskMedium),
                  _KpiCard(label: 'Low', value: '$low', icon: Icons.check_circle, color: XMTheme.riskLow),
                  _KpiCard(label: 'Pending Approval', value: '$unapproved', icon: Icons.hourglass_empty, color: XMTheme.warning),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ─── Risk Matrix Heatmap ───
          Text('Risk Distribution Matrix', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildRiskMatrix(context),

          const SizedBox(height: 24),

          // ─── Recent Assessments ───
          Text('Recent Assessments', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('dynamic_risk_assessments').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(5).snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Text('No assessments yet');
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final level = d['riskLevel'] ?? 'Low';
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(XMTheme.radiusLg),
                      side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _riskColor(level).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(XMTheme.radiusXl),
                        ),
                        child: Icon(Icons.assessment, color: _riskColor(level), size: 20),
                      ),
                      title: Text(d['task'] ?? 'Untitled', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('${d['assessorName'] ?? 'Unknown'} • $level', style: const TextStyle(fontSize: 12)),
                      trailing: d['approved'] == true
                          ? const Icon(Icons.check_circle, color: XMTheme.success, size: 20)
                          : const Icon(Icons.pending, color: XMTheme.warning, size: 20),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRiskMatrix(BuildContext context) {
    final levels = ['Extreme', 'High', 'Medium', 'Low'];
    final colors = [XMTheme.riskExtreme, XMTheme.riskHigh, XMTheme.riskMedium, XMTheme.riskLow];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 80),
              ...['Rare', 'Unlikely', 'Possible', 'Likely', 'Almost Certain'].map((l) =>
                Expanded(child: Center(child: Text(l, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.center))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(4, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(levels[row], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors[row]))),
                  ...List.generate(5, (col) {
                    final intensity = (4 - row + col) / 8;
                    final cellColor = colors[row].withValues(alpha: 0.1 + intensity * 0.5);
                    return Expanded(
                      child: Container(
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(child: Text('${(row + col + 1)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors[row]))),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'Extreme': return XMTheme.riskExtreme;
      case 'High': return XMTheme.riskHigh;
      case 'Medium': return XMTheme.riskMedium;
      default: return XMTheme.riskLow;
    }
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: color.withValues(alpha: 0.15)),
      ),
      color: color.withValues(alpha: 0.06),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
      ),
    );
  }
}
