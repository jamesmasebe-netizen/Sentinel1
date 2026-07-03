import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../providers/dashboard_providers.dart';

class IncidentHeatmapScatterPlot extends ConsumerWidget {
  const IncidentHeatmapScatterPlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapAsync = ref.watch(dashboardIncidentHeatmapProvider);
    return heatmapAsync.when(
      data: (points) {
        final defaultPoints = [
          {'x': 0.2, 'y': 0.1, 'isCritical': 1.0},
          {'x': 0.5, 'y': 0.8, 'isCritical': 0.0},
          {'x': 0.8, 'y': 0.4, 'isCritical': 1.0},
        ];
        final activePoints = points.isEmpty ? defaultPoints : points;
        return Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey, width: 2),
                bottom: BorderSide(color: Colors.grey, width: 2),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      bottom: -20,
                      left: 0,
                      child: Text(
                        '06:00',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                       ),
                    ),
                    const Positioned(
                      bottom: -20,
                      right: 0,
                      child: Text(
                        '18:00',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 80,
                      left: -25,
                      child: Text(
                        'Mon',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...activePoints.map((p) {
                      final x = p['x']! * (width - 16);
                      final y = p['y']! * (height - 16);
                      final isCrit = p['isCritical'] == 1.0;
                      return Positioned(
                        left: x,
                        top: y,
                        child: Container(
                          width: isCrit ? 16 : 12,
                          height: isCrit ? 16 : 12,
                          decoration: BoxDecoration(
                            color: (isCrit ? XMTheme.error : XMTheme.warning).withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: isCrit ? Border.all(color: Colors.white, width: 2) : null,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
