import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/providers/app_providers.dart';
import '../models/hr_models.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class BenefitEnrollmentForm extends ConsumerStatefulWidget {
  final BenefitEnrollment? initialData;

  const BenefitEnrollmentForm({super.key, this.initialData});

  @override
  ConsumerState<BenefitEnrollmentForm> createState() => _BenefitEnrollmentFormState();
}

class _BenefitEnrollmentFormState extends ConsumerState<BenefitEnrollmentForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _planIdCtrl;
  late TextEditingController _planTypeCtrl;
  late TextEditingController _coverageTierCtrl;
  late TextEditingController _employeeContribCtrl;
  late TextEditingController _employerContribCtrl;
  late TextEditingController _dependentsCtrl;
  DateTime? _effectiveDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _planIdCtrl = TextEditingController(text: widget.initialData?.planId ?? '');
    _planTypeCtrl = TextEditingController(text: widget.initialData?.planType ?? '');
    _coverageTierCtrl = TextEditingController(text: widget.initialData?.coverageTier ?? '');
    _employeeContribCtrl = TextEditingController(text: widget.initialData?.employeeContribution.toString() ?? '');
    _employerContribCtrl = TextEditingController(text: widget.initialData?.employerContribution.toString() ?? '');
    _dependentsCtrl = TextEditingController(text: widget.initialData?.dependentsCovered.join(', ') ?? '');
    _effectiveDate = widget.initialData?.effectiveDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _planIdCtrl.dispose();
    _planTypeCtrl.dispose();
    _coverageTierCtrl.dispose();
    _employeeContribCtrl.dispose();
    _employerContribCtrl.dispose();
    _dependentsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final siteId = ref.read(currentTenantIdProvider);
      if (siteId == null) throw Exception('No site selected');

      final enrollment = BenefitEnrollment(
        id: widget.initialData?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        planId: _planIdCtrl.text.trim(),
        planType: _planTypeCtrl.text.trim(),
        coverageTier: _coverageTierCtrl.text.trim(),
        status: widget.initialData?.status ?? 'Active',
        effectiveDate: _effectiveDate,
        dependentsCovered: _dependentsCtrl.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        employeeContribution: double.tryParse(_employeeContribCtrl.text.trim()) ?? 0.0,
        employerContribution: double.tryParse(_employerContribCtrl.text.trim()) ?? 0.0,
      );

      await ref
          .read(firestoreProvider)
          .tenantCollection(siteId, 'benefit_enrollments')
          .doc(enrollment.id)
          .set(enrollment.toJson());

      if (mounted) {
        UIUtils.showToast(context, 'Benefit Enrollment saved', type: ToastType.success);
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
              controller: _planIdCtrl,
              decoration: const InputDecoration(labelText: 'Plan ID', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _planTypeCtrl,
              decoration: const InputDecoration(labelText: 'Plan Type (e.g. Medical, Dental)', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _coverageTierCtrl,
              decoration: const InputDecoration(labelText: 'Coverage Tier (e.g. Employee Only, Family)', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _employeeContribCtrl,
              decoration: const InputDecoration(labelText: 'Employee Contribution (\$)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _employerContribCtrl,
              decoration: const InputDecoration(labelText: 'Employer Contribution (\$)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dependentsCtrl,
              decoration: const InputDecoration(labelText: 'Dependents (Comma-separated names)', border: OutlineInputBorder()),
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
