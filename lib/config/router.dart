import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_providers.dart';
import '../core/services/session_manager.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/lock_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/safety/screens/safety_hub_screen.dart';
import '../features/risk/screens/risk_hub_screen.dart';
import '../features/people/screens/people_hub_screen.dart';
import '../features/operations/screens/action_tracker_screen.dart';
import '../features/operations/screens/operations_hub_screen.dart';
import '../features/environment/screens/environmental_screen.dart';
import '../features/emergency/screens/emergency_response_screen.dart';
import '../features/ai_tools/screens/ai_chat_screen.dart';
import '../features/health/screens/occupational_health_screen.dart';
import '../features/workers_comp/screens/workers_comp_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/offline_queue_screen.dart';
import '../features/property/screens/property_hub_screen.dart';
import '../features/property/screens/property_details_screen.dart';
import '../core/widgets/app_shell.dart';

/// GoRouter configuration with auth guards and shell routes
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final isLocked = ref.watch(isAppLockedProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      final locking = state.matchedLocation == '/lock';
      
      if (!isAuthenticated && !loggingIn) return '/login';
      if (isAuthenticated && loggingIn) return '/dashboard';
      if (isAuthenticated && isLocked && !locking) return '/lock';
      if (isAuthenticated && !isLocked && locking) return '/dashboard';
      
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/lock', builder: (context, state) => const LockScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', pageBuilder: (c, s) => const NoTransitionPage(child: DashboardScreen())),
          GoRoute(path: '/safety', pageBuilder: (c, s) => const NoTransitionPage(child: SafetyHubScreen())),
          GoRoute(path: '/risk', pageBuilder: (c, s) => const NoTransitionPage(child: RiskHubScreen())),
          GoRoute(path: '/people', pageBuilder: (c, s) => const NoTransitionPage(child: PeopleHubScreen())),
          GoRoute(path: '/operations', pageBuilder: (c, s) => const NoTransitionPage(child: OperationsHubScreen())),
          GoRoute(path: '/actions', pageBuilder: (c, s) => const NoTransitionPage(child: ActionTrackerScreen())),
          GoRoute(path: '/environment', pageBuilder: (c, s) => const NoTransitionPage(child: EnvironmentalScreen())),
          GoRoute(path: '/emergency', pageBuilder: (c, s) => const NoTransitionPage(child: EmergencyResponseScreen())),
          GoRoute(path: '/ai', pageBuilder: (c, s) => const NoTransitionPage(child: AIChatScreen())),
          GoRoute(path: '/health', pageBuilder: (c, s) => const NoTransitionPage(child: OccupationalHealthScreen())),
          GoRoute(path: '/workers-comp', pageBuilder: (c, s) => const NoTransitionPage(child: WorkersCompScreen())),
          GoRoute(path: '/settings', pageBuilder: (c, s) => const NoTransitionPage(child: SettingsScreen())),
          GoRoute(path: '/offline-queue', pageBuilder: (c, s) => const NoTransitionPage(child: OfflineQueueScreen())),
          GoRoute(path: '/properties', pageBuilder: (c, s) => const NoTransitionPage(child: PropertyHubScreen())),
          GoRoute(path: '/property/:id', builder: (context, state) => PropertyDetailsScreen(propertyId: state.pathParameters['id']!)),
        ],
      ),
    ],
  );
});
