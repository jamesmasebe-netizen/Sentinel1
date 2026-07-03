import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';

class EmployeeActivityTab extends ConsumerWidget {
  final String employeeId;
  const EmployeeActivityTab({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real implementation we would run parallel queries across 'incidents', 'ptw', 'hira'
    // where applicantId/reporterId/assessorId == employeeId.
    // For now we mock the UI layout.

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Safety & Ops Activity',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final date = DateTime.now().subtract(Duration(days: index * 2));
                final types = [
                  'Incident Reported',
                  'PTW Approved',
                  'HIRA Completed',
                  'Safety Walkabout',
                ];
                final icons = [
                  Icons.warning,
                  Icons.assignment_turned_in,
                  Icons.analytics,
                  Icons.directions_walk,
                ];
                final colors = [
                  XMTheme.error,
                  XMTheme.success,
                  XMTheme.info,
                  XMTheme.primary,
                ];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colors[index].withValues(alpha: 0.1),
                    child: Icon(icons[index], color: colors[index]),
                  ),
                  title: Text(
                    types[index],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, yyyy - HH:mm').format(date),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Activity Heatmap (Coming Soon)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GCard(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.grid_on,
                    size: 48,
                    color: XMTheme.secondaryLight.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text('Activity heatmap will be available here.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
