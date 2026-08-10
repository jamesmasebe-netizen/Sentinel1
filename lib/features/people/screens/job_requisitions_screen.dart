import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../providers/hr_providers.dart';
import '../widgets/employee_selector.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../models/hr_models.dart';

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
                  req.createdAt.toLocal().toString().split(' ')[0],
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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _departmentController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _requirementsController = TextEditingController();
  String _employmentType = 'Full-time';
  String? _selectedManagerId;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _departmentController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _saveRequisition() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedManagerId == null) {
      UIUtils.showToast(context, 'Please select a hiring manager', type: ToastType.error);
      return;
    }

    final siteId = ref.read(currentTenantIdProvider);
    if (siteId == null) return;

    setState(() => _isSaving = true);
    try {
      // New requisitions always start as Draft — this is what feeds the hiring manager's own
      // Approvals inbox (dashboard/providers/approvals_provider.dart); an approver, not the
      // creator, is what advances status to Published/Rejected.
      final req = JobRequisition(
        id: '',
        title: _titleController.text,
        department: _departmentController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        employmentType: _employmentType,
        requirements: _requirementsController.text,
        hiringManagerId: _selectedManagerId!,
        status: 'Draft',
        createdAt: DateTime.now(),
        siteId: siteId,
      );

      await ref
          .read(firestoreProvider)
          .tenantCollection(siteId, 'job_requisitions')
          .add(req.toFirestore());

      if (mounted) {
        UIUtils.showToast(context, 'Requisition created as Draft', type: ToastType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error creating requisition: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Job Requisition'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Job Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: 'Department'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              DropdownButtonFormField<String>(
                value: _employmentType,
                decoration: const InputDecoration(labelText: 'Employment Type'),
                items: const ['Full-time', 'Part-time', 'Contract', 'Internship']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _employmentType = val ?? _employmentType),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _requirementsController,
                decoration: const InputDecoration(labelText: 'Requirements'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hiring Manager',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              EmployeeSelector(
                value: _selectedManagerId,
                onChanged: (val) => setState(() => _selectedManagerId = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveRequisition,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save as Draft'),
        ),
      ],
    );
  }
}
