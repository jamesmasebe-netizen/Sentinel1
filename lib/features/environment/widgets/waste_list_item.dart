import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../models/environment_models.dart';

class WasteListItem extends StatelessWidget {
  final WasteManifest manifest;
  const WasteListItem({super.key, required this.manifest});

  @override
  Widget build(BuildContext context) {
    Color color = XMTheme.info;
    if (manifest.wasteType == 'Hazardous' || manifest.wasteType == 'Medical') {
      color = XMTheme.error;
    }
    if (manifest.wasteType == 'Recyclable') color = XMTheme.success;

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          GSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${manifest.wasteType} • ${manifest.quantity} ${manifest.unit}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${manifest.transporterName} → ${manifest.disposalFacility}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          GStatusTag(label: manifest.status, color: color),
        ],
      ),
    );
  }
}
