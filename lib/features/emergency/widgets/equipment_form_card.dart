import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../../../core/utils/ui_utils.dart';

class EquipmentFormCard extends ConsumerStatefulWidget {
  final VoidCallback onCancel;
  const EquipmentFormCard({super.key, required this.onCancel});

  @override
  ConsumerState<EquipmentFormCard> createState() => _EquipmentFormCardState();
}

class _EquipmentFormCardState extends ConsumerState<EquipmentFormCard> {
  bool _isSubmitting = false;

  String _equipType = 'Extinguisher';
  String _equipStatus = 'Operational';
  final _equipLocCtrl = TextEditingController();
  final _inspDateCtrl = TextEditingController();

  @override
  void dispose() {
    _equipLocCtrl.dispose();
    _inspDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEquipment() async {
    if (_equipLocCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            tenantId: ref.read(currentTenantIdProvider) ?? '',
            collection: 'emergency_equipment',
            data: {
              'equipmentType': _equipType,
              'location': _equipLocCtrl.text.trim(),
              'nextInspectionDate': _inspDateCtrl.text.trim(),
              'status': _equipStatus,
              'authorId': p.uid,
              'siteId': p.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        UIUtils.showToast(context, 'Equipment added', type: ToastType.success);
        widget.onCancel();
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, '$e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Equipment',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            GSpacing.vMd,
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _equipType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items:
                        [
                              'Extinguisher',
                              'First Aid Kit',
                              'Spill Kit',
                              'AED',
                              'Other',
                            ]
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _equipType = v!),
                  ),
                ),
                GSpacing.hMd,
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _equipStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items:
                        ['Operational', 'Needs Inspection', 'Out of Service']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _equipStatus = v!),
                  ),
                ),
              ],
            ),
            GSpacing.vMd,
            TextFormField(
              controller: _equipLocCtrl,
              decoration: const InputDecoration(labelText: 'Location *'),
            ),
            GSpacing.vMd,
            TextFormField(
              controller: _inspDateCtrl,
              decoration: const InputDecoration(
                labelText: 'Next Inspection Date',
                hintText: 'YYYY-MM-DD',
              ),
            ),
            GSpacing.vLg,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitEquipment,
                child: Text(_isSubmitting ? 'Saving...' : 'Save Equipment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
