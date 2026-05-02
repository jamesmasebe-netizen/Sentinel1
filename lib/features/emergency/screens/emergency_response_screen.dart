import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Emergency Response — drills, equipment inventory, contacts, broadcast.
class EmergencyResponseScreen extends ConsumerStatefulWidget {
  const EmergencyResponseScreen({super.key});
  @override
  ConsumerState<EmergencyResponseScreen> createState() => _EmergencyState();
}

class _EmergencyState extends ConsumerState<EmergencyResponseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _showDrillForm = false, _showEquipForm = false, _isSubmitting = false;
  // Drill form
  String _drillType = 'Fire';
  final _dateCtrl = TextEditingController(), _durationCtrl = TextEditingController();
  final _evalCtrl = TextEditingController(), _scenarioCtrl = TextEditingController(), _improvementsCtrl = TextEditingController();
  // Equipment form
  String _equipType = 'Extinguisher', _equipStatus = 'Operational';
  final _equipLocCtrl = TextEditingController(), _inspDateCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); _dateCtrl.dispose(); _durationCtrl.dispose(); _evalCtrl.dispose();
    _scenarioCtrl.dispose(); _improvementsCtrl.dispose(); _equipLocCtrl.dispose(); _inspDateCtrl.dispose(); super.dispose(); }

  Future<void> _submitDrill() async {
    if (_scenarioCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'emergency_drills', data: {
        'drillType': _drillType, 'dateConducted': _dateCtrl.text.trim(),
        'durationMinutes': int.tryParse(_durationCtrl.text) ?? 0,
        'evaluatorName': _evalCtrl.text.trim(), 'scenarioDescription': _scenarioCtrl.text.trim(),
        'areasForImprovement': _improvementsCtrl.text.trim(),
        'authorId': p.uid, 'siteId': p.siteId, 'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Drill logged'), backgroundColor: XMTheme.success));
        setState(() { _showDrillForm = false; _scenarioCtrl.clear(); _evalCtrl.clear(); _durationCtrl.clear(); _improvementsCtrl.clear(); }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSubmitting = false); }
  }

  Future<void> _submitEquipment() async {
    if (_equipLocCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'emergency_equipment', data: {
        'equipmentType': _equipType, 'location': _equipLocCtrl.text.trim(),
        'nextInspectionDate': _inspDateCtrl.text.trim(), 'status': _equipStatus,
        'authorId': p.uid, 'siteId': p.siteId, 'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipment added'), backgroundColor: XMTheme.success));
        setState(() { _showEquipForm = false; _equipLocCtrl.clear(); _inspDateCtrl.clear(); }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSubmitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Response'), bottom: TabBar(controller: _tabCtrl, tabs: const [
        Tab(text: 'Drills'), Tab(text: 'Equipment'), Tab(text: 'Contacts'), Tab(text: 'Broadcast'),
      ])),
      body: TabBarView(controller: _tabCtrl, children: [_drillsTab(), _equipmentTab(), _contactsTab(), _broadcastTab()]),
    );
  }

  Widget _drillsTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FilledButton.icon(onPressed: () => setState(() => _showDrillForm = !_showDrillForm),
          icon: Icon(_showDrillForm ? Icons.close : Icons.add, size: 18), label: Text(_showDrillForm ? 'Cancel' : 'Log Drill'),
          style: FilledButton.styleFrom(backgroundColor: XMTheme.error)),
      ])),
      if (_showDrillForm) Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Log Emergency Drill', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _drillType, decoration: const InputDecoration(labelText: 'Drill Type', isDense: true),
            items: ['Fire', 'Medical', 'Spill', 'Security', 'Evacuation', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _drillType = v!))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: _durationCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (mins)', isDense: true))),
        ]), const SizedBox(height: 10),
        TextFormField(controller: _scenarioCtrl, decoration: const InputDecoration(labelText: 'Scenario Description *')), const SizedBox(height: 10),
        TextFormField(controller: _evalCtrl, decoration: const InputDecoration(labelText: 'Evaluator Name')), const SizedBox(height: 10),
        TextFormField(controller: _improvementsCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Areas for Improvement')), const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSubmitting ? null : _submitDrill, child: Text(_isSubmitting ? 'Saving...' : 'Save Drill'))),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: siteId == null ? null : fs.collection('emergency_drills').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(50).snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No drills logged'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
              leading: Icon(_drillIcon(d['drillType']), color: XMTheme.error),
              title: Text('${d['drillType']} Drill', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${d['durationMinutes'] ?? 0} min • ${d['evaluatorName'] ?? ''}', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 120), child: Text(d['scenarioDescription'] ?? '', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ));
          });
        },
      )),
    ]);
  }

  Widget _equipmentTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FilledButton.icon(onPressed: () => setState(() => _showEquipForm = !_showEquipForm),
          icon: Icon(_showEquipForm ? Icons.close : Icons.add, size: 18), label: Text(_showEquipForm ? 'Cancel' : 'Add Equipment')),
      ])),
      if (_showEquipForm) Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add Equipment', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _equipType, decoration: const InputDecoration(labelText: 'Type', isDense: true),
            items: ['Extinguisher', 'First Aid Kit', 'Spill Kit', 'AED', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _equipType = v!))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(value: _equipStatus, decoration: const InputDecoration(labelText: 'Status', isDense: true),
            items: ['Operational', 'Needs Inspection', 'Out of Service'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _equipStatus = v!))),
        ]), const SizedBox(height: 10),
        TextFormField(controller: _equipLocCtrl, decoration: const InputDecoration(labelText: 'Location *')), const SizedBox(height: 10),
        TextFormField(controller: _inspDateCtrl, decoration: const InputDecoration(labelText: 'Next Inspection Date (YYYY-MM-DD)')), const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSubmitting ? null : _submitEquipment, child: Text(_isSubmitting ? 'Saving...' : 'Save Equipment'))),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: siteId == null ? null : fs.collection('emergency_equipment').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(100).snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No equipment records'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final statusColor = d['status'] == 'Operational' ? XMTheme.success : d['status'] == 'Out of Service' ? XMTheme.error : XMTheme.warning;
            return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(_equipIcon(d['equipmentType']), size: 20, color: statusColor), const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['equipmentType'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(d['location'] ?? '', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(d['status'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
              ]));
          });
        },
      )),
    ]);
  }

  Widget _contactsTab() => Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Emergency Contacts', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 16),
    _ContactCard(name: 'Fire Department', number: '10111', icon: Icons.local_fire_department, color: XMTheme.error),
    _ContactCard(name: 'Ambulance / EMS', number: '10177', icon: Icons.local_hospital, color: XMTheme.info),
    _ContactCard(name: 'Police / SAPS', number: '10111', icon: Icons.local_police, color: XMTheme.primary),
    _ContactCard(name: 'Poison Information', number: '0800 111 990', icon: Icons.warning, color: XMTheme.warning),
    _ContactCard(name: 'SHE Manager', number: 'On-site ext. 201', icon: Icons.person, color: XMTheme.success),
    _ContactCard(name: 'Environmental Officer', number: 'On-site ext. 205', icon: Icons.eco, color: XMTheme.success),
  ]));

  Widget _broadcastTab() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: XMTheme.error.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: const Icon(Icons.campaign, size: 64, color: XMTheme.error)),
    const SizedBox(height: 20),
    Text('Emergency Broadcast', style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 8), const Text('Push notifications & SMS alerts to all personnel'),
    const SizedBox(height: 24),
    FilledButton.icon(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast system connected. Configure in Firebase Cloud Messaging.'), backgroundColor: XMTheme.info)); },
      icon: const Icon(Icons.send), label: const Text('Test Broadcast'), style: FilledButton.styleFrom(backgroundColor: XMTheme.error)),
  ]));

  IconData _drillIcon(String? type) { switch (type) { case 'Fire': return Icons.local_fire_department; case 'Medical': return Icons.local_hospital; case 'Spill': return Icons.water_drop; case 'Security': return Icons.security; default: return Icons.emergency; } }
  IconData _equipIcon(String? type) { switch (type) { case 'Extinguisher': return Icons.fire_extinguisher; case 'First Aid Kit': return Icons.medical_services; case 'AED': return Icons.monitor_heart; case 'Spill Kit': return Icons.cleaning_services; default: return Icons.build; } }
}

class _ContactCard extends StatelessWidget {
  final String name, number; final IconData icon; final Color color;
  const _ContactCard({required this.name, required this.number, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Row(children: [
      Icon(icon, color: color, size: 24), const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(number, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      Icon(Icons.phone, color: color, size: 20),
    ]),
  );
}
