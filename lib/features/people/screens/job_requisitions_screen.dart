import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../models/hr_models.dart';
import '../providers/hr_providers.dart';
import '../widgets/employee_selector.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class JobRequisitionsScreen extends ConsumerStatefulWidget {
  const JobRequisitionsScreen({super.key});

  @override
  ConsumerState<JobRequisitionsScreen> createState() =>
      _JobRequisitionsScreenState();
}

class _JobRequisitionsScreenState extends ConsumerState<JobRequisitionsScreen> {
  void _showCreateRequisitionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _CreateRequisitionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requisitionsAsync = ref.watch(jobRequisitionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Requisitions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateRequisitionDialog,
          ),
        ],
      ),
      body: requisitionsAsync.when(
        data: (requisitions) {
          if (requisitions.isEmpty) {
            return const Center(child: Text('No job requisitions found.'));
          }
          return ListView.builder(
            itemCount: requisitions.length,
            itemBuilder: (context, index) {
              final req = requisitions[index];
              return ListTile(
                title: Text(req.title),
                subtitle: Text('${req.department} • Status: ${req.status}'),
                trailing: Text(
                  req.postedDate.toLocal().toString().split(' ')[0],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _CreateRequisitionDialog extends ConsumerStatefulWidget {
  const _CreateRequisitionDialog();

  @override
  ConsumerState<_CreateRequisitionDialog> createState() =>
      _CreateRequisitionDialogState();
}

class _CreateRequisitionDialogState
    extends ConsumerState<_CreateRequisitionDialog> {
  final _titleController = TextEditingController();
  final _departmentController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedManagerId;
  String _status = 'Open';

  Future<void> _saveRequisition() async {
    final siteId = ref.read(currentTenantIdProvider);
    if (siteId == null) return;

    final req = JobRequisition(
      id: '',
      title: _titleController.text,
      department: _departmentController.text,
      description: _descriptionController.text,
      status: _status,
      postedDate: DateTime.now(),
      siteId: siteId,
    );

    await ref
        .read(firestoreProvider)
        .tenantCollection(
          ref.watch(currentTenantIdProvider) ?? "",
          'job_requisitions',
        )
        .add(req.toFirestore());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Job Requisition'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Job Title'),
            ),
            TextField(
              controller: _departmentController,
              decoration: const InputDecoration(labelText: 'Department'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hiring Manager',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            EmployeeSelector(
              value: _selectedManagerId,
              onChanged: (val) {
                setState(() {
                  _selectedManagerId = val;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'Open', child: Text('Open')),
                DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                DropdownMenuItem(value: 'Closed', child: Text('Closed')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveRequisition, child: const Text('Save')),
      ],
    );
  }
}
