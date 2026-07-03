import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';

void showAddTaskDialog(BuildContext context, WidgetRef ref, String projectId) {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String riskLevel = 'Medium';
  String taskType = 'task';
  DateTime start = DateTime.now();
  DateTime end = DateTime.now().add(const Duration(days: 7));

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Add New Task'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Task Title')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: taskType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['process', 'task', 'subtask'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                  onChanged: (v) { if (v != null) setDialogState(() => taskType = v); },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: riskLevel,
                  decoration: const InputDecoration(labelText: 'Risk Level'),
                  items: ['Low', 'Medium', 'High', 'Critical'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) { if (v != null) setDialogState(() => riskLevel = v); },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: Text('Start: ${start.toIso8601String().split('T')[0]}', style: const TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final picked = await showDatePicker(context: ctx, initialDate: start, firstDate: DateTime(2020), lastDate: DateTime(2035));
                          if (picked != null) setDialogState(() => start = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event, size: 14),
                        label: Text('End: ${end.toIso8601String().split('T')[0]}', style: const TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final picked = await showDatePicker(context: ctx, initialDate: end, firstDate: DateTime(2020), lastDate: DateTime(2035));
                          if (picked != null) setDialogState(() => end = picked);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              
              final newTask = ProjectTask(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                taskType: taskType,
                riskLevel: riskLevel,
                startDate: start,
                endDate: end,
              );
              
              final projectAsync = ref.read(projectProvider(projectId));
              final project = projectAsync.value;
              if (project != null) {
                final updatedTasks = List<ProjectTask>.from(project.tasks)..add(newTask);
                final updatedProject = project.copyWith(tasks: updatedTasks);
                await ref.read(projectServiceProvider).updateProject(updatedProject);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  UIUtils.showToast(context, 'Task "${titleCtrl.text}" created', type: ToastType.success);
                }
              } else {
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create Task'),
          ),
        ],
      ),
    ),
  );
}
