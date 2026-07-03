import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';

class EquipmentListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final IconData categoryIcon;

  const EquipmentListItem({
    super.key,
    required this.data,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Operational';
    final days = data['daysUntilInspection'] as int? ?? 999;

    return GCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            categoryIcon,
            color: XMTheme.primary,
            size: 24,
          ),
          GSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['equipmentName'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${data['assetTag'] ?? ''} • ${data['location'] ?? ''} • ${data['category'] ?? ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GStatusTag(
                label: status,
                color: status == 'Operational'
                    ? XMTheme.success
                    : status == 'Under Maintenance'
                        ? XMTheme.warning
                        : XMTheme.error,
              ),
              GSpacing.vSm,
              Text(
                'Insp: ${days}d',
                style: TextStyle(
                  fontSize: 10,
                  color: days < 30
                      ? XMTheme.warning
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
