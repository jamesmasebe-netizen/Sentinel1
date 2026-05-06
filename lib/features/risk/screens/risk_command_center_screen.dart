import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';

/// Risk Command Center — KPI cards + risk distribution overview.
class RiskCommandCenterScreen extends ConsumerWidget {
  const RiskCommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    final theme = Theme.of(context);

    if (siteId == null) return const Center(child: Text('No site assigned'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── KPI Grid ───
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

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 900 ? 6 : (constraints.maxWidth > 600 ? 3 : 2);
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: constraints.maxWidth > 600 ? 1.4 : 1.1,
                    children: [
                      _KpiCard(label: 'Total Risks', value: '${docs.length}', icon: Icons.shield_outlined, color: theme.colorScheme.primary),
                      _KpiCard(label: 'Extreme', value: '$extreme', icon: Icons.warning_amber_rounded, color: XMTheme.riskExtreme),
                      _KpiCard(label: 'High', value: '$high', icon: Icons.priority_high_rounded, color: XMTheme.riskHigh),
                      _KpiCard(label: 'Medium', value: '$medium', icon: Icons.remove_circle_outline_rounded, color: XMTheme.riskMedium),
                      _KpiCard(label: 'Low', value: '$low', icon: Icons.check_circle_outline_rounded, color: XMTheme.riskLow),
                      _KpiCard(label: 'Pending', value: '$unapproved', icon: Icons.hourglass_empty_rounded, color: XMTheme.warning),
                    ],
                  );
                },
              );
            },
          ),
          GSpacing.vLg,

          Text('Risk Distribution Matrix', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          GSpacing.vXs,
          Text('Likelihood vs Impact assessment heat map', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          GSpacing.vMd,
          _buildRiskMatrix(context),

          GSpacing.vLg,

          Text('Recent Assessments', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          GSpacing.vXs,
          Text('Latest dynamic risk evaluations', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          GSpacing.vMd,
          StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('dynamic_risk_assessments')
                .where('siteId', isEqualTo: siteId)
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              final theme = Theme.of(context);
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return GCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.assessment_outlined, size: 48, color: theme.colorScheme.outline),
                          GSpacing.vMd,
                          Text('No assessments found', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final level = d['riskLevel'] ?? 'Low';
                  final approved = d['approved'] == true;
                  return GCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.zero,
                    onTap: () {},
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _riskColor(level).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.assessment_rounded, color: _riskColor(level), size: 24),
                      ),
                      title: Text(d['task'] ?? 'Untitled Assessment', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${d['assessorName'] ?? 'Unknown'} • ${d['createdAt'] != null ? d['createdAt'].toString().split('T')[0] : 'No date'}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GStatusTag(label: level.toUpperCase(), color: _riskColor(level)),
                          GSpacing.vXs,
                          GStatusTag(label: approved ? 'APPROVED' : 'PENDING', color: approved ? XMTheme.success : XMTheme.warning, icon: approved ? Icons.check_circle : Icons.pending),
                        ],
                      ),
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
    final theme = Theme.of(context);
    final levels = ['Extreme', 'High', 'Medium', 'Low'];
    final colors = [
      XMTheme.riskExtreme,
      XMTheme.riskHigh,
      XMTheme.riskMedium,
      XMTheme.riskLow,
    ];

    return GCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 80),
              ...[
                'Rare',
                'Unlikely',
                'Possible',
                'Likely',
                'Almost Certain',
              ].map(
                (l) => Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          GSpacing.vSm,
          ...List.generate(4, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      levels[row],
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors[row],
                      ),
                    ),
                  ),
                  ...List.generate(5, (col) {
                    final intensity = (4 - row + col) / 8;
                    final cellColor = colors[row].withValues(
                      alpha: 0.1 + intensity * 0.6,
                    );
                    return Expanded(
                      child: Container(
                        height: 42,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colors[row].withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${(row + col + 1)}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors[row],
                            ),
                          ),
                        ),
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
      case 'Extreme':
        return XMTheme.riskExtreme;
      case 'High':
        return XMTheme.riskHigh;
      case 'Medium':
        return XMTheme.riskMedium;
      default:
        return XMTheme.riskLow;
    }
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      color: color.withValues(alpha: 0.08),
      border: BorderSide(color: color.withValues(alpha: 0.2)),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            GSpacing.vMd,
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            GSpacing.vXs,
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
