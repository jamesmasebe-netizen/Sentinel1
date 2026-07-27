import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_models.dart';
import '../services/crm_service.dart';

class ActivityFeedScreen extends ConsumerWidget {
  final String? regardingId;
  final String? regardingType;

  const ActivityFeedScreen({super.key, this.regardingId, this.regardingType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Feed')),
      body: StreamBuilder<List<Activity>>(
        stream: ref
            .read(crmServiceProvider)
            .streamActivities(
              regardingId: regardingId,
              regardingType: regardingType,
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final activities = snapshot.data ?? [];
          if (activities.isEmpty) {
            return const Center(child: Text('No activities found.'));
          }
          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ListTile(
                leading: const Icon(Icons.event_note),
                title: Text(activity.subject),
                subtitle: Text('${activity.type} - ${activity.status}'),
                trailing: Text(
                  activity.dueDate?.toLocal().toString().split(' ')[0] ?? '',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
