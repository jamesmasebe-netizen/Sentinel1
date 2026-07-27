import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../../people/widgets/employee_selector.dart';

class PPEIssuanceForm extends ConsumerStatefulWidget {
  final VoidCallback onCancel;
  const PPEIssuanceForm({super.key, required this.onCancel});

  @override
  ConsumerState<PPEIssuanceForm> createState() => _PPEIssuanceFormState();
}

class _PPEIssuanceFormState extends ConsumerState<PPEIssuanceForm> {
  bool _isSubmitting = false;

  String? _employeeId;
  String _ppeType = 'Hard Hat';
  String _status = 'Compliant';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  static const _ppeTypes = [
    'Hard Hat',
    'Safety Boots',
    'Hi-Vis Vest',
    'Safety Glasses',
    'Gloves',
    'Ear Protection',
    'Harness',
    'Respirator',
  ];
  final bool _isCompliant = true;
  final List<String> _missingItems = [];
  final _commentsController = TextEditingController();
  static const _statuses = ['Compliant', 'Non-Compliant', 'Expired'];

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitLog() async {
    if (_employeeId == null) {
      UIUtils.showToast(
        context,
        'Please enter employee name',
        type: ToastType.error,
      );
      return;
    }

    final role = ref.read(userRoleProvider);
    final canIssue = role == 'admin' || role == 'executive' || role == 'sheq';
    if (!canIssue) {
      UIUtils.showToast(
        context,
        'You do not have permission to log PPE',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');

      final data = {
        'employeeId': _employeeId,
        'ppeType': _ppeType,
        'status': _status,
        'expiryDate': _expiryDate.toIso8601String(),
        'isCompliant': _isCompliant,
        'missingItems': _missingItems,
        'comments': _commentsController.text.trim(),
        'siteId': profile.tenantId,
        'loggedById': profile.uid,
        'loggedByName': profile.displayName,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createDocument(
        tenantId: ref.read(currentTenantIdProvider) ?? '',
        collection: 'ppe_compliance',
        data: data,
      );

      if (mounted) {
        UIUtils.showToast(
          context,
          'PPE check recorded successfully',
          type: ToastType.success,
        );
        widget.onCancel();
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
    return GCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log PPE Compliance',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            GSpacing.vMd,
            EmployeeSelector(
              label: 'Employee Name *',
              value: _employeeId,
              onChanged: (val) => setState(() => _employeeId = val),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _ppeType,
                    decoration: const InputDecoration(
                      labelText: 'PPE Type',
                      isDense: true,
                    ),
                    items:
                        _ppeTypes
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _ppeType = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      isDense: true,
                    ),
                    items:
                        _statuses
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
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Expiry Date'),
              subtitle: Text(
                '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}',
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _expiryDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 1825)),
                );
                if (d != null) setState(() => _expiryDate = d);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : () => _submitLog(),
                icon:
                    _isSubmitting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save),
                label: Text(_isSubmitting ? 'Saving...' : 'Save Record'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
