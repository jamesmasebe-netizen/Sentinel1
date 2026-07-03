import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import 'leave_management_screen.dart';
import '../../training/screens/training_screen.dart';
import '../../operations/screens/action_tracker_screen.dart';

class EmployeeHubScreen extends ConsumerWidget {
  const EmployeeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(XMTheme.spacingXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${profile?.displayName ?? 'Employee'}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Text('Your personal portal for HR, Training, and Tasks.', style: TextStyle(color: Colors.grey)),
                  GSpacing.vXl,
                  _buildQuickStats(context),
                  GSpacing.vXl,
                  Text('My Portal', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  GSpacing.vMd,
                  _buildModuleGrid(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GCard(
            child: Column(
              children: [
                const Text('Leave Balance', style: TextStyle(color: Colors.grey)),
                GSpacing.vSm,
                Text('14 Days', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: XMTheme.primary)),
              ],
            ),
          ),
        ),
        GSpacing.hMd,
        Expanded(
          child: GCard(
            child: Column(
              children: [
                const Text('Pending Tasks', style: TextStyle(color: Colors.grey)),
                GSpacing.vSm,
                Text('3', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: XMTheme.warning)),
              ],
            ),
          ),
        ),
        GSpacing.hMd,
        Expanded(
          child: GCard(
            child: Column(
              children: [
                const Text('Training', style: TextStyle(color: Colors.grey)),
                GSpacing.vSm,
                Text('1 Due', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: XMTheme.error)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildModuleCard(
              context,
              'My Leave',
              'Apply for and track leave requests',
              Icons.event_available,
              Colors.teal,
              () => UIUtils.showSideSheet(context: context, title: 'My Leave', builder: (c) => const LeaveManagementScreen()),
            ),
            _buildModuleCard(
              context,
              'My Training',
              'Access the Learning Management System',
              Icons.school,
              Colors.indigo,
              () => UIUtils.showSideSheet(context: context, title: 'LMS', builder: (c) => const TrainingScreen()),
            ),
            _buildModuleCard(
              context,
              'My Action Items',
              'Tasks assigned to you',
              Icons.checklist,
              Colors.orange,
              () => UIUtils.showSideSheet(context: context, title: 'Action Tracker', builder: (c) => const ActionTrackerScreen()),
            ),
            _buildModuleCard(
              context,
              'Payslips',
              'View your payroll documents',
              Icons.receipt_long,
              Colors.blueGrey,
              () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('My Payslips'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.receipt),
                          title: const Text('Payslip - March 2026'),
                          trailing: const Icon(Icons.download),
                          onTap: () {
                            UIUtils.showToast(context, 'Downloading payslip...');
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildModuleCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Flexible(
              child: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
