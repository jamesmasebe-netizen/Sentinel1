import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/providers/app_providers.dart';
import '../models/hr_models.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class CompensationPlanForm extends ConsumerStatefulWidget {
  final CompensationPlan? initialData;

  const CompensationPlanForm({super.key, this.initialData});

  @override
  ConsumerState<CompensationPlanForm> createState() => _CompensationPlanFormState();
}

class _CompensationPlanFormState extends ConsumerState<CompensationPlanForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _targetPercentCtrl;
  late TextEditingController _vestingCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialData?.name ?? '');
    _typeCtrl = TextEditingController(text: widget.initialData?.type ?? '');
    _targetPercentCtrl = TextEditingController(text: widget.initialData?.targetPercentage.toString() ?? '');
    _vestingCtrl = TextEditingController(text: widget.initialData?.vestingScheduleId ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _targetPercentCtrl.dispose();
    _vestingCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final siteId = ref.read(currentTenantIdProvider);
      if (siteId == null) throw Exception('No site selected');

      final plan = CompensationPlan(
        id: widget.initialData?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtrl.text.trim(),
        type: _typeCtrl.text.trim(),
        eligibilityRules: widget.initialData?.eligibilityRules ?? {},
        targetPercentage: double.tryParse(_targetPercentCtrl.text.trim()) ?? 0.0,
        vestingScheduleId: _vestingCtrl.text.trim().isEmpty ? null : _vestingCtrl.text.trim(),
      );

      await ref
          .read(firestoreProvider)
          .tenantCollection(siteId, 'compensation_plans')
          .doc(plan.id)
          .set(plan.toJson());

      if (mounted) {
        UIUtils.showToast(context, 'Compensation Plan saved', type: ToastType.success);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
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
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Plan Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _typeCtrl,
              decoration: const InputDecoration(labelText: 'Plan Type (e.g. Bonus, Equity)', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetPercentCtrl,
              decoration: const InputDecoration(labelText: 'Target Percentage', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vestingCtrl,
              decoration: const InputDecoration(labelText: 'Vesting Schedule ID (Optional)', border: OutlineInputBorder()),
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
