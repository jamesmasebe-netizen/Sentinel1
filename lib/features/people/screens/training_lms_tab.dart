import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class TrainingLMSTab extends ConsumerWidget {
  final String employeeId;
  const TrainingLMSTab({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.watch(firestoreProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Training Enrollments',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              FilledButton.icon(
                onPressed: () {
                  // Show assign course dialog
                },
                icon: const Icon(Icons.school, size: 18),
                label: const Text('Assign Course'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream:
                firestore
                    .tenantCollection(
                      ref.watch(currentTenantIdProvider) ?? "",
                      'training_enrollments',
                    )
                    .where('employeeId', isEqualTo: employeeId)
                    .orderBy('assignedAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_edu,
                          size: 48,
                          color: XMTheme.secondaryLight.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text('No training enrollments found.'),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  final isCompleted = data['status'] == 'Completed';

                  return GCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                isCompleted
                                    ? XMTheme.success.withValues(alpha: 0.1)
                                    : XMTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.play_circle_fill,
                            color:
                                isCompleted ? XMTheme.success : XMTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['courseName'] ?? 'Unknown Course',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Assigned: ${data['assignedAt'] != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(data['assignedAt'])) : 'Unknown'}',
                                style: TextStyle(
                                  color: XMTheme.secondaryLight,
                                  fontSize: 13,
                                ),
                              ),
                              if (isCompleted && data['completedAt'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Completed: ${DateFormat('MMM d, yyyy').format(DateTime.parse(data['completedAt']))}',
                                    style: const TextStyle(
                                      color: XMTheme.success,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        GStatusTag(
                          label: data['status'] ?? 'In Progress',
                          color:
                              isCompleted ? XMTheme.success : XMTheme.warning,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
