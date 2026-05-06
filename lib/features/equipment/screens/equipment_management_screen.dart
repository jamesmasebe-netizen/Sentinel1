import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

/// Equipment Management — asset register, inspection schedule, maintenance log.
class EquipmentManagementScreen extends ConsumerStatefulWidget {
  const EquipmentManagementScreen({super.key});
  @override
  ConsumerState<EquipmentManagementScreen> createState() => _EquipState();
}

class _EquipState extends ConsumerState<EquipmentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _showForm = false, _isSub = false;
  String _searchQuery = '';
  final _nameCtrl = TextEditingController(),
      _tagCtrl = TextEditingController(),
      _locCtrl = TextEditingController(),
      _mfgCtrl = TextEditingController();
  String _category = 'Heavy Plant', _status = 'Operational';
  DateTime _nextInsp = DateTime.now().add(const Duration(days: 90));

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
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
            collection: 'equipment',
            data: {
              'equipmentName': _nameCtrl.text.trim(),
              'assetTag': _tagCtrl.text.trim(),
              'location': _locCtrl.text.trim(),
              'manufacturer': _mfgCtrl.text.trim(),
              'category': _category,
              'status': _status,
              'nextInspectionDate': _nextInsp.toIso8601String(),
              'daysUntilInspection':
                  _nextInsp.difference(DateTime.now()).inDays,
              'authorId': p.uid,
              'siteId': p.siteId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment registered'),
            backgroundColor: XMTheme.success,
          ),
        );
        setState(() {
          _showForm = false;
          _nameCtrl.clear();
          _tagCtrl.clear();
          _locCtrl.clear();
          _mfgCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: XMTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const GHeader(
          title: 'Equipment Management',
          subtitle: 'Asset register and inspections',
        ),
        // Premium Sub-Header for Tabs
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tab,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Assets'),
              Tab(text: 'Inspections'),
              Tab(text: 'Maintenance'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _assetTab(),
              _inspectionsTab(),
              _maintenanceTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _assetTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search assets…',
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                        .collection('equipment')
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
                      Icon(Icons.precision_manufacturing_outlined, size: 64, color: Theme.of(context).disabledColor),
                      GSpacing.vLg,
                      Text('No equipment registered', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final status = d['status'] ?? 'Operational';
                  final days = d['daysUntilInspection'] as int? ?? 999;

                  return GCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          _categoryIcon(d['category']),
                          color: XMTheme.primary,
                          size: 24,
                        ),
                        GSpacing.hMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d['equipmentName'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${d['assetTag'] ?? ''} • ${d['location'] ?? ''} • ${d['category'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            GStatusTag(
                              label: status,
                              color:
                                  status == 'Operational'
                                      ? XMTheme.success
                                      : status == 'Under Maintenance'
                                      ? XMTheme.warning
                                      : XMTheme.error,
                            ),
                            GSpacing.vSm,
                            Text(
                              'Insp: ${days}d',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    days < 30
                                        ? XMTheme.warning
                                        : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _inspectionsTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    return StreamBuilder<QuerySnapshot>(
      stream:
          siteId == null
              ? null
              : fs
                  .collection('equipment')
                  .where('siteId', isEqualTo: siteId)
                  .where('daysUntilInspection', isLessThanOrEqualTo: 30)
                  .orderBy('daysUntilInspection')
                  .limit(50)
                  .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: XMTheme.success.withValues(alpha: 0.5),
                ),
                GSpacing.vLg,
                Text(
                  'All inspections current',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                GSpacing.vSm,
                Text(
                  'No inspections due in the next 30 days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).disabledColor),
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
            final days = d['daysUntilInspection'] as int? ?? 0;
            return GCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(
                  _categoryIcon(d['category']),
                  color: days < 0 ? XMTheme.error : XMTheme.warning,
                  size: 24,
                ),
                title: Text(
                  d['equipmentName'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${d['location'] ?? ''} • ${d['assetTag'] ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  days < 0 ? 'OVERDUE' : '${days}d',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: days < 0 ? XMTheme.error : XMTheme.warning,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _maintenanceTab() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: XMTheme.warning.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.engineering_outlined, size: 80, color: XMTheme.warning),
        ),
        GSpacing.vLg,
        Text(
          'Maintenance Hub',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        GSpacing.vSm,
        Text(
          'View and manage work orders for on-site equipment maintenance.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        GSpacing.vLg,
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              UIUtils.showToast(context, 'Connecting to Work Order Management...');
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Work Orders'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ),
      ],
    ),
  );

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
}
