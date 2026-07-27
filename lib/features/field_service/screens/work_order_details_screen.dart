import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/field_service_models.dart';
import '../services/field_service_service.dart';

class WorkOrderDetailsScreen extends ConsumerStatefulWidget {
  final String workOrderId;

  const WorkOrderDetailsScreen({super.key, required this.workOrderId});

  @override
  ConsumerState<WorkOrderDetailsScreen> createState() =>
      _WorkOrderDetailsScreenState();
}

class _WorkOrderDetailsScreenState extends ConsumerState<WorkOrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(fieldServiceServiceProvider);

    return StreamBuilder<WorkOrder?>(
      stream: service.streamWorkOrder(widget.workOrderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final workOrder = snapshot.data;
        if (workOrder == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Work Order Details')),
            body: const Center(child: Text('Work Order not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('WO: ${workOrder.workOrderNumber}'),
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Details', icon: Icon(Icons.info_outline)),
                Tab(text: 'Tasks', icon: Icon(Icons.checklist)),
                Tab(text: 'IoT Context', icon: Icon(Icons.sensors)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsTab(workOrder),
              _buildTasksTab(service, workOrder.id),
              _buildIotTab(workOrder),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailsTab(WorkOrder wo) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoCard(
          'Description',
          wo.description ?? 'No description provided.',
          Icons.description,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildInfoCard('Status', wo.status, Icons.flag)),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                'Priority',
                wo.priority,
                Icons.priority_high,
                _getPriorityColor(wo.priority),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Customer',
          'Customer ID: ${wo.customerId}',
          Icons.business,
        ),
        if (wo.assignedTechnicianId != null) ...[
          const SizedBox(height: 16),
          _buildInfoCard(
            'Technician',
            wo.assignedTechnicianId!,
            Icons.person_pin,
          ),
        ],
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoCard(
    String title,
    String content,
    IconData icon, [
    Color? iconColor,
  ]) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.blueAccent).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: iconColor ?? Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab(FieldServiceService service, String workOrderId) {
    return StreamBuilder<List<WorkOrderTask>>(
      stream: service.streamWorkOrderTasks(workOrderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return const Center(
            child: Text('No tasks associated with this Work Order.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final isCompleted = task.status == 'COMPLETED';
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                value: isCompleted,
                activeColor: Colors.green,
                onChanged: (val) {
                  final updatedTask = WorkOrderTask(
                    id: task.id,
                    taskName: task.taskName,
                    description: task.description,
                    status: val == true ? 'COMPLETED' : 'PENDING',
                    sequenceOrder: task.sequenceOrder,
                    isMandatory: task.isMandatory,
                    inspectionTemplateId: task.inspectionTemplateId,
                    estimatedDurationMins: task.estimatedDurationMins,
                    actualDurationMins: task.actualDurationMins,
                    percentComplete: val == true ? 100 : 0,
                  );
                  service.updateWorkOrderTask(workOrderId, updatedTask);
                },
                title: Text(
                  task.taskName,
                  style: TextStyle(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(task.description ?? 'No description'),
                secondary: Icon(
                  task.isMandatory ? Icons.warning : Icons.task,
                  color: task.isMandatory ? Colors.redAccent : Colors.grey,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIotTab(WorkOrder wo) {
    if (wo.iotContext == null || wo.iotContext!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No IoT Context Available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children:
          wo.iotContext!.entries.map((e) {
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                ),
                title: Text(
                  e.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    e.value.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
