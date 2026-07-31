import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

class EmergencyContactFormCard extends ConsumerStatefulWidget {
  final VoidCallback onCancel;
  const EmergencyContactFormCard({super.key, required this.onCancel});

  @override
  ConsumerState<EmergencyContactFormCard> createState() => _EmergencyContactFormCardState();
}

class _EmergencyContactFormCardState extends ConsumerState<EmergencyContactFormCard> {
  bool _isSubmitting = false;
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _numberCtrl.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(
        tenantId: ref.read(currentTenantIdProvider) ?? '',
        collection: 'emergency_contacts',
        data: {
          'name': _nameCtrl.text.trim(),
          'number': _numberCtrl.text.trim(),
          'authorId': p.uid,
          'siteId': p.tenantId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        UIUtils.showToast(context, 'Contact added', type: ToastType.success);
        widget.onCancel();
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
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
              'Add Emergency Contact',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            GSpacing.vMd,
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name *', hintText: 'e.g. SHE Manager'),
            ),
            GSpacing.vMd,
            TextFormField(
              controller: _numberCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number *', hintText: 'e.g. 10111'),
              keyboardType: TextInputType.phone,
            ),
            GSpacing.vLg,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'Saving...' : 'Save Contact'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
