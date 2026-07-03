import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../models/hr_models.dart';
import '../providers/employee_providers.dart';
import 'employee_selector.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class ManualPayslipForm extends ConsumerStatefulWidget {
  const ManualPayslipForm({super.key});

  @override
  ConsumerState<ManualPayslipForm> createState() => ManualPayslipFormState();
}

class ManualPayslipFormState extends ConsumerState<ManualPayslipForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  String? _employeeName;
  double _baseSalary = 0.0;
  double _bonuses = 0.0;
  double _deductions = 0.0;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeId == null) {
      UIUtils.showToast(context, 'Please select an employee', type: ToastType.error);
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final siteId = ref.read(currentTenantIdProvider);
      if (siteId == null) throw Exception('No site ID found');

      final now = DateTime.now();
      // Period start is first day of current month, end is last day
      final periodStart = DateTime(now.year, now.month, 1);
      final periodEnd = DateTime(now.year, now.month + 1, 0);

      final docRef = FirebaseFirestore.instance.tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'payroll_ledgers').doc();
      
      final ledger = PayrollLedger(
        id: docRef.id,
        employeeId: _selectedEmployeeId!,
        employeeName: _employeeName ?? 'Unknown Employee',
        baseSalary: _baseSalary,
        bonuses: _bonuses,
        deductions: _deductions,
        periodStart: periodStart,
        periodEnd: periodEnd,
        status: 'Processed',
        siteId: siteId,
      );

      await docRef.set(ledger.toFirestore());

      if (mounted) {
        UIUtils.showToast(context, 'Payslip generated successfully', type: ToastType.success);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Failed to generate payslip: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            EmployeeSelector(
              value: _selectedEmployeeId,
              onChanged: (val) {
                setState(() {
                  _selectedEmployeeId = val;
                });
                // Find employee name if possible, simplified for now
                final employees = ref.read(employeesProvider).valueOrNull;
                if (employees != null && val != null) {
                  final emp = employees.firstWhere((e) => e.id == val);
                  _employeeName = emp.fullName;
                }
              },
              validator: (val) => val == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Base Salary', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              onSaved: (val) => _baseSalary = double.tryParse(val ?? '0') ?? 0.0,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Bonuses', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              initialValue: '0.0',
              onSaved: (val) => _bonuses = double.tryParse(val ?? '0') ?? 0.0,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Deductions', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              initialValue: '0.0',
              onSaved: (val) => _deductions = double.tryParse(val ?? '0') ?? 0.0,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Generate Payslip'),
            ),
          ],
        ),
      ),
    );
  }
}
