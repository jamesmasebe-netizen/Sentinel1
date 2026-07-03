import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/employee_providers.dart';

class EmployeeSelector extends ConsumerWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? Function(String?)? validator;

  const EmployeeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Select Employee',
    this.validator,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);

    return employeesAsync.when(
      data: (employees) {
        if (employees.isEmpty) {
          return const Text('No records found');
        }
        return DropdownButtonFormField<String>(
          value: value != null && employees.any((e) => e.id == value) ? value : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: employees.map((emp) {
            return DropdownMenuItem(
              value: emp.id,
              child: Text('${emp.fullName} (${emp.jobTitle})'),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Text('Error loading employees: $e'),
    );
  }
}
