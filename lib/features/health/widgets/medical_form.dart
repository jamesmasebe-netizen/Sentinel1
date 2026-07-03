import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../../../core/utils/ui_utils.dart';

class MedicalForm extends ConsumerStatefulWidget {
  const MedicalForm({super.key});

  @override
  ConsumerState<MedicalForm> createState() => _MedicalFormState();
}

class _MedicalFormState extends ConsumerState<MedicalForm> {
  bool _isSub = false;

  final _medEmpCtrl = TextEditingController();
  final _medIdCtrl = TextEditingController();
  final _medRestCtrl = TextEditingController();
  String _medType = 'Pre-employment';
  String _medStatus = 'Fit';
  DateTime _medDate = DateTime.now();
  DateTime _medNextDue = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _medEmpCtrl.dispose();
    _medIdCtrl.dispose();
    _medRestCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitMedical() async {
    if (_medEmpCtrl.text.isEmpty) {
      UIUtils.showToast(
        context,
        'Employee name is required',
        type: ToastType.error,
      );
      return;
    }
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            tenantId: ref.read(currentTenantIdProvider) ?? '',
            collection: 'medical_records',
            data: {
              'employeeName': _medEmpCtrl.text.trim(),
              'idNumber': _medIdCtrl.text.trim(),
              'medicalType': _medType,
              'status': _medStatus,
              'restrictions': _medRestCtrl.text.trim(),
              'dateConducted': _medDate.toIso8601String(),
              'nextDueDate': _medNextDue.toIso8601String(),
              'authorId': p.uid,
              'siteId': p.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        Navigator.pop(context); // Close SideSheet
        UIUtils.showToast(context, 'Medical record saved successfully');
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Employee Details',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          GSpacing.vSm,
          TextFormField(
            controller: _medEmpCtrl,
            decoration: const InputDecoration(
              labelText: 'Employee Name *',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _medIdCtrl,
            decoration: const InputDecoration(
              labelText: 'ID / Employee Number',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          GSpacing.vLg,
          Text(
            'Examination Info',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          GSpacing.vSm,
          DropdownButtonFormField<String>(
            value: _medType,
            decoration: const InputDecoration(labelText: 'Exam Type'),
            items:
                ['Pre-employment', 'Annual', 'Exit', 'Baseline', 'Other']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
            onChanged: (v) => setState(() => _medType = v!),
          ),
          GSpacing.vMd,
          DropdownButtonFormField<String>(
            value: _medStatus,
            decoration: const InputDecoration(labelText: 'Fitness Status'),
            items:
                ['Fit', 'Fit with Restrictions', 'Unfit']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
            onChanged: (v) => setState(() => _medStatus = v!),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _medRestCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Restrictions / Comments',
            ),
          ),
          GSpacing.vLg,
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conducted On',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GSpacing.vSm,
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _medDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => _medDate = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            GSpacing.hSm,
                            Text(UIUtils.formatDate(_medDate)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Due',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GSpacing.vSm,
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _medNextDue,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 1825),
                          ),
                        );
                        if (d != null) setState(() => _medNextDue = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_repeat, size: 16),
                            GSpacing.hSm,
                            Text(UIUtils.formatDate(_medNextDue)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          GSpacing.vLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSub ? null : _submitMedical,
              child: Text(_isSub ? 'Saving…' : 'Save Record'),
            ),
          ),
        ],
      ),
    );
  }
}
