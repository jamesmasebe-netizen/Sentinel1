import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Offline queue viewer — shows pending/failed sync operations and allows retry.
class OfflineQueueScreen extends ConsumerWidget {
  const OfflineQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Offline Sync Queue')),
      body: Column(
        children: [
          // Status header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  XMTheme.primary.withValues(alpha: 0.08),
                  XMTheme.secondary.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: syncStatus.when(
              data: (status) {
                final color =
                    status.name == 'synced'
                        ? XMTheme.success
                        : status.name == 'syncing'
                        ? XMTheme.warning
                        : XMTheme.error;
                final icon =
                    status.name == 'synced'
                        ? Icons.cloud_done
                        : status.name == 'syncing'
                        ? Icons.sync
                        : Icons.cloud_off;
                return Row(
                  children: [
                    Icon(icon, color: color, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.name == 'synced'
                                ? 'All Synced'
                                : status.name == 'syncing'
                                ? 'Syncing…'
                                : 'Sync Failed',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: color,
                            ),
                          ),
                          pendingCount.when(
                            data:
                                (c) => Text(
                                  '$c operations pending',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            loading:
                                () => const Text(
                                  'Checking…',
                                  style: TextStyle(fontSize: 12),
                                ),
                            error:
                                (_, __) => const Text(
                                  'Error checking queue',
                                  style: TextStyle(fontSize: 12),
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (status.name != 'synced')
                      FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final offlineSync = ref.read(
                            offlineSyncServiceProvider,
                          );
                          offlineSync.retrySync();
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ),
          const Divider(height: 1),
          // Queue info
          Expanded(
            child: pendingCount.when(
              data: (count) {
                final offlineSync = ref.read(offlineSyncServiceProvider);
                final items = offlineSync.getPendingOperations();

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_sync,
                          size: 64,
                          color: XMTheme.primary.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Offline Queue is Empty',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Forms submitted while offline are queued here and automatically synced when connectivity returns.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatusChip(
                              icon: Icons.check_circle,
                              label: 'Synced',
                              color: XMTheme.success,
                            ),
                            const SizedBox(width: 12),
                            _StatusChip(
                              icon: Icons.sync,
                              label: 'Pending',
                              color: XMTheme.warning,
                            ),
                            const SizedBox(width: 12),
                            _StatusChip(
                              icon: Icons.error,
                              label: 'Failed',
                              color: XMTheme.error,
                            ),
                          ],
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

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
