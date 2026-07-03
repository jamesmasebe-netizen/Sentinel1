import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../models/project_models.dart';
import 'gantt_task_editor_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GanttTaskRow extends StatelessWidget {
  final ProjectTask task;
  final Map<String, List<String>> depMap;
  final Map<String, List<String>> risksMap;
  final Map<String, List<String>> incidentsMap;
  final Map<String, List<String>> capasMap;
  final DateTime chartStartDate;
  final double dayWidth;
  final double taskHeight;
  final int totalDays;
  final String projectId;
  final List<ProjectTask> allTasks;
  final WidgetRef ref;

  const GanttTaskRow({
    super.key,
    required this.task,
    required this.depMap,
    required this.risksMap,
    required this.incidentsMap,
    required this.capasMap,
    required this.chartStartDate,
    required this.dayWidth,
    required this.taskHeight,
    required this.totalDays,
    required this.projectId,
    required this.allTasks,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final startOffset = task.startDate.difference(chartStartDate).inDays * dayWidth;
    final durationDays = task.endDate.difference(task.startDate).inDays;
    final taskWidth = (durationDays > 0 ? durationDays : 1) * dayWidth;

    // Hierarchy Indent
    double indent = 0.0;
    if (task.taskType == 'task') indent = 15.0;
    if (task.taskType == 'subtask') indent = 30.0;

    // Auto-derived Status Colors
    Color taskColor = Colors.grey;
    final now = DateTime.now();
    if (task.progress == 1.0) {
      taskColor = XMTheme.success;
    } else if (task.endDate.isBefore(now)) {
      taskColor = XMTheme.error;
    } else if (task.endDate.difference(now).inDays <= 3) {
      taskColor = XMTheme.warning;
    } else if (task.progress > 0) {
      taskColor = XMTheme.primary;
    }

    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
        color: task.taskType == 'process' ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100) : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Grid
          Row(
            children: List.generate(totalDays, (index) {
              return Container(
                width: dayWidth,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.grey.shade100, width: 0.5)),
                ),
              );
            }),
          ),

          // Task Bar / Milestone
          Positioned(
            left: startOffset + indent,
            top: 12,
            child: GestureDetector(
              onTap: () => showTaskEditor(context, ref, projectId, allTasks, task, depMap[task.id] ?? [], risksMap[task.id] ?? [], incidentsMap[task.id] ?? [], capasMap[task.id] ?? []),
              child: task.isMilestone ? _buildMilestoneDiamond(task, taskColor) : _buildStandardTaskBar(context, task, taskWidth, taskColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneDiamond(ProjectTask task, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: 3.14159 / 4,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(task.title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStandardTaskBar(BuildContext context, ProjectTask task, double taskWidth, Color taskColor) {
    return Container(
      width: taskWidth,
      height: taskHeight,
      decoration: BoxDecoration(
        color: taskColor.withAlpha(50),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: taskColor),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Progress Fill
          Container(
            width: taskWidth * task.progress,
            height: taskHeight,
            decoration: BoxDecoration(
              color: taskColor.withAlpha(200),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          // Task Title
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: task.taskType == 'process' ? FontWeight.bold : FontWeight.normal,
                  color: task.progress > 0.5 ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Avatar Chip (if assigned)
          if (task.assignedToName.isNotEmpty)
            Positioned(
              right: -12,
              top: 4,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    task.assignedToName.substring(0, 1).toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
