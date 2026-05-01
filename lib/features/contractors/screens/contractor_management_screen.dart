import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Contractor Management — contractor register, compliance status, permit linkage.
class ContractorManagementScreen extends ConsumerStatefulWidget {
  const ContractorManagementScreen({super.key});
  @override
  ConsumerState<ContractorManagementScreen> createState() => _ContractorState();
}

class _ContractorState extends ConsumerState<ContractorManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _showForm = false, _isSub = false;
  String _searchQuery = '', _statusFilter = 'All';
  final _nameCtrl = TextEditingController(), _contactCtrl = TextEditingController();
  final _regCtrl = TextEditingController(), _scopeCtrl = TextEditingController();
  String _riskRating = 'Medium', _status = 'Active';

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tab.dispose(); _nameCtrl.dispose(); _contactCtrl.dispose(); _regCtrl.dispose(); _scopeCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'contractors', data: {
        'companyName': _nameCtrl.text.trim(), 'contactPerson': _contactCtrl.text.trim(),
        'registrationNumber': _regCtrl.text.trim(), 'scopeOfWork': _scopeCtrl.text.trim(),
        'riskRating': _riskRating, 'status': _status,
        'authorId': p.uid, 'siteId': p.siteId, 'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contractor added'), backgroundColor: XMTheme.success));
        setState(() { _showForm = false; _nameCtrl.clear(); _contactCtrl.clear(); _regCtrl.clear(); _scopeCtrl.clear(); }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSub = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contractor Management'), bottom: TabBar(controller: _tab, tabs: const [
        Tab(icon: Icon(Icons.business, size: 16), text: 'Register'),
        Tab(icon: Icon(Icons.verified_user, size: 16), text: 'Compliance'),
        Tab(icon: Icon(Icons.assignment_ind, size: 16), text: 'Inductions'),
      ])),
      body: TabBarView(controller: _tab, children: [_registerTab(), _complianceTab(), _inductionsTab()]),
    );
  }

  Widget _registerTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: TextField(onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search, size: 18), hintText: 'Search contractors…', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))))),
        const SizedBox(width: 12),
        DropdownButton<String>(value: _statusFilter, isDense: true, underline: const SizedBox(),
          items: ['All', 'Active', 'Inactive', 'Suspended'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _statusFilter = v!)),
        const SizedBox(width: 8),
        FilledButton(onPressed: () => setState(() => _showForm = !_showForm), child: Icon(_showForm ? Icons.close : Icons.add, size: 18)),
      ])),
      if (_showForm) Card(margin: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add Contractor', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
        TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Company Name *')), const SizedBox(height: 10),
        Row(children: [Expanded(child: TextFormField(controller: _contactCtrl, decoration: const InputDecoration(labelText: 'Contact Person'))),
          const SizedBox(width: 12), Expanded(child: TextFormField(controller: _regCtrl, decoration: const InputDecoration(labelText: 'Registration No.')))]),
        const SizedBox(height: 10), TextFormField(controller: _scopeCtrl, decoration: const InputDecoration(labelText: 'Scope of Work')), const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _riskRating, decoration: const InputDecoration(labelText: 'Risk Rating', isDense: true),
            items: ['Low', 'Medium', 'High', 'Critical'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _riskRating = v!))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'Status', isDense: true),
            items: ['Active', 'Inactive', 'Suspended'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _status = v!))),
        ]), const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSub ? null : _submit, child: Text(_isSub ? 'Saving…' : 'Add Contractor'))),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: siteId == null ? null : fs.collection('contractors').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(100).snapshots(),
        builder: (ctx, snap) {
          var docs = snap.data?.docs ?? [];
          if (_searchQuery.isNotEmpty) docs = docs.where((d) { final data = d.data() as Map<String, dynamic>; return (data['companyName'] ?? '').toString().toLowerCase().contains(_searchQuery); }).toList();
          if (_statusFilter != 'All') docs = docs.where((d) { final data = d.data() as Map<String, dynamic>; return data['status'] == _statusFilter; }).toList();
          if (docs.isEmpty) return const Center(child: Text('No contractors found'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final riskColor = d['riskRating'] == 'Critical' ? XMTheme.error : d['riskRating'] == 'High' ? XMTheme.warning : d['riskRating'] == 'Medium' ? XMTheme.info : XMTheme.success;
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['companyName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('${d['contactPerson'] ?? ''} • ${d['scopeOfWork'] ?? ''}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(d['riskRating'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: riskColor))),
                  const SizedBox(height: 4),
                  Text(d['status'] ?? '', style: TextStyle(fontSize: 10, color: d['status'] == 'Active' ? XMTheme.success : XMTheme.error)),
                ]),
              ]));
          });
        },
      )),
    ]);
  }

  Widget _complianceTab() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.verified_user, size: 48, color: XMTheme.success.withValues(alpha: 0.4)), const SizedBox(height: 12),
    const Text('Contractor Compliance Tracking'), const SizedBox(height: 8),
    Text('Insurance certificates, tax clearance, safety files', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
  ]));

  Widget _inductionsTab() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.assignment_ind, size: 48, color: XMTheme.primary.withValues(alpha: 0.4)), const SizedBox(height: 12),
    const Text('Contractor Induction Records'), const SizedBox(height: 8),
    Text('Site induction completion tracking per contractor', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
  ]));
}
