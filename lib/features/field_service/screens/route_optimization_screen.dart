import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _WorkOrder {
  _WorkOrder({
    required this.woNumber,
    required this.address,
    required this.timeWindow,
    required this.jobType,
    required this.priority,
  });

  final String woNumber;
  final String address;
  final String timeWindow;
  final String jobType;
  final _Priority priority;
}

enum _Priority { high, medium, low }

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

final _workOrdersProvider =
    StateNotifierProvider<_WorkOrdersNotifier, List<_WorkOrder>>((ref) {
  return _WorkOrdersNotifier();
});

class _WorkOrdersNotifier extends StateNotifier<List<_WorkOrder>> {
  _WorkOrdersNotifier()
      : super([
          _WorkOrder(
            woNumber: 'WO-20410',
            address: '14 Rivonia Rd, Sandton, 2196',
            timeWindow: '08:00 – 10:00',
            jobType: 'Fiber Installation',
            priority: _Priority.high,
          ),
          _WorkOrder(
            woNumber: 'WO-20411',
            address: '302 Commissioner St, Johannesburg, 2001',
            timeWindow: '10:30 – 12:00',
            jobType: 'Router Replacement',
            priority: _Priority.medium,
          ),
          _WorkOrder(
            woNumber: 'WO-20412',
            address: '88 Claim St, Hillbrow, 2001',
            timeWindow: '12:30 – 14:00',
            jobType: 'Signal Fault Diagnosis',
            priority: _Priority.high,
          ),
          _WorkOrder(
            woNumber: 'WO-20413',
            address: '5 Eloff St Ext, Fordsburg, 2092',
            timeWindow: '14:30 – 16:00',
            jobType: 'ONT Swap',
            priority: _Priority.low,
          ),
          _WorkOrder(
            woNumber: 'WO-20414',
            address: '210 Smit St, Braamfontein, 2017',
            timeWindow: '16:30 – 18:00',
            jobType: 'Splitter Replacement',
            priority: _Priority.medium,
          ),
        ]);

  void reorder(int oldIndex, int newIndex) {
    final list = List<_WorkOrder>.from(state);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }

  void optimizeRoute() {
    state = state.reversed.toList();
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class RouteOptimizationScreen extends ConsumerWidget {
  const RouteOptimizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workOrders = ref.watch(_workOrdersProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF051B1F), // very dark teal-black
              Color(0xFF0A2E30), // dark teal
              Color(0xFF051B1F),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildDaySummaryCard(workOrders),
              _buildOptimizeButton(context, ref),
              const SizedBox(height: 8),
              _buildListHeader(),
              Expanded(
                child: _buildReorderableList(context, ref, workOrders),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white70, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Route Optimization',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: 0.3)),
                Text('Monday, 27 July 2026',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF00BFA5).withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.engineering_outlined,
                    color: Color(0xFF00BFA5), size: 14),
                SizedBox(width: 4),
                Text('Field Tech',
                    style: TextStyle(
                        color: Color(0xFF00BFA5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySummaryCard(List<_WorkOrder> workOrders) {
    final high =
        workOrders.where((w) => w.priority == _Priority.high).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00BFA5).withOpacity(0.18),
            const Color(0xFF007A6C).withOpacity(0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF00BFA5).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _statChip(Icons.assignment_outlined,
              workOrders.length.toString(), 'Total WOs'),
          const SizedBox(width: 12),
          _statChip(
              Icons.priority_high_rounded, high.toString(), 'High Priority',
              color: const Color(0xFFFF5252)),
          const SizedBox(width: 12),
          _statChip(Icons.route_outlined, '42 km', 'Est. Distance'),
          const SizedBox(width: 12),
          _statChip(Icons.timer_outlined, '~8.5 h', 'Total Duration'),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label,
      {Color color = const Color(0xFF00BFA5)}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 9),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildOptimizeButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            ref.read(_workOrdersProvider.notifier).optimizeRoute();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF00897B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                content: const Row(
                  children: [
                    Icon(Icons.route, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text('Route optimized!',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          },
          icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
          label: const Text(
            'Optimize Route',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
            shadowColor: const Color(0xFF00BFA5).withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: const [
          Icon(Icons.drag_indicator, color: Colors.white24, size: 16),
          SizedBox(width: 6),
          Text('Drag to reorder  ·  Tap to view details',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildReorderableList(
      BuildContext context, WidgetRef ref, List<_WorkOrder> workOrders) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (_, __) => Material(
            color: Colors.transparent,
            child: child,
          ),
        );
      },
      onReorder: (oldIndex, newIndex) {
        ref.read(_workOrdersProvider.notifier).reorder(oldIndex, newIndex);
      },
      itemCount: workOrders.length,
      itemBuilder: (context, index) {
        final wo = workOrders[index];
        return _WorkOrderCard(
          key: ValueKey(wo.woNumber),
          workOrder: wo,
          index: index,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Work Order Card
// ---------------------------------------------------------------------------

class _WorkOrderCard extends StatelessWidget {
  const _WorkOrderCard({
    super.key,
    required this.workOrder,
    required this.index,
  });

  final _WorkOrder workOrder;
  final int index;

  Color get _priorityColor {
    switch (workOrder.priority) {
      case _Priority.high:
        return const Color(0xFFFF5252);
      case _Priority.medium:
        return const Color(0xFFFFAB40);
      case _Priority.low:
        return const Color(0xFF69F0AE);
    }
  }

  String get _priorityLabel {
    switch (workOrder.priority) {
      case _Priority.high:
        return 'HIGH';
      case _Priority.medium:
        return 'MED';
      case _Priority.low:
        return 'LOW';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sequence indicator
          Container(
            width: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF00BFA5).withOpacity(0.25),
                  const Color(0xFF00897B).withOpacity(0.15),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF00BFA5),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.drag_handle,
                    color: Colors.white24, size: 16),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        workOrder.woNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _priorityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _priorityColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          _priorityLabel,
                          style: TextStyle(
                            color: _priorityColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.work_outline,
                          color: Color(0xFF00BFA5), size: 13),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          workOrder.jobType,
                          style: const TextStyle(
                            color: Color(0xFF00BFA5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Colors.white38, size: 13),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          workOrder.address,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined,
                          color: Colors.white38, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        workOrder.timeWindow,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Arrow
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right,
                color: Colors.white.withOpacity(0.2), size: 20),
          ),
        ],
      ),
    );
  }
}
