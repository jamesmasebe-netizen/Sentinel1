import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';

/// Hazard Register — CRUD for site hazards with severity, location, and description.
/// Mirrors React HazardRegister: create form, severity chips, location tagging.
class HazardRegisterScreen extends ConsumerStatefulWidget {
  const HazardRegisterScreen({super.key});

  @override
  ConsumerState<HazardRegisterScreen> createState() =>
      _HazardRegisterScreenState();
}

class _HazardRegisterScreenState extends ConsumerState<HazardRegisterScreen> {
  bool _isSubmitting = false;

  // Form Fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _severity = 'Low';
  final _severities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitHazard(BuildContext context) async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      UIUtils.showToast(context, 'Please fill all required fields', type: ToastType.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');

      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'severity': _severity,
        'status': 'Open',
        'reportedById': profile.uid,
        'reportedByName': profile.displayName,
        'siteId': profile.siteId,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createDocument(collection: 'hazards', data: data);

      if (mounted) {
        UIUtils.showToast(context, 'Hazard reported successfully', type: ToastType.success);
        Navigator.pop(context); // Close side sheet
        setState(() {
          _titleController.clear();
          _descriptionController.clear();
          _locationController.clear();
          _severity = 'Low';
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

  void _showHazardForm(BuildContext context) {
    UIUtils.showSideSheet(
      context: context,
      title: 'Report New Hazard',
      builder: (ctx) => StatefulBuilder(
        builder: (context, setInternalState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Hazard Title *',
                    prefixIcon: Icon(Icons.warning_amber_rounded),
                  ),
                ),
                GSpacing.vMd,
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                ),
                GSpacing.vMd,
                DropdownButtonFormField<String>(
                  value: _severity,
                  decoration: const InputDecoration(
                    labelText: 'Severity *',
                    prefixIcon: Icon(Icons.priority_high_rounded),
                  ),
                  items: _severities.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setInternalState(() => _severity = v!),
                ),
                GSpacing.vMd,
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    prefixIcon: Icon(Icons.description_rounded),
                  ),
                ),
                GSpacing.vLg,

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : () => _submitHazard(context),
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.report_problem_rounded),
                    label: Text(_isSubmitting ? 'Reporting...' : 'Report Hazard'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);

    if (siteId == null) {
      return const Center(child: Text('No site assigned'));
    }

    return Column(
      children: [
        GHeader(
          title: 'Hazard Register',
          subtitle: 'Track and mitigate workplace hazards',
          trailing: FilledButton.icon(
            onPressed: () => _showHazardForm(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Report Hazard'),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('hazards')
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
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: XMTheme.success.withValues(alpha: 0.4),
                      ),
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
    final location = data['location'] ?? 'Unknown location';
    final severity = data['severity'] ?? 'Medium';
    final reportedBy = data['reportedByName'] ?? 'Unknown';

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
                  color: _sevColor(severity).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_amber_rounded, color: _sevColor(severity), size: 20),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(location, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              GStatusTag(label: severity, color: _sevColor(severity)),
            ],
          ),
          GSpacing.vMd,
          Text(
            desc,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          GSpacing.vMd,
          Row(
            children: [
              _MiniInfo(icon: Icons.person_outline, label: reportedBy),
              GSpacing.hMd,
              _MiniInfo(icon: Icons.calendar_today_rounded, label: UIUtils.formatTimestamp(data['createdAt'])),
            ],
          ),
        ],
      ),
    );
  }

  Color _sevColor(String severity) {
    switch (severity) {
      case 'Critical':
        return XMTheme.severityCritical;
      case 'High':
        return XMTheme.severityMajor;
      case 'Medium':
        return XMTheme.severityModerate;
      case 'Low':
        return XMTheme.severityMinor;
      default:
        return XMTheme.severityNegligible;
    }
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MiniInfo({required this.icon, required this.label});

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
