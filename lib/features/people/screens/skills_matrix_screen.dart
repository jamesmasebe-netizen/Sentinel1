import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Skills Matrix — grid of employees × skill competencies.
class SkillsMatrixScreen extends ConsumerStatefulWidget {
  const SkillsMatrixScreen({super.key});
  @override
  ConsumerState<SkillsMatrixScreen> createState() => _SkillsMatrixScreenState();
}

class _SkillsMatrixScreenState extends ConsumerState<SkillsMatrixScreen> {
  bool _showForm = false;
  final _employeeCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  String _proficiency = 'Intermediate';
  String _verifiedBy = '';
  bool _isSubmitting = false;

  static const _proficiencies = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];
  static const _defaultSkills = ['LOTO Procedure', 'First Aid', 'Fire Safety', 'Working at Heights', 'Confined Space Entry', 'Forklift Operation', 'Crane Operation', 'Fall Protection', 'Hazmat Handling', 'Scaffolding Inspection'];

  @override
  void dispose() { _employeeCtrl.dispose(); _skillCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_employeeCtrl.text.isEmpty || _skillCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill employee and skill'), backgroundColor: XMTheme.error));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'skills_matrix', data: {
        'employeeName': _employeeCtrl.text.trim(),
        'skill': _skillCtrl.text.trim(),
        'proficiency': _proficiency,
        'verifiedBy': _verifiedBy,
        'lastAssessed': DateTime.now().toIso8601String(),
        'siteId': profile.siteId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skill entry added'), backgroundColor: XMTheme.success));
        setState(() { _showForm = false; _employeeCtrl.clear(); _skillCtrl.clear(); });
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
          Expanded(child: Text('Skills Matrix', style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
          FilledButton.icon(
            onPressed: () => setState(() => _showForm = !_showForm),
            icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
            label: Text(_showForm ? 'Cancel' : 'Add Skill'),
          ),
        ]),
      ),
      if (_showForm) _buildForm(context),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('skills_matrix').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(100).snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.grid_view, size: 48, color: XMTheme.warning.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              const Text('No skill records yet'),
            ]));

            // Group by employee
            final byEmployee = <String, List<Map<String, dynamic>>>{};
            for (final doc in docs) {
              final d = doc.data() as Map<String, dynamic>;
              final name = d['employeeName'] ?? 'Unknown';
              byEmployee.putIfAbsent(name, () => []).add(d);
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: byEmployee.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: XMTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.person, size: 18, color: XMTheme.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('${entry.value.length} skills tracked', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ])),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 6, children: entry.value.map((skill) {
                        final prof = skill['proficiency'] ?? 'Beginner';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _profColor(prof).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(XMTheme.radiusSm),
                            border: Border.all(color: _profColor(prof).withValues(alpha: 0.2)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(_profIcon(prof), size: 12, color: _profColor(prof)),
                            const SizedBox(width: 4),
                            Text(skill['skill'] ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _profColor(prof))),
                            const SizedBox(width: 4),
                            Text('($prof)', style: TextStyle(fontSize: 9, color: _profColor(prof).withValues(alpha: 0.7))),
                          ]),
                        );
                      }).toList()),
                    ]),
                  ),
                );
              }).toList(),
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
          Text('Add Skill Entry', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          TextFormField(controller: _employeeCtrl, decoration: const InputDecoration(labelText: 'Employee Name *', prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 12),
          Autocomplete<String>(
            optionsBuilder: (v) => _defaultSkills.where((s) => s.toLowerCase().contains(v.text.toLowerCase())),
            fieldViewBuilder: (context, ctrl, fn, onSubmit) {
              _skillCtrl.text = ctrl.text;
              return TextFormField(controller: ctrl, focusNode: fn, decoration: const InputDecoration(labelText: 'Skill *', prefixIcon: Icon(Icons.build)));
            },
            onSelected: (v) => _skillCtrl.text = v,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _proficiency,
            decoration: const InputDecoration(labelText: 'Proficiency Level'),
            items: _proficiencies.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _proficiency = v!),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            label: Text(_isSubmitting ? 'Saving...' : 'Add Skill Entry'),
          )),
        ]),
      ),
    );
  }

  Color _profColor(String p) {
    switch (p) {
      case 'Expert': return XMTheme.success;
      case 'Advanced': return XMTheme.info;
      case 'Intermediate': return XMTheme.warning;
      default: return XMTheme.error;
    }
  }

  IconData _profIcon(String p) {
    switch (p) {
      case 'Expert': return Icons.star;
      case 'Advanced': return Icons.trending_up;
      case 'Intermediate': return Icons.remove;
      default: return Icons.arrow_downward;
    }
  }
}
