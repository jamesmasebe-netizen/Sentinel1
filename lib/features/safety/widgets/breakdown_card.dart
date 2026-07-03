import 'package:flutter/material.dart';
import '../../../core/widgets/ds_widgets.dart';

class BreakdownCard extends StatelessWidget {
  final String title;
  final Map<String, int> data;
  final Map<String, Color> colors;

  const BreakdownCard({
    super.key,
    required this.title,
    required this.data,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a + b);

    return GCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          GSpacing.vMd,
          if (data.isEmpty)
            const Text('No data')
          else
            ...data.entries.map((e) {
              final pct = (e.value / total);
              final color = colors[e.key] ?? theme.colorScheme.primary;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: theme.textTheme.labelMedium),
                        Text(
                          '${(pct * 100).round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
