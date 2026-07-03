import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../providers/dashboard_providers.dart';

class LtifrHistoryChart extends ConsumerWidget {
  const LtifrHistoryChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ltifrAsync = ref.watch(dashboardLtifrHistoryProvider);
    return ltifrAsync.when(
      data: (values) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(values.length, (index) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                         alignment: Alignment.bottomCenter,
                         decoration: BoxDecoration(
                           color: XMTheme.primary.withValues(alpha: 0.1),
                           borderRadius: const BorderRadius.vertical(
                             top: Radius.circular(8),
                           ),
                         ),
                         child: FractionallySizedBox(
                           heightFactor: (values[index] / 100).clamp(0.0, 1.0),
                           child: Container(
                             decoration: const BoxDecoration(
                               color: XMTheme.secondary,
                               borderRadius: BorderRadius.vertical(
                                 top: Radius.circular(8),
                               ),
                             ),
                           ),
                         ),
                       ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'M${index + 1}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
