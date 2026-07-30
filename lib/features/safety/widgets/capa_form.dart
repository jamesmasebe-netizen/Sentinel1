import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../people/widgets/employee_selector.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../services/safety_service.dart';

class CAPAForm extends ConsumerStatefulWidget {
  final VoidCallback onCancel;
  final String? initialIncidentId;

  const CAPAForm({super.key, required this.onCancel, this.initialIncidentId});

  @override
  ConsumerState<CAPAForm> createState() => _CAPAFormState();
}

class _CAPAFormState extends ConsumerState<CAPAForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rcaController = TextEditingController();
  String _type = 'corrective';
  String _priority = 'medium';
  String? _assignedToId;
  DateTime? _dueDate;
  String? _linkedIncidentId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _linkedIncidentId = widget.initialIncidentId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rcaController.dispose();
    super.dispose();
  }

  Future<void> _submitCAPA() async {
    if (!_formKey.currentState!.validate()) return;
    if (_assignedToId == null || _dueDate == null) {
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
        'type': _type,
        'priority': _priority,
        'rca': _rcaController.text.trim(),
        'assignedTo': _assignedToId,
        'dueDate': _dueDate!.toIso8601String(),
        'status': 'Open',
        'createdBy': profile.uid,
        'tenantId': profile.tenantId,
        'createdAt': DateTime.now().toIso8601String(),
        if (_linkedIncidentId != null) 'incidentId': _linkedIncidentId,
      };

      final safetyService = ref.read(safetyServiceProvider);
      await safetyService.createCapa(data);

      if (mounted) {
        UIUtils.showToast(
          context,
          'CAPA created successfully',
          type: ToastType.success,
        );
        widget.onCancel();
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(
          context,
          'Failed to create CAPA: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firestoreProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Link to incident (optional)
          StreamBuilder<QuerySnapshot>(
            stream:
                firestore
                    .tenantCollection(
                      ref.watch(currentTenantIdProvider) ?? "",
                      'incidents',
                    )
                    .where('siteId', isEqualTo: '')
                    .orderBy('createdAt', descending: true)
                    .limit(20)
                    .snapshots(),
            builder: (context, snapshot) {
              final incidents = snapshot.data?.docs ?? [];
              return DropdownButtonFormField<String?>(
                value: _linkedIncidentId,
                decoration: const InputDecoration(
                  labelText: 'Link to Incident (optional)',
                  prefixIcon: Icon(Icons.link),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...incidents.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(
                        d['title'] ?? 'Untitled',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged:
                    _isSubmitting
                        ? null
                        : (v) => setState(() => _linkedIncidentId = v),
              );
            },
          ),
          GSpacing.vMd,

          TextFormField(
            controller: _titleController,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              labelText: 'Title *',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          GSpacing.vMd,

          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(
              labelText: 'CAPA Type *',
              prefixIcon: Icon(Icons.category),
            ),
            items: const [
              DropdownMenuItem(value: 'corrective', child: Text('Corrective')),
              DropdownMenuItem(value: 'preventive', child: Text('Preventive')),
            ],
            onChanged: _isSubmitting ? null : (v) => setState(() => _type = v!),
          ),
          GSpacing.vMd,

          DropdownButtonFormField<String>(
            value: _priority,
            decoration: const InputDecoration(
              labelText: 'Priority *',
              prefixIcon: Icon(Icons.flag),
            ),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Low')),
              DropdownMenuItem(value: 'medium', child: Text('Medium')),
              DropdownMenuItem(value: 'high', child: Text('High')),
            ],
            onChanged:
                _isSubmitting ? null : (v) => setState(() => _priority = v!),
          ),
          GSpacing.vMd,

          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'What corrective/preventive action is needed?',
              prefixIcon: Icon(Icons.description),
              alignLabelWithHint: true,
            ),
          ),
          GSpacing.vMd,

          TextFormField(
            controller: _rcaController,
            maxLines: 3,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              labelText: 'Root Cause Analysis',
              hintText: 'Enter RCA or use AI to generate...',
              prefixIcon: Icon(Icons.psychology),
              alignLabelWithHint: true,
            ),
          ),
          GSpacing.vMd,

          EmployeeSelector(
            label: 'Assigned To *',
            value: _assignedToId,
            onChanged: (val) => setState(() => _assignedToId = val),
          ),
          GSpacing.vMd,

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Due Date *'),
            subtitle: Text(
              _dueDate != null
                  ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                  : 'Tap to select',
            ),
            onTap:
                _isSubmitting
                    ? null
                    : () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 7),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _dueDate = date);
                      }
                    },
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitCAPA,
              icon:
                  _isSubmitting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.save),
              label: Text(_isSubmitting ? 'Creating...' : 'Create CAPA'),
            ),
          ),
        ],
      ),
    );
  }
}
