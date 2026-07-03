import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/providers/app_providers.dart';
import '../providers/hr_providers.dart';
import '../models/hr_models.dart';
import '../widgets/leave_application_form.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class LeaveManagementScreen extends ConsumerWidget {
  const LeaveManagementScreen({super.key});

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, LeaveRequest req, String status) async {
    try {
      await ref.read(firestoreProvider).tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'leave_requests').doc(req.id).update({
        'status': status,
      });
      if (context.mounted) {
        UIUtils.showToast(context, 'Leave request $status', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        UIUtils.showToast(context, 'Error updating request: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(leaveRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          UIUtils.showSideSheet(
            context: context,
            title: 'Apply for Leave',
            builder: (ctx) => const LeaveApplicationForm(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Apply Leave'),
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(child: Text('No leave requests found.'));
          }
          return ListView.builder(
            itemCount: requests.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final req = requests[index];
              final isPending = req.status == 'Pending';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(req.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Chip(
                            label: Text(req.status),
                            backgroundColor: req.status == 'Approved' ? Colors.green.shade100 
                                : req.status == 'Rejected' ? Colors.red.shade100 : Colors.orange.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Type: ${req.leaveType}'),
                      Text('Dates: ${UIUtils.formatDate(req.startDate)} - ${UIUtils.formatDate(req.endDate)}'),
                      if (req.reason != null && req.reason!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Reason: ${req.reason}', style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                      if (isPending) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => _updateStatus(context, ref, req, 'Rejected'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => _updateStatus(context, ref, req, 'Approved'),
                              style: FilledButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
