import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../services/session_manager.dart';
import '../../config/theme.dart';
import '../utils/ui_utils.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import 'app_header_widgets.dart';

class AppHeaderBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeaderBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final profile = ref.watch(userProfileProvider);

    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: XMTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.gpp_good_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Sentinel1',
            style: TextStyle(fontSize: 20, letterSpacing: -0.5),
          ),
        ],
      ),
      actions: [
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
                prefixIcon: const Icon(
                  Icons.search,
                  color: XMTheme.secondaryLight,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                fillColor: Colors.transparent,
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: GlobalSearchDelegate(ref.read(currentTenantIdProvider) ?? ""));
            },
          ),
        syncStatus.when(
          data: (status) => SyncIndicator(status: status, pendingCount: pendingCount),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        IconButton(
          icon: const Icon(Icons.smart_toy_outlined, color: XMTheme.primary),
          tooltip: 'SHEQ AI Assistant',
          onPressed: () => context.go('/ai'),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () {
            UIUtils.showSideSheet(
              context: context,
              title: 'Notification Center',
              builder: (ctx) => const NotificationsScreen(),
            );
          },
        ),
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
                        style: const TextStyle(
                          fontSize: 14,
                          color: XMTheme.primaryDark,
                        ),
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

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                UIUtils.showToast(context, 'Edit profile opened');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                UIUtils.showToast(context, 'Settings opened');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                ref.read(sessionManagerProvider).endSession();
              },
            ),
          ],
        ),
      ),
    );
  }
}

