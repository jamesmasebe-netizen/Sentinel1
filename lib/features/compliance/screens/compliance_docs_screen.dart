import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Compliance & Documents — register, upload, review, expiry alerts.
class ComplianceDocsScreen extends ConsumerStatefulWidget {
  const ComplianceDocsScreen({super.key});
  @override
  ConsumerState<ComplianceDocsScreen> createState() => _CompDocsState();
}

class _CompDocsState extends ConsumerState<ComplianceDocsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _showDocForm = false, _isSub = false;
  String _docType = 'Licence', _docStatus = 'Current', _searchQuery = '';
  final _titleCtrl = TextEditingController(), _refCtrl = TextEditingController(), _ownerCtrl = TextEditingController();
  DateTime _expiry = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tab.dispose(); _titleCtrl.dispose(); _refCtrl.dispose(); _ownerCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'compliance_docs', data: {
        'title': _titleCtrl.text.trim(), 'referenceNumber': _refCtrl.text.trim(),
        'documentType': _docType, 'status': _docStatus, 'owner': _ownerCtrl.text.trim(),
        'expiryDate': _expiry.toIso8601String(),
        'daysUntilExpiry': _expiry.difference(DateTime.now()).inDays,
        'authorId': p.uid, 'siteId': p.siteId, 'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document registered'), backgroundColor: XMTheme.success));
        setState(() { _showDocForm = false; _titleCtrl.clear(); _refCtrl.clear(); _ownerCtrl.clear(); }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSub = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compliance & Documents'), bottom: TabBar(controller: _tab, tabs: const [
        Tab(icon: Icon(Icons.folder, size: 16), text: 'Register'),
        Tab(icon: Icon(Icons.warning_amber, size: 16), text: 'Expiring Soon'),
        Tab(icon: Icon(Icons.gavel, size: 16), text: 'Legal Requirements'),
      ])),
      body: TabBarView(controller: _tab, children: [_registerTab(), _expiringTab(), _legalTab()]),
    );
  }

  Widget _registerTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return Column(children: [
      // Search + Add bar
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: TextField(onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search, size: 18), hintText: 'Search documents…', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))))),
        const SizedBox(width: 12),
        FilledButton.icon(onPressed: () => setState(() => _showDocForm = !_showDocForm),
          icon: Icon(_showDocForm ? Icons.close : Icons.add, size: 18), label: Text(_showDocForm ? 'Cancel' : 'Add')),
      ])),
      if (_showDocForm) Card(margin: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Register Document', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
        TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Document Title *')), const SizedBox(height: 10),
        Row(children: [Expanded(child: TextFormField(controller: _refCtrl, decoration: const InputDecoration(labelText: 'Reference No.'))),
          const SizedBox(width: 12), Expanded(child: TextFormField(controller: _ownerCtrl, decoration: const InputDecoration(labelText: 'Owner / Responsible')))]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _docType, decoration: const InputDecoration(labelText: 'Type', isDense: true),
            items: ['Licence', 'Certificate', 'Permit', 'Policy', 'Procedure', 'Legal Register', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _docType = v!))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(value: _docStatus, decoration: const InputDecoration(labelText: 'Status', isDense: true),
            items: ['Current', 'Under Review', 'Expired', 'Superseded'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _docStatus = v!))),
        ]), const SizedBox(height: 10),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('Expiry Date', style: TextStyle(fontSize: 12)),
          subtitle: Text('${_expiry.day}/${_expiry.month}/${_expiry.year}', style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.calendar_today, size: 18),
          onTap: () async { final d = await showDatePicker(context: context, initialDate: _expiry, firstDate: DateTime.now(), lastDate: DateTime(2040)); if (d != null) setState(() => _expiry = d); }),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSub ? null : _submit, child: Text(_isSub ? 'Saving…' : 'Register Document'))),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: siteId == null ? null : fs.collection('compliance_docs').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(100).snapshots(),
        builder: (ctx, snap) {
          var docs = snap.data?.docs ?? [];
          if (_searchQuery.isNotEmpty) docs = docs.where((d) { final data = d.data() as Map<String, dynamic>; return (data['title'] ?? '').toString().toLowerCase().contains(_searchQuery); }).toList();
          if (docs.isEmpty) return const Center(child: Text('No documents registered'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final days = d['daysUntilExpiry'] as int? ?? 999;
            final expColor = days < 30 ? XMTheme.error : days < 90 ? XMTheme.warning : XMTheme.success;
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Container(width: 4, height: 44, decoration: BoxDecoration(color: expColor, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${d['documentType']} • ${d['referenceNumber'] ?? 'No Ref'} • ${d['owner'] ?? ''}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: expColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(days < 0 ? 'EXPIRED' : '${days}d left', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: expColor))),
                  const SizedBox(height: 4),
                  Text(d['status'] ?? '', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ]),
              ]));
          });
        },
      )),
    ]);
  }

  Widget _expiringTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return StreamBuilder<QuerySnapshot>(
      stream: siteId == null ? null : fs.collection('compliance_docs').where('siteId', isEqualTo: siteId).where('daysUntilExpiry', isLessThanOrEqualTo: 90).orderBy('daysUntilExpiry').limit(50).snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle, size: 48, color: XMTheme.success.withValues(alpha: 0.4)), const SizedBox(height: 12),
          const Text('No documents expiring in the next 90 days'),
        ]));
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
          final d = docs[i].data() as Map<String, dynamic>;
          final days = d['daysUntilExpiry'] as int? ?? 0;
          final c = days < 0 ? XMTheme.error : days < 30 ? XMTheme.error : XMTheme.warning;
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: CircleAvatar(backgroundColor: c.withValues(alpha: 0.1), child: Icon(days < 0 ? Icons.error : Icons.schedule, color: c, size: 20)),
            title: Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('${d['documentType']} • Owner: ${d['owner'] ?? 'Unknown'}', style: const TextStyle(fontSize: 12)),
            trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(days < 0 ? 'EXPIRED' : '${days}d', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c))),
          ));
        });
      },
    );
  }

  Widget _legalTab() {
    final reqs = [
      ('Occupational Health and Safety Act 85 of 1993', 'Primary OHS legislation', Icons.gavel),
      ('COIDA — Compensation for Occupational Injuries', 'Workplace injury compensation framework', Icons.health_and_safety),
      ('General Safety Regulations (GSR)', 'General workplace safety standards', Icons.rule),
      ('Hazardous Chemical Substances Regulations', 'Chemical safety management requirements', Icons.science),
      ('Noise-Induced Hearing Loss Regulations (NIHL)', 'Noise exposure monitoring and protection', Icons.hearing),
      ('Construction Regulations 2014', 'Construction site safety management', Icons.construction),
      ('National Environmental Management Act (NEMA)', 'Environmental compliance requirements', Icons.eco),
      ('ISO 45001 — OHSMS', 'International OHS management standard', Icons.verified),
      ('ISO 14001 — EMS', 'International environmental management standard', Icons.nature),
      ('ISO 9001 — QMS', 'International quality management standard', Icons.star),
    ];
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: reqs.length, itemBuilder: (ctx, i) {
      final r = reqs[i];
      return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(r.$3, color: XMTheme.primary, size: 22), const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(r.$2, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ])),
        ]));
    });
  }
}
