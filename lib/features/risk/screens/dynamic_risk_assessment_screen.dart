import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Dynamic Risk Assessment — on-the-spot task risk evaluation with hazard/control chip lists.
class DynamicRiskAssessmentScreen extends ConsumerStatefulWidget {
  const DynamicRiskAssessmentScreen({super.key});
  @override
  ConsumerState<DynamicRiskAssessmentScreen> createState() => _DRAState();
}

class _DRAState extends ConsumerState<DynamicRiskAssessmentScreen> {
  bool _showForm = false, _isSubmitting = false, _isSafe = false;
  final _taskCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _hazardCtrl = TextEditingController();
  final _controlCtrl = TextEditingController();
  List<String> _hazards = [], _controls = [];

  @override
  void dispose() { _taskCtrl.dispose(); _locCtrl.dispose(); _hazardCtrl.dispose(); _controlCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_taskCtrl.text.isEmpty || _hazards.isEmpty || _controls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill task, hazards & controls'), backgroundColor: XMTheme.error));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'dynamic_risk_assessments', data: {
        'taskDescription': _taskCtrl.text.trim(), 'location': _locCtrl.text.trim(),
        'hazardsIdentified': _hazards, 'controlsApplied': _controls,
        'isSafeToProceed': _isSafe, 'authorId': profile.uid,
        'authorName': profile.displayName, 'siteId': profile.siteId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DRA submitted'), backgroundColor: XMTheme.success));
        setState(() { _showForm = false; _taskCtrl.clear(); _locCtrl.clear(); _hazards = []; _controls = []; _isSafe = false; });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: XMTheme.error));
    } finally { if (mounted) setState(() => _isSubmitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Scaffold(
      appBar: AppBar(title: const Text('Dynamic Risk Assessment'), actions: [
        FilledButton.icon(onPressed: () => setState(() => _showForm = !_showForm),
          icon: Icon(_showForm ? Icons.close : Icons.add, size: 18), label: Text(_showForm ? 'Cancel' : 'New DRA'),
          style: FilledButton.styleFrom(backgroundColor: XMTheme.warning)),
      ]),
      body: Column(children: [
        if (_showForm) _buildForm(),
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('dynamic_risk_assessments').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(50).snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.assignment, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 12), const Text('No DRAs found'),
            ]));
            return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _DRACard(data: data);
            });
          },
        )),
      ]),
    );
  }

  Widget _buildForm() {
    return Card(margin: const EdgeInsets.all(16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('New On-the-Spot Assessment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: XMTheme.warning)),
      const SizedBox(height: 12),
      TextFormField(controller: _taskCtrl, decoration: const InputDecoration(labelText: 'Task Description *', hintText: 'What task are you about to perform?')),
      const SizedBox(height: 12),
      TextFormField(controller: _locCtrl, decoration: const InputDecoration(labelText: 'Location *', prefixIcon: Icon(Icons.location_on))),
      const SizedBox(height: 16),
      // Hazards
      Text('Hazards Identified', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextFormField(controller: _hazardCtrl, decoration: const InputDecoration(hintText: 'Add hazard...', isDense: true))),
        const SizedBox(width: 8),
        FilledButton(onPressed: () { if (_hazardCtrl.text.isNotEmpty) { setState(() { _hazards.add(_hazardCtrl.text.trim()); _hazardCtrl.clear(); }); } }, child: const Text('Add')),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: _hazards.asMap().entries.map((e) => Chip(
        label: Text(e.value, style: const TextStyle(fontSize: 12)), deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => setState(() => _hazards.removeAt(e.key)),
        backgroundColor: XMTheme.error.withValues(alpha: 0.1), side: BorderSide(color: XMTheme.error.withValues(alpha: 0.3)),
      )).toList()),
      const SizedBox(height: 16),
      // Controls
      Text('Controls Applied', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextFormField(controller: _controlCtrl, decoration: const InputDecoration(hintText: 'Add control...', isDense: true))),
        const SizedBox(width: 8),
        FilledButton(onPressed: () { if (_controlCtrl.text.isNotEmpty) { setState(() { _controls.add(_controlCtrl.text.trim()); _controlCtrl.clear(); }); } }, child: const Text('Add')),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: _controls.asMap().entries.map((e) => Chip(
        label: Text(e.value, style: const TextStyle(fontSize: 12)), deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => setState(() => _controls.removeAt(e.key)),
        backgroundColor: XMTheme.success.withValues(alpha: 0.1), side: BorderSide(color: XMTheme.success.withValues(alpha: 0.3)),
      )).toList()),
      const SizedBox(height: 16),
      // Safe to proceed
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: XMTheme.warning.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: CheckboxListTile(contentPadding: EdgeInsets.zero, value: _isSafe, onChanged: (v) => setState(() => _isSafe = v!),
          title: const Text('I CONFIRM IT IS SAFE TO PROCEED', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          controlAffinity: ListTileControlAffinity.leading)),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: (_isSubmitting || !_isSafe) ? null : _submit,
        icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
        label: Text(_isSubmitting ? 'Saving...' : 'Submit DRA'),
        style: FilledButton.styleFrom(backgroundColor: XMTheme.warning),
      )),
    ])));
  }
}

class _DRACard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DRACard({required this.data});
  @override
  Widget build(BuildContext context) {
    final hazards = (data['hazardsIdentified'] as List?)?.cast<String>() ?? [];
    final controls = (data['controlsApplied'] as List?)?.cast<String>() ?? [];
    final isSafe = data['isSafeToProceed'] == true;
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Column(children: [
      // Header
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(Icons.warning_amber, color: XMTheme.warning, size: 16), const SizedBox(width: 6),
            Text('DRA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 1))]),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(
            color: (isSafe ? XMTheme.success : XMTheme.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(isSafe ? 'Safe' : 'Unsafe', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isSafe ? XMTheme.success : XMTheme.error))),
        ])),
      Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data['taskDescription'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        if (data['location'] != null) Row(children: [Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 4),
          Text(data['location'], style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))]),
        const SizedBox(height: 10),
        if (hazards.isNotEmpty) ...[const Text('Hazards', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)), const SizedBox(height: 4),
          Wrap(spacing: 4, runSpacing: 4, children: hazards.map((h) => Chip(label: Text(h, style: const TextStyle(fontSize: 10)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact,
            backgroundColor: XMTheme.error.withValues(alpha: 0.08), side: BorderSide(color: XMTheme.error.withValues(alpha: 0.2)))).toList()),
          const SizedBox(height: 8)],
        if (controls.isNotEmpty) ...[const Text('Controls', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)), const SizedBox(height: 4),
          Wrap(spacing: 4, runSpacing: 4, children: controls.map((c) => Chip(label: Text(c, style: const TextStyle(fontSize: 10)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact,
            backgroundColor: XMTheme.success.withValues(alpha: 0.08), side: BorderSide(color: XMTheme.success.withValues(alpha: 0.2)))).toList())],
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(data['authorName'] ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(_fmtDate(data['createdAt']), style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ])),
    ]));
  }
  String _fmtDate(String? iso) { if (iso == null) return ''; try { final dt = DateTime.parse(iso); return '${dt.day}/${dt.month}/${dt.year}'; } catch (_) { return iso ?? ''; } }
}
