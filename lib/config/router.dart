import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_providers.dart';
import '../core/services/session_manager.dart';
import '../core/widgets/app_shell.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/lock_screen.dart';
import '../features/auth/screens/enterprise_sso_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/dashboard/screens/business_os_launchpad.dart';
import '../features/finance/screens/finance_hub_screen.dart';
import '../features/supply_chain/screens/supply_chain_hub_screen.dart';
import '../features/supply_chain/screens/mrp_dashboard_screen.dart';
import '../features/supply_chain/screens/wms_scanner_screen.dart';
import '../features/supply_chain/screens/production_order_screen.dart';
import '../features/projects/screens/project_operations_hub_screen.dart';
import '../features/projects/screens/project_dashboard_screen.dart';
import '../features/projects/screens/project_details_screen.dart';
import '../features/projects/screens/revenue_recognition_screen.dart';
import '../features/field_service/screens/field_service_hub_screen.dart';
import '../features/field_service/screens/route_optimization_screen.dart';
import '../features/crm/screens/crm_hub_screen.dart';
import '../features/customer_service/screens/customer_service_hub_screen.dart';

import '../features/people/screens/people_hub_screen.dart';
import '../features/people/screens/hr_hub_screen.dart';
import '../features/people/screens/okr_dashboard_screen.dart';
import '../features/safety/screens/safety_hub_screen.dart';
import '../features/compliance/screens/compliance_docs_screen.dart';
import '../features/risk/screens/risk_hub_screen.dart';
import '../features/operations/screens/schedule_board_screen.dart';
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
import '../features/equipment/screens/loto_management_screen.dart';
import '../features/equipment/screens/equipment_management_screen.dart';
import '../features/public/screens/public_careers_screen.dart';





/// GoRouter configuration with auth guards and shell routes
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final isLocked = ref.watch(isAppLockedProvider);

  return GoRouter(
    initialLocation: '/launchpad',
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Route not found: ${state.uri}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/launchpad'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      final locking = state.matchedLocation == '/lock';
      final isPublicRoute = state.matchedLocation.startsWith('/careers');
      final sso = state.matchedLocation == '/sso';

      if (!isAuthenticated && !loggingIn && !isPublicRoute && !sso) return '/login';
      if (isAuthenticated && (loggingIn || sso)) return '/launchpad';
      if (isAuthenticated && isLocked && !locking) return '/lock';
      if (isAuthenticated && !isLocked && locking) return '/launchpad';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/sso', builder: (context, state) => const EnterpriseSSOScreen()),
      GoRoute(path: '/lock', builder: (context, state) => const LockScreen()),
      GoRoute(
        path: '/careers/:tenantSlug',
        builder: (context, state) => PublicCareersScreen(
          tenantSlug: state.pathParameters['tenantSlug']!,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/launchpad',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: BusinessOsLaunchpad()),
          ),
          GoRoute(
            path: '/finance',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: FinanceHubScreen()),
          ),
          GoRoute(
            path: '/supply-chain',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: SupplyChainHubScreen()),
          ),
          GoRoute(
            path: '/projects-ops',
            pageBuilder:
                (c, s) =>
                    const NoTransitionPage(child: ProjectOperationsHubScreen()),
          ),
          GoRoute(
            path: '/field-service',
            pageBuilder:
                (c, s) =>
                    const NoTransitionPage(child: FieldServiceHubScreen()),
          ),
          GoRoute(
            path: '/crm',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: CrmHubScreen()),
          ),
          GoRoute(
            path: '/customer-service',
            pageBuilder:
                (c, s) =>
                    const NoTransitionPage(child: CustomerServiceHubScreen()),
          ),
          GoRoute(
            path: '/hr',
            pageBuilder: (c, s) => const NoTransitionPage(child: HrHubScreen()),
          ),
          GoRoute(
            path: '/dashboard',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/safety',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: SafetyHubScreen()),
          ),
          GoRoute(
            path: '/compliance',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: ComplianceDocsScreen()),
          ),
          GoRoute(
            path: '/mrp-dashboard',
            pageBuilder: (c, s) => const NoTransitionPage(child: MrpDashboardScreen()),
          ),
          GoRoute(
            path: '/equipment',
            pageBuilder: (c, s) => const NoTransitionPage(child: EquipmentManagementScreen()),
          ),
          GoRoute(
            path: '/wms-scanner',
            pageBuilder: (c, s) => const NoTransitionPage(child: WmsScannerScreen()),
          ),
          GoRoute(
            path: '/manufacturing',
            pageBuilder: (c, s) => const NoTransitionPage(child: ProductionOrderScreen()),
          ),
          GoRoute(
            path: '/risk',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: RiskHubScreen()),
          ),

          GoRoute(
            path: '/route-optimization',
            pageBuilder: (c, s) => const NoTransitionPage(child: RouteOptimizationScreen()),
          ),
          GoRoute(
            path: '/people',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: PeopleHubScreen()),
          ),
          GoRoute(
            path: '/revenue-recognition',
            pageBuilder: (c, s) => const NoTransitionPage(child: RevenueRecognitionScreen()),
          ),
          GoRoute(
            path: '/okr-dashboard',
            pageBuilder: (c, s) => const NoTransitionPage(child: OkrDashboardScreen()),
          ),
          GoRoute(
            path: '/operations',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: OperationsHubScreen()),
          ),
          GoRoute(
            path: '/schedule-board',
            pageBuilder: (c, s) => const NoTransitionPage(child: ScheduleBoardScreen()),
          ),
          GoRoute(
            path: '/actions',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: ActionTrackerScreen()),
          ),
          GoRoute(
            path: '/environment',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: EnvironmentalScreen()),
          ),
          GoRoute(
            path: '/emergency',
            pageBuilder:
                (c, s) =>
                    const NoTransitionPage(child: EmergencyResponseScreen()),
          ),
          GoRoute(
            path: '/ai',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: AIChatScreen()),
          ),
          GoRoute(
            path: '/health',
            pageBuilder:
                (c, s) =>
                    const NoTransitionPage(child: OccupationalHealthScreen()),
          ),
          GoRoute(
            path: '/workers-comp',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: WorkersCompScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: '/offline-queue',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: OfflineQueueScreen()),
          ),
          GoRoute(
            path: '/loto-management',
            pageBuilder: (c, s) => const NoTransitionPage(child: LotoManagementScreen()),
          ),
          GoRoute(
            path: '/equipment',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: EquipmentManagementScreen()),
          ),
          GoRoute(
            path: '/properties',
            pageBuilder:
                (c, s) => const NoTransitionPage(child: PropertyHubScreen()),
          ),
          GoRoute(
            path: '/property/:id',
            builder:
                (context, state) => PropertyDetailsScreen(
                  propertyId: state.pathParameters['id']!,
                ),
          ),
          GoRoute(
            path: '/projects',
            pageBuilder:
                (c, s) =>
                    const NoTransitionPage(child: ProjectDashboardScreen()),
          ),
          GoRoute(
            path: '/projects/:id',
            builder:
                (context, state) => ProjectDetailsScreen(
                  projectId: state.pathParameters['id']!,
                ),
          ),

        ],
      ),
    ],
  );
});
