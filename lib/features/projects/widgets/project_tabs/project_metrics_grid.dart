import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../config/theme.dart';
import '../../../../../core/utils/ui_utils.dart';
import '../../../safety/screens/incidents_register_screen.dart';
import '../../../safety/screens/incident_report_form.dart';
import '../../../safety/screens/capa_screen.dart';
import '../../../safety/screens/permit_to_work_screen.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';
import 'package:xm_system/core/providers/app_providers.dart';

class ProjectMetricsGrid extends ConsumerWidget {
  final Project project;

  const ProjectMetricsGrid({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildMetricActionCard(
          context,
          'Incidents',
          ref.watch(projectIncidentsProvider(project.id)).valueOrNull?.length ??
              0,
          Icons.local_hospital,
          XMTheme.error,
          () {
            UIUtils.showSideSheet(
              context: context,
              title: 'Incidents Register',
              builder: (ctx) => const IncidentsRegisterScreen(),
            );
          },
        ),
        _buildMetricActionCard(
          context,
          'NCRs',
          project.totalNcrs,
          Icons.assignment_late,
          XMTheme.warning,
          () {
            UIUtils.showSideSheet(
              context: context,
              title: 'Report Incident',
              builder:
                  (ctx) => IncidentReportForm(
                    tenantId: ref.read(currentTenantIdProvider) ?? '',
                  ),
            );
          },
        ),
        _buildMetricActionCard(
          context,
          'CAPAs',
          ref.watch(projectCapasProvider(project.id)).valueOrNull?.length ?? 0,
          Icons.check_circle_outline,
          XMTheme.success,
          () {
            UIUtils.showSideSheet(
              context: context,
              title: 'CAPA Management',
              builder: (ctx) => const CAPAScreen(),
            );
          },
        ),
        _buildMetricActionCard(
          context,
          'Permits',
          ref
                  .watch(projectRiskAssessmentsProvider(project.id))
                  .valueOrNull
                  ?.length ??
              0,
          Icons.assignment_turned_in,
          XMTheme.info,
          () {
            UIUtils.showSideSheet(
              context: context,
              title: 'Permit to Work',
              builder: (ctx) => const PermitToWorkScreen(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricActionCard(
    BuildContext context,
    String title,
    int count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.add_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
