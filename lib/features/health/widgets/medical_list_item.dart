import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../../../core/utils/ui_utils.dart';
import '../models/medical_record.dart';

class MedicalListItem extends StatelessWidget {
  final MedicalRecord record;
  const MedicalListItem({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = record.status;
    final type = record.medicalType;

    Color color = XMTheme.success;
    IconData icon = Icons.check_circle_outline_rounded;

    if (status == 'Unfit') {
      color = XMTheme.error;
      icon = Icons.cancel_outlined;
    } else if (status.contains('Restriction')) {
      color = XMTheme.warning;
      icon = Icons.warning_amber_rounded;
    }

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          GSpacing.hLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.employeeName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GSpacing.vXs,
                Text(
                  '$type • ${record.idNumber.isEmpty ? "No ID" : record.idNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          GSpacing.hMd,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GStatusTag(label: status.toUpperCase(), color: color),
              GSpacing.vXs,
              Text(
                'Due: ${UIUtils.formatTimestamp(record.nextDueDate).split(',').first}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
