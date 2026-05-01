import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Behavioral Based Safety — observations, suggestion box, and gamification leaderboard.
/// Mirrors React BehavioralSafety: 3 observation types, points, anonymous, suggestions.
class BBSObservationsScreen extends ConsumerStatefulWidget {
  const BBSObservationsScreen({super.key});

  @override
  ConsumerState<BBSObservationsScreen> createState() => _BBSObservationsScreenState();
}

class _BBSObservationsScreenState extends ConsumerState<BBSObservationsScreen> {
  bool _showForm = false;
  bool _isSubmitting = false;

  // Form
  String _observationType = 'Safe Act';
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _interventionController = TextEditingController();
  bool _isAnonymous = false;

  static const _types = ['Safe Act', 'Unsafe Act', 'Unsafe Condition'];

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _interventionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descriptionController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill location and description'), backgroundColor: XMTheme.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');

      // Gamification: 10pts Safe Act, 5pts for reporting unsafe
      final points = _observationType == 'Safe Act' ? 10 : 5;

      final data = <String, dynamic>{
        'observationType': _observationType,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'pointsAwarded': _isAnonymous ? 0 : points,
        'authorId': profile.uid,
        'siteId': profile.siteId,
        'createdAt': DateTime.now().toIso8601String(),
      };

      if (!_isAnonymous) data['observerName'] = profile.displayName;
      if (_interventionController.text.isNotEmpty) {
        data['interventionAction'] = _interventionController.text.trim();
      }

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createDocument(collection: 'bbs_observations', data: data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Observation logged! ${_isAnonymous ? "" : "+$points pts"}'),
            backgroundColor: XMTheme.success,
          ),
        );
        setState(() {
          _showForm = false;
          _descriptionController.clear();
          _locationController.clear();
          _interventionController.clear();
          _isAnonymous = false;
          _observationType = 'Safe Act';
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BBS Observations', style: Theme.of(context).textTheme.titleMedium),
                    Text('Peer observations & safety culture', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => setState(() => _showForm = !_showForm),
                icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                label: Text(_showForm ? 'Cancel' : 'Log'),
              ),
            ],
          ),
        ),

        // Form
        if (_showForm) _buildForm(),

        // Observations list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('bbs_observations')
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
                      Icon(Icons.visibility, size: 48, color: XMTheme.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      const Text('No observations logged yet'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _ObservationCard(data: data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log BBS Observation', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),

            // Anonymous toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isAnonymous,
              onChanged: (v) => setState(() => _isAnonymous = v),
              title: const Text('Submit Anonymously', style: TextStyle(fontSize: 14)),
              subtitle: const Text('No points awarded', style: TextStyle(fontSize: 12)),
              secondary: const Icon(Icons.visibility_off, size: 20),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _observationType,
                    decoration: const InputDecoration(labelText: 'Type', isDense: true),
                    items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _observationType = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location', isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'What did you observe?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            if (_observationType != 'Safe Act')
              TextFormField(
                controller: _interventionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Intervention Action Taken',
                  hintText: 'What did you do to correct it?',
                  alignLabelWithHint: true,
                ),
              ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_isSubmitting ? 'Saving...' : 'Save Observation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObservationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ObservationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final type = data['observationType'] ?? 'Unknown';
    final desc = data['description'] ?? '';
    final observer = data['observerName'] ?? 'Anonymous';
    final points = data['pointsAwarded'] ?? 0;
    final intervention = data['interventionAction'];
    final location = data['location'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _typeColor(type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(_typeIcon(type), color: _typeColor(type), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _typeColor(type))),
                      Text(location, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (points > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: XMTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events, size: 14, color: XMTheme.primary),
                        const SizedBox(width: 4),
                        Text('+$points', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: XMTheme.primary)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text('"$desc"', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic), maxLines: 3, overflow: TextOverflow.ellipsis),
            if (intervention != null && intervention.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Action Taken:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(intervention, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(observer, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                Text(_formatDate(data['createdAt']), style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Safe Act': return XMTheme.success;
      case 'Unsafe Act': return XMTheme.error;
      case 'Unsafe Condition': return XMTheme.warning;
      default: return XMTheme.info;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Safe Act': return Icons.check_circle;
      case 'Unsafe Act': return Icons.cancel;
      case 'Unsafe Condition': return Icons.warning_amber;
      default: return Icons.visibility;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
