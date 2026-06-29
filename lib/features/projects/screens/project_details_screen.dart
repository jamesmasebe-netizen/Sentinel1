import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../models/project_models.dart';
import '../providers/project_providers.dart';
import '../widgets/custom_gantt_chart.dart';

class ProjectDetailsScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectProvider(widget.projectId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Project Details'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'PRINCE2 Workflow'),
            Tab(text: 'Timeline & Tasks'),
            Tab(text: 'Safety & Compliance'),
          ],
        ),
      ),
      body: projectAsync.when(
        data: (project) {
          if (project == null) {
             return const Center(child: Text('Project not found.'));
          }
          return TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildOverviewTab(project),
              _buildWorkflowTab(project),
              _buildTimelineTab(project),
              _buildSafetyTab(project),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildOverviewTab(Project project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              GStatusTag(
                label: project.status,
                color: project.status == 'Active' ? XMTheme.success : XMTheme.primary,
              ),
            ],
          ),
          GSpacing.vSm,
          Text(
            '${project.id} • ${project.category}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          GSpacing.vLg,

          GCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                GSpacing.vSm,
                Text(project.description),
                GSpacing.vLg,
                const Divider(),
                GSpacing.vLg,
                Row(
                  children: [
                    Expanded(child: _buildInfoItem('Start Date', project.startDate.toIso8601String().split('T')[0], Icons.calendar_today)),
                    Expanded(child: _buildInfoItem('Target Date', project.targetEndDate.toIso8601String().split('T')[0], Icons.event_available)),
                    Expanded(child: _buildInfoItem('Budget', '\$${project.budget.toStringAsFixed(2)}', Icons.monetization_on)),
                  ],
                ),
              ],
            ),
          )
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
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildWorkflowTab(Project project) {
    if (project.stages.isEmpty) {
      return const Center(child: Text('No workflow stages defined.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: project.stages.length,
      itemBuilder: (context, index) {
        final stage = project.stages[index];
        final isCompleted = stage.status == 'Completed';
        final isPending = stage.status == 'Pending';

        return Opacity(
          opacity: isPending && index > 0 && project.stages[index-1].status != 'Completed' ? 0.5 : 1.0,
          child: GCard(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? XMTheme.success : (isPending ? Colors.grey.shade300 : XMTheme.primary),
                  ),
                  child: Center(
                    child: isCompleted
                       ? const Icon(Icons.check, color: Colors.white, size: 16)
                       : Text('${stage.order}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                GSpacing.hMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stage.stageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (stage.requiresSafetyClearance) ...[
                        GSpacing.vXs,
                        const Row(
                          children: [
                            Icon(Icons.lock, size: 12, color: XMTheme.error),
                            SizedBox(width: 4),
                            Text('Requires Safety Clearance', style: TextStyle(color: XMTheme.error, fontSize: 12)),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
                if (!isCompleted)
                  FilledButton.icon(
                    onPressed: () => _showApprovalDialog(context, project, stage),
                    icon: const Icon(Icons.verified, size: 16),
                    label: const Text('Approve'),
                  )
                else
                  Text('Approved by ${stage.approvedBy}', style: const TextStyle(color: XMTheme.success, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showApprovalDialog(BuildContext context, Project project, ProjectStage stage) {
    String selectedApprover = 'System Default';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Approve Stage'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select an approver for ${stage.stageName}:'),
                  GSpacing.vMd,
                  DropdownButtonFormField<String>(
                    value: selectedApprover,
                    decoration: const InputDecoration(labelText: 'Approver'),
                    items: ['System Default', 'John Doe (PM)', 'Jane Smith (Exec)', 'Safety Officer']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedApprover = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _handleStageApproval(context, project, stage, selectedApprover);
                  },
                  child: const Text('Approve'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _handleStageApproval(BuildContext context, Project project, ProjectStage stage, String approverId) async {
    final service = ref.read(projectServiceProvider);

    try {
      UIUtils.showToast(context, 'Validating compliance...');
      await service.approveStage(project.id, stage.id, approverId);
      if (context.mounted) {
         UIUtils.showToast(context, 'Stage approved successfully.', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
         UIUtils.showToast(context, e.toString(), type: ToastType.error);

         // Trigger Action Item automatically on failure
         service.triggerSafetyActionItem(
           project,
           'Stage Clearance Failed - ${stage.stageName}',
           e.toString()
         );
      }
    }
  }

  Widget _buildTimelineTab(Project project) {
    if (project.tasks.isEmpty) {
      return const Center(child: Text('No tasks available for Gantt view.'));
    }
    return CustomGanttChart(tasks: project.tasks, projectId: project.id);
  }

  Widget _buildSafetyTab(Project project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Safety & Compliance Metrics', style: Theme.of(context).textTheme.titleLarge),
          GSpacing.vLg,
          Row(
            children: [
              Expanded(
                child: GCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.shield, color: XMTheme.success, size: 48),
                      GSpacing.vSm,
                      const Text('Contractor Safety File'),
                      Text('${project.safetyFileScore}%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: GCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.assignment_late, color: XMTheme.error, size: 48),
                      GSpacing.vSm,
                      const Text('Open OHS NCRs'),
                      Text('${project.totalNcrs}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          GSpacing.vXl,
          Text('Risk Assessments (HIRA)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          GSpacing.vMd,
          if (project.riskAssessmentIds.isEmpty)
             const Text('No Risk Assessments linked.')
          else
             ...project.riskAssessmentIds.map((id) => GCard(
               margin: const EdgeInsets.only(bottom: 8),
               padding: const EdgeInsets.all(16),
               child: Row(
                 children: [
                   const Icon(Icons.insert_drive_file, color: XMTheme.primary),
                   GSpacing.hMd,
                   Text('Assessment ID: $id'),
                   const Spacer(),
                   const Icon(Icons.open_in_new, size: 16),
                 ],
               ),
             )),
        ],
      ),
    );
  }
}
