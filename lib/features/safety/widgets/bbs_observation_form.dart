import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../../people/widgets/employee_selector.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class BBSObservationForm extends ConsumerStatefulWidget {
  const BBSObservationForm({super.key});

  @override
  ConsumerState<BBSObservationForm> createState() => _BBSObservationFormState();
}

class _BBSObservationFormState extends ConsumerState<BBSObservationForm> {
  String? _observerId;
  final _locCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _interventionCtrl = TextEditingController();
  String _type = 'Safe Act';
  bool _isAnon = false;
  bool _isSubmitting = false;

  static const _types = ['Safe Act', 'Unsafe Act', 'Unsafe Condition'];

  @override
  void dispose() {
    _locCtrl.dispose();
    _descCtrl.dispose();
    _interventionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_locCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      UIUtils.showToast(
        context,
        'Location and description are required',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('User profile not loaded');

      final data = {
        'observationType': _type,
        'location': _locCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'interventionAction': _interventionCtrl.text.trim(),
        'observerId': _isAnon ? null : _observerId,
        'isAnonymous': _isAnon,
        'siteId': profile.tenantId,
        'authorId': profile.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'pointsAwarded': _type == 'Safe Act' ? 5 : 10,
      };

      await FirebaseFirestore.instance
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'bbs_observations',
          )
          .add(data);

      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'Observation recorded successfully');
        _locCtrl.clear();
        _descCtrl.clear();
        _interventionCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Observer Info', style: Theme.of(context).textTheme.titleSmall),
          GSpacing.vSm,
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isAnon,
            onChanged: (v) => setState(() => _isAnon = v),
            title: const Text(
              'Submit Anonymously',
              style: TextStyle(fontSize: 14),
            ),
            secondary: const Icon(Icons.visibility_off_rounded),
          ),
          if (!_isAnon) ...[
            GSpacing.vSm,
            EmployeeSelector(
              label: 'Observer Name',
              value: _observerId,
              onChanged: (val) => setState(() => _observerId = val),
            ),
          ],
          GSpacing.vLg,
          Text(
            'Observation Details',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          GSpacing.vSm,
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Type'),
            items:
                _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _locCtrl,
            decoration: const InputDecoration(
              labelText: 'Location / Area *',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'What did you observe? *',
              alignLabelWithHint: true,
            ),
          ),
          GSpacing.vMd,
          if (_type != 'Safe Act')
            TextFormField(
              controller: _interventionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Intervention Action Taken',
                hintText: 'What did you do to correct it?',
                alignLabelWithHint: true,
              ),
            ),
          UIUtils.buildFormButtons(
            context: context,
            onSave: _submit,
            isSubmitting: _isSubmitting,
          ),
        ],
      ),
    );
  }
}
