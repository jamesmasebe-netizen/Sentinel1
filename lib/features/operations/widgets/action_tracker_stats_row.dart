import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../models/action_tracker_models.dart';
import 'action_tracker_stat_chip.dart';

class ActionTrackerStatsRow extends StatelessWidget {
  final List<ActionItem> items;

  const ActionTrackerStatsRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ActionTrackerStatChip(
            label: 'Total',
            value: '${items.length}',
            color: XMTheme.info,
          ),
          ActionTrackerStatChip(
            label: 'Pending',
            value:
                '${items.where((i) => i.status == 'Pending' || i.status == 'Open').length}',
            color: XMTheme.warning,
          ),
          ActionTrackerStatChip(
            label: 'Active',
            value: '${items.where((i) => i.status == 'In Progress').length}',
            color: XMTheme.primary,
          ),
          ActionTrackerStatChip(
            label: 'Done',
            value:
                '${items.where((i) => i.status == 'Completed' || i.status == 'Closed').length}',
            color: XMTheme.success,
          ),
        ],
      ),
    );
  }
}
