import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'employee_profiles_screen.dart';
import '../widgets/people_hub/stream_metric_card.dart';
import '../widgets/people_hub/people_hub_modules_grid.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

/// People & Health Hub Dashboard — Material 3 Expressive
class PeopleHubScreen extends ConsumerWidget {
  const PeopleHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);

    final employeesStream =
        siteId == null
            ? Stream.value('0')
            : firestore
                .tenantCollection(
                  ref.watch(currentTenantIdProvider) ?? "",
                  'employees',
                )
                .where('siteId', isEqualTo: siteId)
                .snapshots()
                .map((s) => s.docs.length.toString());

    final trainingComplianceStream =
        siteId == null
            ? Stream.value('100%')
            : firestore
                .tenantCollection(
                  ref.watch(currentTenantIdProvider) ?? "",
                  'competency_passports',
                )
                .where('siteId', isEqualTo: siteId)
                .snapshots()
                .map((s) {
                  if (s.docs.isEmpty) return '100%';
                  final valid =
                      s.docs.where((d) => d.data()['status'] == 'Valid').length;
                  return '${((valid / s.docs.length) * 100).toStringAsFixed(0)}%';
                });

    final healthAssessmentsStream =
        siteId == null
            ? Stream.value('0 Due')
            : firestore
                .tenantCollection(
                  ref.watch(currentTenantIdProvider) ?? "",
                  'medical_records',
                )
                .where('siteId', isEqualTo: siteId)
                .snapshots()
                .map((s) {
                  final dueCount =
                      s.docs.where((d) {
                        final data = d.data();
                        final status = data['status'] ?? '';
                        final nextDueStr = data['nextDueDate'] ?? '';
                        if (status == 'Unfit') return true;
                        if (nextDueStr.isNotEmpty) {
                          try {
                            final nextDue = DateTime.parse(nextDueStr);
                            return nextDue.isBefore(DateTime.now());
                          } catch (_) {}
                        }
                        return false;
                      }).length;
                  return '$dueCount Due';
                });

    final workersCompStream =
        siteId == null
            ? Stream.value('0 Open')
            : firestore
                .tenantCollection(
                  ref.watch(currentTenantIdProvider) ?? "",
                  'coida_claims',
                )
                .where('siteId', isEqualTo: siteId)
                .snapshots()
                .map(
                  (s) =>
                      '${s.docs.where((d) => d.data()['status'] != 'Closed').length} Open',
                );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          UIUtils.showSideSheet(
            context: context,
            title: 'Employee Profiles',
            builder: (ctx) => const EmployeeProfilesScreen(),
          );
        },
        backgroundColor: XMTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Employee'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'People & Health Hub',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GSpacing.vSm,
                  Text(
                    'Manage workforce competency, training compliance, and occupational health.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // High-level Metrics Row
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StreamMetricCard(
                        title: 'Active Employees',
                        valueStream: employeesStream,
                        icon: Icons.people_rounded,
                        color: XMTheme.primary,
                        isWide: isWide,
                        initialValue: '0',
                      ),
                      if (isWide) GSpacing.hMd else GSpacing.vMd,
                      StreamMetricCard(
                        title: 'Training Compliance',
                        valueStream: trainingComplianceStream,
                        icon: Icons.school_rounded,
                        color: XMTheme.success,
                        isWide: isWide,
                        initialValue: '100%',
                      ),
                      if (isWide) GSpacing.hMd else GSpacing.vMd,
                      StreamMetricCard(
                        title: 'Health Assessments',
                        valueStream: healthAssessmentsStream,
                        icon: Icons.medical_services_rounded,
                        color: XMTheme.warning,
                        isWide: isWide,
                        initialValue: '0 Due',
                      ),
                      if (isWide) GSpacing.hMd else GSpacing.vMd,
                      StreamMetricCard(
                        title: 'Workers Comp',
                        valueStream: workersCompStream,
                        icon: Icons.healing_rounded,
                        color: XMTheme.error,
                        isWide: isWide,
                        initialValue: '0 Open',
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Main Interactive Modules Grid
          const PeopleHubModulesGrid(),

          // Bottom padding
          const SliverToBoxAdapter(child: GSpacing.vLg),
        ],
      ),
    );
  }
}
