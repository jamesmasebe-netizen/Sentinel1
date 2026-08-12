import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';

class _TileData {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  // Contractor accounts only have Firestore access to a narrow set of
  // collections (safety_file_submissions, contractor_documents,
  // contractor_inductions) — see firestore.rules. Every other tile leads to
  // a screen that would just render empty/permission-denied for them.
  final bool contractorVisible;
  const _TileData({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    this.contractorVisible = false,
  });
}

class _SectionData {
  final String title;
  final List<_TileData> tiles;
  const _SectionData(this.title, this.tiles);
}

// D365 Pivot Roadmap Phase 0 (2026-08-12): sections now mirror the 7 named D365
// pillars (Finance/Project Operations/Human Resources/Field Service/Customer
// Service/Sales/Supply Chain Management) plus the masterplan's explicit
// "Existing Code Mapping" — Risk/Safety/Emergency/Environment grouped under
// EHS & Risk Management rather than scattered across HR/Project Ops/Supply
// Chain. See docs/D365_PIVOT_ROADMAP.md and docs/dynamics_365_masterplan.md §1.
const _sections = [
  _SectionData('Finance', [
    _TileData(title: 'Finance', icon: Icons.account_balance, color: Colors.blueAccent, route: '/finance'),
  ]),
  _SectionData('Project Operations', [
    _TileData(title: 'Projects', icon: Icons.architecture, color: Colors.indigo, route: '/projects'),
    _TileData(title: 'Project Ops', icon: Icons.construction, color: Colors.teal, route: '/projects-ops'),
    _TileData(title: 'Schedule Board', icon: Icons.calendar_view_week, color: Colors.blueAccent, route: '/schedule-board'),
    _TileData(title: 'Contractors', icon: Icons.engineering, color: Colors.brown, route: '/contractors', contractorVisible: true),
  ]),
  _SectionData('Human Resources', [
    _TileData(title: 'HR & Payroll', icon: Icons.people, color: Colors.pinkAccent, route: '/people'),
    _TileData(title: 'Training', icon: Icons.model_training, color: Colors.lightBlue, route: '/training', contractorVisible: true),
    // Wired up 2026-08-12 — EmployeeHubScreen ("My Portal") existed with zero route
    // registration and zero callers anywhere; this is the masterplan's "Employee Hub
    // fuses into HR" instruction, just never actually connected.
    _TileData(title: 'My Portal', icon: Icons.badge, color: Colors.deepPurple, route: '/my-portal'),
  ]),
  _SectionData('Field Service', [
    _TileData(title: 'Field Service', icon: Icons.handyman, color: Colors.lime, route: '/field-service'),
  ]),
  _SectionData('Customer Service', [
    _TileData(title: 'Customer Service', icon: Icons.support_agent, color: Colors.deepPurple, route: '/customer-service'),
  ]),
  _SectionData('Sales', [
    _TileData(title: 'CRM', icon: Icons.point_of_sale, color: Colors.lightGreen, route: '/crm'),
  ]),
  _SectionData('Supply Chain Management', [
    _TileData(title: 'Supply Chain', icon: Icons.local_shipping, color: Colors.orangeAccent, route: '/supply-chain'),
    _TileData(title: 'Master Planning', icon: Icons.auto_awesome, color: Colors.deepOrange, route: '/mrp-dashboard'),
    _TileData(title: 'WMS Scanner', icon: Icons.qr_code_scanner, color: Colors.deepOrangeAccent, route: '/wms-scanner'),
    _TileData(title: 'Manufacturing', icon: Icons.precision_manufacturing, color: Colors.amber, route: '/manufacturing'),
    _TileData(title: 'Equipment', icon: Icons.precision_manufacturing, color: Colors.amber, route: '/equipment'),
    _TileData(title: 'Property & Facilities', icon: Icons.business, color: Colors.grey, route: '/properties'),
  ]),
  _SectionData('EHS & Risk Management', [
    _TileData(title: 'Safety', icon: Icons.health_and_safety, color: Colors.redAccent, route: '/safety', contractorVisible: true),
    _TileData(title: 'Compliance', icon: Icons.fact_check, color: Colors.deepPurpleAccent, route: '/compliance', contractorVisible: true),
    _TileData(title: 'Workers Comp', icon: Icons.personal_injury, color: Colors.orange, route: '/workers-comp'),
    _TileData(title: 'Occupational Health', icon: Icons.medical_services, color: Colors.pink, route: '/health'),
    _TileData(title: 'Risk', icon: Icons.warning_amber_rounded, color: Colors.deepOrange, route: '/risk'),
    _TileData(title: 'Environment', icon: Icons.eco, color: Colors.green, route: '/environment'),
    _TileData(title: 'Emergency', icon: Icons.emergency, color: Colors.red, route: '/emergency', contractorVisible: true),
  ]),
  _SectionData('System Administration', [
    _TileData(title: 'Command Center', icon: Icons.monitor, color: Colors.blueGrey, route: '/operations'),
    _TileData(title: 'AI Chat', icon: Icons.smart_toy, color: Colors.purple, route: '/ai'),
    _TileData(title: 'Global Settings', icon: Icons.settings, color: Colors.grey, route: '/settings'),
    // Control Tower is now the Executive View toggle inside DashboardScreen, not a
    // standalone route — /control-tower no longer exists in router.dart.
    // Renamed from "Global Control Tower" 2026-08-12 — DashboardScreen already merged the two
    // concepts behind an Operational/Executive toggle (see dashboard_screen.dart), and this is
    // the only launchpad tile pointing at /dashboard, so the label should say what it now is.
    _TileData(title: 'Dashboard', icon: Icons.satellite_alt, color: Colors.cyanAccent, route: '/dashboard'),
    _TileData(title: 'Sentinel Copilot', icon: Icons.auto_awesome, color: Colors.deepPurpleAccent, route: '/copilot'),
    _TileData(title: 'Offline Sync Queue', icon: Icons.sync, color: Colors.blueGrey, route: '/offline-queue'),
  ]),
];

class BusinessOsLaunchpad extends ConsumerWidget {
  const BusinessOsLaunchpad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userProfileProvider).valueOrNull?.role;
    final isContractor = role == 'contractor';

    final visibleSections = _sections
        .map((s) => _SectionData(
              s.title,
              isContractor ? s.tiles.where((t) => t.contractorVisible).toList() : s.tiles,
            ))
        .where((s) => s.tiles.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: const Text('Launchpad'), centerTitle: false),
          for (final section in visibleSections) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 24.0, top: 24.0, right: 24.0),
                child: Text(section.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                  for (final tile in section.tiles)
                    _LaunchpadCard(title: tile.title, icon: tile.icon, color: tile.color, route: tile.route),
                ]),
              ),
            ),
          ],
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
