import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/providers/app_providers.dart';
import '../models/hr_models.dart';
import 'employee_selector.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class LeaveApplicationForm extends ConsumerStatefulWidget {
  const LeaveApplicationForm({super.key});

  @override
  ConsumerState<LeaveApplicationForm> createState() => _LeaveApplicationFormState();
}

class _LeaveApplicationFormState extends ConsumerState<LeaveApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  String? _managerId;
  String _leaveType = 'Annual';
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonCtrl = TextEditingController();
  bool _isLoading = false;

  final _leaveTypes = ['Annual', 'Sick', 'Maternity', 'OHS Mandatory', 'Unpaid'];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate != null && _endDate!.isBefore(date)) {
            _endDate = null;
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      UIUtils.showToast(context, 'Please select both start and end dates', type: ToastType.warning);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final siteId = ref.read(currentTenantIdProvider);
      final user = ref.read(userProfileProvider).valueOrNull;
      if (siteId == null) throw Exception('No site selected');
      
      final customId = 'LV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      
      final req = LeaveRequest(
        id: customId,
        employeeId: user?.uid ?? 'unknown',
        employeeName: user?.displayName ?? 'Current User',
        leaveType: _leaveType,
        startDate: _startDate!,
        endDate: _endDate!,
        status: 'Pending',
        managerId: _managerId,
        reason: _reasonCtrl.text.trim(),
        siteId: siteId,
      );
      
      await ref.read(firestoreProvider).tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'leave_requests').doc(customId).set(req.toFirestore());
      
      if (mounted) {
        UIUtils.showToast(context, 'Leave applied successfully', type: ToastType.success);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Failed to apply leave: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            DropdownButtonFormField<String>(
              value: _leaveType,
              decoration: const InputDecoration(
                labelText: 'Leave Type',
                border: OutlineInputBorder(),
              ),
              items: _leaveTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _leaveType = val!),
            ),
            const SizedBox(height: 16),
            EmployeeSelector(
              value: _managerId,
              label: 'Select Manager for Approval',
              onChanged: (val) => setState(() => _managerId = val),
              validator: (val) => val == null ? 'Please select a manager' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_startDate == null ? 'Select Date' : UIUtils.formatDate(_startDate!)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_endDate == null ? 'Select Date' : UIUtils.formatDate(_endDate!)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            UIUtils.buildFormButtons(
              context: context,
              onSave: _submit,
              isSubmitting: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
