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
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 24.0, top: 24.0, right: 24.0),
              child: Text('Finance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
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
              ]),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 24.0, right: 24.0),
              child: Text('Supply Chain Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
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
                  title: 'Supply Chain',
                  icon: Icons.local_shipping,
                  color: Colors.orangeAccent,
                  route: '/supply-chain',
                ),
                const _LaunchpadCard(
                  title: 'Master Planning',
                  icon: Icons.auto_awesome,
                  color: Colors.deepOrange,
                  route: '/mrp-dashboard',
                ),
                const _LaunchpadCard(
                  title: 'WMS Scanner',
                  icon: Icons.qr_code_scanner,
                  color: Colors.deepOrangeAccent,
                  route: '/wms-scanner',
                ),
                const _LaunchpadCard(
                  title: 'Manufacturing',
                  icon: Icons.precision_manufacturing,
                  color: Colors.amber,
                  route: '/manufacturing',
                ),
                const _LaunchpadCard(
                  title: 'Equipment',
                  icon: Icons.precision_manufacturing,
                  color: Colors.amber,
                  route: '/equipment',
                ),
                const _LaunchpadCard(
                  title: 'Property & Facilities',
                  icon: Icons.business,
                  color: Colors.grey,
                  route: '/properties',
                ),
                const _LaunchpadCard(
                  title: 'Environment',
                  icon: Icons.eco,
                  color: Colors.green,
                  route: '/environment',
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 24.0, right: 24.0),
              child: Text('Human Resources', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
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
                  title: 'HR & Payroll',
                  icon: Icons.people,
                  color: Colors.pinkAccent,
                  route: '/people',
                ),
                const _LaunchpadCard(
                  title: 'Training',
                  icon: Icons.model_training,
                  color: Colors.lightBlue,
                  route: '/training',
                ),
                const _LaunchpadCard(
                  title: 'Workers Comp',
                  icon: Icons.personal_injury,
                  color: Colors.orange,
                  route: '/workers-comp',
                ),
                const _LaunchpadCard(
                  title: 'Occupational Health',
                  icon: Icons.medical_services,
                  color: Colors.pink,
                  route: '/health',
                ),
                const _LaunchpadCard(
                  title: 'Safety',
                  icon: Icons.health_and_safety,
                  color: Colors.redAccent,
                  route: '/safety',
                ),
                const _LaunchpadCard(
                  title: 'Compliance',
                  icon: Icons.fact_check,
                  color: Colors.deepPurpleAccent,
                  route: '/compliance',
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 24.0, right: 24.0),
              child: Text('Project Operations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
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
                  title: 'Projects',
                  icon: Icons.architecture,
                  color: Colors.indigo,
                  route: '/projects',
                ),
                const _LaunchpadCard(
                  title: 'Project Ops',
                  icon: Icons.construction,
                  color: Colors.teal,
                  route: '/projects-ops',
                ),
                const _LaunchpadCard(
                  title: 'Schedule Board',
                  icon: Icons.calendar_view_week,
                  color: Colors.blueAccent,
                  route: '/schedule-board',
                ),
                const _LaunchpadCard(
                  title: 'Contractors',
                  icon: Icons.engineering,
                  color: Colors.brown,
                  route: '/contractors',
                ),
                const _LaunchpadCard(
                  title: 'Risk',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.deepOrange,
                  route: '/risk',
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 24.0, right: 24.0),
              child: Text('Customer Engagement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
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
                  title: 'CRM',
                  icon: Icons.point_of_sale,
                  color: Colors.lightGreen,
                  route: '/crm',
                ),
                const _LaunchpadCard(
                  title: 'Customer Service',
                  icon: Icons.support_agent,
                  color: Colors.deepPurple,
                  route: '/customer-service',
                ),
                const _LaunchpadCard(
                  title: 'Field Service',
                  icon: Icons.handyman,
                  color: Colors.lime,
                  route: '/field-service',
                ),
                const _LaunchpadCard(
                  title: 'Emergency',
                  icon: Icons.emergency,
                  color: Colors.red,
                  route: '/emergency',
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 24.0, right: 24.0),
              child: Text('System Administration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
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
                  title: 'Command Center',
                  icon: Icons.monitor,
                  color: Colors.blueGrey,
                  route: '/operations',
                ),
                const _LaunchpadCard(
                  title: 'AI Chat',
                  icon: Icons.smart_toy,
                  color: Colors.purple,
                  route: '/ai',
                ),
                const _LaunchpadCard(
                  title: 'Global Settings',
                  icon: Icons.settings,
                  color: Colors.grey,
                  route: '/settings',
                ),
                const _LaunchpadCard(
                  title: 'Global Control Tower',
                  icon: Icons.satellite_alt,
                  color: Colors.cyanAccent,
                  route: '/control-tower',
                ),
                const _LaunchpadCard(
                  title: 'Sentinel Copilot',
                  icon: Icons.auto_awesome,
                  color: Colors.deepPurpleAccent,
                  route: '/copilot',
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
