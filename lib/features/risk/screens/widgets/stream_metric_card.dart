import 'package:flutter/material.dart';
import '../../../../core/widgets/ds_widgets.dart';

class StreamMetricCard extends StatelessWidget {
  final String title;
  final Stream<String> valueStream;
  final IconData icon;
  final Color color;
  final bool isWide;
  final String initialValue;

  const StreamMetricCard({
    super.key,
    required this.title,
    required this.valueStream,
    required this.icon,
    required this.color,
    required this.isWide,
    required this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: valueStream,
      initialData: initialValue,
      builder: (context, snapshot) {
        final val = snapshot.data ?? initialValue;
        final theme = Theme.of(context);
        final card = GCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                    GSpacing.vXs,
                    Text(val, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
        return isWide ? Expanded(child: card) : card;
      },
    );
  }
}
