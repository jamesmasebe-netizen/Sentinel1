import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../../../core/utils/ui_utils.dart';

class HygieneForm extends ConsumerStatefulWidget {
  const HygieneForm({super.key});

  @override
  ConsumerState<HygieneForm> createState() => _HygieneFormState();
}

class _HygieneFormState extends ConsumerState<HygieneForm> {
  bool _isSub = false;

  final _zoneCtrl = TextEditingController();
  final _readingCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  String _hazardType = 'Noise';
  bool _requiresSurveillance = false;

  @override
  void dispose() {
    _zoneCtrl.dispose();
    _readingCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitHygiene() async {
    if (_zoneCtrl.text.isEmpty) {
      UIUtils.showToast(
        context,
        'Zone name is required',
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
            collection: 'hygiene_surveys',
            data: {
              'zoneName': _zoneCtrl.text.trim(),
              'hazardType': _hazardType,
              'readingValue': _readingCtrl.text.trim(),
              'legalLimit': _limitCtrl.text.trim(),
              'requiresMedicalSurveillance': _requiresSurveillance,
              'dateConducted': DateTime.now().toIso8601String(),
              'authorId': p.uid,
              'siteId': p.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        Navigator.pop(context); // Close SideSheet
        UIUtils.showToast(context, 'Hygiene survey saved successfully');
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _zoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Zone / Area *',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          GSpacing.vMd,
          DropdownButtonFormField<String>(
            value: _hazardType,
            decoration: const InputDecoration(labelText: 'Hazard Type'),
            items:
                [
                      'Noise',
                      'Dust',
                      'Chemical',
                      'Ergonomic',
                      'Illumination',
                      'Thermal',
                      'Other',
                    ]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
            onChanged: (v) => setState(() => _hazardType = v!),
          ),
          GSpacing.vMd,
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _readingCtrl,
                  decoration: const InputDecoration(labelText: 'Reading Value'),
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: TextFormField(
                  controller: _limitCtrl,
                  decoration: const InputDecoration(labelText: 'Legal Limit'),
                ),
              ),
            ],
          ),
          GSpacing.vMd,
          SwitchListTile(
            value: _requiresSurveillance,
            onChanged: (v) => setState(() => _requiresSurveillance = v),
            title: const Text(
              'Requires Medical Surveillance?',
              style: TextStyle(fontSize: 14),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          GSpacing.vLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSub ? null : _submitHygiene,
              child: Text(_isSub ? 'Saving…' : 'Save Survey'),
            ),
          ),
        ],
      ),
    );
  }
}
