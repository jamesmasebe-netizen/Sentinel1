import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';

/// Permit to Work module — create, approve, and manage permits.
/// Mirrors React PermitToWork: types, LOTO, contractor compliance gate, status workflow.
class PermitToWorkScreen extends ConsumerStatefulWidget {
  const PermitToWorkScreen({super.key});

  @override
  ConsumerState<PermitToWorkScreen> createState() => _PermitToWorkScreenState();
}

class _PermitToWorkScreenState extends ConsumerState<PermitToWorkScreen> {
  bool _isSubmitting = false;

  // Form Fields
  String _type = 'Hot Work';
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _validFrom;
  DateTime? _validTo;
  bool _lotoRequired = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitPermit(BuildContext context) async {
    if (_descriptionController.text.isEmpty || _locationController.text.isEmpty || _validFrom == null || _validTo == null) {
      UIUtils.showToast(context, 'Please fill all required fields', type: ToastType.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');

      final data = {
        'type': _type,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'validFrom': _validFrom!.toIso8601String(),
        'validTo': _validTo!.toIso8601String(),
        'lotoRequired': _lotoRequired,
        'status': 'Requested',
        'applicantId': profile.uid,
        'applicantName': profile.displayName,
        'siteId': profile.siteId,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createDocument(collection: 'permits', data: data);

      if (mounted) {
        UIUtils.showToast(context, 'Permit request submitted successfully', type: ToastType.success);
        Navigator.pop(context); // Close side sheet
        setState(() {
          _type = 'Hot Work';
          _descriptionController.clear();
          _locationController.clear();
          _validFrom = null;
          _validTo = null;
          _lotoRequired = false;
        });
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showPermitForm(BuildContext context) {
    UIUtils.showSideSheet(
      context: context,
      title: 'Request New Permit',
      builder: (ctx) => StatefulBuilder(
        builder: (context, setInternalState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Permit Type *',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: ['Hot Work', 'Working at Height', 'Confined Space', 'Excavation', 'Electrical', 'Other']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setInternalState(() => _type = v!),
                ),
                GSpacing.vMd,
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location *',
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                ),
                GSpacing.vMd,
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    prefixIcon: Icon(Icons.description_rounded),
                  ),
                ),
                GSpacing.vMd,
                
                // Date pickers
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('Valid From *'),
                  subtitle: Text(_validFrom != null ? _formatDateTime(_validFrom!) : 'Tap to select'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null && context.mounted) {
                      final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (time != null && context.mounted) {
                        final full = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        setInternalState(() => _validFrom = full);
                      }
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.stop_circle_outlined),
                  title: const Text('Valid To *'),
                  subtitle: Text(_validTo != null ? _formatDateTime(_validTo!) : 'Tap to select'),
                  onTap: () async {
                    final initial = _validFrom ?? DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: initial,
                      lastDate: initial.add(const Duration(days: 365)),
                    );
                    if (date != null && context.mounted) {
                      final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (time != null && context.mounted) {
                        final full = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        setInternalState(() => _validTo = full);
                      }
                    }
                  },
                ),
                GSpacing.vMd,
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('LOTO Required'),
                  subtitle: const Text('Lockout/Tagout isolation required'),
                  value: _lotoRequired,
                  onChanged: (v) => setInternalState(() => _lotoRequired = v),
                ),
                GSpacing.vLg,

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : () => _submitPermit(context),
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: Text(_isSubmitting ? 'Submitting...' : 'Submit Request'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);

    final isExecutive = ref.watch(isExecutiveProvider);

    if (siteId == null) {
      return const Center(child: Text('No site assigned'));
    }

    return Column(
      children: [
        GHeader(
          title: 'Permit to Work',
          subtitle: 'Manage and approve site access permits',
          trailing: FilledButton.icon(
            onPressed: () => _showPermitForm(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Request Permit'),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('permits')
                .where('siteId', isEqualTo: siteId)
                .orderBy('createdAt', descending: true)
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
                      Icon(Icons.assignment_turned_in_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                      GSpacing.vMd,
                      const Text('No permits found'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _PermitCard(
                    docId: doc.id,
                    data: data,
                    canApprove: isExecutive,
                    onStatusUpdate: (newStatus) async {
                      await firestore.collection('permits').doc(doc.id).update({
                        'status': newStatus,
                        'updatedAt': DateTime.now().toIso8601String(),
                      });
                      if (context.mounted) {
                        UIUtils.showToast(context, 'Status updated to $newStatus', type: ToastType.success);
                      }
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
}

class _PermitCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool canApprove;
  final Function(String) onStatusUpdate;

  const _PermitCard({
    required this.docId,
    required this.data,
    required this.canApprove,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? 'General';
    final status = data['status'] ?? 'Requested';
    final location = data['location'] ?? 'Site';
    final applicant = data['applicantName'] ?? 'Unknown';
    final loto = data['lotoRequired'] == true;

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
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
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(location, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              GStatusTag(label: status, color: _statusColor(status)),
            ],
          ),
          GSpacing.vMd,
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MiniInfo(icon: Icons.person_outline, label: applicant),
              if (data['validFrom'] != null) _MiniInfo(icon: Icons.access_time, label: _fmtDate(data['validFrom'])),
              if (loto) _MiniInfo(icon: Icons.lock_outline, label: 'LOTO', color: XMTheme.error),
            ],
          ),
          if (status == 'Requested' && canApprove) ...[
            GSpacing.vMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => onStatusUpdate('Rejected'),
                  style: TextButton.styleFrom(foregroundColor: XMTheme.error),
                  child: const Text('Reject'),
                ),
                GSpacing.hMd,
                FilledButton(
                  onPressed: () => onStatusUpdate('Approved'),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ],
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
      case 'Working at Height': return Icons.height;
      case 'Confined Space': return Icons.meeting_room;
      case 'Electrical': return Icons.bolt;
      case 'Excavation': return Icons.construction;
      default: return Icons.assignment;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Hot Work': return XMTheme.error;
      case 'Working at Height': return XMTheme.warning;
      case 'Confined Space': return XMTheme.info;
      case 'Electrical': return const Color(0xFFF59E0B);
      case 'Excavation': return const Color(0xFF8B5CF6);
      default: return XMTheme.primary;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Requested': return XMTheme.statusDraft;
      case 'Approved': return XMTheme.success;
      case 'Active': return XMTheme.info;
      case 'Rejected': return XMTheme.error;
      case 'Closed': return XMTheme.statusClosed;
      default: return XMTheme.statusDraft;
    }
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
