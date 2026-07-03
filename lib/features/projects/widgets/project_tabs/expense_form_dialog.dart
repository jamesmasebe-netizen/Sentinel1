import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';

void showExpenseForm(BuildContext context, Project project, WidgetRef ref) {
  final formKey = GlobalKey<FormState>();
  String description = '';
  String amount = '';
  String category = 'Materials';

  showDialog(
    context: context,
    builder: (ctx) {
      bool isLoading = false;
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Expense / PO'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    enabled: !isLoading,
                    validator:
                        (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    onSaved: (v) => description = v ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Amount (R)',
                      prefixText: 'R ',
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !isLoading,
                    validator:
                        (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    onSaved: (v) => amount = v ?? '',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items:
                        [
                              'Materials',
                              'Labour',
                              'Equipment',
                              'Subcontractor',
                              'Other',
                            ]
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged:
                        isLoading
                            ? null
                            : (val) {
                              if (val != null) category = val;
                            },
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
                onPressed:
                    isLoading
                        ? null
                        : () async {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            setDialogState(() => isLoading = true);
                            try {
                              final amt = double.tryParse(amount) ?? 0.0;
                              final expense = ProjectExpense(
                                id: '',
                                projectId: project.id,
                                tenantId: project.tenantId,
                                description: description,
                                amount: amt,
                                category: category,
                                loggedAt: DateTime.now(),
                                loggedBy:
                                    ref
                                        .read(userProfileProvider)
                                        .valueOrNull
                                        ?.uid,
                              );
                              await ref
                                  .read(projectServiceProvider)
                                  .addExpense(expense);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                UIUtils.showToast(
                                  context,
                                  'Expense added successfully.',
                                  type: ToastType.success,
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                UIUtils.showToast(
                                  context,
                                  'Failed to save expense: $e',
                                  type: ToastType.error,
                                );
                              }
                            } finally {
                              if (ctx.mounted) {
                                setDialogState(() => isLoading = false);
                              }
                            }
                          }
                        },
                child:
                    isLoading
                        ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Add Expense'),
              ),
            ],
          );
        },
      );
    },
  );
}
