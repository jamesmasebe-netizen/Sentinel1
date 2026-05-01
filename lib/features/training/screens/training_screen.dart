import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Training & Competency — training records, toolbox talks, expiry alerts.
class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});
  @override
  ConsumerState<TrainingScreen> createState() => _TrainingState();
}

class _TrainingState extends ConsumerState<TrainingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _showRecordForm = false, _showTalkForm = false, _isSubmitting = false;

  // Training record form
  final _empNameCtrl = TextEditingController();
  final _idNumCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  DateTime _completed = DateTime.now();
  DateTime _expiry = DateTime.now().add(const Duration(days: 365));

  // Toolbox talk form
  final _topicCtrl = TextEditingController();
  final _talkLocCtrl = TextEditingController();
  final _attendeesCtrl = TextEditingController();
  final DateTime _talkDate = DateTime.now();

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); _empNameCtrl.dispose(); _idNumCtrl.dispose(); _courseCtrl.dispose(); _topicCtrl.dispose(); _talkLocCtrl.dispose(); _attendeesCtrl.dispose(); super.dispose(); }

  Future<void> _submitRecord() async {
    if (_empNameCtrl.text.isEmpty || _courseCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      final status = _expiry.isAfter(DateTime.now()) ? 'Active' : 'Expired';
      await ref.read(firestoreServiceProvider).createDocument(collection: 'training_records', data: {
        'employeeName': _empNameCtrl.text.trim(), 'idNumber': _idNumCtrl.text.trim(),
        'courseName': _courseCtrl.text.trim(), 'dateCompleted': _completed.toIso8601String(),
        'expiryDate': _expiry.toIso8601String(), 'status': status,
        'authorId': profile.uid, 'siteId': profile.siteId, 'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record added'), backgroundColor: XMTheme.success));
        setState(() { _showRecordForm = false; _empNameCtrl.clear(); _idNumCtrl.clear(); _courseCtrl.clear(); }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSubmitting = false); }
  }

  Future<void> _submitTalk() async {
    if (_topicCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      final attendees = _attendeesCtrl.text.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
      await ref.read(firestoreServiceProvider).createDocument(collection: 'toolbox_talks', data: {
        'topic': _topicCtrl.text.trim(), 'date': _talkDate.toIso8601String(),
        'conductorName': profile.displayName, 'location': _talkLocCtrl.text.trim(),
        'attendees': attendees, 'authorId': profile.uid, 'siteId': profile.siteId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Talk logged'), backgroundColor: XMTheme.success));
        setState(() { _showTalkForm = false; _topicCtrl.clear(); _talkLocCtrl.clear(); _attendeesCtrl.clear(); }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSubmitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training & Competency'), bottom: TabBar(controller: _tabCtrl, tabs: const [
        Tab(text: 'Records'), Tab(text: 'Toolbox Talks'), Tab(text: 'Expiry Alerts'),
      ])),
      body: TabBarView(controller: _tabCtrl, children: [_recordsTab(), _toolboxTab(), _expiryTab()]),
    );
  }

  Widget _recordsTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FilledButton.icon(onPressed: () => setState(() => _showRecordForm = !_showRecordForm),
          icon: Icon(_showRecordForm ? Icons.close : Icons.add, size: 18), label: Text(_showRecordForm ? 'Cancel' : 'Add Record')),
      ])),
      if (_showRecordForm) Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add Training Record', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
        TextFormField(controller: _empNameCtrl, decoration: const InputDecoration(labelText: 'Employee Name *')), const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(controller: _idNumCtrl, decoration: const InputDecoration(labelText: 'ID Number', isDense: true))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: _courseCtrl, decoration: const InputDecoration(labelText: 'Course Name *', isDense: true))),
        ]), const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ListTile(contentPadding: EdgeInsets.zero, title: const Text('Completed', style: TextStyle(fontSize: 12)),
            subtitle: Text('${_completed.day}/${_completed.month}/${_completed.year}', style: const TextStyle(fontSize: 13)),
            onTap: () async { final d = await showDatePicker(context: context, initialDate: _completed, firstDate: DateTime(2020), lastDate: DateTime.now()); if (d != null) setState(() => _completed = d); })),
          Expanded(child: ListTile(contentPadding: EdgeInsets.zero, title: const Text('Expiry', style: TextStyle(fontSize: 12)),
            subtitle: Text('${_expiry.day}/${_expiry.month}/${_expiry.year}', style: const TextStyle(fontSize: 13)),
            onTap: () async { final d = await showDatePicker(context: context, initialDate: _expiry, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 1825))); if (d != null) setState(() => _expiry = d); })),
        ]), const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSubmitting ? null : _submitRecord, child: Text(_isSubmitting ? 'Saving...' : 'Save Record'))),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: siteId == null ? null : firestore.collection('training_records').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(100).snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No training records'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final isExpired = d['status'] == 'Expired';
            return Container(margin: const EdgeInsets.only(bottom: 1), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
              child: Row(children: [
                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['employeeName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(d['courseName'] ?? '', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(
                  color: (isExpired ? XMTheme.error : XMTheme.success).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(d['status'] ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isExpired ? XMTheme.error : XMTheme.success))),
              ]));
          });
        },
      )),
    ]);
  }

  Widget _toolboxTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FilledButton.icon(onPressed: () => setState(() => _showTalkForm = !_showTalkForm),
          icon: Icon(_showTalkForm ? Icons.close : Icons.add, size: 18), label: Text(_showTalkForm ? 'Cancel' : 'Log Talk')),
      ])),
      if (_showTalkForm) Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Log Toolbox Talk', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
        TextFormField(controller: _topicCtrl, decoration: const InputDecoration(labelText: 'Topic *')), const SizedBox(height: 12),
        TextFormField(controller: _talkLocCtrl, decoration: const InputDecoration(labelText: 'Location')), const SizedBox(height: 12),
        TextFormField(controller: _attendeesCtrl, decoration: const InputDecoration(labelText: 'Attendees (comma-separated)')), const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSubmitting ? null : _submitTalk, child: Text(_isSubmitting ? 'Saving...' : 'Save Talk'))),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: siteId == null ? null : firestore.collection('toolbox_talks').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(50).snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No toolbox talks logged'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final attendees = (d['attendees'] as List?)?.cast<String>() ?? [];
            return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['topic'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Row(children: [
                if (d['location'] != null) ...[Icon(Icons.location_on, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 4),
                  Text(d['location'], style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(width: 12)],
                Icon(Icons.people, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 4),
                Text('${attendees.length} attendees', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ])));
          });
        },
      )),
    ]);
  }

  Widget _expiryTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    return StreamBuilder<QuerySnapshot>(
      stream: siteId == null ? null : firestore.collection('training_records').where('siteId', isEqualTo: siteId).where('status', isEqualTo: 'Active').snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        // Filter to those expiring within 60 days
        final expiring = docs.where((d) {
          try { final exp = DateTime.parse((d.data() as Map<String, dynamic>)['expiryDate']); return exp.difference(DateTime.now()).inDays <= 60 && exp.isAfter(DateTime.now()); } catch (_) { return false; }
        }).toList();
        if (expiring.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_outline, size: 48, color: XMTheme.success.withValues(alpha: 0.4)), const SizedBox(height: 12),
          const Text('No upcoming expirations'), Text('All certifications current', style: Theme.of(context).textTheme.bodySmall),
        ]));
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: expiring.length, itemBuilder: (ctx, i) {
          final d = expiring[i].data() as Map<String, dynamic>;
          final daysLeft = DateTime.parse(d['expiryDate']).difference(DateTime.now()).inDays;
          final urgent = daysLeft <= 14;
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: (urgent ? XMTheme.error : XMTheme.warning).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: (urgent ? XMTheme.error : XMTheme.warning).withValues(alpha: 0.2))),
            child: Row(children: [
              Icon(urgent ? Icons.error : Icons.warning_amber, color: urgent ? XMTheme.error : XMTheme.warning, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['employeeName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(d['courseName'] ?? '', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(
                color: (urgent ? XMTheme.error : XMTheme.warning).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Text('$daysLeft days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: urgent ? XMTheme.error : XMTheme.warning))),
            ]),
          );
        });
      },
    );
  }
}
