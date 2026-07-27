import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/providers/app_providers.dart';
import '../providers/approvals_provider.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class ApprovalsInboxScreen extends ConsumerWidget {
  const ApprovalsInboxScreen({super.key});

  Future<void> _processApproval(
    BuildContext context,
    WidgetRef ref,
    ApprovalItem item,
    bool isApproved,
  ) async {
    try {
      final status =
          isApproved
              ? (item.type == 'Job Requisition' ? 'Published' : 'Approved')
              : 'Rejected';

      await ref
          .read(firestoreProvider)
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            item.collectionPath,
          )
          .doc(item.id)
          .update({
            'status': status,
            if (isApproved && item.type == 'Job Requisition')
              'publishedAt': FieldValue.serverTimestamp(),
          });

      // Invalidate provider to refresh the list
      ref.invalidate(pendingApprovalsFutureProvider);

      if (context.mounted) {
        UIUtils.showToast(
          context,
          '${item.type} $status',
          type: isApproved ? ToastType.success : ToastType.warning,
        );
      }
    } catch (e) {
      if (context.mounted) {
        UIUtils.showToast(
          context,
          'Failed to process approval: $e',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(pendingApprovalsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Approvals Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(pendingApprovalsFutureProvider),
          ),
        ],
      ),
      body: approvalsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No pending approvals.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You\'re all caught up!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          Text(
                            UIUtils.formatDate(item.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(item.subtitle),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed:
                                () =>
                                    _processApproval(context, ref, item, false),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed:
                                () =>
                                    _processApproval(context, ref, item, true),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Approve'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading approvals: $e')),
      ),
    );
  }
}
