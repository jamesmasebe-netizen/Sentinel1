import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../providers/dashboard_providers.dart';

class OhsComplianceChart extends ConsumerWidget {
  const OhsComplianceChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complianceAsync = ref.watch(dashboardOhsComplianceProvider);
    return complianceAsync.when(
      data: (val) {
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomPaint(size: Size.infinite, painter: _LineChartPainter(value: val)),
              ),
            ),
            Text(
              'Current: ${val.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: XMTheme.success),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final double value;
  _LineChartPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = XMTheme.success
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, size.height * 0.9);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.8,
      size.width * 0.6,
      size.height * (1.0 - (value / 100.0) * 0.7),
    );
    path.lineTo(size.width, size.height * (1.0 - (value / 100.0) * 0.9));

    canvas.drawPath(path, paint);

    final dotPaint =
        Paint()
          ..color = XMTheme.success
          ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, size.height * 0.9), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * (1.0 - (value / 100.0) * 0.7)), 4, dotPaint);
    canvas.drawCircle(Offset(size.width, size.height * (1.0 - (value / 100.0) * 0.9)), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => oldDelegate.value != value;
}
