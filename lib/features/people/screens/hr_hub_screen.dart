import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

import 'employee_profiles_screen.dart';
import 'leave_management_screen.dart';
import 'competency_passport_screen.dart';

class HrHubScreen extends ConsumerStatefulWidget {
  const HrHubScreen({super.key});

  @override
  ConsumerState<HrHubScreen> createState() => _HrHubScreenState();
}

class _HrHubScreenState extends ConsumerState<HrHubScreen> {
  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Human Capital Management')),
      body:
          siteId == null
              ? const Center(child: Text('No site selected.'))
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GHeader(
                      title: 'HCM Dashboard',
                      subtitle: 'Overview of HR metrics and modules',
                    ),
                    GSpacing.vMd,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Headcount',
                              stream:
                                  firestore
                                      .tenantCollection(siteId, 'employees')
                                      .where('status', isEqualTo: 'Active')
                                      .where('siteId', isEqualTo: siteId)
                                      .snapshots(),
                              icon: Icons.people,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Pending Leave',
                              stream:
                                  firestore
                                      .tenantCollection(
                                        siteId,
                                        'leave_requests',
                                      )
                                      .where('status', isEqualTo: 'Pending')
                                      .where('siteId', isEqualTo: siteId)
                                      .snapshots(),
                              icon: Icons.event_busy,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Expiring Certs',
                              stream:
                                  firestore
                                      .tenantCollection(
                                        siteId,
                                        'competency_passports',
                                      )
                                      .where('status', isEqualTo: 'Valid')
                                      .where('siteId', isEqualTo: siteId)
                                      .snapshots(),
                              icon: Icons.warning_amber,
                              color: Colors.red,
                              filterExpiring: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GSpacing.vLg,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Modules',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GSpacing.vMd,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildNavCard(
                            context,
                            title: 'Employee Profiles',
                            icon: Icons.badge,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const EmployeeProfilesScreen(),
                                  ),
                                ),
                          ),
                          _buildNavCard(
                            context,
                            title: 'Leave Management',
                            icon: Icons.event_available,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const LeaveManagementScreen(),
                                  ),
                                ),
                          ),
                          _buildNavCard(
                            context,
                            title: 'Competency Passport',
                            icon: Icons.card_membership,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const CompetencyPassportScreen(),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    GSpacing.vLg,
                  ],
                ),
              ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required Stream<QuerySnapshot> stream,
    required IconData icon,
    required Color color,
    bool filterExpiring = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Text('--');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                int count = 0;
                if (snapshot.hasData) {
                  if (filterExpiring) {
                    final now = DateTime.now();
                    final thirtyDaysFromNow = now.add(const Duration(days: 30));
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['expiryDate'] != null) {
                        try {
                          final expiry = DateTime.parse(data['expiryDate']);
                          if (expiry.isBefore(thirtyDaysFromNow)) {
                            count++;
                          }
                        } catch (_) {}
                      }
                    }
                  } else {
                    count = snapshot.data!.docs.length;
                  }
                }

                return Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
