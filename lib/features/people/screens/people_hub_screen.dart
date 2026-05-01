import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'employee_profiles_screen.dart';
import '../../training/screens/training_screen.dart';

/// People & Training Hub — employees, training, skills matrix, competency
class PeopleHubScreen extends StatelessWidget {
  const PeopleHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.people, size: 16), text: 'Employees'),
              Tab(icon: Icon(Icons.school, size: 16), text: 'Training'),
              Tab(icon: Icon(Icons.grid_view, size: 16), text: 'Skills Matrix'),
              Tab(icon: Icon(Icons.card_membership, size: 16), text: 'Competency'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const EmployeeProfilesScreen(),
                const TrainingScreen(),
                _PeopleTab(title: 'Skills Matrix', icon: Icons.grid_view, color: XMTheme.warning),
                _PeopleTab(title: 'Competency Passport', icon: Icons.card_membership, color: XMTheme.secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeopleTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _PeopleTab({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Coming soon', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
