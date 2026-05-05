import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../services/offline_sync_service.dart';
import '../services/session_manager.dart';
import '../../config/theme.dart';
import '../utils/ui_utils.dart';

/// AppShell: Material 3 Expressive Workspace Shell
/// Features a Google-workspace style top app bar with global search,
/// and a simplified 4-hub navigation rail/bar.
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
    final isWideScreen = MediaQuery.sizeOf(context).width >= 800;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => ref.read(sessionManagerProvider).userInteracted(),
      onPointerMove: (_) => ref.read(sessionManagerProvider).userInteracted(),
      child: Scaffold(
        appBar: _buildWorkspaceAppBar(context, profile, syncStatus, pendingCount.valueOrNull ?? 0),
        body: isWideScreen
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: currentIndex,
                    onDestinationSelected: (index) => _onItemTapped(index, context),
                    labelType: NavigationRailLabelType.all,
                    groupAlignment: -0.85, // Align items closer to the top
                    leading: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                      child: FloatingActionButton(
                        elevation: 0,
                        backgroundColor: XMTheme.primaryLight.withValues(alpha: 0.2),
                        foregroundColor: XMTheme.primaryDark,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showQuickActions(context);
                        },
                        child: const Icon(Icons.add_rounded, size: 28),
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.shield_outlined),
                        selectedIcon: Icon(Icons.shield_rounded),
                        label: Text('Safety & Risk'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.people_outline),
                        selectedIcon: Icon(Icons.people_rounded),
                        label: Text('People'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.domain_outlined),
                        selectedIcon: Icon(Icons.domain_rounded),
                        label: Text('Operations'),
                      ),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: widget.child),
                ],
              )
            : widget.child,
        bottomNavigationBar: isWideScreen
            ? null
            : NavigationBar(
                selectedIndex: currentIndex,
                onDestinationSelected: (index) => _onItemTapped(index, context),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.shield_outlined),
                    selectedIcon: Icon(Icons.shield_rounded),
                    label: 'Safety & Risk',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people_rounded),
                    label: 'People',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.domain_outlined),
                    selectedIcon: Icon(Icons.domain_rounded),
                    label: 'Operations',
                  ),
                ],
              ),
        floatingActionButton: isWideScreen
            ? null
            : FloatingActionButton(
                elevation: 4,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showQuickActions(context);
                },
                child: const Icon(Icons.add_rounded),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildWorkspaceAppBar(
      BuildContext context, AsyncValue profile, AsyncValue<SyncStatus> syncStatus, int pendingCount) {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          // Google-style app branding
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: XMTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.gpp_good_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Sentinel1',
            style: TextStyle(fontSize: 20, letterSpacing: -0.5),
          ),
        ],
      ),
      actions: [
        // Center Search Bar for Desktop
        if (MediaQuery.sizeOf(context).width >= 800)
          Container(
            width: 400,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            decoration: BoxDecoration(
              color: XMTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(XMTheme.radiusXl),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Sentinel1...',
                prefixIcon: const Icon(Icons.search, color: XMTheme.secondaryLight),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                fillColor: Colors.transparent,
              ),
            ),
          )
        else
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),

        // Sync Status
        syncStatus.when(
          data: (status) => _SyncIndicator(status: status, pendingCount: pendingCount),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // AI Assistant
        IconButton(
          icon: const Icon(Icons.smart_toy_outlined, color: XMTheme.primary),
          tooltip: 'SHEQ AI Assistant',
          onPressed: () => context.go('/ai'),
        ),
        
        // Notifications
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () {},
        ),

        // Profile Avatar
        profile.when(
          data: (p) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => _showProfileMenu(context, ref),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: XMTheme.primaryLight.withValues(alpha: 0.3),
                backgroundImage: p?.photoURL != null ? NetworkImage(p!.photoURL!) : null,
                child: p?.photoURL == null
                    ? Text(
                        (p?.displayName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 14, color: XMTheme.primaryDark),
                      )
                    : null,
              ),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _showQuickActions(BuildContext context) {
    UIUtils.showAppBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(XMTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create New', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: XMTheme.spacingMd),
            _QuickActionTile(
              icon: Icons.report_problem,
              color: XMTheme.error,
              title: 'Incident Report',
              subtitle: 'Log a safety incident or near-miss',
              onTap: () {
                Navigator.pop(context);
                context.go('/safety');
              },
            ),
            _QuickActionTile(
              icon: Icons.assignment,
              color: XMTheme.warning,
              title: 'Permit to Work',
              subtitle: 'Create a new PTW request',
              onTap: () {
                Navigator.pop(context);
                context.go('/safety');
              },
            ),
            _QuickActionTile(
              icon: Icons.warning,
              color: XMTheme.info,
              title: 'Hazard Observation',
              subtitle: 'Report a workplace hazard',
              onTap: () {
                Navigator.pop(context);
                context.go('/safety');
              },
            ),
            _QuickActionTile(
              icon: Icons.monitor_heart,
              color: XMTheme.success,
              title: 'Health Check',
              subtitle: 'Log a medical or occupational health entry',
              onTap: () {
                Navigator.pop(context);
                context.go('/people');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    // TODO: Material 3 standard profile popover
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/safety') || location.startsWith('/risk') || location.startsWith('/emergency')) return 1;
    if (location.startsWith('/people') || location.startsWith('/health') || location.startsWith('/workers-comp')) return 2;
    if (location.startsWith('/operations') || location.startsWith('/properties') || location.startsWith('/environment') || location.startsWith('/actions') || location.startsWith('/contractors')) return 3;
    return 0; // Default to Home
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/safety');
        break;
      case 2:
        context.go('/people');
        break;
      case 3:
        context.go('/operations');
        break;
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
        tooltip = 'All changes saved to cloud';
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = XMTheme.info;
        tooltip = 'Saving...';
        break;
      case SyncStatus.pending:
        icon = Icons.cloud_upload;
        color = XMTheme.warning;
        tooltip = '$pendingCount items waiting to sync';
        break;
      case SyncStatus.error:
        icon = Icons.cloud_off;
        color = XMTheme.error;
        tooltip = 'Sync failed. Working offline.';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: XMTheme.secondaryLight)),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}
