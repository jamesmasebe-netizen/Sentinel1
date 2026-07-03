import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../config/theme.dart';
import '../providers/dashboard_providers.dart';

class CapaResolutionChart extends ConsumerWidget {
  const CapaResolutionChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capaAsync = ref.watch(dashboardCapaProvider);
    return capaAsync.when(
      data: (capaMap) {
        final closed = capaMap['closed']!;
        final open = capaMap['open']!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: CustomPaint(painter: _StatusRingPainter(pctClosed: closed)),
            ),
            const SizedBox(width: 24),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: XMTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${closed.toStringAsFixed(0)}% Closed',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${open.toStringAsFixed(0)}% Open',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _StatusRingPainter extends CustomPainter {
  final double pctClosed;
  _StatusRingPainter({required this.pctClosed});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..style = PaintingStyle.fill;

    final sweepClosed = (pctClosed / 100.0) * 2 * math.pi;
    final sweepOpen = 2 * math.pi - sweepClosed;

    paint.color = XMTheme.success;
    canvas.drawArc(rect, -math.pi / 2, sweepClosed, true, paint);

    paint.color = const Color(0xFFE2E8F0);
    canvas.drawArc(rect, -math.pi / 2 + sweepClosed, sweepOpen, true, paint);

    canvas.saveLayer(rect, Paint());

    paint.color = XMTheme.success;
    canvas.drawArc(rect, -math.pi / 2, sweepClosed, true, paint);

    paint.color = const Color(0xFFE2E8F0);
    canvas.drawArc(rect, -math.pi / 2 + sweepClosed, sweepOpen, true, paint);

    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2.5,
      clearPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StatusRingPainter oldDelegate) => oldDelegate.pctClosed != pctClosed;
}
