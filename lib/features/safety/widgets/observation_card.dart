import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

class ObservationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const ObservationCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = data['observationType'] ?? 'Safe Act';
    final desc = data['description'] ?? '';
    final observer = data['observerName'] ?? 'Anonymous';
    final points = data['pointsAwarded'] ?? 0;
    final intervention = data['interventionAction'];
    final location = data['location'] ?? '';

    return GCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GStatusTag(
                label: type,
                color: _typeColor(type),
                icon: _typeIcon(type),
              ),
              const Spacer(),
              if (points > 0)
                GStatusTag(
                  label: '+$points pts',
                  color: theme.colorScheme.primary,
                  icon: Icons.auto_awesome,
                ),
            ],
          ),
          GSpacing.vMd,
          Text(
            location,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(desc, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
          if (intervention != null && intervention.toString().isNotEmpty) ...[
            GSpacing.vMd,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(XMTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Intervention',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    intervention.toString(),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
          GSpacing.vMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                observer,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                UIUtils.formatTimestamp(data['createdAt']),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Safe Act':
        return XMTheme.success;
      case 'Unsafe Act':
        return XMTheme.error;
      case 'Unsafe Condition':
        return XMTheme.warning;
      default:
        return XMTheme.info;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Safe Act':
        return Icons.verified;
      case 'Unsafe Act':
        return Icons.report_problem;
      case 'Unsafe Condition':
        return Icons.warning;
      default:
        return Icons.info_outline;
    }
  }
}
