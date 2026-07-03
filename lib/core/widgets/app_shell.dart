import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../feedback/feedback_overlay.dart';
import '../services/session_manager.dart';
import 'app_header_bar.dart';
import 'app_sidebar.dart';
import 'mobile_bottom_nav.dart';
import 'quick_actions_sheet.dart';

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
    final currentIndex = _calculateSelectedIndex(context);
    final isWideScreen = MediaQuery.sizeOf(context).width >= 800;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => ref.read(sessionManagerProvider).userInteracted(),
      onPointerMove: (_) => ref.read(sessionManagerProvider).userInteracted(),
      child: FeedbackOverlay(
        child: Scaffold(
          appBar: const AppHeaderBar(),
          body:
              isWideScreen
                  ? Row(
                    children: [
                      AppSidebar(
                        selectedIndex: currentIndex,
                        onDestinationSelected:
                            (index) => _onItemTapped(index, context),
                        onAddPressed: () => QuickActionsSheet.show(context),
                      ),
                      const VerticalDivider(thickness: 1, width: 1),
                      Expanded(child: widget.child),
                    ],
                  )
                  : widget.child,
          bottomNavigationBar:
              isWideScreen
                  ? null
                  : MobileBottomNav(
                    selectedIndex: currentIndex,
                    onDestinationSelected:
                        (index) => _onItemTapped(index, context),
                  ),
          floatingActionButton:
              isWideScreen
                  ? null
                  : FloatingActionButton(
                    elevation: 4,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      QuickActionsSheet.show(context);
                    },
                    child: const Icon(Icons.add_rounded),
                  ),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/launchpad') || location.startsWith('/dashboard')) {
      return 0;
    }
    if (location.startsWith('/finance')) return 1;
    if (location.startsWith('/supply-chain')) return 2;
    if (location.startsWith('/projects-ops')) return 3;
    if (location.startsWith('/field-service')) return 4;
    if (location.startsWith('/crm')) return 5;
    if (location.startsWith('/customer-service')) return 6;
    if (location.startsWith('/hr') || location.startsWith('/people')) return 7;
    return 0; // Default to Launchpad
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0:
        context.go('/launchpad');
        break;
      case 1:
        context.go('/finance');
        break;
      case 2:
        context.go('/supply-chain');
        break;
      case 3:
        context.go('/projects-ops');
        break;
      case 4:
        context.go('/field-service');
        break;
      case 5:
        context.go('/crm');
        break;
      case 6:
        context.go('/customer-service');
        break;
      case 7:
        context.go('/hr');
        break;
    }
  }
}
