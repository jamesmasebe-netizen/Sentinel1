import 'package:flutter/material.dart';

class DraggableTaskCard extends StatelessWidget {
  final String taskId;
  final String title;
  final String subtitle;
  final Color color;

  const DraggableTaskCard({
    super.key,
    required this.taskId,
    required this.title,
    required this.subtitle,
    this.color = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ],
        ),
      ),
    );

    return Draggable<String>(
      data: taskId,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: SizedBox(width: 150, child: cardContent),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: cardContent),
      child: cardContent,
    );
  }
}
