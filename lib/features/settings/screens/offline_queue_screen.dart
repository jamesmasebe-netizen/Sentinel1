import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../widgets/offline_queue_widgets.dart';

/// Offline queue viewer — shows pending/failed sync operations and allows retry.
class OfflineQueueScreen extends ConsumerWidget {
  const OfflineQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Offline Sync Queue')),
      body: Column(
        children: [
          // Status header
          const SyncStatusHeader(),
          const Divider(height: 1),
          // Queue info
          Expanded(
            child: pendingCount.when(
              data: (count) {
                final offlineSync = ref.read(offlineSyncServiceProvider);
                final items = offlineSync.getPendingOperations();

                if (items.isEmpty) {
                  return const EmptyQueueView();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isError = item.status.name == 'failed';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isError
                                  ? XMTheme.error.withValues(alpha: 0.1)
                                  : XMTheme.warning.withValues(alpha: 0.1),
                          child: Icon(
                            isError ? Icons.error : Icons.sync,
                            color: isError ? XMTheme.error : XMTheme.warning,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '${item.operation.name.toUpperCase()} ${item.collection}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Retries: ${item.retryCount}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (isError && item.lastError != null)
                              Text(
                                item.lastError!,
                                style: TextStyle(
                                  color: XMTheme.error,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing:
                            isError
                                ? IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    ref
                                        .read(offlineSyncServiceProvider)
                                        .retryOperation(item.id);
                                  },
                                )
                                : null,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (_, __) => const Center(child: Text('Error loading queue')),
            ),
          ),
        ],
      ),
    );
  }
}
