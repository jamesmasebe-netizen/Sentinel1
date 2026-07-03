import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/project_models.dart';
import '../custom_gantt_chart.dart';

class TimelineTab extends ConsumerWidget {
  final Project project;
  const TimelineTab({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (project.tasks.isEmpty) {
      return const Center(child: Text('No tasks available for Gantt view.'));
    }
    return CustomGanttChart(tasks: project.tasks, projectId: project.id);
  }
}
