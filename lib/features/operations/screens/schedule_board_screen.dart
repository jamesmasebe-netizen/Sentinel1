import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/draggable_task_card.dart';

class ScheduleBoardScreen extends ConsumerStatefulWidget {
  const ScheduleBoardScreen({super.key});

  @override
  ConsumerState<ScheduleBoardScreen> createState() =>
      _ScheduleBoardScreenState();
}

class _ScheduleBoardScreenState extends ConsumerState<ScheduleBoardScreen> {
  // Mock data for resources (technicians/employees)
  final List<String> resources = ['John Doe', 'Jane Smith', 'Mike Johnson', 'Sarah Connor'];
  
  // Mock data for unassigned tasks
  final List<Map<String, dynamic>> unassignedTasks = [
    {'id': 'wo-1', 'title': 'WO #101', 'subtitle': 'HVAC Repair'},
    {'id': 'wo-2', 'title': 'WO #102', 'subtitle': 'Electrical Inspection'},
    {'id': 'wo-3', 'title': 'PMO-200', 'subtitle': 'Site Audit'},
  ];

  // Map of resource name to a list of assigned tasks
  final Map<String, List<Map<String, dynamic>>> assignedTasks = {
    'John Doe': [],
    'Jane Smith': [],
    'Mike Johnson': [],
    'Sarah Connor': [],
  };

  void _assignTask(String taskId, String resourceName) {
    setState(() {
      final taskIndex = unassignedTasks.indexWhere((t) => t['id'] == taskId);
      if (taskIndex != -1) {
        final task = unassignedTasks.removeAt(taskIndex);
        assignedTasks[resourceName]?.add(task);
      } else {
        // If moving between resources
        for (var res in assignedTasks.keys) {
          final resTaskIndex = assignedTasks[res]?.indexWhere((t) => t['id'] == taskId) ?? -1;
          if (resTaskIndex != -1) {
            final task = assignedTasks[res]!.removeAt(resTaskIndex);
            assignedTasks[resourceName]?.add(task);
            break;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    itemCount: resources.length,
                    itemBuilder: (context, index) {
                      final resource = resources[index];
                      final tasks = assignedTasks[resource] ?? [];
                      
                      return DragTarget<String>(
                        onAccept: (taskId) => _assignTask(taskId, resource),
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
                                    child: Center(child: Text(resource, style: const TextStyle(fontWeight: FontWeight.bold))),
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
                                            color: Colors.green,
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
