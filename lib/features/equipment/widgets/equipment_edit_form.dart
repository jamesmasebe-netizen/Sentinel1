import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../models/equipment_models.dart';

/// Real edit form for an existing equipment item. Deliberately separate from
/// EquipmentAssetTab's create form, which also triggers asset_lifecycle BPF
/// deployment when an assignee is picked — that side effect only makes sense
/// on creation, not on every edit — see F-216 in docs/fixes/FIX_LIST.md.
class EquipmentEditForm extends ConsumerStatefulWidget {
  final EquipmentModel initialData;
  const EquipmentEditForm({super.key, required this.initialData});

  @override
  ConsumerState<EquipmentEditForm> createState() => _EquipmentEditFormState();
}

class _EquipmentEditFormState extends ConsumerState<EquipmentEditForm> {
  late final _nameCtrl = TextEditingController(text: widget.initialData.equipmentName);
  late final _tagCtrl = TextEditingController(text: widget.initialData.assetTag);
  late final _locCtrl = TextEditingController(text: widget.initialData.location);
  late final _mfgCtrl = TextEditingController(text: widget.initialData.manufacturer);
  late String _category = widget.initialData.category;
  late final bool _isLockedOut = widget.initialData.status == 'Locked Out';
  late String _status = widget.initialData.status;
  late DateTime _nextInsp = widget.initialData.nextInspectionDate;
  bool _isSubmitting = false;

  static const _categories = [
    'Heavy Plant',
    'Light Vehicle',
    'Power Tools',
    'Lifting Equipment',
    'Electrical',
    'Pressure Vessel',
    'Safety Equipment',
    'Other',
  ];
  static const _statuses = [
    'Operational',
    'Deployed',
    'Under Maintenance',
    'Out of Service',
    'Decommissioned',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tagCtrl.dispose();
    _locCtrl.dispose();
    _mfgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final tenantId = ref.read(currentTenantIdProvider) ?? '';
      final updated = EquipmentModel(
        id: widget.initialData.id,
        equipmentName: _nameCtrl.text.trim(),
        assetTag: _tagCtrl.text.trim(),
        location: _locCtrl.text.trim(),
        manufacturer: _mfgCtrl.text.trim(),
        category: _category,
        status: _status,
        assignedToId: widget.initialData.assignedToId,
        nextInspectionDate: _nextInsp,
        daysUntilInspection: _nextInsp.difference(DateTime.now()).inDays,
        authorId: widget.initialData.authorId,
        createdAt: widget.initialData.createdAt,
        tenantId: tenantId,
      );
      await ref
          .read(firestoreProvider)
          .tenantCollection(tenantId, 'equipment')
          .doc(widget.initialData.id)
          .update(updated.toMap());
      if (mounted) {
        UIUtils.showToast(context, 'Equipment updated', type: ToastType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Equipment Name *'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagCtrl,
                decoration: const InputDecoration(labelText: 'Asset Tag / ID'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _locCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _mfgCtrl,
          decoration: const InputDecoration(labelText: 'Manufacturer / Model'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _isLockedOut
                  ? TextFormField(
                      initialValue: 'Locked Out',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        helperText: 'Use Verify & Return to Service to change this',
                        helperMaxLines: 2,
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _status = v ?? _status),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Next Inspection'),
          subtitle: Text('${_nextInsp.day}/${_nextInsp.month}/${_nextInsp.year}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _nextInsp,
              firstDate: DateTime(2020),
              lastDate: DateTime(2040),
            );
            if (d != null) setState(() => _nextInsp = d);
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(_isSubmitting ? 'Saving...' : 'Save Changes'),
          ),
        ),
      ],
    );
  }
}
