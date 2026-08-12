import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/widgets/entity_selector.dart';
import '../../../core/utils/ui_utils.dart';
import '../../property/models/property_models.dart';
import '../../property/providers/property_providers.dart';
import '../models/emergency_equipment.dart';
import '../services/emergency_service.dart';

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
  String? _propertyId;

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
      String? propertyName;
      if (_propertyId != null) {
        final properties = ref.read(propertiesProvider).valueOrNull ?? [];
        for (final prop in properties) {
          if (prop.id == _propertyId) {
            propertyName = prop.name;
            break;
          }
        }
      }
      await ref.read(emergencyServiceProvider).createEquipment(
            EmergencyEquipment(
              id: '',
              equipmentType: _equipType,
              location: _equipLocCtrl.text.trim(),
              nextInspectionDate: _inspDateCtrl.text.trim(),
              status: _equipStatus,
              authorId: p.uid,
              propertyId: _propertyId,
              propertyName: propertyName,
              createdAt: DateTime.now(),
            ),
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
            GSpacing.vMd,
            EntitySelector<Property>(
              value: _propertyId,
              onChanged: (val) => setState(() => _propertyId = val),
              label: 'Site / Property (optional)',
              asyncEntities: ref.watch(propertiesProvider),
              idMapper: (p) => p.id,
              displayMapper: (p) => p.name,
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
