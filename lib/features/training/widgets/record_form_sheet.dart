import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';

class RecordFormSheet extends ConsumerStatefulWidget {
  const RecordFormSheet({super.key});

  @override
  ConsumerState<RecordFormSheet> createState() => _RecordFormSheetState();
}

class _RecordFormSheetState extends ConsumerState<RecordFormSheet> {
  bool _isSubmitting = false;
  final _empNameCtrl = TextEditingController();
  final _idNumCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  DateTime _completed = DateTime.now();
  DateTime _expiry = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _empNameCtrl.dispose();
    _idNumCtrl.dispose();
    _courseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRecord() async {
    if (_empNameCtrl.text.isEmpty || _courseCtrl.text.isEmpty) {
      UIUtils.showToast(
        context,
        'Please fill in required fields',
        type: ToastType.error,
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      final status = _expiry.isAfter(DateTime.now()) ? 'Active' : 'Expired';

      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            tenantId: ref.read(currentTenantIdProvider) ?? '',
            collection: 'training_records',
            data: {
              'employeeName': _empNameCtrl.text.trim(),
              'idNumber': _idNumCtrl.text.trim(),
              'courseName': _courseCtrl.text.trim(),
              'dateCompleted': _completed.toIso8601String(),
              'expiryDate': _expiry.toIso8601String(),
              'status': status,
              'authorId': profile.uid,
              'siteId': profile.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );

      if (mounted) {
        Navigator.pop(context); // Close side sheet
        UIUtils.showToast(context, 'Training record added successfully');
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _empNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Employee Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                GSpacing.vLg,
                TextFormField(
                  controller: _idNumCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ID / Payroll Number',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                GSpacing.vLg,
                TextFormField(
                  controller: _courseCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Course / Qualification *',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
                GSpacing.vLg,
                const Text(
                  'Certification Dates',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                GSpacing.vMd,
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _completed,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) {
                            setState(() => _completed = d);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Completed',
                          ),
                          child: Text(
                            '${_completed.day}/${_completed.month}/${_completed.year}',
                          ),
                        ),
                      ),
                    ),
                    GSpacing.hLg,
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _expiry,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                          );
                          if (d != null) {
                            setState(() => _expiry = d);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Expiry',
                          ),
                          child: Text(
                            '${_expiry.day}/${_expiry.month}/${_expiry.year}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        UIUtils.buildFormButtons(
          context: context,
          onSave: _submitRecord,
          isSubmitting: _isSubmitting,
        ),
      ],
    );
  }
}
