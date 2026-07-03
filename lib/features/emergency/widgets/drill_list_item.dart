import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/ds_widgets.dart';

class DrillListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const DrillListItem({super.key, required this.data});

  IconData _drillIcon(String? type) {
    switch (type) {
      case 'Fire':
        return Icons.local_fire_department;
      case 'Medical':
        return Icons.medical_services;
      case 'Spill':
        return Icons.water_drop;
      case 'Security':
        return Icons.security;
      case 'Evacuation':
        return Icons.directions_run;
      default:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.errorContainer.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(_drillIcon(data['drillType']), color: XMTheme.error),
        ),
        title: Text(
          '${data['drillType']} Drill',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GSpacing.vSm,
            Text(
              '${data['durationMinutes'] ?? 0} min • ${data['evaluatorName'] ?? 'No evaluator'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            GSpacing.vSm,
            Text(
              data['scenarioDescription'] ?? '',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).disabledColor,
        ),
      ),
    );
  }
}
