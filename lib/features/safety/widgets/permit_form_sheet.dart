import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';

void showPermitForm(BuildContext context) {
  UIUtils.showSideSheet(
    context: context,
    title: 'Request New Permit',
    builder: (ctx) => const PermitFormContent(),
  );
}

class PermitFormContent extends ConsumerStatefulWidget {
  const PermitFormContent({super.key});

  @override
  ConsumerState<PermitFormContent> createState() => _PermitFormContentState();
}

class _PermitFormContentState extends ConsumerState<PermitFormContent> {
  bool _isSubmitting = false;

  // Form Fields
  String _type = 'Hot Work';
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _validFrom;
  DateTime? _validTo;
  bool _lotoRequired = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitPermit() async {
    if (_descriptionController.text.isEmpty || _locationController.text.isEmpty || _validFrom == null || _validTo == null) {
      UIUtils.showToast(context, 'Please fill all required fields', type: ToastType.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');

      final data = {
        'type': _type,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'validFrom': _validFrom!.toIso8601String(),
        'validTo': _validTo!.toIso8601String(),
        'lotoRequired': _lotoRequired,
        'status': 'Requested',
        'applicantId': profile.uid,
        'applicantName': profile.displayName,
        'siteId': profile.tenantId,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createDocument(tenantId: ref.read(currentTenantIdProvider) ?? '', collection: 'permits', data: data);

      if (mounted) {
        UIUtils.showToast(context, 'Permit request submitted successfully', type: ToastType.success);
        Navigator.pop(context); // Close side sheet
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(
              labelText: 'Permit Type *',
              prefixIcon: Icon(Icons.category_rounded),
            ),
            items: ['Hot Work', 'Working at Height', 'Confined Space', 'Excavation', 'Electrical', 'Other']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location *',
              prefixIcon: Icon(Icons.location_on_rounded),
            ),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description *',
              prefixIcon: Icon(Icons.description_rounded),
            ),
          ),
          GSpacing.vMd,
          
          // Date pickers
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.play_circle_outline),
            title: const Text('Valid From *'),
            subtitle: Text(_validFrom != null ? _formatDateTime(_validFrom!) : 'Tap to select'),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null && context.mounted) {
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (time != null && context.mounted) {
                  final full = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  setState(() => _validFrom = full);
                }
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.stop_circle_outlined),
            title: const Text('Valid To *'),
            subtitle: Text(_validTo != null ? _formatDateTime(_validTo!) : 'Tap to select'),
            onTap: () async {
              final initial = _validFrom ?? DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: initial,
                lastDate: initial.add(const Duration(days: 365)),
              );
              if (date != null && context.mounted) {
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (time != null && context.mounted) {
                  final full = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  setState(() => _validTo = full);
                }
              }
            },
          ),
          GSpacing.vMd,
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('LOTO Required'),
            subtitle: const Text('Lockout/Tagout isolation required'),
            value: _lotoRequired,
            onChanged: (v) => setState(() => _lotoRequired = v),
          ),
          GSpacing.vLg,

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitPermit,
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Request'),
            ),
          ),
        ],
      ),
    );
  }
}
