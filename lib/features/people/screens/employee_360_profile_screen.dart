import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import 'ohs_appointments_tab.dart';
import 'training_lms_tab.dart';
import 'employee_hr_tab.dart';
import 'employee_activity_tab.dart';
import '../widgets/detail_row.dart';
import '../../safety/screens/employee_qr_passport_screen.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../../../core/bpf/bpf_ribbon_widget.dart';
import '../../../core/bpf/hire_to_retire_bpf.dart';
import '../../../core/bpf/bpf_service.dart';
import '../../../core/bpf/bpf_orchestrator.dart';

class Employee360ProfileScreen extends ConsumerStatefulWidget {
  final String employeeId;
  const Employee360ProfileScreen({super.key, required this.employeeId});

  @override
  ConsumerState<Employee360ProfileScreen> createState() =>
      _Employee360ProfileScreenState();
}

class _Employee360ProfileScreenState
    extends ConsumerState<Employee360ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _terminateEmployee(String employeeName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Terminate Employee?'),
            content: Text(
              'Are you sure you want to terminate $employeeName? This will revoke access and fire a global event.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Terminate'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await ref
          .read(firestoreProvider)
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'employees',
          )
          .doc(widget.employeeId)
          .update({
            'status': 'Terminated',
            'terminatedAt': DateTime.now().toIso8601String(),
          });
      ref
          .read(appEventBusProvider)
          .fire(
            EmployeeTerminatedEvent(
              employeeId: widget.employeeId,
              employeeName: employeeName,
            ),
          );
      if (mounted) {
        UIUtils.showToast(
          context,
          'Employee terminated',
          type: ToastType.success,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firestoreProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('360° Profile'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.person)),
            Tab(text: 'OHS Appointments', icon: Icon(Icons.gavel)),
            Tab(text: 'Training & LMS', icon: Icon(Icons.school)),
            Tab(text: 'Safety & Ops Activity', icon: Icon(Icons.assignment)),
            Tab(text: 'HR & Payroll', icon: Icon(Icons.cases_rounded)),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            firestore
                .tenantCollection(
                  ref.watch(currentTenantIdProvider) ?? "",
                  'employees',
                )
                .doc(widget.employeeId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Employee not found'));
          }

          final emp = snapshot.data!.data() as Map<String, dynamic>;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(emp),
              OHSAppointmentsTab(employeeId: widget.employeeId),
              TrainingLMSTab(employeeId: widget.employeeId),
              EmployeeActivityTab(employeeId: widget.employeeId),
              EmployeeHRTab(employeeId: widget.employeeId),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> emp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: XMTheme.primary.withValues(alpha: 0.1),
                child: Text(
                  (emp['fullName'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: XMTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp['fullName'] ?? '',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${emp['jobTitle'] ?? ''} • ${emp['department'] ?? ''}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: XMTheme.secondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GStatusTag(
                          label: emp['employmentStatus'] ?? 'Active',
                          color:
                              emp['employmentStatus'] == 'Active'
                                  ? XMTheme.success
                                  : XMTheme.error,
                        ),
                        if (emp['employmentStatus'] != 'Terminated') ...[
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed:
                                () => _terminateEmployee(
                                  emp['fullName'] ?? 'Employee',
                                ),
                            icon: const Icon(
                              Icons.person_off,
                              size: 16,
                              color: XMTheme.error,
                            ),
                            label: const Text(
                              'Terminate',
                              style: TextStyle(color: XMTheme.error),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: XMTheme.error),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              UIUtils.showSideSheet(
                                context: context,
                                title: 'Employee Passport',
                                builder: (_) => EmployeeQrPassportScreen(employeeData: emp),
                              );
                            },
                            icon: const Icon(
                              Icons.qr_code,
                              size: 16,
                              color: XMTheme.primary,
                            ),
                            label: const Text(
                              'Generate Passport',
                              style: TextStyle(color: XMTheme.primary),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: XMTheme.primary),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                            ),
                          ),
                        ],
                        if (emp['employmentStatus'] != 'Terminated' && emp['employmentStatus'] != 'Active') ...[
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final bpfService = ref.read(bpfServiceProvider);
                                final bpfInstances = await bpfService
                                    .streamBpfInstancesByRecord('employee', widget.employeeId)
                                    .first;
                                
                                String? bpfId = bpfInstances.isNotEmpty ? bpfInstances.first.id : null;
                                bpfId ??= await bpfService.startBpf(
                                    'hire_to_retire', 'onboarding', 'employee', widget.employeeId);

                                final orchestrator = ref.read(bpfOrchestratorProvider);
                                await orchestrator.completeOnboarding(widget.employeeId, bpfId);

                                if (mounted) {
                                  UIUtils.showToast(
                                    context,
                                    'Onboarding completed successfully',
                                    type: ToastType.success,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  UIUtils.showToast(
                                    context,
                                    'Failed to complete onboarding: $e',
                                    type: ToastType.error,
                                  );
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: XMTheme.success,
                            ),
                            label: const Text(
                              'Complete Onboarding',
                              style: TextStyle(color: XMTheme.success),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: XMTheme.success),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          BpfRibbonWidget(
            bpfTypeId: 'hire_to_retire',
            recordType: 'employee',
            recordId: widget.employeeId,
            definition: hireToRetireDefinition,
          ),
          const SizedBox(height: 32),
          Text(
            'Contact & Identification',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                DetailRow(
                  icon: Icons.badge,
                  label: 'Employee Code',
                  value: emp['employeeCode'] ?? '',
                ),
                const Divider(height: 1),
                DetailRow(
                  icon: Icons.credit_card,
                  label: 'ID Number',
                  value: emp['idNumber'] ?? '',
                ),
                const Divider(height: 1),
                DetailRow(
                  icon: Icons.email,
                  label: 'Email Address',
                  value: emp['email'] ?? '',
                ),
                const Divider(height: 1),
                DetailRow(
                  icon: Icons.phone,
                  label: 'Phone Number',
                  value: emp['phone'] ?? '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
