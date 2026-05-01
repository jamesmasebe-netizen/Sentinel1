import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Workers Compensation (COIDA) — claims, RTW tracking, COIDA compliance checklist.
class WorkersCompScreen extends ConsumerStatefulWidget {
  const WorkersCompScreen({super.key});
  @override
  ConsumerState<WorkersCompScreen> createState() => _WCState();
}

class _WCState extends ConsumerState<WorkersCompScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _showClaimForm = false, _isSub = false;

  // Claim form
  final _empCtrl = TextEditingController(), _idCtrl = TextEditingController();
  final _claimNoCtrl = TextEditingController(), _lostDaysCtrl = TextEditingController();
  DateTime _incidentDate = DateTime.now();

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tab.dispose(); for (final c in [_empCtrl, _idCtrl, _claimNoCtrl, _lostDaysCtrl]) { c.dispose(); } super.dispose(); }

  Future<void> _submitClaim() async {
    if (_empCtrl.text.isEmpty) return;
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'coida_claims', data: {
        'employeeName': _empCtrl.text.trim(), 'idNumber': _idCtrl.text.trim(),
        'claimNumber': _claimNoCtrl.text.trim(),
        'incidentDate': _incidentDate.toIso8601String(),
        'lostDays': int.tryParse(_lostDaysCtrl.text) ?? 0,
        'status': 'Submitted', 'rtwStatus': 'Off Sick',
        'authorId': p.uid, 'siteId': p.siteId, 'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Claim submitted'), backgroundColor: XMTheme.success));
        setState(() { _showClaimForm = false; _empCtrl.clear(); _idCtrl.clear(); _claimNoCtrl.clear(); _lostDaysCtrl.clear(); }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSub = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workers Compensation — COIDA'), bottom: TabBar(controller: _tab, tabs: const [
        Tab(icon: Icon(Icons.assignment, size: 16), text: 'Claims'),
        Tab(icon: Icon(Icons.directions_walk, size: 16), text: 'Return to Work'),
        Tab(icon: Icon(Icons.checklist, size: 16), text: 'Compliance'),
      ])),
      body: TabBarView(controller: _tab, children: [_claimsTab(), _rtwTab(), _complianceTab()]),
    );
  }

  Widget _claimsTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FilledButton.icon(onPressed: () => setState(() => _showClaimForm = !_showClaimForm),
          icon: Icon(_showClaimForm ? Icons.close : Icons.add, size: 18), label: Text(_showClaimForm ? 'Cancel' : 'New Claim')),
      ])),
      if (_showClaimForm) Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COIDA Claim', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
        Row(children: [Expanded(child: TextFormField(controller: _empCtrl, decoration: const InputDecoration(labelText: 'Employee Name *'))),
          const SizedBox(width: 12), Expanded(child: TextFormField(controller: _idCtrl, decoration: const InputDecoration(labelText: 'ID Number')))]),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: TextFormField(controller: _claimNoCtrl, decoration: const InputDecoration(labelText: 'Claim Number'))),
          const SizedBox(width: 12), Expanded(child: TextFormField(controller: _lostDaysCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Lost Work Days')))]),
        const SizedBox(height: 10),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('Incident Date', style: TextStyle(fontSize: 12)),
          subtitle: Text('${_incidentDate.day}/${_incidentDate.month}/${_incidentDate.year}', style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.calendar_today, size: 18),
          onTap: () async { final d = await showDatePicker(context: context, initialDate: _incidentDate, firstDate: DateTime(2020), lastDate: DateTime.now()); if (d != null) setState(() => _incidentDate = d); }),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSub ? null : _submitClaim, child: Text(_isSub ? 'Submitting…' : 'Submit Claim'))),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: siteId == null ? null : fs.collection('coida_claims').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(50).snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No COIDA claims'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final statusColor = d['status'] == 'Accepted' ? XMTheme.success : d['status'] == 'Rejected' ? XMTheme.error : d['status'] == 'Closed' ? XMTheme.primary : XMTheme.warning;
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(d['employeeName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(d['status'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
                ]),
                const SizedBox(height: 4),
                Text('Claim: ${d['claimNumber'] ?? 'N/A'} • Lost Days: ${d['lostDays'] ?? 0}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Row(children: [
                  _RtwBadge(label: d['rtwStatus'] ?? 'Off Sick'),
                  const Spacer(),
                  for (final status in ['Accepted', 'Rejected', 'Closed']) if (d['status'] != status) TextButton(
                    onPressed: () => _updateStatus(docs[i].id, 'status', status),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text(status, style: const TextStyle(fontSize: 11))),
                ]),
              ]));
          });
        },
      )),
    ]);
  }

  Widget _rtwTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return StreamBuilder<QuerySnapshot>(
      stream: siteId == null ? null : fs.collection('coida_claims').where('siteId', isEqualTo: siteId).where('status', isNotEqualTo: 'Closed').snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No active RTW cases'));
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
          final d = docs[i].data() as Map<String, dynamic>;
          return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['employeeName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Lost days: ${d['lostDays'] ?? 0}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Row(children: [const Text('RTW Status:', style: TextStyle(fontSize: 12)), const SizedBox(width: 12),
              for (final s in ['Off Sick', 'Light Duty', 'Full Duty']) Padding(padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(label: Text(s, style: const TextStyle(fontSize: 11)), selected: d['rtwStatus'] == s,
                  onSelected: (_) => _updateStatus(docs[i].id, 'rtwStatus', s),
                  selectedColor: XMTheme.success.withValues(alpha: 0.2), labelStyle: TextStyle(color: d['rtwStatus'] == s ? XMTheme.success : null))),
            ]),
          ])));
        });
      },
    );
  }

  Widget _complianceTab() {
    final items = [
      ('Register with COIDA Fund (RAF)', true),
      ('Annual Return of Earnings submitted', true),
      ('W.CL.2 form filed within 7 days of incident', true),
      ('Medical reports obtained from treating doctor', false),
      ('Employee notified of claim status', false),
      ('Return-to-work plan documented', false),
      ('COIDA claim file retained for 3 years', true),
      ('Compensation Commissioner correspondence filed', false),
      ('Section 56 investigation if applicable', false),
      ('Death benefit notifications processed', false),
    ];
    final done = items.where((e) => e.$2).length;
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
        gradient: LinearGradient(colors: [XMTheme.primary.withValues(alpha: 0.08), XMTheme.secondary.withValues(alpha: 0.04)]),
        borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('COIDA Compliance', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4), Text('$done / ${items.length} requirements met', style: const TextStyle(fontSize: 12)),
          ]),
          const Spacer(),
          CircularProgressIndicator(value: done / items.length, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest, color: XMTheme.success, strokeWidth: 6),
          const SizedBox(width: 8),
          Text('${(done / items.length * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ])),
      const SizedBox(height: 16),
      ...items.map((item) => Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(item.$2 ? Icons.check_circle : Icons.radio_button_unchecked, color: item.$2 ? XMTheme.success : Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(item.$1, style: TextStyle(fontSize: 13, color: item.$2 ? null : Theme.of(context).colorScheme.onSurfaceVariant))),
        ]))),
    ]));
  }

  Future<void> _updateStatus(String id, String field, String value) async {
    try { await ref.read(firestoreProvider).collection('coida_claims').doc(id).update({field: value}); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }
}

class _RtwBadge extends StatelessWidget {
  final String label;
  const _RtwBadge({required this.label});
  @override
  Widget build(BuildContext context) {
    final color = label == 'Full Duty' ? XMTheme.success : label == 'Light Duty' ? XMTheme.warning : XMTheme.error;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)));
  }
}
