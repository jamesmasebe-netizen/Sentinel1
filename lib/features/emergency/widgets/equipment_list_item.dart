import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../models/emergency_equipment.dart';

class EquipmentListItem extends StatelessWidget {
  final EmergencyEquipment equipment;
  const EquipmentListItem({super.key, required this.equipment});

  IconData _equipIcon(String type) {
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
    final statusColor =
        equipment.status == 'Operational'
            ? XMTheme.success
            : equipment.status == 'Out of Service'
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
                _equipIcon(equipment.equipmentType),
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
                    equipment.equipmentType.isEmpty
                        ? 'Unknown Item'
                        : equipment.equipmentType,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GSpacing.vSm,
                  Text(
                    equipment.location.isEmpty
                        ? 'No location'
                        : equipment.location,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (equipment.propertyName != null)
                    Text(
                      equipment.propertyName!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            GStatusTag(
              label: equipment.status.isEmpty ? 'Unknown' : equipment.status,
              color: statusColor,
            ),
          ],
        ),
      ),
    );
  }
}
