import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../providers/hr_provider.dart';
import '../../../core/bpf/bpf_ribbon_widget.dart';
import '../../../core/bpf/hire_to_retire_bpf.dart';

class EmployeeProfileDetailScreen extends ConsumerWidget {
  final String employeeId;

  const EmployeeProfileDetailScreen({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(employeeDetailProvider(employeeId));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Employee Profile'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Leave Requests'),
              Tab(text: 'Performance'),
              Tab(text: 'Benefits'),
            ],
          ),
        ),
        body: employeeAsync.when(
          data: (employee) {
            if (employee == null) {
              return const Center(child: Text('Employee not found'));
            }
            return Column(
              children: [
                _buildHeader(context, employee),
                BpfRibbonWidget(
                  bpfTypeId: 'hire_to_retire',
                  recordType: 'employee',
                  recordId: employeeId,
                  definition: hireToRetireDefinition,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OverviewTab(employee: employee),
                      _LeaveRequestsTab(employeeId: employeeId),
                      _PerformanceTab(employeeId: employeeId),
                      _BenefitsTab(employeeId: employeeId),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> emp) {
    final name = emp['fullName'] as String? ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final title = emp['jobTitle'] as String? ?? '';
    final dept = emp['department'] as String? ?? '';
    final status = emp['status'] as String? ?? 'Active';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: XMTheme.primary.withValues(alpha: 0.1),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: XMTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '$title • $dept',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                _StatusBadge(status: status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'active':
        return XMTheme.success;
      case 'on leave':
        return XMTheme.info;
      case 'terminated':
        return XMTheme.error;
      default:
        return XMTheme.statusDraft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _color,
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> employee;
  const _OverviewTab({required this.employee});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal & Contact Info',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.badge,
                    label: 'Employee Code',
                    value: employee['employeeCode'] ?? 'N/A',
                  ),
                  const Divider(),
                  _DetailRow(
                    icon: Icons.credit_card,
                    label: 'ID Number',
                    value: employee['idNumber'] ?? 'N/A',
                  ),
                  const Divider(),
                  _DetailRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: employee['email'] ?? 'N/A',
                  ),
                  const Divider(),
                  _DetailRow(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: employee['phone'] ?? 'N/A',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveRequestsTab extends ConsumerWidget {
  final String employeeId;
  const _LeaveRequestsTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaveAsync = ref.watch(employeeLeaveRequestsProvider(employeeId));
    return leaveAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(child: Text('No leave requests found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (ctx, i) {
            final req = requests[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text('${req['leaveType'] ?? 'Leave'}'),
                subtitle: Text(
                  '${_formatDate(req['startDate'])} - ${_formatDate(req['endDate'])}',
                ),
                trailing: _StatusBadge(status: req['status'] ?? 'Pending'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return dateStr.toString();
    }
  }
}

class _PerformanceTab extends ConsumerWidget {
  final String employeeId;
  const _PerformanceTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfAsync = ref.watch(employeePerformanceReviewsProvider(employeeId));
    return perfAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(child: Text('No performance reviews found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (ctx, i) {
            final rev = reviews[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(rev['reviewTitle'] ?? 'Review'),
                subtitle: Text('Score: ${rev['score'] ?? 'N/A'}'),
                trailing: Text(
                  rev['reviewDate']?.toString().split('T').first ?? '',
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _BenefitsTab extends ConsumerWidget {
  final String employeeId;
  const _BenefitsTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benAsync = ref.watch(employeeBenefitsProvider(employeeId));
    return benAsync.when(
      data: (benefits) {
        if (benefits.isEmpty) {
          return const Center(child: Text('No benefits enrolled.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: benefits.length,
          itemBuilder: (ctx, i) {
            final ben = benefits[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(ben['benefitName'] ?? 'Benefit'),
                subtitle: Text(
                  'Coverage: ${ben['coverageLevel'] ?? 'Standard'}',
                ),
                trailing: _StatusBadge(status: ben['status'] ?? 'Active'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
