import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/providers/app_providers.dart';
import '../../people/widgets/employee_selector.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class ActionForm extends ConsumerStatefulWidget {
  const ActionForm({super.key});

  @override
  ConsumerState<ActionForm> createState() => _ActionFormState();
}

class _ActionFormState extends ConsumerState<ActionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedEmployeeId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeId == null) {
      UIUtils.showToast(context, 'Please select an assignee', type: ToastType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final siteId = ref.read(currentTenantIdProvider);
      await ref.read(firestoreProvider).tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'actionItems').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'assigneeId': _selectedEmployeeId,
        'status': 'Pending',
        'dueDate': _dueDate.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'siteId': siteId,
        'type': 'General',
      });
      if (mounted) {
        UIUtils.showToast(context, 'Action item created', type: ToastType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    EmployeeSelector(
                      value: _selectedEmployeeId,
                      onChanged: (val) => setState(() => _selectedEmployeeId = val),
                      label: 'Assigned To *',
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text('Due Date: ${_dueDate.toString().split(' ')[0]}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _dueDate = d);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
