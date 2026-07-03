import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/ds_widgets.dart';

class WasteListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const WasteListItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    Color color = XMTheme.info;
    if (data['wasteType'] == 'Hazardous' || data['wasteType'] == 'Medical') color = XMTheme.error;
    if (data['wasteType'] == 'Recyclable') color = XMTheme.success;

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          GSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data['wasteType']} • ${data['quantity']} ${data['unit']}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text('${data['transporterName'] ?? ""} → ${data['disposalFacility'] ?? ""}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          GStatusTag(label: data['status'] ?? 'Log', color: color),
        ],
      ),
    );
  }
}
