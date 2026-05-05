import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Baseline HIRA (Hazard Identification & Risk Assessment) — full CRUD register.
class HiraScreen extends ConsumerStatefulWidget {
  const HiraScreen({super.key});
  @override
  ConsumerState<HiraScreen> createState() => _HiraScreenState();
}

class _HiraScreenState extends ConsumerState<HiraScreen> {
  bool _showForm = false;
  final _titleCtrl = TextEditingController();
  final _hazardCtrl = TextEditingController();
  final _consequenceCtrl = TextEditingController();
  String _likelihood = 'Possible';
  String _severity = 'Major';
  String _controlMeasure = '';
  bool _isSubmitting = false;

  static const _likelihoods = ['Rare', 'Unlikely', 'Possible', 'Likely', 'Almost Certain'];
  static const _severities = ['Negligible', 'Minor', 'Moderate', 'Major', 'Catastrophic'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _hazardCtrl.dispose();
    _consequenceCtrl.dispose();
    super.dispose();
  }

  int _riskScore(String likelihood, String severity) {
    final l = _likelihoods.indexOf(likelihood) + 1;
    final s = _severities.indexOf(severity) + 1;
    return l * s;
  }

  String _riskLevel(int score) {
    if (score >= 16) return 'Extreme';
    if (score >= 10) return 'High';
    if (score >= 5) return 'Medium';
    return 'Low';
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _hazardCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill title and hazard'), backgroundColor: XMTheme.error));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      final score = _riskScore(_likelihood, _severity);
      await ref.read(firestoreServiceProvider).createDocument(collection: 'risk_assessments', data: {
        'title': _titleCtrl.text.trim(),
        'hazard': _hazardCtrl.text.trim(),
        'consequence': _consequenceCtrl.text.trim(),
        'likelihood': _likelihood,
        'severity': _severity,
        'riskScore': score,
        'riskLevel': _riskLevel(score),
        'controlMeasure': _controlMeasure,
        'status': 'Active',
        'assessorId': profile.uid,
        'siteId': profile.siteId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('HIRA created'), backgroundColor: XMTheme.success));
        setState(() { _showForm = false; _titleCtrl.clear(); _hazardCtrl.clear(); _consequenceCtrl.clear(); });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: XMTheme.error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Baseline Risk Assessments (HIRA)', style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
            FilledButton.icon(
              onPressed: () => setState(() => _showForm = !_showForm),
              icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
              label: Text(_showForm ? 'Cancel' : 'New HIRA'),
            ),
          ],
        ),
      ),
      if (_showForm) _buildForm(context),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('risk_assessments').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(50).snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (docs.isEmpty) return const Center(child: Text('No HIRA records'));
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final level = d['riskLevel'] ?? 'Low';
                final score = d['riskScore'] ?? 0;
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(XMTheme.radiusLg),
                    side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: _levelColor(level).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
                          child: Text('$level ($score)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _levelColor(level))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 8),
                      Text('Hazard: ${d['hazard'] ?? ''}', style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (d['consequence'] != null && d['consequence'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Consequence: ${d['consequence']}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, children: [
                        _Chip(label: 'L: ${d['likelihood']}'),
                        _Chip(label: 'S: ${d['severity']}'),
                        if (d['controlMeasure'] != null && d['controlMeasure'].toString().isNotEmpty)
                          _Chip(label: d['controlMeasure']),
                      ]),
                    ]),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildForm(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('New Risk Assessment', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Assessment Title *', prefixIcon: Icon(Icons.title))),
          const SizedBox(height: 12),
          TextFormField(controller: _hazardCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Hazard Description *', prefixIcon: Icon(Icons.warning), alignLabelWithHint: true)),
          const SizedBox(height: 12),
          TextFormField(controller: _consequenceCtrl, decoration: const InputDecoration(labelText: 'Potential Consequence', prefixIcon: Icon(Icons.dangerous))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: _likelihood, decoration: const InputDecoration(labelText: 'Likelihood'),
              items: _likelihoods.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _likelihood = v!),
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(
              value: _severity, decoration: const InputDecoration(labelText: 'Severity'),
              items: _severities.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _severity = v!),
            )),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _levelColor(_riskLevel(_riskScore(_likelihood, _severity))).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
            child: Row(children: [
              Icon(Icons.speed, size: 16, color: _levelColor(_riskLevel(_riskScore(_likelihood, _severity)))),
              const SizedBox(width: 8),
              Text('Risk Score: ${_riskScore(_likelihood, _severity)} — ${_riskLevel(_riskScore(_likelihood, _severity))}',
                style: TextStyle(fontWeight: FontWeight.w700, color: _levelColor(_riskLevel(_riskScore(_likelihood, _severity))))),
            ]),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _controlMeasure.isEmpty ? null : _controlMeasure,
            decoration: const InputDecoration(labelText: 'Control Measure'),
            items: ['Elimination', 'Substitution', 'Engineering Controls', 'Administrative Controls', 'PPE']
                .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _controlMeasure = v ?? ''),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            label: Text(_isSubmitting ? 'Creating...' : 'Create HIRA'),
          )),
        ]),
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Extreme': return XMTheme.riskExtreme;
      case 'High': return XMTheme.riskHigh;
      case 'Medium': return XMTheme.riskMedium;
      default: return XMTheme.riskLow;
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
    child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
  );
}
