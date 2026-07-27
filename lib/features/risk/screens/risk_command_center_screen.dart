import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/kpi_card.dart';
import '../widgets/risk_matrix_widget.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

/// Risk Command Center — KPI cards + risk distribution overview.
class RiskCommandCenterScreen extends ConsumerWidget {
  const RiskCommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
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
            stream:
                firestore
                    .tenantCollection(
                      ref.watch(currentTenantIdProvider) ?? "",
                      'dynamic_risk_assessments',
                    )
                    .where('siteId', isEqualTo: siteId)
                    .snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              int extreme = 0, high = 0, medium = 0, low = 0, unapproved = 0;
              for (final doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                switch (d['riskLevel']) {
                  case 'Extreme':
                    extreme++;
                  case 'High':
                    high++;
                  case 'Medium':
                    medium++;
                  case 'Low':
                    low++;
                }
                if (d['approved'] != true) unapproved++;
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount =
                      constraints.maxWidth > 900
                          ? 6
                          : (constraints.maxWidth > 600 ? 3 : 2);
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: constraints.maxWidth > 600 ? 1.4 : 1.1,
                    children: [
                      KpiCard(
                        label: 'Total Risks',
                        value: '${docs.length}',
                        icon: Icons.shield_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      KpiCard(
                        label: 'Extreme',
                        value: '$extreme',
                        icon: Icons.warning_amber_rounded,
                        color: XMTheme.riskExtreme,
                      ),
                      KpiCard(
                        label: 'High',
                        value: '$high',
                        icon: Icons.priority_high_rounded,
                        color: XMTheme.riskHigh,
                      ),
                      KpiCard(
                        label: 'Medium',
                        value: '$medium',
                        icon: Icons.remove_circle_outline_rounded,
                        color: XMTheme.riskMedium,
                      ),
                      KpiCard(
                        label: 'Low',
                        value: '$low',
                        icon: Icons.check_circle_outline_rounded,
                        color: XMTheme.riskLow,
                      ),
                      KpiCard(
                        label: 'Pending',
                        value: '$unapproved',
                        icon: Icons.hourglass_empty_rounded,
                        color: XMTheme.warning,
                      ),
                    ],
                  );
                },
              );
            },
          ),
          GSpacing.vLg,

          Text(
            'Risk Distribution Matrix',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          GSpacing.vXs,
          Text(
            'Likelihood vs Impact assessment heat map',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          GSpacing.vMd,
          const RiskMatrixWidget(),

          GSpacing.vLg,

          Text(
            'Recent Assessments',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          GSpacing.vXs,
          Text(
            'Latest dynamic risk evaluations',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          GSpacing.vMd,
          StreamBuilder<QuerySnapshot>(
            stream:
                firestore
                    .tenantCollection(
                      ref.watch(currentTenantIdProvider) ?? "",
                      'dynamic_risk_assessments',
                    )
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
                          Icon(
                            Icons.assessment_outlined,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          GSpacing.vMd,
                          Text(
                            'No assessments found',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children:
                    docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final level = d['riskLevel'] ?? 'Low';
                      final approved = d['approved'] == true;
                      return GCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.zero,
                        onTap: () => _showDetails(context, d),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _riskColor(level).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.assessment_rounded,
                              color: _riskColor(level),
                              size: 24,
                            ),
                          ),
                          title: Text(
                            d['task'] ?? 'Untitled Assessment',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${d['assessorName'] ?? 'Unknown'} • ${d['createdAt'] != null ? d['createdAt'].toString().split('T')[0] : 'No date'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          trailing: SizedBox(
                            height: 56,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                GStatusTag(
                                  label: level.toUpperCase(),
                                  color: _riskColor(level),
                                ),
                                const SizedBox(height: 4),
                                GStatusTag(
                                  label: approved ? 'APPROVED' : 'PENDING',
                                  color:
                                      approved
                                          ? XMTheme.success
                                          : XMTheme.warning,
                                  icon:
                                      approved
                                          ? Icons.check_circle
                                          : Icons.pending,
                                ),
                              ],
                            ),
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

  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(data['task'] ?? 'Details'),
            content: Text(
              'Assessor: ${data['assessorName'] ?? 'Unknown'}\nRisk Level: ${data['riskLevel'] ?? 'Low'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
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
