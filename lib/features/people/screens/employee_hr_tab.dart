import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/employee_providers.dart';
import '../widgets/employee_hr/leave_summary_section.dart';
import '../widgets/employee_hr/payslips_section.dart';
import '../widgets/employee_hr/disciplinary_section.dart';

class EmployeeHRTab extends ConsumerWidget {
  final String employeeId;
  const EmployeeHRTab({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider).valueOrNull ?? [];
    final employeeName = employees.where((e) => e.id == employeeId).firstOrNull?.fullName ?? 'Unknown Employee';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LeaveSummarySection(employeeId: employeeId),
          const SizedBox(height: 32),
          PayslipsSection(employeeId: employeeId),
          const SizedBox(height: 32),
          DisciplinarySection(employeeId: employeeId, employeeName: employeeName),
        ],
      ),
    );
  }
}
