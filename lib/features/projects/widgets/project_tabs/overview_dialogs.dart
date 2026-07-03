import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/ui_utils.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';

export 'edit_contacts_dialog.dart';

void showEditProjectDetailsDialog(BuildContext context, Project project, WidgetRef ref) {
  final formKey = GlobalKey<FormState>();
  String name = project.name;
  String category = project.category;
  String budgetStr = project.budget.toStringAsFixed(2);
  String status = project.status;

  showDialog(
    context: context,
    builder: (ctx) {
      bool isLoading = false;
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Project Details'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(labelText: 'Project Name'),
                      enabled: !isLoading,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      onSaved: (v) => name = v ?? '',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: ['Maintenance', 'Opex', 'Renovation', 'Emergency'].contains(category) ? category : 'Maintenance',
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: ['Maintenance', 'Opex', 'Renovation', 'Emergency']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: isLoading ? null : (val) {
                        if (val != null) category = val;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: budgetStr,
                      decoration: const InputDecoration(labelText: 'Total Budget (R)', prefixText: 'R '),
                      keyboardType: TextInputType.number,
                      enabled: !isLoading,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      onSaved: (v) => budgetStr = v ?? '',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: ['Draft', 'Active', 'On Hold', 'Completed'].contains(status) ? status : 'Draft',
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: ['Draft', 'Active', 'On Hold', 'Completed']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: isLoading ? null : (val) {
                        if (val != null) status = val;
                      },
                    ),
                  ],
                ),
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
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          setDialogState(() => isLoading = true);
                          try {
                            final amt = double.tryParse(budgetStr) ?? project.budget;
                            final updated = project.copyWith(
                              name: name,
                              category: category,
                              budget: amt,
                              status: status,
                            );
                            await ref.read(projectServiceProvider).updateProject(updated);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              UIUtils.showToast(context, 'Project updated successfully.', type: ToastType.success);
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              UIUtils.showToast(context, 'Failed to update project: $e', type: ToastType.error);
                            }
                          } finally {
                            if (ctx.mounted) {
                              setDialogState(() => isLoading = false);
                            }
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

void showEditDescriptionDialog(BuildContext context, Project project, WidgetRef ref) {
  final controller = TextEditingController(text: project.description);

  showDialog(
    context: context,
    builder: (ctx) {
      bool isLoading = false;
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Project Description'),
            content: SizedBox(
              width: 400,
              child: TextField(
                controller: controller,
                maxLines: 6,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  hintText: 'Enter project description...',
                  border: OutlineInputBorder(),
                ),
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
                          final newDesc = controller.text.trim();
                          final updated = project.copyWith(description: newDesc);
                          await ref.read(projectServiceProvider).updateProject(updated);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            UIUtils.showToast(context, 'Project description updated.', type: ToastType.success);
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            UIUtils.showToast(context, 'Failed to save description: $e', type: ToastType.error);
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
