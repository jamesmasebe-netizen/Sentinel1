import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

class BowTieCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const BowTieCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = data['status'] ?? 'Draft';

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_tree_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Untitled Analysis',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
              ),
              GStatusTag(
                label: status.toUpperCase(),
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          GSpacing.vLg,
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.2,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _buildExpressiveRow(
                  context,
                  'THREATS & PREVENTION',
                  data['threats'],
                  data['preventiveBarriers'],
                  XMTheme.riskHigh,
                  Icons.shield_rounded,
                  true,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: XMTheme.riskExtreme,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data['topEvent']?.toUpperCase() ?? 'TOP EVENT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                _buildExpressiveRow(
                  context,
                  'MITIGATION & RECOVERY',
                  data['mitigationBarriers'],
                  data['consequences'],
                  XMTheme.success,
                  Icons.healing_rounded,
                  false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpressiveRow(
    BuildContext context,
    String title,
    String? val1,
    String? val2,
    Color color,
    IconData icon,
    bool isTop,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            GSpacing.hSm,
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        GSpacing.vSm,
        Text(
          '${val1 ?? "N/A"} • ${val2 ?? "N/A"}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
