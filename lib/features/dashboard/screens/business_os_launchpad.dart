import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BusinessOsLaunchpad extends StatelessWidget {
  const BusinessOsLaunchpad({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Launchpad'),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 1.1,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              delegate: SliverChildListDelegate([
                const _LaunchpadCard(
                  title: 'Finance',
                  icon: Icons.account_balance,
                  color: Colors.blueAccent,
                  route: '/finance',
                ),
                const _LaunchpadCard(
                  title: 'Supply Chain',
                  icon: Icons.local_shipping,
                  color: Colors.orangeAccent,
                  route: '/supply-chain',
                ),
                const _LaunchpadCard(
                  title: 'Project Operations',
                  icon: Icons.architecture,
                  color: Colors.teal,
                  route: '/projects-ops',
                ),
                const _LaunchpadCard(
                  title: 'Field Service',
                  icon: Icons.engineering,
                  color: Colors.brown,
                  route: '/field-service',
                ),
                const _LaunchpadCard(
                  title: 'Sales & CRM',
                  icon: Icons.point_of_sale,
                  color: Colors.green,
                  route: '/crm',
                ),
                const _LaunchpadCard(
                  title: 'Customer Service',
                  icon: Icons.support_agent,
                  color: Colors.deepPurple,
                  route: '/customer-service',
                ),
                const _LaunchpadCard(
                  title: 'Human Resources',
                  icon: Icons.people,
                  color: Colors.pinkAccent,
                  route: '/hr',
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaunchpadCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  const _LaunchpadCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => context.go(route),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
