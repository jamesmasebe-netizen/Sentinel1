import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../../../core/utils/ui_utils.dart';

class SpillForm extends ConsumerStatefulWidget {
  const SpillForm({super.key});

  @override
  ConsumerState<SpillForm> createState() => _SpillFormState();
}

class _SpillFormState extends ConsumerState<SpillForm> {
  final _substanceCtrl = TextEditingController();
  final _volCtrl = TextEditingController();
  final _spillLocCtrl = TextEditingController();
  bool _contained = false;
  bool _reported = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _substanceCtrl.dispose();
    _volCtrl.dispose();
    _spillLocCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitSpill() async {
    if (_substanceCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Substance is required', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(
        tenantId: ref.read(currentTenantIdProvider) ?? '',
        collection: 'environmental_spills',
        data: {
          'substance': _substanceCtrl.text.trim(),
          'volume': _volCtrl.text.trim(),
          'location': _spillLocCtrl.text.trim(),
          'contained': _contained,
          'reportedToAuthorities': _reported,
          'authorId': p.uid,
          'siteId': p.tenantId,
          'dateOfSpill': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'Environmental spill logged successfully');
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
            controller: _substanceCtrl,
            decoration: const InputDecoration(labelText: 'Substance Spilled *', prefixIcon: Icon(Icons.opacity)),
          ),
          GSpacing.vMd,
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _volCtrl,
                  decoration: const InputDecoration(labelText: 'Volume / Qty'),
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: TextFormField(
                  controller: _spillLocCtrl,
                  decoration: const InputDecoration(labelText: 'Specific Location', prefixIcon: Icon(Icons.place_outlined)),
                ),
              ),
            ],
          ),
          GSpacing.vMd,
          SwitchListTile(
            value: _contained,
            onChanged: (v) => setState(() => _contained = v),
            title: const Text('Was the spill contained?', style: TextStyle(fontSize: 14)),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _reported,
            onChanged: (v) => setState(() => _reported = v),
            title: const Text('Reported to Authorities?', style: TextStyle(fontSize: 14)),
            contentPadding: EdgeInsets.zero,
          ),
          GSpacing.vLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submitSpill,
              child: Text(_isSubmitting ? 'Logging Spill...' : 'Log Spill'),
            ),
          ),
        ],
      ),
    );
  }
}
