import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../../people/widgets/employee_selector.dart';
import '../models/finance_models.dart';
import '../services/finance_service.dart';

class CostCenterForm extends ConsumerStatefulWidget {
  const CostCenterForm({super.key});

  @override
  ConsumerState<CostCenterForm> createState() => _CostCenterFormState();
}

class _CostCenterFormState extends ConsumerState<CostCenterForm> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _totalBudgetCtrl = TextEditingController();
  String? _managerId;
  bool _isActive = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _totalBudgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final center = CostCenter(
        id: 'CC-${DateTime.now().millisecondsSinceEpoch}',
        code: _codeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        managerId: _managerId,
        isActive: _isActive,
        totalBudget: double.tryParse(_totalBudgetCtrl.text.trim()) ?? 0.0,
        totalSpend: 0.0,
      );
      await ref.read(financeServiceProvider).createCostCenter(center);
      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'Cost center created', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'Cost Center Code *', hintText: 'e.g. CC-OPS-01'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            EmployeeSelector(
              label: 'Manager',
              value: _managerId,
              onChanged: (val) => setState(() => _managerId = val),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalBudgetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Total Budget'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Cost Center'),
            ),
          ],
        ),
      ),
    );
  }
}
