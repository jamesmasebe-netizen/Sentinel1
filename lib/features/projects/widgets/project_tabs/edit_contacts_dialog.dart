import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/ui_utils.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';
import '../../../people/widgets/employee_selector.dart';
import '../../../people/providers/employee_providers.dart';

void showEditContactsDialog(BuildContext context, Project project, WidgetRef ref) {
  final leadController = TextEditingController(text: project.projectLead);
  final leadContactController = TextEditingController(text: project.projectLeadContact);
  final backupController = TextEditingController(text: project.fallbackContact);
  final backupContactController = TextEditingController(text: project.fallbackContactContact);

  String? selectedLeadId;
  String? selectedBackupId;

  final initialEmployees = ref.read(employeesProvider).valueOrNull;
  if (initialEmployees != null) {
    try {
      selectedLeadId = initialEmployees.firstWhere((e) => e.fullName == project.projectLead).id;
    } catch (_) {}
    try {
      selectedBackupId = initialEmployees.firstWhere((e) => e.fullName == project.fallbackContact).id;
    } catch (_) {}
  }

  showDialog(
    context: context,
    builder: (ctx) {
      bool isLoading = false;
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Contacts & Escalation'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EmployeeSelector(
                    label: 'Project Lead',
                    value: selectedLeadId,
                    onChanged: (val) {
                      setDialogState(() {
                        selectedLeadId = val;
                        if (val != null) {
                          final emps = ref.read(employeesProvider).valueOrNull;
                          if (emps != null) {
                            try {
                              final emp = emps.firstWhere((e) => e.id == val);
                              leadController.text = emp.fullName;
                              leadContactController.text = emp.email;
                            } catch (_) {}
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: leadContactController,
                    enabled: !isLoading,
                    decoration: const InputDecoration(labelText: 'Lead Contact Info'),
                  ),
                  const SizedBox(height: 16),
                  EmployeeSelector(
                    label: 'Backup / Escalation',
                    value: selectedBackupId,
                    onChanged: (val) {
                      setDialogState(() {
                        selectedBackupId = val;
                        if (val != null) {
                          final emps = ref.read(employeesProvider).valueOrNull;
                          if (emps != null) {
                            try {
                              final emp = emps.firstWhere((e) => e.id == val);
                              backupController.text = emp.fullName;
                              backupContactController.text = emp.email;
                            } catch (_) {}
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: backupContactController,
                    enabled: !isLoading,
                    decoration: const InputDecoration(labelText: 'Backup Contact Info'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setDialogState(() => isLoading = true);
                        try {
                          final updated = project.copyWith(
                            projectLead: leadController.text.trim(),
                            projectLeadContact: leadContactController.text.trim(),
                            fallbackContact: backupController.text.trim(),
                            fallbackContactContact: backupContactController.text.trim(),
                          );
                          await ref.read(projectServiceProvider).updateProject(updated);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            UIUtils.showToast(context, 'Contacts updated.', type: ToastType.success);
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            UIUtils.showToast(context, 'Failed to save contacts: $e', type: ToastType.error);
                          }
                        } finally {
                          if (ctx.mounted) {
                            setDialogState(() => isLoading = false);
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
