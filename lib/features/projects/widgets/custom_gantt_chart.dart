import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_models.dart';
import '../providers/project_providers.dart';
import 'custom_gantt_chart/gantt_dependency_painter.dart';
import 'custom_gantt_chart/gantt_add_task_dialog.dart';
import 'custom_gantt_chart/gantt_task_row.dart';

class CustomGanttChart extends ConsumerStatefulWidget {
  final List<ProjectTask> tasks;
  final String projectId;

  const CustomGanttChart({
    super.key,
    required this.tasks,
    required this.projectId,
  });

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
      chartStartDate = widget.tasks
          .map((t) => t.startDate)
          .reduce((a, b) => a.isBefore(b) ? a : b)
          .subtract(const Duration(days: 2));
      chartEndDate = widget.tasks
          .map((t) => t.endDate)
          .reduce((a, b) => a.isAfter(b) ? a : b)
          .add(const Duration(days: 7));
    }
    totalDays = chartEndDate.difference(chartStartDate).inDays;
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
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 0.5),
              ),
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

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return const Center(child: Text("No tasks found."));
    }

    final taskDependencies =
        ref.watch(projectDependenciesProvider(widget.projectId)).valueOrNull ??
        [];
    final taskLinkedRisks =
        ref.watch(projectLinkedRisksProvider(widget.projectId)).valueOrNull ??
        [];
    final taskLinkedIncidents =
        ref
            .watch(projectLinkedIncidentsProvider(widget.projectId))
            .valueOrNull ??
        [];

    final taskLinkedCapas =
        ref.watch(projectLinkedCapasProvider(widget.projectId)).valueOrNull ??
        [];

    Map<String, List<String>> depMap = {};
    for (var d in taskDependencies) {
      depMap
          .putIfAbsent(d['taskId'] as String, () => [])
          .add(d['dependencyId'] as String);
    }
    Map<String, List<String>> risksMap = {};
    for (var r in taskLinkedRisks) {
      risksMap
          .putIfAbsent(r['taskId'] as String, () => [])
          .add(r['riskId'] as String);
    }
    Map<String, List<String>> incidentsMap = {};
    for (var i in taskLinkedIncidents) {
      incidentsMap
          .putIfAbsent(i['taskId'] as String, () => [])
          .add(i['incidentId'] as String);
    }
    Map<String, List<String>> capasMap = {};
    for (var c in taskLinkedCapas) {
      capasMap
          .putIfAbsent(c['taskId'] as String, () => [])
          .add(c['capaId'] as String);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Interactive Gantt Timeline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              FilledButton.icon(
                onPressed: () {
                  showAddTaskDialog(context, ref, widget.projectId);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Task'),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderTimeline(),
                      const Divider(height: 1),
                      ...widget.tasks.map(
                        (task) => GanttTaskRow(
                          task: task,
                          depMap: depMap,
                          risksMap: risksMap,
                          incidentsMap: incidentsMap,
                          capasMap: capasMap,
                          chartStartDate: chartStartDate,
                          dayWidth: dayWidth,
                          taskHeight: taskHeight,
                          totalDays: totalDays,
                          projectId: widget.projectId,
                          allTasks: widget.tasks,
                          ref: ref,
                        ),
                      ),
                    ],
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GanttDependencyPainter(
                        dependenciesMap: depMap,
                        tasks: widget.tasks,
                        chartStartDate: chartStartDate,
                        dayWidth: dayWidth,
                        taskHeight: taskHeight,
                        rowHeight: 60.0,
                        headerHeight: 41.0,
                      ),
                    ),
                  ),
                  if (DateTime.now().isAfter(chartStartDate) &&
                      DateTime.now().isBefore(chartEndDate))
                    Positioned(
                      left:
                          DateTime.now().difference(chartStartDate).inDays *
                          dayWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Colors.orange.withAlpha(200),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
