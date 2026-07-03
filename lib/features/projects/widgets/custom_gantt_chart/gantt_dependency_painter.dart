import 'package:flutter/material.dart';
import '../../models/project_models.dart';

class GanttDependencyPainter extends CustomPainter {
  final Map<String, List<String>> dependenciesMap;
  final List<ProjectTask> tasks;
  final DateTime chartStartDate;
  final double dayWidth;
  final double taskHeight;
  final double rowHeight;
  final double headerHeight;

  GanttDependencyPainter({
    required this.dependenciesMap,
    required this.tasks,
    required this.chartStartDate,
    required this.dayWidth,
    required this.taskHeight,
    required this.rowHeight,
    required this.headerHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    // Create a map of task index to easily calculate Y positions
    final taskMap = {for (var i = 0; i < tasks.length; i++) tasks[i].id: i};

    for (var i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      for (final depId in dependenciesMap[task.id] ?? []) {
        if (!taskMap.containsKey(depId)) continue;
        
        final depIndex = taskMap[depId]!;
        final depTask = tasks[depIndex];

        // Highlight in red if this dependency is blocking current progress timeline
        bool isDelayed = depTask.progress < 1.0 && DateTime.now().isAfter(depTask.endDate);
        paint.color = isDelayed ? Colors.red.withAlpha(200) : Colors.grey.shade500;
        arrowPaint.color = paint.color;

        double depStartOffset = depTask.startDate.difference(chartStartDate).inDays * dayWidth;
        double depIndent = depTask.taskType == 'subtask' ? 30.0 : (depTask.taskType == 'task' ? 15.0 : 0.0);
        double depDuration = (depTask.endDate.difference(depTask.startDate).inDays > 0 ? depTask.endDate.difference(depTask.startDate).inDays : 1) * dayWidth;
        
        // Right edge of predecessor
        double startX = depStartOffset + depIndent + depDuration;
        double startY = headerHeight + (depIndex * rowHeight) + 12 + (taskHeight / 2);

        double curStartOffset = task.startDate.difference(chartStartDate).inDays * dayWidth;
        double curIndent = task.taskType == 'subtask' ? 30.0 : (task.taskType == 'task' ? 15.0 : 0.0);
        
        // Left edge of successor
        double endX = curStartOffset + curIndent;
        double endY = headerHeight + (i * rowHeight) + 12 + (taskHeight / 2);

        // Draw Elbow Arrow
        final path = Path();
        path.moveTo(startX, startY);
        path.lineTo(startX + 10, startY); // small horizontal extension
        path.lineTo(startX + 10, endY);   // vertical drop/rise
        path.lineTo(endX - 4, endY);      // horizontal to target

        canvas.drawPath(path, paint);

        // Draw Arrowhead
        final arrowPath = Path();
        arrowPath.moveTo(endX, endY);
        arrowPath.lineTo(endX - 6, endY - 4);
        arrowPath.lineTo(endX - 6, endY + 4);
        arrowPath.close();
        
        canvas.drawPath(arrowPath, arrowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GanttDependencyPainter oldDelegate) => true;
}
