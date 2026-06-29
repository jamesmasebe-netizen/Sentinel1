import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../models/project_models.dart';
import '../providers/project_providers.dart';

class CustomGanttChart extends ConsumerStatefulWidget {
  final List<ProjectTask> tasks;
  final String projectId;

  const CustomGanttChart({super.key, required this.tasks, required this.projectId});

  @override
  ConsumerState<CustomGanttChart> createState() => _CustomGanttChartState();
}

class _CustomGanttChartState extends ConsumerState<CustomGanttChart> {
  final double dayWidth = 40.0;
  final double taskHeight = 36.0;
  late DateTime chartStartDate;
  late DateTime chartEndDate;
  late int totalDays;

  @override
  void initState() {
    super.initState();
    _calculateDateRange();
  }

  void _calculateDateRange() {
    if (widget.tasks.isEmpty) {
      chartStartDate = DateTime.now();
      chartEndDate = DateTime.now().add(const Duration(days: 7));
    } else {
      chartStartDate = widget.tasks.map((t) => t.startDate).reduce((a, b) => a.isBefore(b) ? a : b).subtract(const Duration(days: 2));
      chartEndDate = widget.tasks.map((t) => t.endDate).reduce((a, b) => a.isAfter(b) ? a : b).add(const Duration(days: 7));
    }
    totalDays = chartEndDate.difference(chartStartDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) return const Center(child: Text("No tasks found."));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Interactive Gantt Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderTimeline(),
                  const Divider(height: 1),
                  ...widget.tasks.map((task) => _buildTaskRow(task)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTimeline() {
    return Container(
      height: 40,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        children: List.generate(totalDays, (index) {
          final date = chartStartDate.add(Duration(days: index));
          return Container(
            width: dayWidth,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: Text(
              '${date.day}/${date.month}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTaskRow(ProjectTask task) {
    final startOffset = task.startDate.difference(chartStartDate).inDays * dayWidth;
    final durationDays = task.endDate.difference(task.startDate).inDays;
    final taskWidth = (durationDays > 0 ? durationDays : 1) * dayWidth;

    Color taskColor = XMTheme.primary;
    if (task.riskLevel == 'Critical') taskColor = XMTheme.error;
    if (task.riskLevel == 'High') taskColor = Colors.orange;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Stack(
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

          // Task Bar
          Positioned(
            left: startOffset,
            top: 12,
            child: GestureDetector(
              onTap: () => _showTaskEditor(task),
              child: Container(
                width: taskWidth,
                height: taskHeight,
                decoration: BoxDecoration(
                  color: taskColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: taskColor),
                ),
                child: Stack(
                  children: [
                    // Progress Fill
                    Container(
                      width: taskWidth * task.progress,
                      height: taskHeight,
                      decoration: BoxDecoration(
                        color: taskColor.withValues(alpha: 0.8),
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
                            fontWeight: FontWeight.bold,
                            color: task.progress > 0.5 ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskEditor(ProjectTask initialTask) {
    ProjectTask task = initialTask;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SizedBox(
            height: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Update Task Progress', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 24),
                const Text('Progress Slider:'),
                Slider(
                  value: task.progress,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: '${(task.progress * 100).toInt()}%',
                  onChanged: (val) {
                    setModalState(() {
                      task = task.copyWith(progress: val);
                    });
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      // Update task in Firestore
                      final projectAsync = ref.read(projectProvider(widget.projectId));
                      final project = projectAsync.value;
                      if (project != null) {
                        final updatedTasks = project.tasks.map((t) => t.id == task.id ? task : t).toList();
                        final updatedProject = project.copyWith(tasks: updatedTasks);
                        await ref.read(projectServiceProvider).updateProject(updatedProject);
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                )
              ],
            ),
          ),
        );
          },
        );
      }
    );
  }
}
