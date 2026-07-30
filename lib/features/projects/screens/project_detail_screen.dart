import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/pmo_providers.dart';
import '../models/pmo_models.dart';
import 'wbs_task_detail_screen.dart';
import '../../finance/screens/invoice_detail_screen.dart';
import '../../../core/bpf/bpf_ribbon_widget.dart';
import '../../../core/bpf/lead_to_cash_bpf.dart';
import '../../../core/bpf/bpf_orchestrator.dart';
import '../../../core/bpf/bpf_service.dart';
import '../../../core/utils/ui_utils.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(pmoProjectStreamProvider(projectId));

    return projectAsync.when(
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Project Details')),
            body: const Center(child: Text('Project not found')),
          );
        }

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerLowest,
            appBar: AppBar(
              title: Text(
                project.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerLowest,
              scrolledUnderElevation: 0,
              bottom: const TabBar(
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  Tab(text: 'Overview', icon: Icon(Icons.dashboard_rounded)),
                  Tab(
                    text: 'WBS Tasks',
                    icon: Icon(Icons.account_tree_rounded),
                  ),
                  Tab(
                    text: 'Time Entries',
                    icon: Icon(Icons.access_time_filled_rounded),
                  ),
                  Tab(text: 'Expenses', icon: Icon(Icons.receipt_long_rounded)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildOverview(context, ref, project),
                _buildWbsTasks(context, ref, projectId),
                _buildTimeEntries(context, ref, projectId),
                _buildExpenses(context, ref, projectId),
              ],
            ),
          ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildOverview(BuildContext context, WidgetRef ref, Project project) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        BpfRibbonWidget(
          bpfTypeId: 'lead_to_cash',
          recordType: 'projectId',
          recordId: project.projectId,
          definition: leadToCashDefinition,
        ),
        _buildHeaderCard(context, ref, project),
        const SizedBox(height: 16),
        _buildInfoCard(
          context,
          title: 'Project Information',
          icon: Icons.info_outline_rounded,
          children: [
            _buildDetailRow(
              'Description',
              project.description.isNotEmpty
                  ? project.description
                  : 'No description provided',
            ),
            _buildDetailRow('Client ID', project.clientId),
            _buildDetailRow('Contract ID', project.contractId),
            _buildDetailRow('Project Manager', project.projectManagerId),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          context,
          title: 'Timeline & Budget',
          icon: Icons.date_range_rounded,
          children: [
            _buildDetailRow('Start Date', _formatDate(project.startDate)),
            _buildDetailRow('End Date', _formatDate(project.endDate)),
            if (project.budget != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(),
              ),
              _buildDetailRow(
                'Total Budget',
                '${project.budget!.currency} ${_formatNumber(project.budget!.totalBudgetAmount)}',
              ),
              _buildDetailRow(
                'Consumed Budget',
                '${project.budget!.currency} ${_formatNumber(project.budget!.consumedBudget)}',
              ),
              _buildProgressBar(
                context,
                project.budget!.consumedBudget,
                project.budget!.totalBudgetAmount,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, WidgetRef ref, Project project) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    project.status.toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              project.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rev Rec Method: ${project.revenueRecognitionMethod}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton.icon(
                onPressed: () async {
                    try {
                      final orchestrator = ref.read(bpfOrchestratorProvider);
                      final bpfService = ref.read(bpfServiceProvider);
                      String? bpfId;
                      final bpfs = await bpfService.streamBpfInstancesByRecord('projectId', project.projectId).first;
                      if (bpfs.isNotEmpty) {
                        bpfId = bpfs.first.id;
                      } else {
                        bpfId = await bpfService.startBpf('lead_to_cash', 'project', 'projectId', project.projectId);
                      }
                      final invoiceId = await orchestrator.createInvoiceFromProject(project, bpfId);
                      if (context.mounted) {
                        UIUtils.showToast(context, 'Invoice generated successfully (ID: $invoiceId)');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InvoiceDetailScreen(
                              invoiceId: invoiceId,
                              invoiceType: 'AR',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        UIUtils.showToast(context, 'Error generating invoice: $e');
                      }
                    }
                },
                icon: const Icon(Icons.receipt),
                label: const Text('Generate Invoice'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    double consumed,
    double total,
  ) {
    if (total == 0) return const SizedBox.shrink();
    final percent = (consumed / total).clamp(0.0, 1.0);
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Consumption',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: Colors.grey[600]),
              ),
              Text(
                '${(percent * 100).toStringAsFixed(1)}%',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: percent > 0.9 ? colorScheme.error : colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatNumber(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  Widget _buildWbsTasks(BuildContext context, WidgetRef ref, String projectId) {
    final tasksAsync = ref.watch(pmoWbsTasksStreamProvider(projectId));
    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return _buildEmptyState(
            context,
            'No WBS Tasks',
            Icons.account_tree_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => WbsTaskDetailScreen(
                            projectId: projectId,
                            taskId: task.taskId,
                          ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              task.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildStatusChip(context, task.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description.isNotEmpty
                            ? task.description
                            : 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_formatDate(task.startDate)} - ${_formatDate(task.endDate)}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const Spacer(),
                          Text(
                            '${task.percentComplete}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: task.percentComplete / 100,
                        backgroundColor:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 4,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildTimeEntries(
    BuildContext context,
    WidgetRef ref,
    String projectId,
  ) {
    final entriesAsync = ref.watch(pmoTimeEntriesStreamProvider(projectId));
    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmptyState(
            context,
            'No Time Entries',
            Icons.access_time_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  child: Text(
                    '${entry.hours}h',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  entry.description,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.resourceId,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(entry.date),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                trailing: _buildStatusChip(context, entry.approvalStatus),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildExpenses(BuildContext context, WidgetRef ref, String projectId) {
    final expensesAsync = ref.watch(pmoExpensesStreamProvider(projectId));
    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return _buildEmptyState(
            context,
            'No Expenses',
            Icons.receipt_long_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final exp = expenses[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.tertiaryContainer,
                  child: Icon(
                    Icons.attach_money_rounded,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        exp.category,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${exp.amount?.currency ?? 'USD'} ${_formatNumber(exp.amount?.value ?? 0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        exp.resourceId,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(exp.incurredDate),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                trailing: _buildStatusChip(context, exp.approvalStatus),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        color = Colors.green;
        break;
      case 'pending':
      case 'in progress':
      case 'notstarted':
        color = Colors.orange;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
