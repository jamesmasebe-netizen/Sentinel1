import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../providers/hr_provider.dart';

class LeaveRequestDetailScreen extends ConsumerWidget {
  final String requestId;

  const LeaveRequestDetailScreen({super.key, required this.requestId});

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String newStatus,
  ) async {
    try {
      await ref
          .read(firestoreProvider)
          .collection('leave_requests')
          .doc(requestId)
          .update({
            'status': newStatus,
            'updatedAt': DateTime.now().toIso8601String(),
          });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave request marked as $newStatus'),
            backgroundColor:
                newStatus == 'Approved' ? XMTheme.success : XMTheme.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: XMTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaveAsync = ref.watch(leaveRequestDetailProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('Leave Request Detail')),
      body: leaveAsync.when(
        data: (leave) {
          if (leave == null) {
            return const Center(child: Text('Leave request not found'));
          }

          final status = leave['status'] as String? ?? 'Pending';
          final isPending = status.toLowerCase() == 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Request Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    _StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.category,
                          label: 'Leave Type',
                          value: leave['leaveType'] ?? 'N/A',
                        ),
                        const Divider(),
                        _DetailRow(
                          icon: Icons.calendar_today,
                          label: 'Start Date',
                          value: _formatDate(leave['startDate']),
                        ),
                        const Divider(),
                        _DetailRow(
                          icon: Icons.calendar_today,
                          label: 'End Date',
                          value: _formatDate(leave['endDate']),
                        ),
                        const Divider(),
                        _DetailRow(
                          icon: Icons.format_align_left,
                          label: 'Reason',
                          value: leave['reason'] ?? 'No reason provided',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (isPending) ...[
                  Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              () => _updateStatus(context, ref, 'Approved'),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: XMTheme.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              () => _updateStatus(context, ref, 'Rejected'),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: XMTheme.error,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return DateFormat('MMMM d, yyyy').format(dt);
    } catch (_) {
      return dateStr.toString();
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'approved':
        return XMTheme.success;
      case 'pending':
        return XMTheme.warning;
      case 'rejected':
        return XMTheme.error;
      default:
        return XMTheme.statusDraft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _color,
        ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
