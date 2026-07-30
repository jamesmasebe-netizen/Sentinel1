import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../widgets/draggable_task_card.dart';
import '../../people/providers/employee_providers.dart';
import '../../field_service/providers/field_service_providers.dart';
import '../../field_service/services/field_service_service.dart';
import '../../field_service/models/field_service_models.dart';
import '../../projects/providers/project_providers.dart';
import '../../projects/models/project_models.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

final scheduleWorkOrdersProvider = StreamProvider<List<WorkOrder>>((ref) {
  return ref.watch(fieldServiceServiceProvider).streamWorkOrders();
});

class ScheduleBoardScreen extends ConsumerStatefulWidget {
  const ScheduleBoardScreen({super.key});

  @override
  ConsumerState<ScheduleBoardScreen> createState() =>
      _ScheduleBoardScreenState();
}

class _ScheduleBoardScreenState extends ConsumerState<ScheduleBoardScreen> {
  Future<void> _assignTask(String taskId, String resourceId, bool isWorkOrder, String? projectId) async {
    try {
      if (isWorkOrder) {
        final service = ref.read(fieldServiceServiceProvider);
        final wo = await service.getWorkOrder(taskId);
        if (wo != null) {
          final updated = wo.toJson();
          updated['assigned_technician_id'] = resourceId;
          await service.updateWorkOrder(WorkOrder.fromJson(updated, taskId));
        }
      } else {
        if (projectId != null) {
          final doc = await ref.read(firestoreProvider).tenantCollection(ref.read(currentTenantIdProvider) ?? '', 'projects').doc(projectId).get();
          if (doc.exists) {
            final project = Project.fromFirestore(doc);
            final updatedTasks = project.tasks.map((t) {
              if (t.id == taskId) {
                return t.copyWith(assignedTo: resourceId);
              }
              return t;
            }).toList();
            final updatedProject = project.copyWith(tasks: updatedTasks);
            await ref.read(projectServiceProvider).updateProject(updatedProject);
          }
        }
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Failed to assign task: $e', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    final workOrdersAsync = ref.watch(scheduleWorkOrdersProvider);
    final projectsAsync = ref.watch(projectsProvider);

    final isLoading = employeesAsync.isLoading || workOrdersAsync.isLoading || projectsAsync.isLoading;
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final employees = employeesAsync.valueOrNull ?? [];
    final workOrders = workOrdersAsync.valueOrNull ?? [];
    final projects = projectsAsync.valueOrNull ?? [];

    final List<Map<String, dynamic>> allTasks = [];
    for (var wo in workOrders) {
      if (wo.status != 'COMPLETED' && wo.status != 'CLOSED') {
        allTasks.add({
          'id': wo.id,
          'title': wo.workOrderNumber,
          'subtitle': wo.description ?? 'Work Order',
          'assignedTo': wo.assignedTechnicianId,
          'isWorkOrder': true,
          'projectId': null,
        });
      }
    }

    for (var proj in projects) {
      for (var task in proj.tasks) {
        if (task.progress < 1.0) {
          allTasks.add({
            'id': task.id,
            'title': task.title,
            'subtitle': proj.name,
            'assignedTo': task.assignedTo.isNotEmpty ? task.assignedTo : null,
            'isWorkOrder': false,
            'projectId': proj.id,
          });
        }
      }
    }

    final unassignedTasks = allTasks.where((t) => t['assignedTo'] == null).toList();
    
    final assignedTasks = <String, List<Map<String, dynamic>>>{};
    for (var emp in employees) {
      assignedTasks[emp.id] = allTasks.where((t) => t['assignedTo'] == emp.id).toList();
    }

    return Scaffold(
      body: Column(
        children: [
          const GHeader(title: 'Universal Schedule Board'),
          Expanded(
            child: Row(
              children: [
                // Unassigned Tasks Sidebar
                Container(
                  width: 250,
                  color: Colors.grey[100],
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Unassigned Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: unassignedTasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final task = unassignedTasks[index];
                            return DraggableTaskCard(
                              taskId: task['id'],
                              title: task['title'],
                              subtitle: task['subtitle'],
                              taskData: task,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                // Schedule Timeline View
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      final resource = employees[index];
                      final tasks = assignedTasks[resource.id] ?? [];
                      
                      return DragTarget<Map<String, dynamic>>(
                        onAccept: (taskData) => _assignTask(taskData['id'], resource.id, taskData['isWorkOrder'], taskData['projectId']),
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: candidateData.isNotEmpty ? Colors.blue.withOpacity(0.1) : Colors.white,
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Container(
                                    width: 120,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      border: Border(right: BorderSide(color: Colors.grey[300]!)),
                                    ),
                                    child: Center(child: Text(resource.fullName, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: tasks.map((task) {
                                          return DraggableTaskCard(
                                            taskId: task['id'],
                                            title: task['title'],
                                            subtitle: task['subtitle'],
                                            color: task['isWorkOrder'] ? Colors.green : Colors.purple,
                                            taskData: task,
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
