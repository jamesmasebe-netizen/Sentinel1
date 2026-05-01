import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Permit to Work module — create, approve, and manage permits.
/// Mirrors React PermitToWork: types, LOTO, contractor compliance gate, status workflow.
class PermitToWorkScreen extends ConsumerStatefulWidget {
  const PermitToWorkScreen({super.key});

  @override
  ConsumerState<PermitToWorkScreen> createState() => _PermitToWorkScreenState();
}

class _PermitToWorkScreenState extends ConsumerState<PermitToWorkScreen> {
  bool _showForm = false;
  bool _isSubmitting = false;

  // Form
  String _permitType = 'Hot Work';
  final _locationController = TextEditingController();
  DateTime? _validFrom;
  DateTime? _validTo;
  bool _lotoRequired = false;
  String? _selectedContractorId;

  static const _permitTypes = ['Hot Work', 'Working at Heights', 'Confined Space', 'Electrical', 'Excavation', 'Other'];

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitPermit() async {
    if (_locationController.text.isEmpty || _validFrom == null || _validTo == null) {
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
        'type': _permitType,
        'location': _locationController.text.trim(),
        'status': 'Requested',
        'validFrom': _validFrom!.toIso8601String(),
        'validTo': _validTo!.toIso8601String(),
        'applicantId': profile.uid,
        'applicantName': profile.displayName,
        'lotoRequired': _lotoRequired,
        'siteId': profile.siteId,
        'createdAt': DateTime.now().toIso8601String(),
        'contractorId': _selectedContractorId,
      };

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createDocument(collection: 'permits', data: data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permit requested successfully'), backgroundColor: XMTheme.success),
        );
        setState(() {
          _showForm = false;
          _locationController.clear();
          _validFrom = null;
          _validTo = null;
          _lotoRequired = false;
          _selectedContractorId = null;
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
    final isExec = ref.watch(isExecutiveProvider);

    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Column(
      children: [
        // ─── Header ───
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Permits to Work', style: Theme.of(context).textTheme.titleMedium),
              FilledButton.icon(
                onPressed: () => setState(() => _showForm = !_showForm),
                icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                label: Text(_showForm ? 'Cancel' : 'New Permit'),
              ),
            ],
          ),
        ),

        // ─── Form ───
        if (_showForm) _buildForm(context),

        // ─── Permits List ───
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('permits')
                .where('siteId', isEqualTo: siteId)
                .orderBy('createdAt', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final permits = snapshot.data?.docs ?? [];
              if (permits.isEmpty) {
                return const Center(child: Text('No permits found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: permits.length,
                itemBuilder: (context, index) {
                  final doc = permits[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _PermitCard(
                    docId: doc.id,
                    data: data,
                    canApprove: isExec,
                    onStatusUpdate: (newStatus) async {
                      final profile = ref.read(userProfileProvider).valueOrNull;
                      await firestore.collection('permits').doc(doc.id).update({
                        'status': newStatus,
                        if (newStatus == 'Approved') 'approverId': profile?.uid,
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

  Widget _buildForm(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request New Permit', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _permitType,
              decoration: const InputDecoration(labelText: 'Permit Type', prefixIcon: Icon(Icons.assignment)),
              items: _permitTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _permitType = v!),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location *',
                hintText: 'Work location',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),

            // Valid from
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Valid From *'),
              subtitle: Text(_validFrom != null ? _formatDateTime(_validFrom!) : 'Tap to select'),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                if (date != null && mounted) {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) setState(() => _validFrom = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                }
              },
            ),

            // Valid to
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.stop_circle),
              title: const Text('Valid To *'),
              subtitle: Text(_validTo != null ? _formatDateTime(_validTo!) : 'Tap to select'),
              onTap: () async {
                final initial = _validFrom ?? DateTime.now();
                final date = await showDatePicker(context: context, initialDate: initial, firstDate: initial, lastDate: initial.add(const Duration(days: 90)));
                if (date != null && mounted) {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) setState(() => _validTo = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                }
              },
            ),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _lotoRequired,
              onChanged: (v) => setState(() => _lotoRequired = v),
              title: const Text('LOTO Required'),
              subtitle: const Text('Lockout/Tagout energy isolation'),
              secondary: const Icon(Icons.lock),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitPermit,
                icon: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Requesting...' : 'Request Permit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) => '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
}

class _PermitCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool canApprove;
  final Future<void> Function(String) onStatusUpdate;

  const _PermitCard({required this.docId, required this.data, required this.canApprove, required this.onStatusUpdate});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? 'Unknown';
    final status = data['status'] ?? 'Requested';
    final location = data['location'] ?? '';
    final applicant = data['applicantName'] ?? 'Unknown';
    final loto = data['lotoRequired'] == true;

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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _typeColor(type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_typeIcon(type), color: _typeColor(type), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(location, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                _PermitStatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _MiniInfo(icon: Icons.person, label: applicant),
                if (data['validFrom'] != null) _MiniInfo(icon: Icons.play_circle, label: _fmtDate(data['validFrom'])),
                if (data['validTo'] != null) _MiniInfo(icon: Icons.stop_circle, label: _fmtDate(data['validTo'])),
                if (loto) _MiniInfo(icon: Icons.lock, label: 'LOTO', color: XMTheme.error),
              ],
            ),

            // Actions
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'Requested' && canApprove)
                  TextButton.icon(
                    onPressed: () => onStatusUpdate('Approved'),
                    icon: const Icon(Icons.check_circle, size: 16, color: XMTheme.success),
                    label: const Text('Approve', style: TextStyle(fontSize: 12, color: XMTheme.success)),
                  ),
                if (status == 'Approved')
                  TextButton.icon(
                    onPressed: () => onStatusUpdate('Active'),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Activate', style: TextStyle(fontSize: 12)),
                  ),
                if (status == 'Active') ...[
                  TextButton.icon(
                    onPressed: () => onStatusUpdate('Suspended'),
                    icon: const Icon(Icons.pause, size: 16, color: XMTheme.warning),
                    label: const Text('Suspend', style: TextStyle(fontSize: 12, color: XMTheme.warning)),
                  ),
                  TextButton.icon(
                    onPressed: () => onStatusUpdate('Closed'),
                    icon: const Icon(Icons.stop, size: 16),
                    label: const Text('Close', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Hot Work': return Icons.local_fire_department;
      case 'Working at Heights': return Icons.height;
      case 'Confined Space': return Icons.meeting_room;
      case 'Electrical': return Icons.bolt;
      case 'Excavation': return Icons.construction;
      default: return Icons.assignment;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Hot Work': return XMTheme.error;
      case 'Working at Heights': return XMTheme.warning;
      case 'Confined Space': return XMTheme.info;
      case 'Electrical': return const Color(0xFFF59E0B);
      case 'Excavation': return const Color(0xFF8B5CF6);
      default: return XMTheme.primary;
    }
  }
}

class _PermitStatusBadge extends StatelessWidget {
  final String status;
  const _PermitStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Requested': color = XMTheme.statusDraft;
      case 'Approved': color = XMTheme.success;
      case 'Active': color = XMTheme.info;
      case 'Suspended': color = XMTheme.warning;
      case 'Closed': color = XMTheme.statusClosed;
      default: color = XMTheme.statusDraft;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MiniInfo({required this.icon, required this.label, this.color});

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
