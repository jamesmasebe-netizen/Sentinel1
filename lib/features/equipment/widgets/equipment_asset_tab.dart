import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../people/widgets/employee_selector.dart';
import 'equipment_list_item.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class EquipmentAssetTab extends ConsumerStatefulWidget {
  final String? initialSearch;

  const EquipmentAssetTab({super.key, this.initialSearch});

  @override
  ConsumerState<EquipmentAssetTab> createState() => _EquipmentAssetTabState();
}

class _EquipmentAssetTabState extends ConsumerState<EquipmentAssetTab> {
  bool _showForm = false, _isSub = false;
  String _searchQuery = '';
  final _nameCtrl = TextEditingController(),
      _tagCtrl = TextEditingController(),
      _locCtrl = TextEditingController(),
      _mfgCtrl = TextEditingController();
  String? _assignedToId;
  String _category = 'Heavy Plant', _status = 'Operational';
  DateTime _nextInsp = DateTime.now().add(const Duration(days: 90));

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      _searchQuery = widget.initialSearch!.toLowerCase();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tagCtrl.dispose();
    _locCtrl.dispose();
    _mfgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            tenantId: ref.read(currentTenantIdProvider) ?? '',
            collection: 'equipment',
            data: {
              'equipmentName': _nameCtrl.text.trim(),
              'assetTag': _tagCtrl.text.trim(),
              'location': _locCtrl.text.trim(),
              'manufacturer': _mfgCtrl.text.trim(),
              'category': _category,
              'status': _status,
              'assignedToId': _assignedToId,
              'nextInspectionDate': _nextInsp.toIso8601String(),
              'daysUntilInspection':
                  _nextInsp.difference(DateTime.now()).inDays,
              'authorId': p.uid,
              'siteId': p.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        UIUtils.showToast(
          context,
          'Equipment registered',
          type: ToastType.success,
        );
        setState(() {
          _showForm = false;
          _nameCtrl.clear();
          _tagCtrl.clear();
          _locCtrl.clear();
          _mfgCtrl.clear();
          _assignedToId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, '$e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSub = false);
    }
  }

  IconData _categoryIcon(String? cat) {
    switch (cat) {
      case 'Heavy Plant':
        return Icons.agriculture;
      case 'Light Vehicle':
        return Icons.directions_car;
      case 'Power Tools':
        return Icons.handyman;
      case 'Lifting Equipment':
        return Icons.forklift;
      case 'Electrical':
        return Icons.electrical_services;
      case 'Pressure Vessel':
        return Icons.science;
      default:
        return Icons.precision_manufacturing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged:
                      (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search assets…',
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              GSpacing.hMd,
              FilledButton(
                onPressed: () => setState(() => _showForm = !_showForm),
                child: Icon(_showForm ? Icons.close : Icons.add, size: 18),
              ),
            ],
          ),
        ),
        if (_showForm)
          GCard(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Register New Equipment',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                GSpacing.vMd,
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Equipment Name *',
                  ),
                ),
                GSpacing.vMd,
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tagCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Asset Tag / ID',
                        ),
                      ),
                    ),
                    GSpacing.hMd,
                    Expanded(
                      child: TextFormField(
                        controller: _locCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                        ),
                      ),
                    ),
                  ],
                ),
                GSpacing.vMd,
                TextFormField(
                  controller: _mfgCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer / Model',
                  ),
                ),
                GSpacing.vMd,
                EmployeeSelector(
                  value: _assignedToId,
                  onChanged: (val) => setState(() => _assignedToId = val),
                  label: 'Assigned To / Inspector',
                ),
                GSpacing.vMd,
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          isDense: true,
                        ),
                        items:
                            [
                                  'Heavy Plant',
                                  'Light Vehicle',
                                  'Power Tools',
                                  'Lifting Equipment',
                                  'Electrical',
                                  'Pressure Vessel',
                                  'Safety Equipment',
                                  'Other',
                                ]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    ),
                    GSpacing.hMd,
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          isDense: true,
                        ),
                        items:
                            [
                                  'Operational',
                                  'Under Maintenance',
                                  'Out of Service',
                                  'Decommissioned',
                                ]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ),
                  ],
                ),
                GSpacing.vMd,
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Next Inspection',
                    style: TextStyle(fontSize: 12),
                  ),
                  subtitle: Text(
                    '${_nextInsp.day}/${_nextInsp.month}/${_nextInsp.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _nextInsp,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2040),
                    );
                    if (d != null) setState(() => _nextInsp = d);
                  },
                ),
                GSpacing.vMd,
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSub ? null : _submit,
                    child: Text(_isSub ? 'Saving…' : 'Register'),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                siteId == null
                    ? null
                    : fs
                        .tenantCollection(
                          ref.watch(currentTenantIdProvider) ?? "",
                          'equipment',
                        )
                        .where('siteId', isEqualTo: siteId)
                        .orderBy('createdAt', descending: true)
                        .limit(100)
                        .snapshots(),
            builder: (ctx, snap) {
              var docs = snap.data?.docs ?? [];
              if (_searchQuery.isNotEmpty) {
                docs =
                    docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return (data['equipmentName'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(_searchQuery) ||
                          (data['assetTag'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(_searchQuery);
                    }).toList();
              }
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.precision_manufacturing_outlined,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      GSpacing.vLg,
                      Text(
                        'No equipment registered',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return EquipmentListItem(
                    data: d,
                    categoryIcon: _categoryIcon(d['category']),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
