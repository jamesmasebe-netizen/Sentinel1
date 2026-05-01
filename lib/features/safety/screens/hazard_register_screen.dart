import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Hazard Register — CRUD for site hazards with severity, location, and description.
/// Mirrors React HazardRegister: create form, severity chips, location tagging.
class HazardRegisterScreen extends ConsumerStatefulWidget {
  const HazardRegisterScreen({super.key});

  @override
  ConsumerState<HazardRegisterScreen> createState() => _HazardRegisterScreenState();
}

class _HazardRegisterScreenState extends ConsumerState<HazardRegisterScreen> {
  bool _showForm = false;
  bool _isSubmitting = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _severity = 'Medium';

  static const _severities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title and description'), backgroundColor: XMTheme.error),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');

      await ref.read(firestoreServiceProvider).createDocument(
        collection: 'hazards',
        data: {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'location': _locationController.text.trim(),
          'severity': _severity,
          'authorId': profile.uid,
          'siteId': profile.siteId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hazard logged successfully'), backgroundColor: XMTheme.success),
        );
        setState(() {
          _showForm = false;
          _titleController.clear();
          _descriptionController.clear();
          _locationController.clear();
          _severity = 'Medium';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: XMTheme.error));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);

    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hazard Register', style: Theme.of(context).textTheme.titleMedium),
              FilledButton.icon(
                onPressed: () => setState(() => _showForm = !_showForm),
                icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                label: Text(_showForm ? 'Cancel' : 'Log Hazard'),
                style: FilledButton.styleFrom(backgroundColor: XMTheme.error),
              ),
            ],
          ),
        ),

        // Form
        if (_showForm)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log New Hazard', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Hazard Title *', prefixIcon: Icon(Icons.warning)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Describe the hazard in detail',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _severity,
                          decoration: const InputDecoration(labelText: 'Severity'),
                          items: _severities.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() => _severity = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(_isSubmitting ? 'Saving...' : 'Save Hazard'),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Hazards list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('hazards')
                .where('siteId', isEqualTo: siteId)
                .orderBy('createdAt', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: XMTheme.success.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      const Text('No hazards registered'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _HazardCard(data: data);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HazardCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HazardCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled';
    final desc = data['description'] ?? '';
    final location = data['location'] ?? '';
    final severity = data['severity'] ?? 'Medium';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, size: 20, color: _sevColor(severity)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _sevColor(severity).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _sevColor(severity).withValues(alpha: 0.3)),
                  ),
                  child: Text(severity, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _sevColor(severity))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(desc, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                if (location.isNotEmpty) ...[
                  Icon(Icons.location_on, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(location, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 12),
                ],
                Icon(Icons.calendar_today, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(_fmtDate(data['createdAt']), style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _sevColor(String severity) {
    switch (severity) {
      case 'Critical': return XMTheme.severityCritical;
      case 'High': return XMTheme.severityMajor;
      case 'Medium': return XMTheme.severityModerate;
      case 'Low': return XMTheme.severityMinor;
      default: return XMTheme.severityNegligible;
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
