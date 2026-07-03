import 'package:flutter/material.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../../../core/utils/ui_utils.dart';

class FirstAidListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const FirstAidListItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: theme.colorScheme.errorContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.medical_services_rounded, color: theme.colorScheme.error, size: 24),
          ),
          GSpacing.hLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['employeeName'] ?? 'Unknown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      UIUtils.formatTimestamp(data['date']).split(',').first,
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                GSpacing.vSm,
                Text(data['description'] ?? 'No description', style: theme.textTheme.bodySmall),
                GSpacing.vMd,
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.healing_rounded, size: 14, color: theme.colorScheme.primary),
                      GSpacing.hMd,
                      Expanded(
                        child: Text(
                          'Treatment: ${data['treatment'] ?? "None recorded"}',
                          style: theme.textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
