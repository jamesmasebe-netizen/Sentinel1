import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'incidents_register_screen.dart';
import 'capa_screen.dart';
import 'permit_to_work_screen.dart';
import 'hazard_register_screen.dart';
import 'bbs_observations_screen.dart';
import 'ppe_compliance_screen.dart';
import 'safety_analytics_screen.dart';
import 'incident_report_form.dart';

/// Safety & Risk Hub Dashboard — Material 3 Expressive
class SafetyHubScreen extends StatelessWidget {
  const SafetyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GHeader(
          title: 'Safety & Risk Hub',
          subtitle: 'Unified command center for organizational safety, risk assessments, and compliance.',
          trailing: FilledButton.icon(
            onPressed: () {
              UIUtils.showSideSheet(
                context: context,
                title: 'Report Incident',
                builder: (ctx) => const IncidentReportForm(),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: XMTheme.error,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_alert_rounded, size: 18),
            label: const Text('Report Incident'),
          ),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              // High-level Metrics Row
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
                          _buildMetricCard(context, 'Open Incidents', '12', Icons.report_problem, XMTheme.error, isWide),
                          if (isWide) GSpacing.hMd else GSpacing.vMd,
                          _buildMetricCard(context, 'Active Permits', '8', Icons.assignment, XMTheme.primary, isWide),
                          if (isWide) GSpacing.hMd else GSpacing.vMd,
                          _buildMetricCard(context, 'Hazards Reported', '24', Icons.warning_rounded, XMTheme.warning, isWide),
                          if (isWide) GSpacing.hMd else GSpacing.vMd,
                          _buildMetricCard(context, 'CAPA Completion', '85%', Icons.check_circle_rounded, XMTheme.success, isWide),
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
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.2,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildModuleCard(
                      context,
                      title: 'Incidents Register',
                      subtitle: 'Real-time incident tracking and reporting.',
                      icon: Icons.assignment_late_rounded,
                      color: XMTheme.error,
                      onTap: () => _openModule(context, 'Incidents Register', const IncidentsRegisterScreen()),
                    ),
                    _buildModuleCard(
                      context,
                      title: 'Permit to Work',
                      subtitle: 'Manage and approve hazardous work permits.',
                      icon: Icons.vpn_key_rounded,
                      color: XMTheme.primary,
                      onTap: () => _openModule(context, 'Permit to Work', const PermitToWorkScreen()),
                    ),
                    _buildModuleCard(
                      context,
                      title: 'Hazard Register',
                      subtitle: 'Report and track workplace hazards.',
                      icon: Icons.warning_amber_rounded,
                      color: XMTheme.warning,
                      onTap: () => _openModule(context, 'Hazard Register', const HazardRegisterScreen()),
                    ),
                    _buildModuleCard(
                      context,
                      title: 'CAPA Management',
                      subtitle: 'Corrective and Preventive Actions.',
                      icon: Icons.fact_check_rounded,
                      color: XMTheme.success,
                      onTap: () => _openModule(context, 'CAPA Management', const CAPAScreen()),
                    ),
                    _buildModuleCard(
                      context,
                      title: 'BBS Observations',
                      subtitle: 'Behavioral-based safety program.',
                      icon: Icons.visibility_rounded,
                      color: XMTheme.info,
                      onTap: () => _openModule(context, 'BBS Observations', const BBSObservationsScreen()),
                    ),
                    _buildModuleCard(
                      context,
                      title: 'PPE Compliance',
                      subtitle: 'Track equipment issuance and compliance.',
                      icon: Icons.health_and_safety_rounded,
                      color: XMTheme.primary,
                      onTap: () => _openModule(context, 'PPE Compliance', const PPEComplianceScreen()),
                    ),
                    _buildModuleCard(
                      context,
                      title: 'Safety Analytics',
                      subtitle: 'Performance indicators and safety trends.',
                      icon: Icons.analytics_rounded,
                      color: XMTheme.warning,
                      onTap: () => _openModule(context, 'Safety Analytics', const SafetyAnalyticsScreen()),
                    ),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(child: GSpacing.vXl),
            ],
          ),
        ),
      ],
    );
  }

  // Opens a module inside a massive side-sheet rather than routing away
  void _openModule(BuildContext context, String title, Widget child) {
    UIUtils.showSideSheet(
      context: context,
      title: title,
      builder: (ctx) => child,
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool isWide,
  ) {
    final theme = Theme.of(context);
    final card = GCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          GSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GSpacing.vXs,
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isWide) {
      return Expanded(child: card);
    }
    return card;
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            GSpacing.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'Open Module',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
