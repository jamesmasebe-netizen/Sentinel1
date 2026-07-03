import 'package:flutter/material.dart';
import '../../../core/widgets/ds_widgets.dart';

class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      color: color.withValues(alpha: 0.08),
      border: BorderSide(color: color.withValues(alpha: 0.2)),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            GSpacing.vMd,
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            GSpacing.vXs,
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
