// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

class RegisterDocForm extends ConsumerStatefulWidget {
  const RegisterDocForm({super.key});

  @override
  ConsumerState<RegisterDocForm> createState() => _RegisterDocFormState();
}

class _RegisterDocFormState extends ConsumerState<RegisterDocForm> {
  bool _isSub = false;
  String _docType = 'Licence', _docStatus = 'Current';
  final _titleCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  DateTime _expiry = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _titleCtrl.dispose();
    _refCtrl.dispose();
    _ownerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (_titleCtrl.text.isEmpty) {
      UIUtils.showToast(
        context,
        'Document title is required',
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
            collection: 'compliance_documents',
            data: {
              'title': _titleCtrl.text.trim(),
              'referenceNumber': _refCtrl.text.trim(),
              'documentType': _docType,
              'status': _docStatus,
              'owner': _ownerCtrl.text.trim(),
              'expiryDate': _expiry.toIso8601String(),
              'daysUntilExpiry': _expiry.difference(DateTime.now()).inDays,
              'authorId': p.uid,
              'siteId': p.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'Document successfully registered');
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Document Title *',
              hintText: 'e.g., Forklift Operator License',
              prefixIcon: Icon(Icons.description_rounded),
            ),
          ),
          GSpacing.vMd,
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _refCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reference #',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: TextFormField(
                  controller: _ownerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Owner / Dept',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
              ),
            ],
          ),
          GSpacing.vMd,
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _docType,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items:
                      [
                            'Licence',
                            'Certificate',
                            'Permit',
                            'Policy',
                            'Procedure',
                            'Audit',
                            'Other',
                          ]
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _docType = v!),
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _docStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items:
                      ['Current', 'Under Review', 'Expired', 'Superseded']
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _docStatus = v!),
                ),
              ),
            ],
          ),
          GSpacing.vMd,
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _expiry,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime(2040),
              );
              if (d != null) setState(() => _expiry = d);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  GSpacing.hMd,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXPIRY DATE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${_expiry.day} ${UIUtils.getMonthName(_expiry.month)} ${_expiry.year}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          GSpacing.vXl,
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _isSub ? null : () => _submit(context),
              icon:
                  _isSub
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.app_registration_rounded),
              label: Text(_isSub ? 'REGISTERING...' : 'REGISTER DOCUMENT'),
            ),
          ),
          GSpacing.vXl,
        ],
      ),
    );
  }
}
