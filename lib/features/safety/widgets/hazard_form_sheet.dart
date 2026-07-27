import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';

class HazardFormSheet extends ConsumerStatefulWidget {
  const HazardFormSheet({super.key});

  @override
  ConsumerState<HazardFormSheet> createState() => _HazardFormSheetState();
}

class _HazardFormSheetState extends ConsumerState<HazardFormSheet> {
  bool _isSubmitting = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _severity = 'Low';
  final _severities = const ['Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitHazard() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      UIUtils.showToast(
        context,
        'Please fill all required fields',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');

      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'severity': _severity,
        'status': 'Open',
        'reportedById': profile.uid,
        'reportedByName': profile.displayName,
        'siteId': profile.tenantId,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createDocument(
        tenantId: ref.read(currentTenantIdProvider) ?? '',
        collection: 'hazards',
        data: data,
      );

      if (mounted) {
        UIUtils.showToast(
          context,
          'Hazard reported successfully',
          type: ToastType.success,
        );
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Hazard Title *',
              prefixIcon: Icon(Icons.warning_amber_rounded),
            ),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.location_on_rounded),
            ),
          ),
          GSpacing.vMd,
          DropdownButtonFormField<String>(
            value: _severity,
            decoration: const InputDecoration(
              labelText: 'Severity *',
              prefixIcon: Icon(Icons.priority_high_rounded),
            ),
            items:
                _severities
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
            onChanged: (v) => setState(() => _severity = v!),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description *',
              prefixIcon: Icon(Icons.description_rounded),
            ),
          ),
          GSpacing.vLg,

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitHazard,
              icon:
                  _isSubmitting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.report_problem_rounded),
              label: Text(_isSubmitting ? 'Reporting...' : 'Report Hazard'),
            ),
          ),
        ],
      ),
    );
  }
}
