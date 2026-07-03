import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

class EmployeeHRTab extends ConsumerWidget {
  final String employeeId;
  const EmployeeHRTab({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app we'd fetch HR data (Leave, Payroll, Disciplinary) from respective collections.
    // For now we mock the UI layout.

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leave Balances',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  UIUtils.showToast(context, 'Leave form opened');
                },
                icon: const Icon(Icons.beach_access, size: 18),
                label: const Text('Book Leave'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLeaveCard(
                  'Annual Leave',
                  '15 Days',
                  XMTheme.primary,
                  Icons.calendar_month,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLeaveCard(
                  'Sick Leave',
                  '8 Days',
                  XMTheme.info,
                  Icons.medical_services,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLeaveCard(
                  'Family Resp.',
                  '3 Days',
                  XMTheme.warning,
                  Icons.family_restroom,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Recent Payslips',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final date = DateTime.now().subtract(
                  Duration(days: index * 30),
                );
                return ListTile(
                  leading: const Icon(
                    Icons.request_quote,
                    color: XMTheme.primary,
                  ),
                  title: Text(
                    'Payslip - ${DateFormat('MMMM yyyy').format(date)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Processed successfully'),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      UIUtils.showToast(
                        context,
                        'Payslip downloaded successfully',
                        type: ToastType.success,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disciplinary Record',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  UIUtils.showToast(context, 'Disciplinary action form opened');
                },
                icon: const Icon(Icons.add),
                label: const Text('Log Action'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.gavel,
                    size: 48,
                    color: XMTheme.secondaryLight.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text('No disciplinary records found.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(
    String title,
    String balance,
    Color color,
    IconData icon,
  ) {
    return GCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: XMTheme.secondaryLight),
          ),
          const SizedBox(height: 4),
          Text(
            balance,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
