import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/searchable_multi_select.dart';
import '../../people/widgets/employee_selector.dart';
import '../../people/providers/employee_providers.dart';

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
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _areaController = TextEditingController();
  DateTime? _validFrom;
  DateTime? _validTo;
  bool _lotoRequired = false;
  final _riskAssessmentIdController = TextEditingController();
  String? _approverId;
  List<String> _workers = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _areaController.dispose();
    _riskAssessmentIdController.dispose();
    super.dispose();
  }

  Future<void> _submitPermit() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _validFrom == null ||
        _validTo == null) {
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
        'type': _type,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'area': _areaController.text.trim(),
        'startDate': _validFrom!.toIso8601String(),
        'endDate': _validTo!.toIso8601String(),
        'lotoRequired': _lotoRequired,
        'status': 'Requested',
        'requestedBy': profile.uid,
        'applicantName': profile.displayName,
        'approverId': _approverId,
        'riskAssessmentId': _riskAssessmentIdController.text.trim(),
        'workers': _workers,
        'tenantId': profile.tenantId,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createDocument(
        tenantId: ref.read(currentTenantIdProvider) ?? '',
        collection: 'permits',
        data: data,
      );

      if (mounted) {
        UIUtils.showToast(
          context,
          'Permit request submitted successfully',
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
            items:
                [
                      'Hot Work',
                      'Working at Height',
                      'Confined Space',
                      'Excavation',
                      'Electrical',
                      'Other',
                    ]
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Permit Title *',
              prefixIcon: Icon(Icons.title_rounded),
            ),
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
            controller: _areaController,
            decoration: const InputDecoration(
              labelText: 'Area',
              prefixIcon: Icon(Icons.map_rounded),
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
            subtitle: Text(
              _validFrom != null
                  ? _formatDateTime(_validFrom!)
                  : 'Tap to select',
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null && context.mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null && context.mounted) {
                  final full = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  setState(() => _validFrom = full);
                }
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.stop_circle_outlined),
            title: const Text('Valid To *'),
            subtitle: Text(
              _validTo != null ? _formatDateTime(_validTo!) : 'Tap to select',
            ),
            onTap: () async {
              final initial = _validFrom ?? DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: initial,
                lastDate: initial.add(const Duration(days: 365)),
              );
              if (date != null && context.mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null && context.mounted) {
                  final full = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  setState(() => _validTo = full);
                }
              }
            },
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _riskAssessmentIdController,
            decoration: const InputDecoration(
              labelText: 'Risk Assessment ID (Optional)',
              prefixIcon: Icon(Icons.assignment_rounded),
            ),
          ),
          GSpacing.vMd,
          EmployeeSelector(
            label: 'Approving Authority',
            value: _approverId,
            onChanged: (val) => setState(() => _approverId = val),
          ),
          GSpacing.vMd,
          ref
              .watch(employeesProvider)
              .when(
                data: (employees) {
                  final options = employees.map((e) => e.id).toList();
                  final labels = <String, String>{
                    for (var e in employees) e.id: e.fullName,
                  };
                  return SearchableStringMultiSelect(
                    label: 'Workers Assigned',
                    hintText: 'Search workers...',
                    availableItems: options,
                    itemLabels: labels,
                    selectedItems: _workers,
                    onChanged: (vals) => setState(() => _workers = vals),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => Text('Error loading employees: $e'),
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
              icon:
                  _isSubmitting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.send_rounded),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Request'),
            ),
          ),
        ],
      ),
    );
  }
}
