import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../providers/dashboard_providers.dart';

class HiraHeatmapChart extends ConsumerWidget {
  const HiraHeatmapChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiraAsync = ref.watch(dashboardHiraMatrixProvider);
    return hiraAsync.when(
      data: (counts) {
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: 25,
          itemBuilder: (context, index) {
            final row = index ~/ 5;
            final col = index % 5;
            final sev = 4 - row + col;
            Color bgColor = XMTheme.success.withValues(alpha: 0.2);
            Color textColor = XMTheme.success;
            if (sev > 3) {
              bgColor = XMTheme.warning.withValues(alpha: 0.2);
              textColor = XMTheme.warning;
            }
            if (sev > 5) {
              bgColor = XMTheme.error.withValues(alpha: 0.2);
              textColor = XMTheme.error;
            }

            final count = counts[index];
            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 0 ? count.toString() : '',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
