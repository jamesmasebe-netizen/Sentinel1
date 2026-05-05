import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Bow-Tie Analysis — register for threat/barrier/consequence chains.
class BowtieScreen extends ConsumerStatefulWidget {
  const BowtieScreen({super.key});
  @override
  ConsumerState<BowtieScreen> createState() => _BowtieScreenState();
}

class _BowtieScreenState extends ConsumerState<BowtieScreen> {
  bool _showForm = false;
  final _titleCtrl = TextEditingController();
  final _threatCtrl = TextEditingController();
  final _consequenceCtrl = TextEditingController();
  final _preventiveCtrl = TextEditingController();
  final _mitigationCtrl = TextEditingController();
  String _topEvent = '';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose(); _threatCtrl.dispose(); _consequenceCtrl.dispose();
    _preventiveCtrl.dispose(); _mitigationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _topEvent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill title and top event'), backgroundColor: XMTheme.error));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'bowtie_analyses', data: {
        'title': _titleCtrl.text.trim(),
        'topEvent': _topEvent,
        'threats': _threatCtrl.text.trim(),
        'consequences': _consequenceCtrl.text.trim(),
        'preventiveBarriers': _preventiveCtrl.text.trim(),
        'mitigationBarriers': _mitigationCtrl.text.trim(),
        'status': 'Draft',
        'authorId': profile.uid,
        'siteId': profile.siteId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bow-Tie created'), backgroundColor: XMTheme.success));
        setState(() { _showForm = false; _titleCtrl.clear(); _threatCtrl.clear(); _consequenceCtrl.clear(); _preventiveCtrl.clear(); _mitigationCtrl.clear(); _topEvent = ''; });
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
          Expanded(child: Text('Bow-Tie Analyses', style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
          FilledButton.icon(
            onPressed: () => setState(() => _showForm = !_showForm),
            icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
            label: Text(_showForm ? 'Cancel' : 'New Bow-Tie'),
          ),
        ]),
      ),
      if (_showForm) _buildForm(context),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('bowtie_analyses').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(30).snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (docs.isEmpty) return const Center(child: Text('No bow-tie analyses'));
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: XMTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(d['status'] ?? 'Draft', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: XMTheme.primary)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                      ]),
                      const SizedBox(height: 12),
                      // Bow-Tie Visual Summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(XMTheme.radiusMd),
                          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                        ),
                        child: Row(children: [
                          Expanded(child: _BowTieSection(title: 'Threats', content: d['threats'] ?? '', color: XMTheme.riskHigh, icon: Icons.warning)),
                          _BowTieArrow(),
                          Expanded(child: _BowTieSection(title: 'Preventive', content: d['preventiveBarriers'] ?? '', color: XMTheme.info, icon: Icons.shield)),
                          _BowTieArrow(),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: XMTheme.riskExtreme.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: XMTheme.riskExtreme.withValues(alpha: 0.3))),
                              child: Column(children: [
                                const Icon(Icons.crisis_alert, size: 16, color: XMTheme.riskExtreme),
                                const SizedBox(height: 4),
                                Text('TOP EVENT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: XMTheme.riskExtreme)),
                                Text(d['topEvent'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                              ]),
                            ),
                          ),
                          _BowTieArrow(),
                          Expanded(child: _BowTieSection(title: 'Mitigation', content: d['mitigationBarriers'] ?? '', color: XMTheme.success, icon: Icons.healing)),
                          _BowTieArrow(),
                          Expanded(child: _BowTieSection(title: 'Consequences', content: d['consequences'] ?? '', color: XMTheme.error, icon: Icons.dangerous)),
                        ]),
                      ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('New Bow-Tie Analysis', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Analysis Title *', prefixIcon: Icon(Icons.title))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _topEvent.isEmpty ? null : _topEvent,
            decoration: const InputDecoration(labelText: 'Top Event *', prefixIcon: Icon(Icons.crisis_alert)),
            items: ['Fire / Explosion', 'Structural Collapse', 'Chemical Release', 'Electrical Contact', 'Fall from Height', 'Vehicle Incident', 'Confined Space Emergency']
                .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _topEvent = v ?? ''),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _threatCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Threats (comma-separated)', prefixIcon: Icon(Icons.warning), alignLabelWithHint: true)),
          const SizedBox(height: 12),
          TextFormField(controller: _preventiveCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Preventive Barriers', prefixIcon: Icon(Icons.shield), alignLabelWithHint: true)),
          const SizedBox(height: 12),
          TextFormField(controller: _mitigationCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Mitigation Barriers', prefixIcon: Icon(Icons.healing), alignLabelWithHint: true)),
          const SizedBox(height: 12),
          TextFormField(controller: _consequenceCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Consequences', prefixIcon: Icon(Icons.dangerous), alignLabelWithHint: true)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            label: Text(_isSubmitting ? 'Creating...' : 'Create Bow-Tie'),
          )),
        ]),
      ),
    );
  }
}

class _BowTieSection extends StatelessWidget {
  final String title, content;
  final Color color;
  final IconData icon;
  const _BowTieSection({required this.title, required this.content, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(6),
    child: Column(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(height: 2),
      Text(title, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 2),
      Text(content, style: const TextStyle(fontSize: 9), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _BowTieArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Icon(Icons.chevron_right, size: 14, color: Theme.of(context).dividerColor),
  );
}
