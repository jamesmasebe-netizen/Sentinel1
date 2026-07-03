import 'package:flutter/material.dart';
import '../../../core/widgets/ds_widgets.dart';

class ActionTrackerStatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const ActionTrackerStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: GCard(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: color.withValues(alpha: 0.05),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
