import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../scripts/seed_dummy_data.dart';
import '../../property/providers/property_providers.dart';

import '../../../core/providers/app_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isSeeding = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    if (screenWidth > 1200) {
      crossAxisCount = 3;
    } else if (screenWidth > 800) {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analytics Hub',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Integrated SHEQ & Property Performance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isSeeding ? null : () async {
                    setState(() => _isSeeding = true);
                    try {
                      final firestore = ref.read(firestoreProvider);
                      await seedAllDummyData(firestore);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database Seeded Successfully!')));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seeding Failed: $e')));
                    } finally {
                      if (mounted) setState(() => _isSeeding = false);
                    }
                  },
                  icon: _isSeeding ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text(_isSeeding ? 'Seeding...' : 'Seed Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: XMTheme.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.description, size: 18),
                  label: const Text('Export CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: XMTheme.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 9 Charts Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 20)) / crossAxisCount;
                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    _buildChartContainer(itemWidth, '1. LTIFR History (6 Mo)', _buildBarChart(), onTap: () => context.go('/safety')),
                    _buildChartContainer(itemWidth, '2. Incidents by Category', _buildDoughnutChart(context), onTap: () => context.go('/safety')),
                    _buildChartContainer(itemWidth, '3. OHS Act Compliance %', _buildLineChart(), onTap: () => context.go('/safety')),
                    _buildChartContainer(itemWidth, '4. HIRA Risk Matrix', _buildHeatmap(), onTap: () => context.go('/risk')),
                    _buildChartContainer(itemWidth, '5. Mandatory Training', _buildProgressBars(), onTap: () => context.go('/people')),
                    _buildChartContainer(itemWidth, '6. CAPA Resolution', _buildStatusRing(), onTap: () => context.go('/safety')),
                    _buildChartContainer(itemWidth, '7. Waste Mgmt (Tons)', _buildStackedBar(), onTap: () => context.go('/environment')),
                    _buildChartContainer(itemWidth, '8. Incident Heatmap (Time)', _buildScatterPlot(), onTap: () => context.go('/safety')),
                    _buildChartContainer(
                      crossAxisCount == 3 ? itemWidth : constraints.maxWidth, 
                      '9. Incident Mapping (HQ)', 
                      _buildRealMap(),
                      onTap: () => context.go('/properties'),
                    ),
                  ],
                );
              }
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer(double width, String title, Widget child, {VoidCallback? onTap}) {
    return SizedBox(
      width: width,
      height: 280,
      child: Card(
        elevation: 0,
        color: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(XMTheme.radiusLg),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 16, color: XMTheme.primary.withValues(alpha: 0.5)),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final values = [75, 80, 60, 45, 30, 42];
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
                      color: XMTheme.primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: FractionallySizedBox(
                      heightFactor: values[index] / 100,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: XMTheme.secondary,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('M${index + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDoughnutChart(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _DoughnutPainter(),
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('42', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                Text('TOTAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CustomPaint(
        size: Size.infinite,
        painter: _LineChartPainter(),
      ),
    );
  }

  Widget _buildHeatmap() {
    final counts = [0,2,0,0,1, 4,0,0,2,0, 1,5,0,0,0, 0,0,1,0,0, 12,3,0,0,0];
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
        Color bgColor = XMTheme.success.withOpacity(0.2);
        Color textColor = XMTheme.success;
        if (sev > 3) { bgColor = XMTheme.warning.withOpacity(0.2); textColor = XMTheme.warning; }
        if (sev > 5) { bgColor = XMTheme.error.withOpacity(0.2); textColor = XMTheme.error; }
        
        final count = counts[index];
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            count > 0 ? count.toString() : '',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        );
      },
    );
  }

  Widget _buildProgressBars() {
    final items = [
      {'label': 'First Aid Level 1', 'percent': 90, 'color': XMTheme.secondary},
      {'label': 'Fire Fighting', 'percent': 65, 'color': XMTheme.warning},
      {'label': 'SHE Rep', 'percent': 100, 'color': XMTheme.success},
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e['label'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('${e['percent']}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (e['percent'] as int) / 100,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(e['color'] as Color),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusRing() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: CustomPaint(
            painter: _StatusRingPainter(),
          ),
        ),
        const SizedBox(width: 24),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Container(width: 12, height: 12, decoration: const BoxDecoration(color: XMTheme.success, shape: BoxShape.circle)), const SizedBox(width: 8), const Text('60% Closed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)), const SizedBox(width: 8), const Text('40% Open', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
          ],
        ),
      ],
    );
  }

  Widget _buildStackedBar() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(flex: 5, child: Container(color: XMTheme.success, alignment: Alignment.center, child: const Text('Recycle', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                Expanded(flex: 3, child: Container(color: XMTheme.warning, alignment: Alignment.center, child: const Text('General', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                Expanded(flex: 2, child: Container(color: XMTheme.error, alignment: Alignment.center, child: const Text('Haz', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total: 4.2t', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text('Target: <5t', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildScatterPlot() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.grey, width: 2),
            bottom: BorderSide(color: Colors.grey, width: 2),
          ),
        ),
        child: Stack(
          children: [
            const Positioned(bottom: -20, left: 0, child: Text('06:00', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
            const Positioned(bottom: -20, right: 0, child: Text('18:00', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
            const Positioned(bottom: 80, left: -25, child: Text('Mon', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
            Positioned(left: 40, top: 40, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: XMTheme.error.withOpacity(0.8), shape: BoxShape.circle))),
            Positioned(left: 80, top: 160, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: XMTheme.warning.withOpacity(0.8), shape: BoxShape.circle))),
            Positioned(left: 150, top: 100, child: Container(width: 16, height: 16, decoration: BoxDecoration(color: const Color(0xFFC5221F).withOpacity(0.8), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
            Positioned(left: 170, top: 60, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: XMTheme.warning.withOpacity(0.8), shape: BoxShape.circle))),
          ],
        ),
      ),
    );
  }

  Widget _buildRealMap() {
    return Consumer(
      builder: (context, ref, child) {
        final propertiesAsync = ref.watch(propertiesProvider);
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: propertiesAsync.when(
              data: (properties) {
                final markers = properties.map((p) => Marker(
                  markerId: MarkerId(p.id),
                  position: LatLng(p.lat, p.lng),
                  infoWindow: InfoWindow(title: p.name, snippet: p.type),
                  onTap: () => context.go('/properties'),
                )).toSet();

                return GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-26.1075, 28.0567),
                    zoom: 10,
                  ),
                  markers: markers,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Icon(Icons.map_outlined, color: Colors.white24, size: 48)),
            ),
          ),
        );
      },
    );
  }
}

class _DoughnutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..style = PaintingStyle.fill;
    
    paint.color = XMTheme.error;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 0.6, true, paint);
    
    paint.color = XMTheme.warning;
    canvas.drawArc(rect, math.pi * 0.1, math.pi * 0.5, true, paint);
    
    paint.color = XMTheme.success;
    canvas.drawArc(rect, math.pi * 0.6, math.pi * 0.6, true, paint);
    
    paint.color = XMTheme.secondary;
    canvas.drawArc(rect, math.pi * 1.2, math.pi * 0.3, true, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = XMTheme.success
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    final path = Path();
    path.moveTo(0, size.height * 0.9);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.8, size.width * 0.4, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.3, size.width, size.height * 0.1);
    
    canvas.drawPath(path, paint);
    
    final dotPaint = Paint()..color = XMTheme.success..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, size.height * 0.9), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.5), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.3), 4, dotPaint);
    canvas.drawCircle(Offset(size.width, size.height * 0.1), 4, dotPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatusRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..style = PaintingStyle.fill;
    
    paint.color = XMTheme.success;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.2, true, paint);
    
    paint.color = const Color(0xFFE2E8F0);
    canvas.drawArc(rect, math.pi * 0.7, math.pi * 0.8, true, paint);
    
    final inner = Paint()..color = Colors.white..style = PaintingStyle.fill..blendMode = BlendMode.clear;
    // Since BlendMode.clear requires an opacity layer, we can just paint over it with the theme background color.
    // However, since it's hard to get the exact theme background here without context,
    // let's assume it's drawn on a white/dark card.
    final clearPaint = Paint()..color = Colors.white..style = PaintingStyle.fill..blendMode = BlendMode.clear;
    canvas.saveLayer(rect, Paint());
    
    paint.color = XMTheme.success;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.2, true, paint);
    
    paint.color = const Color(0xFFE2E8F0);
    canvas.drawArc(rect, math.pi * 0.7, math.pi * 0.8, true, paint);
    
    canvas.drawCircle(Offset(size.width/2, size.height/2), size.width/2.5, clearPaint);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.4), paint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.4, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.6, 0), Offset(size.width * 0.8, size.height), paint);
    
    final dot = Paint()..color = XMTheme.error.withOpacity(0.5)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.35), 8, dot);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.7), 6, dot);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
