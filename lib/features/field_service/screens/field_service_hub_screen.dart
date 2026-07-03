import 'package:flutter/material.dart';
import 'dispatcher_board_screen.dart';
import 'work_order_list_screen.dart';

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
              destination: null, // Placeholder
            ),
            _buildDashboardCard(
              context,
              title: 'Safety PTW Registry',
              icon: Icons.security,
              color: Colors.orange,
              destination: null, // Placeholder
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
    Widget? destination,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        onTap: () {
          if (destination != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title is under construction.')),
            );
          }
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.7), color],
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
