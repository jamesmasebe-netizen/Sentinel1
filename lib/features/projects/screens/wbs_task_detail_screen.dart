import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/pmo_providers.dart';
import '../models/pmo_models.dart';

class WbsTaskDetailScreen extends ConsumerWidget {
  final String projectId;
  final String taskId;

  const WbsTaskDetailScreen({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(
      pmoWbsTaskStreamProvider((projectId: projectId, taskId: taskId)),
    );

    return taskAsync.when(
      data: (task) {
        if (task == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Task Details')),
            body: const Center(child: Text('Task not found')),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            title: Text(
              task.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerLowest,
            scrolledUnderElevation: 0,
            actions: [
              _buildStatusChip(context, task.status),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(context, task),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        context,
                        title: 'Schedule',
                        icon: Icons.calendar_today_rounded,
                        children: [
                          _buildDetailRow(
                            'Start Date',
                            _formatDate(task.startDate),
                          ),
                          _buildDetailRow(
                            'End Date',
                            _formatDate(task.endDate),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        context,
                        title: 'Details',
                        icon: Icons.info_outline_rounded,
                        children: [
                          _buildDetailRow('Task Type', task.taskType),
                          _buildDetailRow(
                            'Billable',
                            task.isBillable ? 'Yes' : 'No',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (task.effort != null)
                  _buildEffortCard(context, task.effort!),
                const SizedBox(height: 16),
                _buildResourcesAndDependenciesCard(context, task),
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

  Widget _buildHeaderCard(BuildContext context, WbsTask task) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.secondary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.description.isNotEmpty
                  ? task.description
                  : 'No description provided.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Completion Progress',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                Text(
                  '${task.percentComplete}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: task.percentComplete / 100,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffortCard(BuildContext context, EffortModel effort) {
    return _buildInfoCard(
      context,
      title: 'Effort & Hours',
      icon: Icons.timer_rounded,
      children: [
        _buildDetailRow('Estimated Hours', '${effort.estimatedHours} h'),
        _buildDetailRow('Actual Hours', '${effort.actualHours} h'),
        _buildDetailRow('Remaining Hours', '${effort.remainingHours} h'),
        if (effort.estimatedHours > 0) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (effort.actualHours / effort.estimatedHours).clamp(0.0, 1.0),
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            color:
                effort.actualHours > effort.estimatedHours
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Text(
            '${(effort.actualHours / effort.estimatedHours * 100).toStringAsFixed(1)}% of estimated hours used',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildResourcesAndDependenciesCard(
    BuildContext context,
    WbsTask task,
  ) {
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
                  Icons.group_work_rounded,
                  size: 22,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Resources & Dependencies',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Assigned Resources',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (task.assignedResourceIds.isEmpty)
              const Text(
                'No resources assigned',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    task.assignedResourceIds
                        .map(
                          (res) => Chip(
                            avatar: const CircleAvatar(
                              child: Icon(Icons.person, size: 16),
                            ),
                            label: Text(res),
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          ),
                        )
                        .toList(),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Dependencies',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (task.dependencies.isEmpty)
              const Text(
                'No dependencies',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    task.dependencies
                        .map(
                          (dep) => Chip(
                            avatar: const Icon(Icons.link, size: 16),
                            label: Text(dep),
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          ),
                        )
                        .toList(),
              ),
          ],
        ),
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
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'completed':
      case 'done':
        color = Colors.green;
        break;
      case 'inprogress':
        color = Colors.blue;
        break;
      case 'notstarted':
      case 'todo':
        color = Colors.orange;
        break;
      case 'blocked':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
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
