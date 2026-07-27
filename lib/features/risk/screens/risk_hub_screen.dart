import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'hira_screen.dart';
import 'dynamic_risk_assessment_screen.dart';
import 'strategic_risk_register_screen.dart';
import 'bowtie_screen.dart';
import 'risk_command_center_screen.dart';
import 'widgets/stream_metric_card.dart';
import 'widgets/risk_module_card.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

/// Risk Management Hub — Unified access to HIRAs, DRAs, Bowties, and command centers.
class RiskHubScreen extends ConsumerWidget {
  const RiskHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);

    final criticalRisksStream =
        siteId == null
            ? Stream.value('0')
            : firestore
                .tenantCollection(
                  ref.watch(currentTenantIdProvider) ?? "",
                  'hazards',
                )
                .where('siteId', isEqualTo: siteId)
                .snapshots()
                .map(
                  (s) =>
                      s.docs
                          .where((d) {
                            final severity = d.data()['severity'] ?? '';
                            return severity == 'Major' ||
                                severity == 'Critical';
                          })
                          .length
                          .toString(),
                );

    final openAssessmentsStream =
        siteId == null
            ? Stream.value('0')
            : firestore
                .tenantCollection(
                  ref.watch(currentTenantIdProvider) ?? "",
                  'dynamic_risk_assessments',
                )
                .where('siteId', isEqualTo: siteId)
                .snapshots()
                .map(
                  (s) =>
                      s.docs
                          .where((d) => d.data()['status'] != 'Approved')
                          .length
                          .toString(),
                );

    final controlStrengthStream =
        siteId == null
            ? Stream.value('100%')
            : firestore
                .tenantCollection(
                  ref.watch(currentTenantIdProvider) ?? "",
                  'dynamic_risk_assessments',
                )
                .where('siteId', isEqualTo: siteId)
                .snapshots()
                .map((s) {
                  if (s.docs.isEmpty) return '80%';
                  final approved =
                      s.docs
                          .where((d) => d.data()['status'] == 'Approved')
                          .length;
                  return '${((approved / s.docs.length) * 100).round()}%';
                });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Risk Management Hub',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GSpacing.vSm,
                  Text(
                    'Evaluate risk thresholds, baseline HIRA, bowtie analysis, and dynamic controls.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // High-level Metrics Row
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StreamMetricCard(
                        title: 'Critical Risks',
                        valueStream: criticalRisksStream,
                        icon: Icons.gpp_maybe_rounded,
                        color: XMTheme.riskExtreme,
                        isWide: isWide,
                        initialValue: '0',
                      ),
                      if (isWide) GSpacing.hLg else GSpacing.vLg,
                      StreamMetricCard(
                        title: 'Open Assessments',
                        valueStream: openAssessmentsStream,
                        icon: Icons.pending_actions_rounded,
                        color: XMTheme.primary,
                        isWide: isWide,
                        initialValue: '0',
                      ),
                      if (isWide) GSpacing.hLg else GSpacing.vLg,
                      StreamMetricCard(
                        title: 'Control Strength',
                        valueStream: controlStrengthStream,
                        icon: Icons.security_rounded,
                        color: XMTheme.success,
                        isWide: isWide,
                        initialValue: '80%',
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisExtent: 140,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildListDelegate([
                RiskModuleCard(
                  title: 'Command Center',
                  subtitle: 'Live risk posture and executive dashboard.',
                  icon: Icons.dashboard_rounded,
                  color: XMTheme.primary,
                  onTap:
                      () => _openModule(
                        context,
                        'Risk Command Center',
                        const RiskCommandCenterScreen(),
                      ),
                ),
                RiskModuleCard(
                  title: 'HIRA Register',
                  subtitle: 'Baseline Hazard Identification & Risk Assessment.',
                  icon: Icons.assessment_rounded,
                  color: XMTheme.warning,
                  onTap:
                      () => _openModule(
                        context,
                        'Baseline HIRA',
                        const HiraScreen(),
                      ),
                ),
                RiskModuleCard(
                  title: 'Dynamic RA',
                  subtitle: 'Continuous and task-specific risk evaluations.',
                  icon: Icons.bolt_rounded,
                  color: XMTheme.error,
                  onTap:
                      () => _openModule(
                        context,
                        'Dynamic Risk Assessment',
                        const DynamicRiskAssessmentScreen(),
                      ),
                ),
                RiskModuleCard(
                  title: 'Bow-Tie Analysis',
                  subtitle: 'Visualize barriers, threats, and consequences.',
                  icon: Icons.account_tree_rounded,
                  color: XMTheme.info,
                  onTap:
                      () => _openModule(
                        context,
                        'Bow-Tie Analysis',
                        const BowtieScreen(),
                      ),
                ),
                RiskModuleCard(
                  title: 'Strategic Register',
                  subtitle: 'High-level organizational risk tracking.',
                  icon: Icons.list_alt_rounded,
                  color: XMTheme.secondary,
                  onTap:
                      () => _openModule(
                        context,
                        'Strategic Risk Register',
                        const StrategicRiskRegisterScreen(),
                      ),
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: GSpacing.vXxl),
        ],
      ),
    );
  }

  void _openModule(BuildContext context, String title, Widget child) {
    UIUtils.showSideSheet(
      context: context,
      title: title,
      builder: (ctx) => child,
    );
  }
}
