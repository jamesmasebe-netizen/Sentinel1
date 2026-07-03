import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../../../core/utils/ui_utils.dart';

class FirstAidForm extends ConsumerStatefulWidget {
  const FirstAidForm({super.key});

  @override
  ConsumerState<FirstAidForm> createState() => _FirstAidFormState();
}

class _FirstAidFormState extends ConsumerState<FirstAidForm> {
  bool _isSub = false;

  final _faEmpCtrl = TextEditingController();
  final _faDescCtrl = TextEditingController();
  final _faTreatCtrl = TextEditingController();

  @override
  void dispose() {
    _faEmpCtrl.dispose();
    _faDescCtrl.dispose();
    _faTreatCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitFirstAid() async {
    if (_faEmpCtrl.text.isEmpty) {
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
            collection: 'first_aid_logs',
            data: {
              'employeeName': _faEmpCtrl.text.trim(),
              'description': _faDescCtrl.text.trim(),
              'treatment': _faTreatCtrl.text.trim(),
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
          TextFormField(
            controller: _faEmpCtrl,
            decoration: const InputDecoration(
              labelText: 'Employee / Person *',
              prefixIcon: Icon(Icons.person_outline),
            ),
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
