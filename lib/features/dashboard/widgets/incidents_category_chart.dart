import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class IncidentsCategoryChart extends ConsumerWidget {
  const IncidentsCategoryChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);

    if (siteId == null) {
      return const Center(child: Text('No site assigned'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          firestore
              .tenantCollection(
                ref.watch(currentTenantIdProvider) ?? "",
                'incidents',
              )
              .where('siteId', isEqualTo: siteId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final docs = snapshot.data?.docs ?? [];
        final total = docs.length;

        // Group by category/type
        final injuryCount = docs.where((d) => d.get('type') == 'Injury').length;
        final nearMissCount =
            docs.where((d) => d.get('type') == 'Near Miss').length;
        final envCount =
            docs.where((d) => d.get('type') == 'Environmental').length;
        final propDamageCount =
            docs.where((d) => d.get('type') == 'Property Damage').length;
        final hazardObsCount =
            docs.where((d) => d.get('type') == 'Hazard Observation').length;

        final values = [
          injuryCount.toDouble(),
          nearMissCount.toDouble(),
          envCount.toDouble(),
          propDamageCount.toDouble(),
          hazardObsCount.toDouble(),
        ];

        final colors = [
          XMTheme.error,
          XMTheme.warning,
          XMTheme.success,
          XMTheme.primary,
          XMTheme.secondary,
        ];

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _DoughnutPainter(values: values, colors: colors),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$total',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'TOTAL',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DoughnutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DoughnutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..style = PaintingStyle.fill;

    double startAngle = -math.pi / 2;
    final total = values.fold<double>(0.0, (s, v) => s + v);
    if (total == 0) {
      paint.color = Colors.grey.shade300;
      canvas.drawArc(rect, 0, 2 * math.pi, true, paint);
      return;
    }

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      paint.color = colors[i % colors.length];
      final sweepAngle = (values[i] / total) * 2 * math.pi;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DoughnutPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}
