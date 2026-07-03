import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/app_providers.dart';

class SyncStatusHeader extends ConsumerWidget {
  const SyncStatusHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Container(
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
          final color = status.name == 'synced'
              ? XMTheme.success
              : status.name == 'syncing'
                  ? XMTheme.warning
                  : XMTheme.error;
          final icon = status.name == 'synced'
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
                      data: (c) => Text(
                        '$c operations pending',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      loading: () => const Text(
                        'Checking…',
                        style: TextStyle(fontSize: 12),
                      ),
                      error: (_, __) => const Text(
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
                    final offlineSync = ref.read(offlineSyncServiceProvider);
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
    );
  }
}

class EmptyQueueView extends StatelessWidget {
  const EmptyQueueView({super.key});

  @override
  Widget build(BuildContext context) {
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatusChip(
                icon: Icons.check_circle,
                label: 'Synced',
                color: XMTheme.success,
              ),
              const SizedBox(width: 12),
              StatusChip(
                icon: Icons.sync,
                label: 'Pending',
                color: XMTheme.warning,
              ),
              const SizedBox(width: 12),
              StatusChip(
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
}

class StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const StatusChip({
    super.key,
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
