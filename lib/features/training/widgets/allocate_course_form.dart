import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/searchable_multi_select.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../../people/providers/employee_providers.dart';

class AllocateCourseForm extends ConsumerStatefulWidget {
  const AllocateCourseForm({super.key});
  @override
  ConsumerState<AllocateCourseForm> createState() => _AllocateCourseFormState();
}

class _AllocateCourseFormState extends ConsumerState<AllocateCourseForm> {
  bool _isSubmitting = false;
  List<String> _enrolledEmployees = [];
  final _courseCtrl = TextEditingController();
  final _courseIdCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  Future<void> _submit() async {
    if (_enrolledEmployees.isEmpty || _courseCtrl.text.isEmpty || _courseIdCtrl.text.isEmpty) {
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
      final employees = ref.read(employeesProvider).valueOrNull ?? [];
      final employeeNames = {for (var e in employees) e.id: e.fullName};

      // Create enrollment for each selected employee
      for (final empId in _enrolledEmployees) {
        final existingQuery = await ref
            .read(firestoreProvider)
            .tenantCollection(ref.read(currentTenantIdProvider) ?? '', 'enrollments')
            .where('employeeId', isEqualTo: empId)
            .where('courseId', isEqualTo: _courseIdCtrl.text.trim())
            .get();
        
        bool isAlreadyCompleted = false;
        if (existingQuery.docs.isNotEmpty) {
          final data = existingQuery.docs.first.data();
          if (data['status'] == 'Completed') {
            isAlreadyCompleted = true;
          }
        }

        await ref
            .read(firestoreServiceProvider)
            .createDocument(
              tenantId: ref.read(currentTenantIdProvider) ?? '',
              collection: 'training_enrollments',
              data: {
                'employeeId': empId,
                'employeeName': employeeNames[empId] ?? 'Unknown Employee',
                'courseId': _courseIdCtrl.text.trim(),
                'courseName': _courseCtrl.text.trim(),
                'dueDate': _dueDate.toIso8601String(),
                'enrollmentDate': DateTime.now().toIso8601String(),
                // manager_training_dashboard.dart orders by this field — without it, an
                // allocation is invisible on that dashboard (see docs/fixes/FIX_LIST.md F-009)
                'assignedAt': DateTime.now().toIso8601String(),
                'status': isAlreadyCompleted ? 'Completed' : 'Assigned',
                'authorId': profile.uid,
                'siteId': profile.tenantId,
                'progressPercentage': isAlreadyCompleted ? 1.0 : 0.0,
              },
            );
      }

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
          ref.watch(employeesProvider).when(
            data: (employees) {
              final options = employees.map((e) => e.id).toList();
              final labels = <String, String>{for (var e in employees) e.id: e.fullName};
              return SearchableStringMultiSelect(
                label: 'Select Employees',
                hintText: 'Search employees...',
                availableItems: options,
                itemLabels: labels,
                selectedItems: _enrolledEmployees,
                onChanged: (val) {
                  setState(() {
                    _enrolledEmployees = val;
                  });
                },
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text('Error loading employees: $e'),
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
          TextFormField(
            controller: _courseIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Course ID *',
              hintText: 'e.g. CRS-101',
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
