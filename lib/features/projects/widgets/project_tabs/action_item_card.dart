import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';
import '../../../../../core/widgets/ds_widgets.dart';

class ActionItemCard extends StatelessWidget {
  final Map<String, dynamic> act;

  const ActionItemCard({super.key, required this.act});

  @override
  Widget build(BuildContext context) {
    final priority = act['priority'] as String;
    Color priorityColor = Colors.grey;
    if (priority == 'critical' || priority == 'high') priorityColor = XMTheme.error;
    if (priority == 'medium') priorityColor = XMTheme.warning;
    if (priority == 'low') priorityColor = XMTheme.success;

    return GCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 4, height: 36, color: priorityColor, margin: const EdgeInsets.only(right: 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(act['title'] ?? 'Action Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(act['description'] ?? '', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(priority.toUpperCase(), style: TextStyle(fontSize: 8, color: priorityColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
