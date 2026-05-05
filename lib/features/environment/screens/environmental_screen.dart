import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Environmental & ESG Management — waste manifests, spill response, emissions tracking, water/energy.
class EnvironmentalScreen extends ConsumerStatefulWidget {
  const EnvironmentalScreen({super.key});
  @override
  ConsumerState<EnvironmentalScreen> createState() => _EnvState();
}

class _EnvState extends ConsumerState<EnvironmentalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _showWasteForm = false, _showSpillForm = false, _showMetricForm = false, _isSubmitting = false;
  // Waste form
  String _wasteType = 'General', _wasteUnit = 'kg'; final String _wasteStatus = 'Pending Pickup';
  final _qtyCtrl = TextEditingController(), _transporterCtrl = TextEditingController(), _facilityCtrl = TextEditingController();
  // Spill form
  final _substanceCtrl = TextEditingController(), _volCtrl = TextEditingController(), _spillLocCtrl = TextEditingController();
  bool _contained = false, _reported = false;
  // ESG metric form
  String _esgCategory = 'Scope 1', _esgUnit = 'tCO2e'; final String _esgPeriod = '2026';
  final _esgValueCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); _qtyCtrl.dispose(); _transporterCtrl.dispose(); _facilityCtrl.dispose();
    _substanceCtrl.dispose(); _volCtrl.dispose(); _spillLocCtrl.dispose(); _esgValueCtrl.dispose(); super.dispose(); }

  Future<void> _submitWaste() async {
    if (_qtyCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'waste_manifests', data: {
        'wasteType': _wasteType, 'quantity': double.tryParse(_qtyCtrl.text) ?? 0, 'unit': _wasteUnit,
        'transporterName': _transporterCtrl.text.trim(), 'disposalFacility': _facilityCtrl.text.trim(),
        'status': _wasteStatus, 'authorId': p.uid, 'siteId': p.siteId, 'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manifest added'), backgroundColor: XMTheme.success));
        setState(() { _showWasteForm = false; _qtyCtrl.clear(); _transporterCtrl.clear(); _facilityCtrl.clear(); }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSubmitting = false); }
  }

  Future<void> _submitSpill() async {
    if (_substanceCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'environmental_spills', data: {
        'substance': _substanceCtrl.text.trim(), 'volume': _volCtrl.text.trim(),
        'location': _spillLocCtrl.text.trim(), 'contained': _contained,
        'reportedToAuthorities': _reported, 'authorId': p.uid, 'siteId': p.siteId,
        'dateOfSpill': DateTime.now().toIso8601String(), 'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spill logged'), backgroundColor: XMTheme.success));
        setState(() { _showSpillForm = false; _substanceCtrl.clear(); _volCtrl.clear(); _spillLocCtrl.clear(); _contained = false; _reported = false; }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSubmitting = false); }
  }

  Future<void> _submitMetric() async {
    if (_esgValueCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'esg_metrics', data: {
        'category': _esgCategory, 'value': double.tryParse(_esgValueCtrl.text) ?? 0,
        'unit': _esgUnit, 'period': _esgPeriod,
        'authorId': p.uid, 'siteId': p.siteId, 'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Metric added'), backgroundColor: XMTheme.success));
        setState(() { _showMetricForm = false; _esgValueCtrl.clear(); }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSubmitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Environmental & ESG'), bottom: TabBar(controller: _tabCtrl, isScrollable: true, tabAlignment: TabAlignment.start, tabs: const [
        Tab(icon: Icon(Icons.delete_outline, size: 16), text: 'Waste'), Tab(icon: Icon(Icons.water_drop, size: 16), text: 'Spills'),
        Tab(icon: Icon(Icons.eco, size: 16), text: 'ESG Metrics'), Tab(icon: Icon(Icons.bar_chart, size: 16), text: 'Analytics'),
      ])),
      body: TabBarView(controller: _tabCtrl, children: [_wasteTab(), _spillsTab(), _metricsTab(), _analyticsTab()]),
    );
  }

  Widget _wasteTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FilledButton.icon(onPressed: () => setState(() => _showWasteForm = !_showWasteForm),
          icon: Icon(_showWasteForm ? Icons.close : Icons.add, size: 18), label: Text(_showWasteForm ? 'Cancel' : 'Add Manifest'),
          style: FilledButton.styleFrom(backgroundColor: XMTheme.success)),
      ])),
      if (_showWasteForm) Card(elevation: 0, margin: const EdgeInsets.symmetric(horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(XMTheme.radiusLg), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Waste Manifest', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _wasteType, decoration: const InputDecoration(labelText: 'Waste Type', isDense: true),
            items: ['Hazardous', 'General', 'Recyclable', 'Medical', 'E-Waste'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _wasteType = v!))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity *', isDense: true))),
          const SizedBox(width: 12),
          SizedBox(width: 70, child: DropdownButtonFormField<String>(value: _wasteUnit, decoration: const InputDecoration(labelText: 'Unit', isDense: true),
            items: ['kg', 'tons', 'liters', 'm3'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _wasteUnit = v!))),
        ]), const SizedBox(height: 10),
        Row(children: [Expanded(child: TextFormField(controller: _transporterCtrl, decoration: const InputDecoration(labelText: 'Transporter'))),
          const SizedBox(width: 12), Expanded(child: TextFormField(controller: _facilityCtrl, decoration: const InputDecoration(labelText: 'Disposal Facility')))]), const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSubmitting ? null : _submitWaste, child: Text(_isSubmitting ? 'Saving...' : 'Save Manifest'))),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: siteId == null ? null : fs.collection('waste_manifests').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(50).snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No waste manifests'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final typeColor = d['wasteType'] == 'Hazardous' ? XMTheme.error : d['wasteType'] == 'Recyclable' ? XMTheme.success : XMTheme.info;
            return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(XMTheme.radiusLg), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
              child: Padding(padding: const EdgeInsets.all(12),
              child: Row(children: [
                Container(width: 4, height: 36, decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${d['wasteType']} — ${d['quantity']} ${d['unit']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${d['transporterName'] ?? ''} → ${d['disposalFacility'] ?? ''}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: XMTheme.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
                  child: Text(d['status'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: XMTheme.info))),
              ])));
          });
        },
      )),
    ]);
  }

  Widget _spillsTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FilledButton.icon(onPressed: () => setState(() => _showSpillForm = !_showSpillForm),
          icon: Icon(_showSpillForm ? Icons.close : Icons.add, size: 18), label: Text(_showSpillForm ? 'Cancel' : 'Log Spill'),
          style: FilledButton.styleFrom(backgroundColor: XMTheme.error)),
      ])),
      if (_showSpillForm) Card(elevation: 0, margin: const EdgeInsets.symmetric(horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(XMTheme.radiusLg), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Log Environmental Spill', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
        TextFormField(controller: _substanceCtrl, decoration: const InputDecoration(labelText: 'Substance *')), const SizedBox(height: 10),
        Row(children: [Expanded(child: TextFormField(controller: _volCtrl, decoration: const InputDecoration(labelText: 'Volume/Quantity'))),
          const SizedBox(width: 12), Expanded(child: TextFormField(controller: _spillLocCtrl, decoration: const InputDecoration(labelText: 'Location')))]), const SizedBox(height: 10),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: _contained, onChanged: (v) => setState(() => _contained = v!), title: const Text('Contained?', style: TextStyle(fontSize: 13)), controlAffinity: ListTileControlAffinity.leading),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: _reported, onChanged: (v) => setState(() => _reported = v!), title: const Text('Reported to Authorities?', style: TextStyle(fontSize: 13)), controlAffinity: ListTileControlAffinity.leading),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSubmitting ? null : _submitSpill, child: Text(_isSubmitting ? 'Saving...' : 'Save Spill'))),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: siteId == null ? null : fs.collection('environmental_spills').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(50).snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No spill records'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(XMTheme.radiusLg), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
              Icon(Icons.water_drop, color: d['contained'] == true ? XMTheme.success : XMTheme.error, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['substance'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${d['volume'] ?? ''} @ ${d['location'] ?? ''}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(
                color: (d['contained'] == true ? XMTheme.success : XMTheme.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
                child: Text(d['contained'] == true ? 'Contained' : 'Uncontained', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: d['contained'] == true ? XMTheme.success : XMTheme.error))),
            ])));
          });
        },
      )),
    ]);
  }

  Widget _metricsTab() {
    final siteId = ref.watch(currentSiteIdProvider); final fs = ref.watch(firestoreProvider);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FilledButton.icon(onPressed: () => setState(() => _showMetricForm = !_showMetricForm),
          icon: Icon(_showMetricForm ? Icons.close : Icons.add, size: 18), label: Text(_showMetricForm ? 'Cancel' : 'Add Metric')),
      ])),
      if (_showMetricForm) Card(elevation: 0, margin: const EdgeInsets.symmetric(horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(XMTheme.radiusLg), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ESG Metric', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _esgCategory, decoration: const InputDecoration(labelText: 'Category', isDense: true),
            items: ['Scope 1', 'Scope 2', 'Scope 3', 'Water', 'Waste', 'Diversity', 'Training', 'Ethics'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _esgCategory = v!))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: _esgValueCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Value *', isDense: true))),
          const SizedBox(width: 12),
          SizedBox(width: 80, child: TextFormField(initialValue: _esgUnit, onChanged: (v) => _esgUnit = v, decoration: const InputDecoration(labelText: 'Unit', isDense: true))),
        ]), const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSubmitting ? null : _submitMetric, child: Text(_isSubmitting ? 'Saving...' : 'Save Metric'))),
      ]))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: siteId == null ? null : fs.collection('esg_metrics').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(100).snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No ESG metrics'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(XMTheme.radiusLg), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: XMTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
                  child: Text(d['category'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: XMTheme.success))),
                const SizedBox(width: 16),
                Text('${d['value']} ${d['unit']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(d['period'] ?? '', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ])));
          });
        },
      )),
    ]);
  }

  Widget _analyticsTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Environmental Analytics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Performance overview for $siteId', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),

        // ─── Spill KPIs ───
        Text('Spill Response', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: fs.collection('environmental_spills').where('siteId', isEqualTo: siteId).snapshots(),
          builder: (ctx, snap) {
            final docs = snap.data?.docs ?? [];
            int total = docs.length, contained = 0, uncontained = 0;
            for (final doc in docs) {
              final d = doc.data() as Map<String, dynamic>;
              if (d['contained'] == true) { contained++; } else { uncontained++; }
            }
            return Wrap(spacing: 12, runSpacing: 12, children: [
              _AnalyticsKpi(label: 'Total Spills', value: '$total', icon: Icons.water_drop, color: XMTheme.info),
              _AnalyticsKpi(label: 'Contained', value: '$contained', icon: Icons.check_circle, color: XMTheme.success),
              _AnalyticsKpi(label: 'Uncontained', value: '$uncontained', icon: Icons.cancel, color: XMTheme.error),
              _AnalyticsKpi(label: 'Containment %', value: total > 0 ? '${(contained / total * 100).toStringAsFixed(0)}%' : '—', icon: Icons.percent, color: XMTheme.primary),
            ]);
          },
        ),
        const SizedBox(height: 24),

        // ─── Waste Distribution ───
        Text('Waste Distribution', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: fs.collection('waste_manifests').where('siteId', isEqualTo: siteId).snapshots(),
          builder: (ctx, snap) {
            final docs = snap.data?.docs ?? [];
            final byType = <String, int>{};
            for (final doc in docs) {
              final d = doc.data() as Map<String, dynamic>;
              final t = (d['wasteType'] ?? d['type'] ?? 'Other').toString();
              byType[t] = (byType[t] ?? 0) + 1;
            }
            if (byType.isEmpty) return const Text('No waste data');
            final total = byType.values.reduce((a, b) => a + b);
            return Column(children: byType.entries.map((e) {
              final pct = e.value / total;
              final color = e.key == 'Hazardous' ? XMTheme.error : e.key == 'Recyclable' ? XMTheme.success : e.key == 'General' ? XMTheme.info : XMTheme.warning;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  SizedBox(width: 100, child: Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: pct, minHeight: 14, backgroundColor: color.withValues(alpha: 0.1), color: color),
                  )),
                  const SizedBox(width: 8),
                  Text('${e.value} (${(pct * 100).toStringAsFixed(0)}%)', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ]),
              );
            }).toList());
          },
        ),
        const SizedBox(height: 24),

        // ─── ESG Scorecard ───
        Text('ESG Scorecard', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: fs.collection('esg_metrics').where('siteId', isEqualTo: siteId).snapshots(),
          builder: (ctx, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) return const Text('No ESG metrics');
            return Wrap(spacing: 12, runSpacing: 12, children: docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final metric = d['metric'] ?? d['category'] ?? 'Metric';
              final value = d['value']?.toString() ?? '0';
              final target = d['target']?.toString() ?? '';
              final status = d['status'] ?? '';
              final statusColor = status == 'On Track' || status == 'Achieved' ? XMTheme.success : XMTheme.warning;
              return Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(XMTheme.radiusLg),
                  side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
                child: Container(width: 180, padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(metric, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  if (target.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('Target: $target', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                  if (status.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
                      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                  ],
                ])),
              );
            }).toList());
          },
        ),
      ]),
    );
  }
}

class _AnalyticsKpi extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _AnalyticsKpi({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: EdgeInsets.zero,
    color: color.withValues(alpha: 0.06),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(XMTheme.radiusLg),
      side: BorderSide(color: color.withValues(alpha: 0.15)),
    ),
    child: Container(width: 140, padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ])),
  );
}
