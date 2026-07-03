import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/ds_widgets.dart';

class SpillListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const SpillListItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final contained = data['contained'] == true;
    final color = contained ? XMTheme.success : XMTheme.error;
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.water_drop, color: color, size: 20),
          ),
          GSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['substance'] ?? 'Unknown Substance', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${data['volume'] ?? ""} @ ${data['location'] ?? ""}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          GStatusTag(label: contained ? 'Contained' : 'Active', color: color),
        ],
      ),
    );
  }
}
