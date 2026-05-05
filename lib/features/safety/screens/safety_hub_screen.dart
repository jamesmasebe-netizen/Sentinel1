import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import 'incidents_register_screen.dart';
import 'capa_screen.dart';
import 'permit_to_work_screen.dart';
import 'bbs_observations_screen.dart';
import 'ppe_compliance_screen.dart';
import 'safety_analytics_screen.dart';
import 'hazard_register_screen.dart';
import 'incident_report_form.dart';

/// Safety & Risk Hub Dashboard — Material 3 Expressive
class SafetyHubScreen extends StatelessWidget {
  const SafetyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          UIUtils.showSideSheet(
            context: context,
            title: 'Report Incident',
            width: 600,
            builder: (ctx) => const IncidentReportForm(),
          );
        },
        backgroundColor: XMTheme.error,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Report Incident'),
      ),
      body: CustomScrollView(
        slivers: [
          // Dashboard Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safety & Risk Hub',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unified command center for organizational safety, risk assessments, and compliance.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                      _buildMetricCard(context, 'Open Incidents', '12', Icons.report_problem, XMTheme.error, isWide),
                      if (isWide) const SizedBox(width: 16),
                      if (!isWide) const SizedBox(height: 16),
                      _buildMetricCard(context, 'Active Permits', '8', Icons.assignment, XMTheme.primary, isWide),
                      if (isWide) const SizedBox(width: 16),
                      if (!isWide) const SizedBox(height: 16),
                      _buildMetricCard(context, 'Hazards Reported', '24', Icons.warning_rounded, XMTheme.warning, isWide),
                      if (isWide) const SizedBox(width: 16),
                      if (!isWide) const SizedBox(height: 16),
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
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisExtent: 140, // Fixed height for cards
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildListDelegate([
                _buildModuleCard(
                  context,
                  title: 'Incidents Register',
                  subtitle: 'Track and investigate workplace incidents.',
                  icon: Icons.list_alt_rounded,
                  color: XMTheme.error,
                  onTap: () => _openModule(context, 'Incidents Register', const IncidentsRegisterScreen()),
                ),
                _buildModuleCard(
                  context,
                  title: 'Permit to Work',
                  subtitle: 'Manage and approve safety permits.',
                  icon: Icons.assignment_turned_in_rounded,
                  color: XMTheme.primary,
                  onTap: () => _openModule(context, 'Permit to Work', const PermitToWorkScreen()),
                ),
                _buildModuleCard(
                  context,
                  title: 'Hazard Register',
                  subtitle: 'Identify and mitigate workplace hazards.',
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
                  subtitle: 'Behavior Based Safety reports.',
                  icon: Icons.visibility_rounded,
                  color: XMTheme.info,
                  onTap: () => _openModule(context, 'BBS Observations', const BBSObservationsScreen()),
                ),
                _buildModuleCard(
                  context,
                  title: 'PPE Compliance',
                  subtitle: 'Track personal protective equipment.',
                  icon: Icons.health_and_safety_rounded,
                  color: XMTheme.secondary,
                  onTap: () => _openModule(context, 'PPE Compliance', const PPEComplianceScreen()),
                ),
                _buildModuleCard(
                  context,
                  title: 'Safety Analytics',
                  subtitle: 'Data-driven safety insights and trends.',
                  icon: Icons.analytics_rounded,
                  color: const Color(0xFF8B5CF6), // Purple
                  onTap: () => _openModule(context, 'Safety Analytics', const SafetyAnalyticsScreen()),
                ),
              ]),
            ),
          ),
          
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // Opens a module inside a massive side-sheet rather than routing away
  void _openModule(BuildContext context, String title, Widget child) {
    // Determine a wide width for full module views
    final width = MediaQuery.sizeOf(context).width * 0.85; 
    
    UIUtils.showSideSheet(
      context: context,
      title: title,
      width: width.clamp(400.0, 1200.0), // Cap max width
      builder: (ctx) => child,
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color, bool isWide) {
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(XMTheme.radiusLg), // 24px squircle
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildModuleCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
