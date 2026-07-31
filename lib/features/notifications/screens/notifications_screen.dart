import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/providers/app_providers.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isMarkingAll = false;

  static const _typeRoutes = {
    'leave': '/hr',
    'training': '/hr',
    'action': '/actions',
  };

  Future<void> _markAllRead(List<AppNotification> notifications) async {
    final unread = notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    setState(() => _isMarkingAll = true);
    try {
      final tenantId = ref.read(currentTenantIdProvider) ?? '';
      final batch = ref.read(firestoreProvider).batch();
      for (final n in unread) {
        batch.update(
          ref.read(firestoreProvider).tenantCollection(tenantId, 'notifications').doc(n.id),
          {'isRead': true},
        );
      }
      await batch.commit();
      if (mounted) UIUtils.showToast(context, 'All marked as read', type: ToastType.success);
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isMarkingAll = false);
    }
  }

  Future<void> _openNotification(AppNotification n) async {
    final tenantId = ref.read(currentTenantIdProvider) ?? '';
    if (!n.isRead) {
      await ref
          .read(firestoreProvider)
          .tenantCollection(tenantId, 'notifications')
          .doc(n.id)
          .update({'isRead': true});
    }
    final route = _typeRoutes[n.type];
    if (route != null && mounted) {
      context.go(route);
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'leave':
        return Icons.event_available;
      case 'training':
        return Icons.school;
      case 'action':
        return Icons.checklist;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'leave':
        return Colors.teal;
      case 'training':
        return Colors.indigo;
      case 'action':
        return Colors.orange;
      default:
        return XMTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _isMarkingAll
                ? null
                : () => _markAllRead(notificationsAsync.valueOrNull ?? []),
            child: Text(_isMarkingAll ? 'Marking...' : 'Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getColor(n.type).withValues(alpha: 0.2),
                  child: Icon(_getIcon(n.type), color: _getColor(n.type)),
                ),
                title: Text(
                  n.title,
                  style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(n.body),
                    const SizedBox(height: 4),
                    Text(
                      _relativeTime(n.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: n.isRead ? null : const Icon(Icons.circle, size: 12, color: XMTheme.primary),
                isThreeLine: true,
                onTap: () => _openNotification(n),
              );
            },
          );
        },
      ),
    );
  }
}
