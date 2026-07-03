import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../../people/widgets/employee_selector.dart';

class AddContractorForm extends ConsumerStatefulWidget {
  final VoidCallback onCancel;

  const AddContractorForm({super.key, required this.onCancel});

  @override
  ConsumerState<AddContractorForm> createState() => _AddContractorFormState();
}

class _AddContractorFormState extends ConsumerState<AddContractorForm> {
  bool _isSub = false;
  final _nameCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _scopeCtrl = TextEditingController();
  String? _selectedContactPersonId;
  String _riskRating = 'Medium';
  String _status = 'Active';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _regCtrl.dispose();
    _scopeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            tenantId: ref.read(currentTenantIdProvider) ?? '',
            collection: 'contractors',
            data: {
              'companyName': _nameCtrl.text.trim(),
              'contactPersonId': _selectedContactPersonId,
              'registrationNumber': _regCtrl.text.trim(),
              'scopeOfWork': _scopeCtrl.text.trim(),
              'riskRating': _riskRating,
              'status': _status,
              'authorId': p.uid,
              'siteId': p.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        UIUtils.showToast(
          context,
          'Contractor added successfully',
          type: ToastType.success,
        );
        widget.onCancel();
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(
          context,
          'Failed to add contractor: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Contractor', style: Theme.of(context).textTheme.titleSmall),
          GSpacing.vMd,
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Company Name *'),
          ),
          GSpacing.vMd,
          Row(
            children: [
              Expanded(
                child: EmployeeSelector(
                  value: _selectedContactPersonId,
                  onChanged:
                      (val) => setState(() => _selectedContactPersonId = val),
                  label: 'Contact Person',
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: TextFormField(
                  controller: _regCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Registration No.',
                  ),
                ),
              ),
            ],
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _scopeCtrl,
            decoration: const InputDecoration(labelText: 'Scope of Work'),
          ),
          GSpacing.vMd,
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _riskRating,
                  decoration: const InputDecoration(
                    labelText: 'Risk Rating',
                    isDense: true,
                  ),
                  items:
                      ['Low', 'Medium', 'High', 'Critical']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _riskRating = v!),
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                  ),
                  items:
                      ['Active', 'Inactive', 'Suspended']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ),
            ],
          ),
          GSpacing.vLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSub ? null : _submit,
              child: Text(_isSub ? 'Saving…' : 'Add Contractor'),
            ),
          ),
        ],
      ),
    );
  }
}
