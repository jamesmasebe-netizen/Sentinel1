import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../providers/dashboard_providers.dart';

class MandatoryTrainingChart extends ConsumerWidget {
  const MandatoryTrainingChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainingAsync = ref.watch(dashboardTrainingProvider);
    return trainingAsync.when(
      data: (trainingMap) {
        final theme = Theme.of(context);
        final items = [
          {'label': 'First Aid Level 1', 'percent': trainingMap['First Aid']!.toInt(), 'color': XMTheme.secondary},
          {'label': 'Fire Fighting', 'percent': trainingMap['Fire Fighting']!.toInt(), 'color': XMTheme.warning},
          {'label': 'SHE Rep', 'percent': trainingMap['SHE Rep']!.toInt(), 'color': XMTheme.success},
        ];
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              items.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              e['label'] as String,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${e['percent']}%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (e['percent'] as int) / 100,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            e['color'] as Color,
                          ),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
