import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../providers/dashboard_providers.dart';

class WasteManagementChart extends ConsumerWidget {
  const WasteManagementChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wasteAsync = ref.watch(dashboardWasteProvider);
    return wasteAsync.when(
      data: (wasteMap) {
        final theme = Theme.of(context);
        final recycle = wasteMap['Recycle']!;
        final general = wasteMap['General']!;
        final haz = wasteMap['Haz']!;
        final total = recycle + general + haz;

        final recycleFlex = total == 0 ? 33 : ((recycle / total) * 100).round();
        final generalFlex = total == 0 ? 33 : ((general / total) * 100).round();
        final hazFlex = total == 0 ? 34 : ((haz / total) * 100).round();

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 40,
                child: Row(
                  children: [
                    if (recycleFlex > 0)
                      Expanded(
                        flex: recycleFlex,
                        child: Container(
                          color: XMTheme.success,
                          alignment: Alignment.center,
                          child: Text(
                            'Recycle (${recycle.toStringAsFixed(1)}t)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (generalFlex > 0)
                      Expanded(
                        flex: generalFlex,
                        child: Container(
                          color: XMTheme.warning,
                          alignment: Alignment.center,
                          child: Text(
                            'General (${general.toStringAsFixed(1)}t)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (hazFlex > 0)
                      Expanded(
                        flex: hazFlex,
                        child: Container(
                          color: XMTheme.error,
                          alignment: Alignment.center,
                          child: Text(
                            'Haz (${haz.toStringAsFixed(1)}t)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16), // Replaces GSpacing.vLg
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${total.toStringAsFixed(1)}t',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Target: <5t',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading:
          () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
