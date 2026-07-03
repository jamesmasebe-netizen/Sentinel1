import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';
import '../../../people/widgets/employee_selector.dart';
import '../../../people/providers/employee_providers.dart';

class WorkflowTab extends ConsumerWidget {
  final Project project;
  const WorkflowTab({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    onPressed: () => _showApprovalDialog(context, project, stage, ref),
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

  void _showApprovalDialog(BuildContext context, Project project, ProjectStage stage, WidgetRef ref) {
    String? selectedApproverId;
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
                  EmployeeSelector(
                    label: 'Approver',
                    value: selectedApproverId,
                    onChanged: (val) {
                      setState(() => selectedApproverId = val);
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
                  onPressed: selectedApproverId == null ? null : () {
                    Navigator.pop(ctx);
                    final emps = ref.read(employeesProvider).valueOrNull;
                    String approverName = selectedApproverId!;
                    if (emps != null) {
                      try {
                        approverName = emps.firstWhere((e) => e.id == selectedApproverId).fullName;
                      } catch (_) {}
                    }
                    _handleStageApproval(context, project, stage, approverName, ref);
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

  void _handleStageApproval(BuildContext context, Project project, ProjectStage stage, String approverId, WidgetRef ref) async {
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
}
