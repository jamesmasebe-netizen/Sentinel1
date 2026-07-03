import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/ds_widgets.dart';

class EquipmentListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const EquipmentListItem({super.key, required this.data});

  IconData _equipIcon(String? type) {
    switch (type) {
      case 'Extinguisher':
        return Icons.fire_extinguisher;
      case 'First Aid Kit':
        return Icons.medical_services;
      case 'AED':
        return Icons.monitor_heart;
      case 'Spill Kit':
        return Icons.cleaning_services;
      default:
        return Icons.build_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = data['status'] == 'Operational'
        ? XMTheme.success
        : data['status'] == 'Out of Service'
            ? XMTheme.error
            : XMTheme.warning;

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _equipIcon(data['equipmentType']),
                size: 20,
                color: statusColor,
              ),
            ),
            GSpacing.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['equipmentType'] ?? 'Unknown Item',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  GSpacing.vSm,
                  Text(
                    data['location'] ?? 'No location',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            GStatusTag(
              label: data['status'] ?? 'Unknown',
              color: statusColor,
            ),
          ],
        ),
      ),
    );
  }
}
