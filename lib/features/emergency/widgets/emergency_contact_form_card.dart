import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/widgets/entity_selector.dart';
import '../../../core/utils/ui_utils.dart';
import '../../property/models/property_models.dart';
import '../../property/providers/property_providers.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_service.dart';

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
  String? _propertyId;

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
      await ref.read(emergencyServiceProvider).createContact(
        EmergencyContact(
          id: '',
          name: _nameCtrl.text.trim(),
          number: _numberCtrl.text.trim(),
          authorId: p.uid,
          siteId: p.tenantId ?? '',
          propertyId: _propertyId,
          propertyName: propertyName,
          createdAt: DateTime.now(),
        ),
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
