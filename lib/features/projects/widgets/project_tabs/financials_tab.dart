import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';
import 'expense_form_dialog.dart';

class FinancialsTab extends ConsumerWidget {
  final Project project;
  const FinancialsTab({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cpi = project.costPerformanceIndex;
    final spi = project.schedulePerformanceIndex;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cost & Budget Tracking', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Budget Overview Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Budget', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    Text('\$${project.budget.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Actual Spend', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    Text('\$${project.actualSpend.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: cpi < 1.0 ? XMTheme.error : XMTheme.primary)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remaining Budget', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    Text('\$${(project.budget - project.actualSpend).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // CPI / SPI Indices
          Row(
            children: [
              Expanded(
                child: _buildMetricIndexCard(
                  'Cost Performance (CPI)',
                  cpi,
                  cpi >= 1.0 ? 'Under Budget' : 'Over Budget',
                  cpi >= 1.0 ? XMTheme.success : XMTheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricIndexCard(
                  'Schedule (SPI)',
                  spi,
                  spi >= 1.0 ? 'Ahead of Schedule' : 'Behind Schedule',
                  spi >= 1.0 ? XMTheme.success : XMTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Action Buttons
          FilledButton.icon(
            label: const Text('Add Expense / PO'),
            onPressed: () {
               showExpenseForm(context, project, ref);
            },
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          const SizedBox(height: 32),
          Text('Expense History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              final expensesAsync = ref.watch(projectExpensesProvider(project.id));
              return expensesAsync.when(
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return const Center(child: Text('No expenses logged yet.'));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: expenses.length,
                    itemBuilder: (ctx, i) {
                      final exp = expenses[i];
                      return ListTile(
                        leading: const Icon(Icons.receipt_long_rounded),
                        title: Text(exp.description),
                        subtitle: Text('${exp.category} • ${exp.loggedAt.toLocal().toString().split(' ')[0]}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('-R${exp.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: XMTheme.error)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: XMTheme.error),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Delete Expense?'),
                                    content: const Text('Are you sure you want to delete this expense?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await ref.read(projectServiceProvider).deleteExpense(exp.id, project.id, exp.amount);
                                    if (ctx.mounted) {
                                      UIUtils.showToast(context, 'Expense deleted.', type: ToastType.success);
                                    }
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      UIUtils.showToast(context, 'Error deleting expense: $e', type: ToastType.error);
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricIndexCard(String label, double value, String subLabel, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value.toStringAsFixed(2), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subLabel, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
