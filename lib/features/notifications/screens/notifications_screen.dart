import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app, this would use a StreamProvider over a 'notifications' Firestore collection
    final notifications = [
      {'title': 'Leave Approved', 'body': 'Your annual leave request has been approved by your manager.', 'time': '2 hours ago', 'isRead': false, 'type': 'leave'},
      {'title': 'New Training Assigned', 'body': 'You have been enrolled in "Site Safety 101". Please complete it by Friday.', 'time': '1 day ago', 'isRead': false, 'type': 'training'},
      {'title': 'Task Overdue', 'body': 'Action item "Inspect harness" is overdue.', 'time': '2 days ago', 'isRead': true, 'type': 'action'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => UIUtils.showToast(context, 'All marked as read'),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index];
          final isRead = n['isRead'] as bool;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColor(n['type'] as String).withValues(alpha: 0.2),
              child: Icon(_getIcon(n['type'] as String), color: _getColor(n['type'] as String)),
            ),
            title: Text(n['title'] as String, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(n['body'] as String),
                const SizedBox(height: 4),
                Text(n['time'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            trailing: isRead ? null : const Icon(Icons.circle, size: 12, color: XMTheme.primary),
            isThreeLine: true,
            onTap: () {
              UIUtils.showToast(context, 'Opening ${n['type']} details...');
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'leave': return Icons.event_available;
      case 'training': return Icons.school;
      case 'action': return Icons.checklist;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'leave': return Colors.teal;
      case 'training': return Colors.indigo;
      case 'action': return Colors.orange;
      default: return XMTheme.primary;
    }
  }
}
