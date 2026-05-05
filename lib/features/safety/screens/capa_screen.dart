import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// CAPA Management Screen — Create, track, and update corrective/preventive actions.
/// Mirrors React CAPA tab: linked incidents, RCA, assignment, due dates, status workflow.
class CAPAScreen extends ConsumerStatefulWidget {
  const CAPAScreen({super.key});

  @override
  ConsumerState<CAPAScreen> createState() => _CAPAScreenState();
}

class _CAPAScreenState extends ConsumerState<CAPAScreen> {
  bool _showForm = false;

  // Form
  final _descriptionController = TextEditingController();
  final _rcaController = TextEditingController();
  final _assignedToController = TextEditingController();
  DateTime? _dueDate;
  String? _linkedIncidentId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _rcaController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  Future<void> _submitCAPA() async {
    if (_descriptionController.text.isEmpty || _assignedToController.text.isEmpty || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: XMTheme.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');

      final data = {
        'description': _descriptionController.text.trim(),
        'rca': _rcaController.text.trim(),
        'assignedToName': _assignedToController.text.trim(),
        'dueDate': _dueDate!.toIso8601String(),
        'status': 'Open',
        'createdById': profile.uid,
        'siteId': profile.siteId,
        'createdAt': DateTime.now().toIso8601String(),
        if (_linkedIncidentId != null) 'incidentId': _linkedIncidentId,
      };

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createDocument(collection: 'capas', data: data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CAPA created successfully'), backgroundColor: XMTheme.success),
        );
        setState(() {
          _showForm = false;
          _descriptionController.clear();
          _rcaController.clear();
          _assignedToController.clear();
          _dueDate = null;
          _linkedIncidentId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: XMTheme.error),
        );
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
        // ─── Header ───
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Corrective & Preventive Actions', style: Theme.of(context).textTheme.titleMedium),
              FilledButton.icon(
                onPressed: () => setState(() => _showForm = !_showForm),
                icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                label: Text(_showForm ? 'Cancel' : 'New CAPA'),
              ),
            ],
          ),
        ),

        // ─── Form ───
        if (_showForm) _buildForm(context, firestore, siteId),

        // ─── CAPA List ───
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('capas')
                .where('siteId', isEqualTo: siteId)
                .orderBy('createdAt', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final capas = snapshot.data?.docs ?? [];
              if (capas.isEmpty) {
                return const Center(child: Text('No CAPAs found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: capas.length,
                itemBuilder: (context, index) {
                  final doc = capas[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _CAPACard(
                    docId: doc.id,
                    data: data,
                    onStatusUpdate: (newStatus) async {
                      await firestore.collection('capas').doc(doc.id).update({
                        'status': newStatus,
                        'updatedAt': DateTime.now().toIso8601String(),
                      });
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, FirebaseFirestore firestore, String siteId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create New CAPA', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),

            // Link to incident (optional)
            StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('incidents')
                  .where('siteId', isEqualTo: siteId)
                  .orderBy('createdAt', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                final incidents = snapshot.data?.docs ?? [];
                return DropdownButtonFormField<String?>(
                  value: _linkedIncidentId,
                  decoration: const InputDecoration(labelText: 'Link to Incident (optional)', prefixIcon: Icon(Icons.link)),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('None')),
                    ...incidents.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(value: doc.id, child: Text(d['title'] ?? 'Untitled', overflow: TextOverflow.ellipsis));
                    }),
                  ],
                  onChanged: (v) => setState(() => _linkedIncidentId = v),
                );
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'What corrective/preventive action is needed?',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _rcaController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Root Cause Analysis',
                hintText: 'Enter RCA or use AI to generate...',
                prefixIcon: Icon(Icons.psychology),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _assignedToController,
              decoration: const InputDecoration(
                labelText: 'Assigned To *',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Due Date *'),
              subtitle: Text(_dueDate != null ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}' : 'Tap to select'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _dueDate = date);
              },
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitCAPA,
                icon: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_isSubmitting ? 'Creating...' : 'Create CAPA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CAPACard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final Future<void> Function(String) onStatusUpdate;

  const _CAPACard({required this.docId, required this.data, required this.onStatusUpdate});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Open';
    final assignee = data['assignedToName'] ?? 'Unassigned';
    final description = data['description'] ?? 'No description';
    final dueDateStr = data['dueDate'];
    final isOverdue = _isOverdue(dueDateStr, status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(
          color: isOverdue ? XMTheme.error.withValues(alpha: 0.4) : Colors.transparent,
          width: isOverdue ? 1.5 : 0,
        ),
      ),
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
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.check_box, color: _statusColor(status), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _MiniChip(icon: Icons.person, label: assignee),
                if (dueDateStr != null) _MiniChip(
                  icon: Icons.calendar_today,
                  label: _formatDate(dueDateStr),
                  color: isOverdue ? XMTheme.error : null,
                ),
                if (isOverdue)
                  _MiniChip(icon: Icons.warning, label: 'OVERDUE', color: XMTheme.error),
              ],
            ),
            if (data['rca'] != null && data['rca'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('RCA: ${data['rca']}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],

            // Status actions
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'Open')
                  TextButton(onPressed: () => onStatusUpdate('In Progress'), child: const Text('Start', style: TextStyle(fontSize: 12))),
                if (status == 'In Progress')
                  TextButton(onPressed: () => onStatusUpdate('Completed'), child: const Text('Complete', style: TextStyle(fontSize: 12))),
                if (status == 'Completed')
                  TextButton(onPressed: () => onStatusUpdate('Verified'), child: const Text('Verify', style: TextStyle(fontSize: 12))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isOverdue(String? dueDateStr, String status) {
    if (dueDateStr == null || status == 'Completed' || status == 'Verified') return false;
    try {
      return DateTime.parse(dueDateStr).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open': return XMTheme.statusOpen;
      case 'In Progress': return XMTheme.statusInProgress;
      case 'Completed': return XMTheme.statusResolved;
      case 'Verified': return XMTheme.statusClosed;
      default: return XMTheme.statusDraft;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Open': color = XMTheme.statusOpen;
      case 'In Progress': color = XMTheme.statusInProgress;
      case 'Completed': color = XMTheme.statusResolved;
      case 'Verified': color = XMTheme.statusClosed;
      default: color = XMTheme.statusDraft;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(XMTheme.radiusXl), // Fully rounded pill
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MiniChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: c)),
      ],
    );
  }
}
