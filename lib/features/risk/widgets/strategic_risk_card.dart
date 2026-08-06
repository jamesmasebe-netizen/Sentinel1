import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../models/strategic_risk.dart';

class StrategicRiskCard extends StatelessWidget {
  final StrategicRisk risk;

  const StrategicRiskCard({super.key, required this.risk});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = risk.riskRating;
    final score = risk.riskScore;
    final status = risk.status;

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GStatusTag(
                label: '$rating ($score)'.toUpperCase(),
                color: _ratingColor(rating),
                icon: Icons.speed_rounded,
              ),
              GSpacing.hSm,
              GStatusTag(
                label: risk.category.toUpperCase(),
                color: theme.colorScheme.secondary,
              ),
              const Spacer(),
              GStatusTag(
                label: status.toUpperCase(),
                color: _statusColor(status),
                icon: _statusIcon(status),
              ),
            ],
          ),
          GSpacing.vMd,
          Text(
            risk.title.isEmpty ? 'Untitled Risk' : risk.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (risk.description.isNotEmpty) ...[
            GSpacing.vSm,
            Text(
              risk.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          GSpacing.vMd,
          const Divider(height: 1, thickness: 0.5),
          GSpacing.vMd,
          Row(
            children: [
              if (risk.owner.isNotEmpty) ...[
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                GSpacing.hSm,
                Text(
                  risk.owner,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GSpacing.hLg,
              ],
              Icon(
                Icons.analytics_outlined,
                size: 16,
                color: theme.colorScheme.outline,
              ),
              GSpacing.hSm,
              Text(
                'L: ${risk.likelihood} • I: ${risk.impact}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'Critical':
        return XMTheme.riskExtreme;
      case 'High':
        return XMTheme.riskHigh;
      case 'Medium':
        return XMTheme.riskMedium;
      default:
        return XMTheme.riskLow;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return XMTheme.error;
      case 'Mitigating':
        return XMTheme.warning;
      case 'Monitoring':
        return XMTheme.info;
      case 'Closed':
        return XMTheme.success;
      default:
        return XMTheme.primary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Open':
        return Icons.error_outline_rounded;
      case 'Mitigating':
        return Icons.shield_outlined;
      case 'Monitoring':
        return Icons.visibility_outlined;
      case 'Closed':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}
