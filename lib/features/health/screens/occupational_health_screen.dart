import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Occupational Health — medical exams, hygiene surveys, first aid log, wellbeing.
class OccupationalHealthScreen extends ConsumerStatefulWidget {
  const OccupationalHealthScreen({super.key});
  @override
  ConsumerState<OccupationalHealthScreen> createState() => _OHState();
}

class _OHState extends ConsumerState<OccupationalHealthScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _showMedForm = false, _showHygForm = false, _showFaForm = false, _isSub = false;

  // Medical form
  final _medEmpCtrl = TextEditingController(), _medIdCtrl = TextEditingController(), _medRestCtrl = TextEditingController();
  String _medType = 'Pre-employment', _medStatus = 'Fit';
  DateTime _medDate = DateTime.now(), _medNextDue = DateTime.now().add(const Duration(days: 365));

  // Hygiene survey form
  final _zoneCtrl = TextEditingController(), _readingCtrl = TextEditingController(), _limitCtrl = TextEditingController();
  String _hazardType = 'Noise';
  bool _requiresSurveillance = false;

  // First aid form
  final _faEmpCtrl = TextEditingController(), _faDescCtrl = TextEditingController(), _faTreatCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _tab = TabController(length: 4, vsync: this); }
  @override
  void dispose() {
    _tab.dispose();
    for (final c in [_medEmpCtrl, _medIdCtrl, _medRestCtrl, _zoneCtrl, _readingCtrl, _limitCtrl, _faEmpCtrl, _faDescCtrl, _faTreatCtrl]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _submitMedical() async {
    if (_medEmpCtrl.text.isEmpty) return;
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'medical_records', data: {
        'employeeName': _medEmpCtrl.text.trim(), 'idNumber': _medIdCtrl.text.trim(),
        'medicalType': _medType, 'status': _medStatus,
        'restrictions': _medRestCtrl.text.trim(),
        'dateConducted': _medDate.toIso8601String(), 'nextDueDate': _medNextDue.toIso8601String(),
        'authorId': p.uid, 'siteId': p.siteId, 'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medical record saved'), backgroundColor: XMTheme.success));
        setState(() { _showMedForm = false; _medEmpCtrl.clear(); _medIdCtrl.clear(); _medRestCtrl.clear(); }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSub = false); }
  }

  Future<void> _submitHygiene() async {
    if (_zoneCtrl.text.isEmpty) return;
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'hygiene_surveys', data: {
        'zoneName': _zoneCtrl.text.trim(), 'hazardType': _hazardType,
        'readingValue': _readingCtrl.text.trim(), 'legalLimit': _limitCtrl.text.trim(),
        'requiresMedicalSurveillance': _requiresSurveillance,
        'dateConducted': DateTime.now().toIso8601String(),
        'authorId': p.uid, 'siteId': p.siteId, 'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Survey saved'), backgroundColor: XMTheme.success));
        setState(() { _showHygForm = false; _zoneCtrl.clear(); _readingCtrl.clear(); _limitCtrl.clear(); }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSub = false); }
  }

  Future<void> _submitFirstAid() async {
    if (_faEmpCtrl.text.isEmpty) return;
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'first_aid_log', data: {
        'employeeName': _faEmpCtrl.text.trim(), 'description': _faDescCtrl.text.trim(),
        'treatment': _faTreatCtrl.text.trim(), 'date': DateTime.now().toIso8601String(),
        'authorId': p.uid, 'siteId': p.siteId, 'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('First aid entry saved'), backgroundColor: XMTheme.success));
        setState(() { _showFaForm = false; _faEmpCtrl.clear(); _faDescCtrl.clear(); _faTreatCtrl.clear(); }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSub = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Occupational Health'), bottom: TabBar(controller: _tab, isScrollable: true, tabAlignment: TabAlignment.start, tabs: const [
        Tab(icon: Icon(Icons.monitor_heart, size: 16), text: 'Medicals'),
        Tab(icon: Icon(Icons.science, size: 16), text: 'Hygiene'),
        Tab(icon: Icon(Icons.medical_services, size: 16), text: 'First Aid'),
        Tab(icon: Icon(Icons.favorite, size: 16), text: 'Wellbeing'),
      ])),
      body: TabBarView(controller: _tab, children: [_medicalsTab(), _hygieneTab(), _firstAidTab(), _wellbeingTab()]),
    );
  }

  Widget _medicalsTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        // Stats
        _OHStat(label: 'Fit', icon: Icons.check_circle, color: XMTheme.success),
        _OHStat(label: 'Restricted', icon: Icons.warning, color: XMTheme.warning),
        _OHStat(label: 'Unfit', icon: Icons.cancel, color: XMTheme.error),
        FilledButton.icon(onPressed: () => setState(() => _showMedForm = !_showMedForm),
          icon: Icon(_showMedForm ? Icons.close : Icons.add, size: 16), label: Text(_showMedForm ? 'Cancel' : 'Add'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
      ])),
      if (_showMedForm) Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Medical Examination Record', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
        Row(children: [Expanded(child: TextFormField(controller: _medEmpCtrl, decoration: const InputDecoration(labelText: 'Employee Name *'))),
          const SizedBox(width: 12), Expanded(child: TextFormField(controller: _medIdCtrl, decoration: const InputDecoration(labelText: 'ID Number')))]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _medType, decoration: const InputDecoration(labelText: 'Exam Type', isDense: true),
            items: ['Pre-employment', 'Annual', 'Exit', 'Baseline', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _medType = v!))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(value: _medStatus, decoration: const InputDecoration(labelText: 'Fitness Status', isDense: true),
            items: ['Fit', 'Fit with Restrictions', 'Unfit'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _medStatus = v!))),
        ]), const SizedBox(height: 10),
        TextFormField(controller: _medRestCtrl, decoration: const InputDecoration(labelText: 'Restrictions (if any)')), const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ListTile(contentPadding: EdgeInsets.zero, title: const Text('Conducted', style: TextStyle(fontSize: 11)),
            subtitle: Text('${_medDate.day}/${_medDate.month}/${_medDate.year}'),
            onTap: () async { final d = await showDatePicker(context: context, initialDate: _medDate, firstDate: DateTime(2020), lastDate: DateTime.now()); if (d != null) setState(() => _medDate = d); })),
          Expanded(child: ListTile(contentPadding: EdgeInsets.zero, title: const Text('Next Due', style: TextStyle(fontSize: 11)),
            subtitle: Text('${_medNextDue.day}/${_medNextDue.month}/${_medNextDue.year}'),
            onTap: () async { final d = await showDatePicker(context: context, initialDate: _medNextDue, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 1825))); if (d != null) setState(() => _medNextDue = d); })),
        ]),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSub ? null : _submitMedical, child: Text(_isSub ? 'Saving…' : 'Save Record'))),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: siteId == null ? null : fs.collection('medical_records').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(100).snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No medical records'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final c = d['status'] == 'Fit' ? XMTheme.success : d['status'] == 'Unfit' ? XMTheme.error : XMTheme.warning;
            return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['employeeName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${d['medicalType']} • ${d['idNumber'] ?? ''}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(d['status'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c))),
              ]));
          });
        },
      )),
    ]);
  }

  Widget _hygieneTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FilledButton.icon(onPressed: () => setState(() => _showHygForm = !_showHygForm),
          icon: Icon(_showHygForm ? Icons.close : Icons.add, size: 18), label: Text(_showHygForm ? 'Cancel' : 'Add Survey')),
      ])),
      if (_showHygForm) Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hygiene Survey', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
        TextFormField(controller: _zoneCtrl, decoration: const InputDecoration(labelText: 'Zone / Area *')), const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: _hazardType, decoration: const InputDecoration(labelText: 'Hazard Type'),
          items: ['Noise', 'Dust', 'Chemical', 'Ergonomic', 'Illumination', 'Thermal', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _hazardType = v!)),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: TextFormField(controller: _readingCtrl, decoration: const InputDecoration(labelText: 'Reading Value'))),
          const SizedBox(width: 12), Expanded(child: TextFormField(controller: _limitCtrl, decoration: const InputDecoration(labelText: 'Legal Limit')))]),
        const SizedBox(height: 10),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: _requiresSurveillance, onChanged: (v) => setState(() => _requiresSurveillance = v!),
          title: const Text('Requires Medical Surveillance?', style: TextStyle(fontSize: 13)), controlAffinity: ListTileControlAffinity.leading),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSub ? null : _submitHygiene, child: Text(_isSub ? 'Saving…' : 'Save Survey'))),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: siteId == null ? null : fs.collection('hygiene_surveys').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(50).snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No hygiene surveys'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(d['zoneName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: XMTheme.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(d['hazardType'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: XMTheme.info))),
              ]),
              const SizedBox(height: 4),
              Text('Reading: ${d['readingValue']} / Limit: ${d['legalLimit']}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              if (d['requiresMedicalSurveillance'] == true) Container(margin: const EdgeInsets.only(top: 6), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: XMTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: const Text('⚠ Medical Surveillance Required', style: TextStyle(fontSize: 10, color: XMTheme.warning))),
            ])));
          });
        },
      )),
    ]);
  }

  Widget _firstAidTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FilledButton.icon(onPressed: () => setState(() => _showFaForm = !_showFaForm),
          icon: Icon(_showFaForm ? Icons.close : Icons.add, size: 18), label: Text(_showFaForm ? 'Cancel' : 'Log Entry'),
          style: FilledButton.styleFrom(backgroundColor: XMTheme.error)),
      ])),
      if (_showFaForm) Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('First Aid Entry', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
        TextFormField(controller: _faEmpCtrl, decoration: const InputDecoration(labelText: 'Employee / Person *')), const SizedBox(height: 10),
        TextFormField(controller: _faDescCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Injury / Complaint Description')), const SizedBox(height: 10),
        TextFormField(controller: _faTreatCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Treatment Provided')), const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSub ? null : _submitFirstAid, child: Text(_isSub ? 'Saving…' : 'Save Entry'))),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: siteId == null ? null : fs.collection('first_aid_log').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(50).snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No first aid entries'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0x1AEF4444), child: Icon(Icons.medical_services, color: XMTheme.error, size: 20)),
              title: Text(d['employeeName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text(d['description'] ?? '', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(_fmtDate(d['date']), style: const TextStyle(fontSize: 11)),
            ));
          });
        },
      )),
    ]);
  }

  Widget _wellbeingTab() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Wellbeing Initiatives', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 16),
      _WellbeingCard(title: 'Mental Health Support', subtitle: 'Employee Assistance Programme (EAP) available 24/7', icon: Icons.psychology, color: XMTheme.primary),
      _WellbeingCard(title: 'Fatigue Management', subtitle: 'Shift rotation monitoring and rest period compliance', icon: Icons.bedtime, color: XMTheme.secondary),
      _WellbeingCard(title: 'Substance Awareness', subtitle: 'Alcohol & drug awareness training schedule', icon: Icons.local_bar, color: XMTheme.warning),
      _WellbeingCard(title: 'Wellness Campaigns', subtitle: 'Monthly health campaigns and screening drives', icon: Icons.favorite, color: XMTheme.error),
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
        gradient: LinearGradient(colors: [XMTheme.success.withValues(alpha: 0.08), XMTheme.primary.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(12), border: Border.all(color: XMTheme.success.withValues(alpha: 0.2))),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.tips_and_updates, color: XMTheme.success, size: 18), SizedBox(width: 8), Text('EAP Helpline', style: TextStyle(fontWeight: FontWeight.w700))]),
          SizedBox(height: 8),
          Text('0800 611 655 — Confidential, free, 24/7 counselling and support services available to all employees.', style: TextStyle(fontSize: 13, height: 1.4)),
        ])),
    ]));
  }

  String _fmtDate(String? iso) { if (iso == null) return ''; try { final dt = DateTime.parse(iso); return '${dt.day}/${dt.month}/${dt.year}'; } catch (_) { return ''; } }
}

class _OHStat extends StatelessWidget {
  final String label; final IconData icon; final Color color;
  const _OHStat({required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 16), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))]);
}

class _WellbeingCard extends StatelessWidget {
  final String title, subtitle; final IconData icon; final Color color;
  const _WellbeingCard({required this.title, required this.subtitle, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Row(children: [Icon(icon, color: color, size: 22), const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]))
    ]));
}
