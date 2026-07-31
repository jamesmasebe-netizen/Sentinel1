import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../models/hr_models.dart';

class DisciplinaryRecordForm extends ConsumerStatefulWidget {
  final String employeeId;
  final String employeeName;
  const DisciplinaryRecordForm({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  ConsumerState<DisciplinaryRecordForm> createState() =>
      _DisciplinaryRecordFormState();
}

class _DisciplinaryRecordFormState extends ConsumerState<DisciplinaryRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  String _actionType = 'Verbal Warning';
  DateTime _dateIssued = DateTime.now();
  bool _isLoading = false;

  static const _actionTypes = [
    'Verbal Warning',
    'Written Warning',
    'Final Written Warning',
    'Suspension',
    'Dismissal',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      final siteId = ref.read(currentTenantIdProvider);
      if (profile == null || siteId == null) throw Exception('Not signed in');

      final record = DisciplinaryRecord(
        employeeId: widget.employeeId,
        employeeName: widget.employeeName,
        actionType: _actionType,
        description: _descCtrl.text.trim(),
        dateIssued: _dateIssued,
        issuedByName: profile.displayName,
        siteId: siteId,
      );

      await ref
          .read(firestoreProvider)
          .tenantCollection(siteId, 'disciplinary_records')
          .add(record.toFirestore());

      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'Disciplinary action logged', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            DropdownButtonFormField<String>(
              value: _actionType,
              decoration: const InputDecoration(labelText: 'Action Type'),
              items: _actionTypes
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _actionType = v!),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date Issued'),
              subtitle: Text('${_dateIssued.toLocal()}'.split(' ').first),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dateIssued,
                  firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _dateIssued = picked);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description / Reason *',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Log Disciplinary Action'),
            ),
          ],
        ),
      ),
    );
  }
}
