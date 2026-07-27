import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../people/widgets/employee_selector.dart';

class FirstAidForm extends ConsumerStatefulWidget {
  const FirstAidForm({super.key});

  @override
  ConsumerState<FirstAidForm> createState() => _FirstAidFormState();
}

class _FirstAidFormState extends ConsumerState<FirstAidForm> {
  bool _isSub = false;

  String? _patientId;
  String? _firstAiderId;
  final _faDescCtrl = TextEditingController();
  final _faTreatCtrl = TextEditingController();
  final _actionTakenCtrl = TextEditingController();
  bool _referredToMedical = false;

  @override
  void dispose() {
    _faDescCtrl.dispose();
    _faTreatCtrl.dispose();
    _actionTakenCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitFirstAid() async {
    if (_patientId == null || _firstAiderId == null) {
      UIUtils.showToast(
        context,
        'Patient and First Aider are required',
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
            collection: 'first_aid_logs',
            data: {
              'patientId': _patientId,
              'firstAiderId': _firstAiderId,
              'description': _faDescCtrl.text.trim(),
              'treatment': _faTreatCtrl.text.trim(),
              'actionTaken': _actionTakenCtrl.text.trim(),
              'referredToMedical': _referredToMedical,
              'date': DateTime.now().toIso8601String(),
              'authorId': p.uid,
              'siteId': p.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        Navigator.pop(context); // Close SideSheet
        UIUtils.showToast(context, 'First aid entry saved successfully');
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
          EmployeeSelector(
            value: _patientId,
            onChanged: (val) {
              setState(() => _patientId = val);
            },
            label: 'Patient (Employee) *',
          ),
          GSpacing.vMd,
          EmployeeSelector(
            value: _firstAiderId,
            onChanged: (val) {
              setState(() => _firstAiderId = val);
            },
            label: 'First Aider *',
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _faDescCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Injury / Complaint Description',
            ),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _faTreatCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Treatment Provided'),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _actionTakenCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Action Taken'),
          ),
          GSpacing.vMd,
          SwitchListTile(
            value: _referredToMedical,
            onChanged: (v) => setState(() => _referredToMedical = v),
            title: const Text(
              'Referred to Medical?',
              style: TextStyle(fontSize: 14),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          GSpacing.vXl,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSub ? null : _submitFirstAid,
              child: Text(_isSub ? 'Saving…' : 'Save Entry'),
            ),
          ),
        ],
      ),
    );
  }
}
