import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/widgets/entity_selector.dart';
import '../../../core/utils/ui_utils.dart';
import '../../property/models/property_models.dart';
import '../../property/providers/property_providers.dart';
import '../models/emergency_drill.dart';
import '../services/emergency_service.dart';

class DrillFormCard extends ConsumerStatefulWidget {
  final VoidCallback onCancel;
  const DrillFormCard({super.key, required this.onCancel});

  @override
  ConsumerState<DrillFormCard> createState() => _DrillFormCardState();
}

class _DrillFormCardState extends ConsumerState<DrillFormCard> {
  bool _isSubmitting = false;

  String _drillType = 'Fire';
  final _dateCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _evalCtrl = TextEditingController();
  final _scenarioCtrl = TextEditingController();
  final _improvementsCtrl = TextEditingController();
  String? _propertyId;

  @override
  void dispose() {
    _dateCtrl.dispose();
    _durationCtrl.dispose();
    _evalCtrl.dispose();
    _scenarioCtrl.dispose();
    _improvementsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitDrill() async {
    if (_scenarioCtrl.text.isEmpty) return;
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
      await ref.read(emergencyServiceProvider).createDrill(
            EmergencyDrill(
              id: '',
              drillType: _drillType,
              dateConducted: _dateCtrl.text.trim(),
              durationMinutes: int.tryParse(_durationCtrl.text) ?? 0,
              evaluatorName: _evalCtrl.text.trim(),
              scenarioDescription: _scenarioCtrl.text.trim(),
              areasForImprovement: _improvementsCtrl.text.trim(),
              authorId: p.uid,
              propertyId: _propertyId,
              propertyName: propertyName,
              createdAt: DateTime.now(),
            ),
          );
      if (mounted) {
        UIUtils.showToast(context, 'Drill logged', type: ToastType.success);
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
              'Log Emergency Drill',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            GSpacing.vMd,
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _drillType,
                    decoration: const InputDecoration(labelText: 'Drill Type'),
                    items:
                        [
                              'Fire',
                              'Medical',
                              'Spill',
                              'Security',
                              'Evacuation',
                              'Other',
                            ]
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _drillType = v!),
                  ),
                ),
                GSpacing.hMd,
                Expanded(
                  child: TextFormField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (mins)',
                    ),
                  ),
                ),
              ],
            ),
            GSpacing.vMd,
            TextFormField(
              controller: _scenarioCtrl,
              decoration: const InputDecoration(
                labelText: 'Scenario Description *',
              ),
            ),
            GSpacing.vMd,
            TextFormField(
              controller: _evalCtrl,
              decoration: const InputDecoration(labelText: 'Evaluator Name'),
            ),
            GSpacing.vMd,
            TextFormField(
              controller: _improvementsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Areas for Improvement',
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
                onPressed: _isSubmitting ? null : _submitDrill,
                child: Text(_isSubmitting ? 'Saving...' : 'Save Drill'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
