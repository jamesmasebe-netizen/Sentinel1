import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/providers/app_providers.dart';
import '../models/pmo_models.dart';
import '../services/pmo_service.dart';

class TimesheetEntryScreen extends ConsumerStatefulWidget {
  final String projectId;

  const TimesheetEntryScreen({super.key, required this.projectId});

  @override
  ConsumerState<TimesheetEntryScreen> createState() =>
      _TimesheetEntryScreenState();
}

class _TimesheetEntryScreenState extends ConsumerState<TimesheetEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _hoursController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final tenantId = ref.read(currentTenantIdProvider);
      final profile = ref.read(userProfileProvider).valueOrNull;

      if (tenantId == null || profile == null) {
        throw Exception('Not authenticated or no active tenant.');
      }

      // Unified onto the same time_entries collection/TimeEntry model as
      // PmoService's Time Entries tab (project_detail_screen.dart) reads from —
      // previously this screen wrote to a separate 'timeEntries' collection that
      // had no reader anywhere in the app. No specific WBS task is selected from
      // this quick-entry screen, so taskId is left blank (matches TimeEntry's own
      // fromJson default for an absent task).
      final entry = TimeEntry(
        entryId: DateTime.now().millisecondsSinceEpoch.toString(),
        resourceId: profile.uid,
        projectId: widget.projectId,
        taskId: '',
        date: _selectedDate,
        hours: double.parse(_hoursController.text.trim()),
        description: _descriptionController.text.trim(),
        isBillable: true,
        billingStatus: 'Unbilled',
        approvalStatus: 'Draft',
      );

      await ref.read(pmoServiceProvider).createTimeEntry(entry);

      if (mounted) {
        UIUtils.showToast(context, 'Timesheet submitted successfully', type: ToastType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Failed to submit: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timesheet Entry'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log Hours',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Task Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Required'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _hoursController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Hours Worked',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.timer),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (date != null) {
                                  setState(() => _selectedDate = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                            : const Icon(Icons.save),
                          label: Text(_isSubmitting ? 'Submitting...' : 'Submit Timesheet'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
