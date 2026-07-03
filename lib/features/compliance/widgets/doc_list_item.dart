import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

class DocListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool showExpiryContext;

  const DocListItem({
    super.key,
    required this.data,
    this.showExpiryContext = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = data['daysUntilExpiry'] as int? ?? 999;

    Color statusColor = XMTheme.success;
    IconData statusIcon = Icons.check_circle_outline_rounded;

    if (days < 0) {
      statusColor = XMTheme.error;
      statusIcon = Icons.error_outline_rounded;
    } else if (days < 30) {
      statusColor = XMTheme.riskHigh;
      statusIcon = Icons.warning_amber_rounded;
    } else if (days < 90) {
      statusColor = XMTheme.warning;
      statusIcon = Icons.timer_outlined;
    }

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          GSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Untitled Doc',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                GSpacing.vSm,
                Text(
                  '${data['documentType']} • ${data['referenceNumber'] ?? "No Ref"}',
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
              GStatusTag(
                label: days < 0 ? 'EXPIRED' : '${days}d',
                color: statusColor,
              ),
              if (showExpiryContext)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    UIUtils.formatTimestamp(
                      data['expiryDate'],
                    ).split(',').first,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
