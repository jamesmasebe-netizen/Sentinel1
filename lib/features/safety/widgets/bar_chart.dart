import 'package:flutter/material.dart';

class BarChart extends StatelessWidget {
  final Map<String, int> data;
  
  const BarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);
    final entries = data.entries.toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: entries.map((e) {
        final height = maxVal > 0 ? (e.value / maxVal) * 140 : 0.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${e.value}', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(e.key, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
