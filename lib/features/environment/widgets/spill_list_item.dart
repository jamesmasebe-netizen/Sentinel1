import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../models/environment_models.dart';

class SpillListItem extends StatelessWidget {
  final EnvironmentalSpill spill;
  const SpillListItem({super.key, required this.spill});

  @override
  Widget build(BuildContext context) {
    final color = spill.contained ? XMTheme.success : XMTheme.error;
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.water_drop, color: color, size: 20),
          ),
          GSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spill.substance.isNotEmpty ? spill.substance : 'Unknown Substance',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${spill.volume} @ ${spill.location}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          GStatusTag(label: spill.contained ? 'Contained' : 'Active', color: color),
        ],
      ),
    );
  }
}
