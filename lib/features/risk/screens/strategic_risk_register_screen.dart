import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Strategic Risk Register — corporate-level risks with likelihood × impact scoring.
class StrategicRiskRegisterScreen extends ConsumerStatefulWidget {
  const StrategicRiskRegisterScreen({super.key});
  @override
  ConsumerState<StrategicRiskRegisterScreen> createState() => _StrategicRiskRegisterScreenState();
}

class _StrategicRiskRegisterScreenState extends ConsumerState<StrategicRiskRegisterScreen> {
  bool _showForm = false;
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _mitigationCtrl = TextEditingController();
  String _category = 'Operational';
  String _likelihood = 'Possible';
  String _impact = 'Significant';
  String _status = 'Open';
  bool _isSubmitting = false;

  static const _categories = ['Operational', 'Financial', 'Regulatory', 'Reputational', 'Strategic', 'Environmental'];
  static const _likelihoods = ['Rare', 'Unlikely', 'Possible', 'Likely', 'Almost Certain'];
  static const _impacts = ['Negligible', 'Minor', 'Moderate', 'Significant', 'Severe'];
  static const _statuses = ['Open', 'Mitigating', 'Monitoring', 'Closed'];

  @override
  void dispose() { _titleCtrl.dispose(); _descriptionCtrl.dispose(); _ownerCtrl.dispose(); _mitigationCtrl.dispose(); super.dispose(); }

  int _riskScore() => (_likelihoods.indexOf(_likelihood) + 1) * (_impacts.indexOf(_impact) + 1);

  String _riskRating(int score) {
    if (score >= 16) return 'Critical';
    if (score >= 10) return 'High';
    if (score >= 5) return 'Medium';
    return 'Low';
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill title'), backgroundColor: XMTheme.error));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      final score = _riskScore();
      await ref.read(firestoreServiceProvider).createDocument(collection: 'strategic_risks', data: {
        'title': _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'category': _category,
        'owner': _ownerCtrl.text.trim(),
        'likelihood': _likelihood,
        'impact': _impact,
        'riskScore': score,
        'riskRating': _riskRating(score),
        'mitigation': _mitigationCtrl.text.trim(),
        'status': _status,
        'authorId': profile.uid,
        'siteId': profile.siteId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Strategic risk created'), backgroundColor: XMTheme.success));
        setState(() { _showForm = false; _titleCtrl.clear(); _descriptionCtrl.clear(); _ownerCtrl.clear(); _mitigationCtrl.clear(); });
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
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text('Strategic Risk Register', style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
          FilledButton.icon(
            onPressed: () => setState(() => _showForm = !_showForm),
            icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
            label: Text(_showForm ? 'Cancel' : 'New Risk'),
          ),
        ]),
      ),
      if (_showForm) _buildForm(context),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('strategic_risks').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(50).snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (docs.isEmpty) return const Center(child: Text('No strategic risks'));
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final rating = d['riskRating'] ?? 'Low';
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
                          decoration: BoxDecoration(color: _ratingColor(rating).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
                          child: Text('$rating ($score)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _ratingColor(rating))),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
                          child: Text(d['category'] ?? '', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSecondaryContainer)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _statusColor(d['status'] ?? 'Open').withValues(alpha: 0.1), borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
                          child: Text(d['status'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(d['status'] ?? 'Open'))),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      if (d['description'] != null && d['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(d['description'], style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Row(children: [
                        if (d['owner'] != null && d['owner'].toString().isNotEmpty) ...[
                          Icon(Icons.person, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(d['owner'], style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          const SizedBox(width: 12),
                        ],
                        Text('L: ${d['likelihood']} • I: ${d['impact']}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
          Text('New Strategic Risk', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Risk Title *', prefixIcon: Icon(Icons.title))),
          const SizedBox(height: 12),
          TextFormField(controller: _descriptionCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description), alignLabelWithHint: true)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(value: _category, decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _category = v!))),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'Status'),
              items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _status = v!))),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: _ownerCtrl, decoration: const InputDecoration(labelText: 'Risk Owner', prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(value: _likelihood, decoration: const InputDecoration(labelText: 'Likelihood'),
              items: _likelihoods.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _likelihood = v!))),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(value: _impact, decoration: const InputDecoration(labelText: 'Impact'),
              items: _impacts.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _impact = v!))),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _ratingColor(_riskRating(_riskScore())).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
            child: Row(children: [
              Icon(Icons.speed, size: 16, color: _ratingColor(_riskRating(_riskScore()))),
              const SizedBox(width: 8),
              Text('Score: ${_riskScore()} — ${_riskRating(_riskScore())}', style: TextStyle(fontWeight: FontWeight.w700, color: _ratingColor(_riskRating(_riskScore())))),
            ]),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _mitigationCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Mitigation Strategy', prefixIcon: Icon(Icons.shield), alignLabelWithHint: true)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            label: Text(_isSubmitting ? 'Creating...' : 'Create Risk'),
          )),
        ]),
      ),
    );
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'Critical': return XMTheme.riskExtreme;
      case 'High': return XMTheme.riskHigh;
      case 'Medium': return XMTheme.riskMedium;
      default: return XMTheme.riskLow;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open': return XMTheme.error;
      case 'Mitigating': return XMTheme.warning;
      case 'Monitoring': return XMTheme.info;
      case 'Closed': return XMTheme.success;
      default: return XMTheme.primary;
    }
  }
}
