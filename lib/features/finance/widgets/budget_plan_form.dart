import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../models/finance_models.dart';
import '../services/finance_service.dart';

class BudgetPlanForm extends ConsumerStatefulWidget {
  const BudgetPlanForm({super.key});

  @override
  ConsumerState<BudgetPlanForm> createState() => _BudgetPlanFormState();
}

class _BudgetPlanFormState extends ConsumerState<BudgetPlanForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _fiscalYearCtrl = TextEditingController(text: '${DateTime.now().year}');
  final _plannedAmountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _fiscalPeriod = 'Q1';
  String _status = 'Draft';
  bool _isSubmitting = false;

  static const _periods = ['Q1', 'Q2', 'Q3', 'Q4', 'Annual'];
  static const _statuses = ['Draft', 'Active', 'Closed', 'Exceeded'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fiscalYearCtrl.dispose();
    _plannedAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final plan = BudgetPlan(
        id: 'BUD-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        fiscalYear: _fiscalYearCtrl.text.trim(),
        fiscalPeriod: _fiscalPeriod,
        plannedAmount: double.tryParse(_plannedAmountCtrl.text.trim()) ?? 0.0,
        actualAmount: 0.0,
        variance: 0.0,
        variancePercentage: 0.0,
        status: _status,
        notes: _notesCtrl.text.trim(),
        createdBy: ref.read(userProfileProvider).valueOrNull?.uid,
      );
      await ref.read(financeServiceProvider).createBudgetPlan(plan);
      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'Budget plan created', type: ToastType.success);
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
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Plan Name *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fiscalYearCtrl,
                    decoration: const InputDecoration(labelText: 'Fiscal Year *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _fiscalPeriod,
                    decoration: const InputDecoration(labelText: 'Fiscal Period'),
                    items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setState(() => _fiscalPeriod = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plannedAmountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Planned Amount *'),
              validator: (v) => double.tryParse(v?.trim() ?? '') == null ? 'Enter a valid number' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Budget Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
