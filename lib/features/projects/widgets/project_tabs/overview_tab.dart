import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../models/project_models.dart';
import 'overview_dialogs.dart';
import 'project_health_status.dart';
import 'project_metrics_grid.dart';
import '../../../../core/bpf/bpf_ribbon_widget.dart';
import '../../../../core/bpf/project_lifecycle_bpf.dart';

class OverviewTab extends ConsumerWidget {
  final Project project;
  const OverviewTab({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BpfRibbonWidget(
            bpfTypeId: 'project_lifecycle',
            recordType: 'project',
            recordId: project.id,
            definition: projectLifecycleDefinition,
          ),
          GSpacing.vLg,
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GStatusTag(
                label: project.status,
                color:
                    project.status == 'Active'
                        ? XMTheme.success
                        : XMTheme.primary,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                onPressed:
                    () => showEditProjectDetailsDialog(context, project, ref),
                tooltip: 'Edit Project details',
              ),
            ],
          ),
          GSpacing.vSm,
          Text(
            '${project.id} • ${project.category}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          GSpacing.vLg,

          // ─── Live Health Status Hero ───
          ProjectHealthStatus(project: project),
          GSpacing.vLg,

          // ─── Quick Actions & Associated Metrics ───
          Text(
            'Project Metrics & Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          GSpacing.vMd,
          ProjectMetricsGrid(project: project),
          GSpacing.vLg,

          GCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      onPressed: () {
                        showEditDescriptionDialog(context, project, ref);
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                GSpacing.vSm,
                Text(project.description),
                GSpacing.vLg,
                const Divider(),
                GSpacing.vLg,
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Start Date',
                        project.startDate.toIso8601String().split('T')[0],
                        Icons.calendar_today,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Target Date',
                        project.targetEndDate.toIso8601String().split('T')[0],
                        Icons.event_available,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Budget',
                        'R${project.budget.toStringAsFixed(2)}',
                        Icons.monetization_on,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GSpacing.vMd,
          GCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Contacts & Escalation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      onPressed: () {
                        showEditContactsDialog(context, project, ref);
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                GSpacing.vMd,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: XMTheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Project Lead',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            project.projectLead.isNotEmpty
                                ? project.projectLead
                                : 'None Assigned',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (project.projectLeadContact.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              project.projectLeadContact,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 16,
                                color: XMTheme.warning,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Backup / Escalation',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            project.fallbackContact.isNotEmpty
                                ? project.fallbackContact
                                : 'None Assigned',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (project.fallbackContactContact.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              project.fallbackContactContact,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: XMTheme.primary),
        GSpacing.hSm,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
