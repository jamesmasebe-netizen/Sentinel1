import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Equipment Management — asset register, inspection schedule, maintenance log.
class EquipmentManagementScreen extends ConsumerStatefulWidget {
  const EquipmentManagementScreen({super.key});
  @override
  ConsumerState<EquipmentManagementScreen> createState() => _EquipState();
}

class _EquipState extends ConsumerState<EquipmentManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _showForm = false, _isSub = false;
  String _searchQuery = '';
  final _nameCtrl = TextEditingController(), _tagCtrl = TextEditingController(), _locCtrl = TextEditingController(), _mfgCtrl = TextEditingController();
  String _category = 'Heavy Plant', _status = 'Operational';
  DateTime _nextInsp = DateTime.now().add(const Duration(days: 90));

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tab.dispose(); _nameCtrl.dispose(); _tagCtrl.dispose(); _locCtrl.dispose(); _mfgCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'equipment', data: {
        'equipmentName': _nameCtrl.text.trim(), 'assetTag': _tagCtrl.text.trim(),
        'location': _locCtrl.text.trim(), 'manufacturer': _mfgCtrl.text.trim(),
        'category': _category, 'status': _status,
        'nextInspectionDate': _nextInsp.toIso8601String(),
        'daysUntilInspection': _nextInsp.difference(DateTime.now()).inDays,
        'authorId': p.uid, 'siteId': p.siteId, 'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipment registered'), backgroundColor: XMTheme.success));
        setState(() { _showForm = false; _nameCtrl.clear(); _tagCtrl.clear(); _locCtrl.clear(); _mfgCtrl.clear(); }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSub = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment Management'), bottom: TabBar(controller: _tab, isScrollable: true, tabAlignment: TabAlignment.start, tabs: const [
        Tab(icon: Icon(Icons.precision_manufacturing, size: 16), text: 'Asset Register'),
        Tab(icon: Icon(Icons.event_available, size: 16), text: 'Inspections Due'),
        Tab(icon: Icon(Icons.build, size: 16), text: 'Maintenance'),
      ])),
      body: TabBarView(controller: _tab, children: [_assetTab(), _inspectionsTab(), _maintenanceTab()]),
    );
  }

  Widget _assetTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: TextField(onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search, size: 18), hintText: 'Search assets…', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))))),
        const SizedBox(width: 12),
        FilledButton(onPressed: () => setState(() => _showForm = !_showForm), child: Icon(_showForm ? Icons.close : Icons.add, size: 18)),
      ])),
      if (_showForm) Card(margin: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Register Equipment', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
        TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Equipment Name *')), const SizedBox(height: 10),
        Row(children: [Expanded(child: TextFormField(controller: _tagCtrl, decoration: const InputDecoration(labelText: 'Asset Tag / ID'))),
          const SizedBox(width: 12), Expanded(child: TextFormField(controller: _locCtrl, decoration: const InputDecoration(labelText: 'Location')))]),
        const SizedBox(height: 10), TextFormField(controller: _mfgCtrl, decoration: const InputDecoration(labelText: 'Manufacturer / Model')), const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _category, decoration: const InputDecoration(labelText: 'Category', isDense: true),
            items: ['Heavy Plant', 'Light Vehicle', 'Power Tools', 'Lifting Equipment', 'Electrical', 'Pressure Vessel', 'Safety Equipment', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _category = v!))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'Status', isDense: true),
            items: ['Operational', 'Under Maintenance', 'Out of Service', 'Decommissioned'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _status = v!))),
        ]), const SizedBox(height: 10),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('Next Inspection', style: TextStyle(fontSize: 12)),
          subtitle: Text('${_nextInsp.day}/${_nextInsp.month}/${_nextInsp.year}'),
          trailing: const Icon(Icons.calendar_today, size: 18),
          onTap: () async { final d = await showDatePicker(context: context, initialDate: _nextInsp, firstDate: DateTime.now(), lastDate: DateTime(2040)); if (d != null) setState(() => _nextInsp = d); }),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSub ? null : _submit, child: Text(_isSub ? 'Saving…' : 'Register'))),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: siteId == null ? null : fs.collection('equipment').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(100).snapshots(),
        builder: (ctx, snap) {
          var docs = snap.data?.docs ?? [];
          if (_searchQuery.isNotEmpty) docs = docs.where((d) { final data = d.data() as Map<String, dynamic>; return (data['equipmentName'] ?? '').toString().toLowerCase().contains(_searchQuery) || (data['assetTag'] ?? '').toString().toLowerCase().contains(_searchQuery); }).toList();
          if (docs.isEmpty) return const Center(child: Text('No equipment registered'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final statusColor = d['status'] == 'Operational' ? XMTheme.success : d['status'] == 'Under Maintenance' ? XMTheme.warning : XMTheme.error;
            final days = d['daysUntilInspection'] as int? ?? 999;
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(_categoryIcon(d['category']), color: XMTheme.primary, size: 24), const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['equipmentName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('${d['assetTag'] ?? ''} • ${d['location'] ?? ''} • ${d['category'] ?? ''}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(d['status'] ?? '', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor))),
                  const SizedBox(height: 4),
                  Text('Insp: ${days}d', style: TextStyle(fontSize: 10, color: days < 30 ? XMTheme.warning : Theme.of(context).colorScheme.onSurfaceVariant)),
                ]),
              ]));
          });
        },
      )),
    ]);
  }

  Widget _inspectionsTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return StreamBuilder<QuerySnapshot>(
      stream: siteId == null ? null : fs.collection('equipment').where('siteId', isEqualTo: siteId).where('daysUntilInspection', isLessThanOrEqualTo: 30).orderBy('daysUntilInspection').limit(50).snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle, size: 48, color: XMTheme.success.withValues(alpha: 0.4)), const SizedBox(height: 12),
          const Text('No inspections due in the next 30 days'),
        ]));
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
          final d = docs[i].data() as Map<String, dynamic>;
          final days = d['daysUntilInspection'] as int? ?? 0;
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: Icon(_categoryIcon(d['category']), color: days < 0 ? XMTheme.error : XMTheme.warning, size: 24),
            title: Text(d['equipmentName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('${d['location'] ?? ''} • ${d['assetTag'] ?? ''}', style: const TextStyle(fontSize: 12)),
            trailing: Text(days < 0 ? 'OVERDUE' : '${days}d', style: TextStyle(fontWeight: FontWeight.w700, color: days < 0 ? XMTheme.error : XMTheme.warning)),
          ));
        });
      },
    );
  }

  Widget _maintenanceTab() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.build, size: 48, color: XMTheme.warning.withValues(alpha: 0.4)), const SizedBox(height: 12),
    const Text('Maintenance Work Orders'), const SizedBox(height: 8),
    Text('Link to Work Order Management module', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
  ]));

  IconData _categoryIcon(String? cat) { switch (cat) { case 'Heavy Plant': return Icons.agriculture; case 'Light Vehicle': return Icons.directions_car; case 'Power Tools': return Icons.handyman; case 'Lifting Equipment': return Icons.forklift; case 'Electrical': return Icons.electrical_services; case 'Pressure Vessel': return Icons.science; default: return Icons.precision_manufacturing; } }
}
