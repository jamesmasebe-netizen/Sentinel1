import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../../../core/utils/ui_utils.dart';

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
      await ref.read(firestoreServiceProvider).createDocument(
            tenantId: ref.read(currentTenantIdProvider) ?? '',
            collection: 'emergency_drills',
        data: {
          'drillType': _drillType,
          'dateConducted': _dateCtrl.text.trim(),
          'durationMinutes': int.tryParse(_durationCtrl.text) ?? 0,
          'evaluatorName': _evalCtrl.text.trim(),
          'scenarioDescription': _scenarioCtrl.text.trim(),
          'areasForImprovement': _improvementsCtrl.text.trim(),
          'authorId': p.uid,
          'siteId': p.tenantId,
          'createdAt': DateTime.now().toIso8601String(),
        },
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
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            GSpacing.vMd,
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _drillType,
                    decoration: const InputDecoration(
                      labelText: 'Drill Type',
                    ),
                    items: [
                      'Fire',
                      'Medical',
                      'Spill',
                      'Security',
                      'Evacuation',
                      'Other',
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
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
              decoration: const InputDecoration(
                labelText: 'Evaluator Name',
              ),
            ),
            GSpacing.vMd,
            TextFormField(
              controller: _improvementsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Areas for Improvement',
              ),
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
