import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../widgets/allocate_course_form.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class ManagerTrainingDashboard extends ConsumerStatefulWidget {
  const ManagerTrainingDashboard({super.key});

  @override
  ConsumerState<ManagerTrainingDashboard> createState() => _ManagerTrainingDashboardState();
}

class _ManagerTrainingDashboardState extends ConsumerState<ManagerTrainingDashboard> {
  void _openAllocateForm() {
    UIUtils.showSideSheet(
      context: context,
      title: 'Allocate Mandatory Course',
      builder: (ctx) => AllocateCourseForm(tenantId: ref.read(currentTenantIdProvider) ?? '', ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firestoreProvider);
    final siteId = ref.watch(currentTenantIdProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Course Allocations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              FilledButton.icon(
                onPressed: _openAllocateForm,
                icon: const Icon(Icons.assignment_ind, size: 18),
                label: const Text('Allocate Course'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'training_enrollments')
                .where('siteId', isEqualTo: siteId)
                .orderBy('assignedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 48, color: Theme.of(context).disabledColor),
                      const SizedBox(height: 16),
                      const Text('No courses have been allocated yet.'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  final isCompleted = data['status'] == 'Completed';

                  return GCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: XMTheme.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.person, color: XMTheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['employeeName'] ?? 'Unknown Employee', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('Course: ${data['courseName'] ?? 'Unknown'}', style: TextStyle(color: XMTheme.secondaryLight, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Due: ${data['dueDate'] != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(data['dueDate'])) : 'No due date'}', style: TextStyle(color: XMTheme.warning, fontSize: 12)),
                            ],
                          ),
                        ),
                        GStatusTag(
                          label: data['status'] ?? 'Assigned',
                          color: isCompleted ? XMTheme.success : XMTheme.info,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
