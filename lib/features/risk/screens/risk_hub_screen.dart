import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'risk_command_center_screen.dart';
import 'hira_screen.dart';
import 'dynamic_risk_assessment_screen.dart';
import 'bowtie_screen.dart';
import 'strategic_risk_register_screen.dart';

/// Risk Intelligence Hub — Material 3 Expressive
class RiskHubScreen extends StatelessWidget {
  const RiskHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GHeader(
          title: 'Risk Intelligence Hub',
          subtitle: 'Unified command center for organizational risk profiling, assessment, and mitigation.',
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              // High-level Metrics Row (Simplified placeholders for now)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                sliver: SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;
                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetricCard(context, 'Critical Risks', '4', Icons.gpp_maybe_rounded, XMTheme.riskExtreme, isWide),
                          if (isWide) GSpacing.hLg,
                          if (!isWide) GSpacing.vLg,
                          _buildMetricCard(context, 'Open Assessments', '12', Icons.pending_actions_rounded, XMTheme.primary, isWide),
                          if (isWide) GSpacing.hLg,
                          if (!isWide) GSpacing.vLg,
                          _buildMetricCard(context, 'Control Strength', '78%', Icons.security_rounded, XMTheme.success, isWide),
                        ],
                      );
                    },
                  ),
                ),
              ),
    
              // Main Interactive Modules Grid
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
                    _buildModuleCard(
                      context,
                      title: 'Command Center',
                      subtitle: 'Live risk posture and executive dashboard.',
                      icon: Icons.dashboard_rounded,
                      color: XMTheme.primary,
                      onTap: () => _openModule(context, 'Risk Command Center', const RiskCommandCenterScreen()),
                    ),
                    _buildModuleCard(
                      context,
                      title: 'HIRA Register',
                      subtitle: 'Baseline Hazard Identification & Risk Assessment.',
                      icon: Icons.assessment_rounded,
                      color: XMTheme.warning,
                      onTap: () => _openModule(context, 'Baseline HIRA', const HiraScreen()),
                    ),
                    _buildModuleCard(
                      context,
                      title: 'Dynamic RA',
                      subtitle: 'Continuous and task-specific risk evaluations.',
                      icon: Icons.bolt_rounded,
                      color: XMTheme.error,
                      onTap: () => _openModule(context, 'Dynamic Risk Assessment', const DynamicRiskAssessmentScreen()),
                    ),
                    _buildModuleCard(
                      context,
                      title: 'Bow-Tie Analysis',
                      subtitle: 'Visualize barriers, threats, and consequences.',
                      icon: Icons.account_tree_rounded,
                      color: XMTheme.info,
                      onTap: () => _openModule(context, 'Bow-Tie Analysis', const BowtieScreen()),
                    ),
                    _buildModuleCard(
                      context,
                      title: 'Strategic Register',
                      subtitle: 'High-level organizational risk tracking.',
                      icon: Icons.list_alt_rounded,
                      color: XMTheme.secondary,
                      onTap: () => _openModule(context, 'Strategic Risk Register', const StrategicRiskRegisterScreen()),
                    ),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(child: GSpacing.vXxl),
            ],
          ),
        ),
      ],
    );
  }

  void _openModule(BuildContext context, String title, Widget child) {
    UIUtils.showSideSheet(
      context: context,
      title: title,
      builder: (ctx) => child,
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color, bool isWide) {
    final theme = Theme.of(context);
    final card = GCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          GSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                GSpacing.vXs,
                Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
    return isWide ? Expanded(child: card) : card;
  }

  Widget _buildModuleCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return GCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            GSpacing.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  GSpacing.vSm,
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Row(
                    children: [
                      Text('Open Module', style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
                      GSpacing.hSm,
                      Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
