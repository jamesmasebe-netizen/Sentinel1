import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../people/widgets/employee_selector.dart';

class AllocateCourseForm extends ConsumerStatefulWidget {
  final String tenantId;
  const AllocateCourseForm({super.key, required this.tenantId});
  @override
  ConsumerState<AllocateCourseForm> createState() => _AllocateCourseFormState();
}

class _AllocateCourseFormState extends ConsumerState<AllocateCourseForm> {
  bool _isSubmitting = false;
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;
  final _courseCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  Future<void> _submit() async {
    if (_selectedEmployeeId == null || _courseCtrl.text.isEmpty) {
      UIUtils.showToast(
        context,
        'Please fill in required fields',
        type: ToastType.error,
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');

      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            tenantId: widget.tenantId,
            collection: 'training_enrollments',
            data: {
              'employeeId': _selectedEmployeeId,
              'employeeName': _selectedEmployeeName,
              'courseName': _courseCtrl.text.trim(),
              'dueDate': _dueDate.toIso8601String(),
              'assignedAt': DateTime.now().toIso8601String(),
              'status': 'Assigned',
              'authorId': profile.uid,
              'siteId': profile.tenantId,
              'progressPercentage': 0.0,
            },
          );

      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(
          context,
          'Course allocated successfully',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Allocate a mandatory course to an employee.'),
          const SizedBox(height: 24),
          const Text(
            'Select Employee *',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          EmployeeSelector(
            value: _selectedEmployeeId,
            onChanged: (val) {
              setState(() {
                _selectedEmployeeId = val;
                _selectedEmployeeName = 'Unknown (Fetched via ID)';
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _courseCtrl,
            decoration: const InputDecoration(
              labelText: 'Course Name *',
              hintText: 'e.g. Health & Safety Level 1',
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Due Date'),
            subtitle: Text(DateFormat('MMM d, yyyy').format(_dueDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _dueDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              );
              if (d != null) setState(() => _dueDate = d);
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Allocating...' : 'Allocate Course'),
            ),
          ),
        ],
      ),
    );
  }
}
