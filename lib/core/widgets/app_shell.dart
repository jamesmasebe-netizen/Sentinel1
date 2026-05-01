import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../services/offline_sync_service.dart';
import '../services/session_manager.dart';
import '../../config/theme.dart';

/// Main app shell with bottom navigation, drawer, and sync status indicator.
/// This replaces the React Layout component with its sidebar navigation.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionManagerProvider).startSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final profile = ref.watch(userProfileProvider);
    final currentIndex = _calculateSelectedIndex(context);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => ref.read(sessionManagerProvider).userInteracted(),
      onPointerMove: (_) => ref.read(sessionManagerProvider).userInteracted(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('XM System'),
        actions: [
          // ─── Sync Status Indicator ───
          syncStatus.when(
            data: (status) => _SyncIndicator(
              status: status,
              pendingCount: pendingCount.valueOrNull ?? 0,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ─── Notifications ───
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),

          // ─── Profile Avatar ───
          profile.when(
            data: (p) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _showProfileMenu(context, ref),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: p?.photoURL != null
                      ? NetworkImage(p!.photoURL!)
                      : null,
                  child: p?.photoURL == null
                      ? Text(
                          (p?.displayName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 14),
                        )
                      : null,
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),

      // ─── Drawer (Full Navigation — matches React sidebar) ───
      drawer: _buildDrawer(context, ref),

      // ─── Body ───
      body: widget.child,

      // ─── Bottom Navigation Bar ───
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Safety',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: 'Risk',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'People',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI',
          ),
        ],
      ),

      // ─── FAB for Quick Actions ───
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showQuickActions(context);
        },
        child: const Icon(Icons.add),
      ),
    ));
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final isExec = ref.watch(isExecutiveProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            decoration: const BoxDecoration(
              color: XMTheme.sidebarBg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'XM System',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SHEQ Enterprise Platform',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                profile.when(
                  data: (p) => Text(
                    p?.displayName ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // ─── Safety Operations ───
          _DrawerSection(
            title: 'Safety Operations',
            icon: Icons.shield,
            children: [
              _DrawerItem(title: 'Incidents & CAPA', icon: Icons.report_problem, route: '/safety'),
              _DrawerItem(title: 'Permit to Work', icon: Icons.assignment, route: '/safety'),
              _DrawerItem(title: 'Behavioral Safety', icon: Icons.visibility, route: '/safety'),
              _DrawerItem(title: 'Hazard Register', icon: Icons.warning, route: '/safety'),
              _DrawerItem(title: 'PPE Compliance', icon: Icons.health_and_safety, route: '/safety'),
              _DrawerItem(title: 'Safety Analytics', icon: Icons.analytics, route: '/safety'),
            ],
          ),

          // ─── Risk Intelligence ───
          _DrawerSection(
            title: 'Risk Intelligence',
            icon: Icons.warning_amber,
            children: [
              _DrawerItem(title: 'Risk Command Center', icon: Icons.dashboard, route: '/risk'),
              _DrawerItem(title: 'HIRA', icon: Icons.assessment, route: '/risk'),
              _DrawerItem(title: 'Dynamic Risk Assessment', icon: Icons.bolt, route: '/risk'),
              _DrawerItem(title: 'Bow-Tie Analysis', icon: Icons.account_tree, route: '/risk'),
              _DrawerItem(title: 'Strategic Risk Register', icon: Icons.list_alt, route: '/risk'),
            ],
          ),

          // ─── Occupational Health ───
          _DrawerSection(
            title: 'Occupational Health',
            icon: Icons.medical_services,
            children: [
              _DrawerItem(title: 'Health Surveillance', icon: Icons.monitor_heart, route: '/health'),
              _DrawerItem(title: 'Medical Response', icon: Icons.local_hospital, route: '/health'),
              _DrawerItem(title: 'Wellbeing Pulse', icon: Icons.favorite, route: '/health'),
              _DrawerItem(title: 'First Aid Log', icon: Icons.healing, route: '/health'),
            ],
          ),

          // ─── Environment & ESG ───
          _DrawerSection(
            title: 'Environment & ESG',
            icon: Icons.eco,
            children: [
              _DrawerItem(title: 'Environmental Management', icon: Icons.nature, route: '/environment'),
              _DrawerItem(title: 'ESG Reporting', icon: Icons.bar_chart, route: '/environment'),
              _DrawerItem(title: 'Waste Management', icon: Icons.delete, route: '/environment'),
              _DrawerItem(title: 'Spill Response', icon: Icons.water_drop, route: '/environment'),
            ],
          ),

          // ─── People Management ───
          _DrawerSection(
            title: 'People & Training',
            icon: Icons.people,
            children: [
              _DrawerItem(title: 'Employee Profiles', icon: Icons.person, route: '/people'),
              _DrawerItem(title: 'Training Scheduler', icon: Icons.school, route: '/people'),
              _DrawerItem(title: 'Skills Matrix', icon: Icons.grid_view, route: '/people'),
              _DrawerItem(title: 'Competency Passport', icon: Icons.card_membership, route: '/people'),
            ],
          ),

          // ─── Workers' Compensation ───
          _DrawerSection(
            title: 'Workers\' Compensation',
            icon: Icons.account_balance,
            children: [
              _DrawerItem(title: 'COIDA Claims', icon: Icons.description, route: '/workers-comp'),
              _DrawerItem(title: 'Return to Work', icon: Icons.work, route: '/workers-comp'),
              _DrawerItem(title: 'COIDA Compliance', icon: Icons.checklist, route: '/workers-comp'),
            ],
          ),

          // ─── Emergency Response ───
          _DrawerSection(
            title: 'Emergency Response',
            icon: Icons.emergency,
            children: [
              _DrawerItem(title: 'Emergency Broadcast', icon: Icons.campaign, route: '/emergency'),
              _DrawerItem(title: 'Muster Roll', icon: Icons.checklist, route: '/emergency'),
              _DrawerItem(title: 'Emergency Contacts', icon: Icons.contact_phone, route: '/emergency'),
            ],
          ),

          // ─── Executive (conditional) ───
          if (isExec) ...[
            _DrawerSection(
              title: 'Enterprise',
              icon: Icons.business,
              children: [
                _DrawerItem(title: 'Portfolio Dashboard', icon: Icons.dashboard_customize, route: '/dashboard'),
                _DrawerItem(title: 'Executive Dashboard', icon: Icons.insights, route: '/dashboard'),
                _DrawerItem(title: 'Enterprise Risk & ESG', icon: Icons.public, route: '/dashboard'),
              ],
            ),
          ],

          const Divider(),

          // ─── AI Tools ───
          ListTile(
            leading: const Icon(Icons.smart_toy, color: XMTheme.secondary),
            title: const Text('SHEQ AI Assistant'),
            onTap: () {
              Navigator.pop(context);
              context.go('/ai');
            },
          ),

          // ─── Offline Queue ───
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined, color: XMTheme.info),
            title: const Text('Offline Queue'),
            onTap: () {
              Navigator.pop(context);
              context.go('/offline-queue');
            },
          ),

          // ─── Settings ───
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.go('/settings');
            },
          ),

          // ─── Sign Out ───
          ListTile(
            leading: const Icon(Icons.logout, color: XMTheme.error),
            title: const Text('Sign Out'),
            onTap: () async {
              Navigator.pop(context);
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
            },
          ),
        ],
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(XMTheme.radiusLg)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(XMTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: XMTheme.spacingMd),
            _QuickActionTile(
              icon: Icons.report_problem,
              color: XMTheme.error,
              title: 'Report Incident',
              subtitle: 'Log a safety incident or near-miss',
              onTap: () {
                Navigator.pop(context);
                context.go('/safety');
              },
            ),
            _QuickActionTile(
              icon: Icons.assignment,
              color: XMTheme.warning,
              title: 'New Permit',
              subtitle: 'Create a permit to work request',
              onTap: () {
                Navigator.pop(context);
                context.go('/safety');
              },
            ),
            _QuickActionTile(
              icon: Icons.warning,
              color: XMTheme.info,
              title: 'Log Hazard',
              subtitle: 'Report a workplace hazard',
              onTap: () {
                Navigator.pop(context);
                context.go('/safety');
              },
            ),
            _QuickActionTile(
              icon: Icons.visibility,
              color: XMTheme.success,
              title: 'Safety Observation',
              subtitle: 'Record a behavioral safety observation',
              onTap: () {
                Navigator.pop(context);
                context.go('/safety');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    // TODO: Implement profile menu
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/safety')) return 1;
    if (location.startsWith('/risk')) return 2;
    if (location.startsWith('/people')) return 3;
    if (location.startsWith('/ai')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0: context.go('/dashboard');
      case 1: context.go('/safety');
      case 2: context.go('/risk');
      case 3: context.go('/people');
      case 4: context.go('/ai');
    }
  }
}

// ─── Helper Widgets ───

class _SyncIndicator extends StatelessWidget {
  final SyncStatus status;
  final int pendingCount;

  const _SyncIndicator({required this.status, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String tooltip;

    switch (status) {
      case SyncStatus.synced:
        icon = Icons.cloud_done;
        color = XMTheme.success;
        tooltip = 'All synced';
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = XMTheme.info;
        tooltip = 'Syncing...';
      case SyncStatus.pending:
        icon = Icons.cloud_upload;
        color = XMTheme.warning;
        tooltip = '$pendingCount pending';
      case SyncStatus.error:
        icon = Icons.cloud_off;
        color = XMTheme.error;
        tooltip = '$pendingCount failed';
    }

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            if (pendingCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$pendingCount',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_DrawerItem> children;

  const _DrawerSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: children,
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final String route;

  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}
