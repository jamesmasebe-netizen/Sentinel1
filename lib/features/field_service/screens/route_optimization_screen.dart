import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../providers/field_service_providers.dart';
import '../models/field_service_models.dart';
import '../../../core/utils/ui_utils.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class RouteOptimizationScreen extends ConsumerStatefulWidget {
  const RouteOptimizationScreen({super.key});

  @override
  ConsumerState<RouteOptimizationScreen> createState() => _RouteOptimizationScreenState();
}

class _RouteOptimizationScreenState extends ConsumerState<RouteOptimizationScreen> {
  List<String>? _orderedIds;
  bool _isOptimizing = false;
  double? _totalDistanceKm;
  String? _estimatedDuration;

  List<WorkOrder> _routableOrders(List<WorkOrder> all) {
    return all
        .where((wo) => wo.location != null)
        .where((wo) => wo.status != 'COMPLETED' && wo.status != 'CANCELED')
        .toList();
  }

  List<WorkOrder> _ordered(List<WorkOrder> routable) {
    if (_orderedIds == null) return routable;
    final byId = {for (final wo in routable) wo.id: wo};
    final ordered = _orderedIds!.map((id) => byId[id]).whereType<WorkOrder>().toList();
    // Any work order not covered by the last optimization run (e.g. newly
    // arrived) is appended so it's never silently dropped from the list.
    for (final wo in routable) {
      if (!ordered.any((o) => o.id == wo.id)) ordered.add(wo);
    }
    return ordered;
  }

  Future<void> _optimizeRoute(List<WorkOrder> routable) async {
    if (routable.isEmpty) return;
    setState(() => _isOptimizing = true);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final result = await functions.httpsCallable('optimizeRoute').call({
        'locations': routable
            .map((wo) => {
                  'workOrderId': wo.id,
                  'lat': wo.location!.latitude,
                  'lng': wo.location!.longitude,
                })
            .toList(),
      });
      final data = result.data as Map;
      setState(() {
        _orderedIds = List<String>.from(data['optimizedOrder'] as List);
        _totalDistanceKm = (data['totalDistanceKm'] as num).toDouble();
        _estimatedDuration = data['estimatedDuration'] as String;
      });
      if (mounted) {
        UIUtils.showToast(context, 'Route optimized!', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Route optimization failed: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isOptimizing = false);
    }
  }

  void _reorder(List<WorkOrder> ordered, int oldIndex, int newIndex) {
    final ids = ordered.map((wo) => wo.id).toList();
    if (newIndex > oldIndex) newIndex -= 1;
    final item = ids.removeAt(oldIndex);
    ids.insert(newIndex, item);
    setState(() {
      _orderedIds = ids;
      // Manual reordering invalidates the optimizer's own distance/duration claim.
      _totalDistanceKm = null;
      _estimatedDuration = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final workOrdersAsync = ref.watch(workOrdersStreamProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF051B1F),
              Color(0xFF0A2E30),
              Color(0xFF051B1F),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: workOrdersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white70))),
            data: (allOrders) {
              final routable = _routableOrders(allOrders);
              final ordered = _ordered(routable);

              return Column(
                children: [
                  _buildAppBar(context),
                  _buildDaySummaryCard(ordered),
                  _buildOptimizeButton(routable),
                  const SizedBox(height: 8),
                  _buildListHeader(),
                  Expanded(
                    child: ordered.isEmpty
                        ? const Center(
                            child: Text(
                              'No work orders with a location to route.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : _buildReorderableList(ordered),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text('Route Optimization',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.3)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00BFA5).withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.engineering_outlined, color: Color(0xFF00BFA5), size: 14),
                SizedBox(width: 4),
                Text('Field Tech',
                    style: TextStyle(color: Color(0xFF00BFA5), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySummaryCard(List<WorkOrder> ordered) {
    final high = ordered.where((w) => w.priority == 'HIGH' || w.priority == 'CRITICAL').length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00BFA5).withValues(alpha: 0.18),
            const Color(0xFF007A6C).withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00BFA5).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _statChip(Icons.assignment_outlined, ordered.length.toString(), 'Total WOs'),
          const SizedBox(width: 12),
          _statChip(Icons.priority_high_rounded, high.toString(), 'High Priority',
              color: const Color(0xFFFF5252)),
          const SizedBox(width: 12),
          _statChip(Icons.route_outlined,
              _totalDistanceKm != null ? '${_totalDistanceKm!.toStringAsFixed(1)} km' : '—',
              'Est. Distance'),
          const SizedBox(width: 12),
          _statChip(Icons.timer_outlined, _estimatedDuration ?? '—', 'Total Duration'),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, {Color color = const Color(0xFF00BFA5)}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildOptimizeButton(List<WorkOrder> routable) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: (_isOptimizing || routable.isEmpty) ? null : () => _optimizeRoute(routable),
          icon: _isOptimizing
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_fix_high_rounded, size: 18),
          label: Text(
            _isOptimizing ? 'Optimizing...' : 'Optimize Route',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 4,
            shadowColor: const Color(0xFF00BFA5).withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.drag_indicator, color: Colors.white24, size: 16),
          SizedBox(width: 6),
          Text('Drag to reorder  ·  Tap to view details', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildReorderableList(List<WorkOrder> ordered) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (_, __) => Material(color: Colors.transparent, child: child),
        );
      },
      onReorder: (oldIndex, newIndex) => _reorder(ordered, oldIndex, newIndex),
      itemCount: ordered.length,
      itemBuilder: (context, index) {
        final wo = ordered[index];
        return _WorkOrderCard(key: ValueKey(wo.id), workOrder: wo, index: index);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Work Order Card
// ---------------------------------------------------------------------------

class _WorkOrderCard extends StatelessWidget {
  const _WorkOrderCard({super.key, required this.workOrder, required this.index});

  final WorkOrder workOrder;
  final int index;

  Color get _priorityColor {
    switch (workOrder.priority) {
      case 'CRITICAL':
        return const Color(0xFFD32F2F);
      case 'HIGH':
        return const Color(0xFFFF5252);
      case 'MEDIUM':
        return const Color(0xFFFFAB40);
      default:
        return const Color(0xFF69F0AE);
    }
  }

  String get _addressLabel {
    final addr = workOrder.address;
    if (addr == null || addr.isEmpty) return 'No address on file';
    final parts = [addr['street'], addr['city'], addr['postalCode']]
        .where((p) => p != null && p.toString().isNotEmpty)
        .join(', ');
    return parts.isEmpty ? 'No address on file' : parts;
  }

  String get _timeWindowLabel {
    final start = workOrder.scheduling?['scheduled_start'];
    if (start == null) return 'Unscheduled';
    final dt = start is String ? DateTime.tryParse(start) : null;
    if (dt == null) return 'Unscheduled';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF00BFA5).withValues(alpha: 0.25),
                  const Color(0xFF00897B).withValues(alpha: 0.15),
                ],
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${index + 1}',
                    style:
                        const TextStyle(color: Color(0xFF00BFA5), fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Icon(Icons.drag_handle, color: Colors.white24, size: 16),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(workOrder.workOrderNumber,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _priorityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _priorityColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(workOrder.priority,
                            style: TextStyle(
                                color: _priorityColor, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.work_outline, color: Color(0xFF00BFA5), size: 13),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(workOrder.description ?? 'No description',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF00BFA5), fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white38, size: 13),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(_addressLabel,
                            style: const TextStyle(color: Colors.white54, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined, color: Colors.white38, size: 13),
                      const SizedBox(width: 5),
                      Text(_timeWindowLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.2), size: 20),
          ),
        ],
      ),
    );
  }
}
