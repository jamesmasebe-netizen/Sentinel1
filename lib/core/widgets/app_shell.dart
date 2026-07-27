import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../feedback/feedback_overlay.dart';
import '../services/session_manager.dart';
import 'app_header_bar.dart';
import 'app_sidebar.dart';
import 'quick_actions_sheet.dart';

/// AppShell: Material 3 Expressive Workspace Shell
/// Features a Google-workspace style top app bar with global search,
/// and a custom scrollable sidebar for all modules.
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
    final location = GoRouterState.of(context).matchedLocation;
    final isWideScreen = MediaQuery.sizeOf(context).width >= 800;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => ref.read(sessionManagerProvider).userInteracted(),
      onPointerMove: (_) => ref.read(sessionManagerProvider).userInteracted(),
      child: FeedbackOverlay(
        child: Scaffold(
          appBar: const AppHeaderBar(),
          drawer: isWideScreen
              ? null
              : Drawer(
                  child: AppSidebar(
                    currentRoute: location,
                    onDestinationSelected: (route) {
                      context.go(route);
                      Navigator.pop(context); // Close drawer
                    },
                    onAddPressed: () {
                      Navigator.pop(context); // Close drawer
                      QuickActionsSheet.show(context);
                    },
                  ),
                ),
          body:
              isWideScreen
                  ? Row(
                    children: [
                      AppSidebar(
                        currentRoute: location,
                        onDestinationSelected: (route) => context.go(route),
                        onAddPressed: () => QuickActionsSheet.show(context),
                      ),
                      const VerticalDivider(thickness: 1, width: 1),
                      Expanded(child: widget.child),
                    ],
                  )
                  : widget.child,
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
}
