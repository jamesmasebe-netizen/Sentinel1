import 'package:flutter/material.dart';
import '../../../core/utils/ui_utils.dart';
import '../../emergency/screens/emergency_response_screen.dart';
import '../../safety/screens/permit_to_work_screen.dart';
import 'dispatcher_board_screen.dart';
import 'work_order_list_screen.dart';
import 'route_optimization_screen.dart';

class FieldServiceHubScreen extends StatelessWidget {
  const FieldServiceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Field Service Hub')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildDashboardCard(
              context,
              title: 'Dispatcher Board',
              icon: Icons.dashboard_customize,
              color: Colors.blue,
              destination: const DispatcherBoardScreen(),
            ),
            _buildDashboardCard(
              context,
              title: 'Work Orders',
              icon: Icons.assignment,
              color: Colors.green,
              destination: const WorkOrderListScreen(),
            ),
            _buildDashboardCard(
              context,
              title: 'Emergency Response',
              icon: Icons.emergency,
              color: Colors.red,
              destination: const EmergencyResponseScreen(),
            ),
            _buildDashboardCard(
              context,
              title: 'Route Optimization',
              icon: Icons.map,
              color: Colors.teal,
              destination: const RouteOptimizationScreen(),
            ),
            _buildDashboardCard(
              context,
              title: 'Safety PTW Registry',
              icon: Icons.security,
              color: Colors.orange,
              destination: const PermitToWorkScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        onTap: () => UIUtils.showSideSheet(
          context: context,
          title: title,
          builder: (ctx) => destination,
        ),
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.7), color],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
