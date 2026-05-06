import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

/// Behavioral Based Safety — observations, suggestion box, and gamification leaderboard.
class BBSObservationsScreen extends ConsumerStatefulWidget {
  const BBSObservationsScreen({super.key});

  @override
  ConsumerState<BBSObservationsScreen> createState() => _BBSState();
}

class _BBSState extends ConsumerState<BBSObservationsScreen> {
  final _observerCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _interventionCtrl = TextEditingController();
  String _type = 'Safe Act';
  bool _isAnon = false;
  bool _isSubmitting = false;

  static const _types = ['Safe Act', 'Unsafe Act', 'Unsafe Condition'];

  @override
  void dispose() {
    _observerCtrl.dispose();
    _locCtrl.dispose();
    _descCtrl.dispose();
    _interventionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_locCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Location and description are required', type: ToastType.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('User profile not loaded');

      final data = {
        'observationType': _type,
        'location': _locCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'interventionAction': _interventionCtrl.text.trim(),
        'observerName': _isAnon ? 'Anonymous' : _observerCtrl.text.trim(),
        'isAnonymous': _isAnon,
        'siteId': profile.siteId,
        'authorId': profile.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'pointsAwarded': _type == 'Safe Act' ? 5 : 10,
      };

      await FirebaseFirestore.instance.collection('bbs_observations').add(data);

      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'Observation recorded successfully');
        _locCtrl.clear();
        _descCtrl.clear();
        _interventionCtrl.clear();
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    final theme = Theme.of(context);

    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Column(
      children: [
        GHeader(
          title: 'BBS Observations',
          subtitle: 'Behavioral safety and interventions',
          trailing: FilledButton.icon(
            onPressed: () => UIUtils.showSideSheet(
              context: context,
              title: 'New Observation',
              builder: (ctx) => _buildForm(context),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Observation'),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('bbs_observations')
                .where('siteId', isEqualTo: siteId)
                .orderBy('createdAt', descending: true)
                .limit(50)
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
                      Icon(Icons.visibility_outlined, size: 48, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                      GSpacing.vMd,
                      Text('No observations found', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8),
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

  Widget _buildForm(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Observer Info', style: Theme.of(context).textTheme.titleSmall),
              GSpacing.vSm,
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isAnon,
                onChanged: (v) => setLocalState(() => _isAnon = v),
                title: const Text('Submit Anonymously', style: TextStyle(fontSize: 14)),
                secondary: const Icon(Icons.visibility_off_rounded),
              ),
              if (!_isAnon) ...[
                GSpacing.vSm,
                TextFormField(
                  controller: _observerCtrl,
                  decoration: const InputDecoration(labelText: 'Observer Name', prefixIcon: Icon(Icons.person_outline)),
                ),
              ],
              GSpacing.vLg,
              Text('Observation Details', style: Theme.of(context).textTheme.titleSmall),
              GSpacing.vSm,
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setLocalState(() => _type = v!),
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _locCtrl,
                decoration: const InputDecoration(labelText: 'Location / Area *', prefixIcon: Icon(Icons.place_outlined)),
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'What did you observe? *', alignLabelWithHint: true),
              ),
              GSpacing.vMd,
              if (_type != 'Safe Act')
                TextFormField(
                  controller: _interventionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Intervention Action Taken', hintText: 'What did you do to correct it?', alignLabelWithHint: true),
                ),
              UIUtils.buildFormButtons(
                context: context,
                onSave: _submit,
                isSubmitting: _isSubmitting,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ObservationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ObservationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = data['observationType'] ?? 'Safe Act';
    final desc = data['description'] ?? '';
    final observer = data['observerName'] ?? 'Anonymous';
    final points = data['pointsAwarded'] ?? 0;
    final intervention = data['interventionAction'];
    final location = data['location'] ?? '';

    return GCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GStatusTag(
                label: type,
                color: _typeColor(type),
                icon: _typeIcon(type),
              ),
              const Spacer(),
              if (points > 0)
                GStatusTag(
                  label: '+$points pts',
                  color: theme.colorScheme.primary,
                  icon: Icons.auto_awesome,
                ),
            ],
          ),
          GSpacing.vMd,
          Text(
            location,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          if (intervention != null && intervention.toString().isNotEmpty) ...[
            GSpacing.vMd,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(XMTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Intervention',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(intervention.toString(), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
          GSpacing.vMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                observer,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              Text(
                UIUtils.formatTimestamp(data['createdAt']),
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
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
      case 'Safe Act': return Icons.verified;
      case 'Unsafe Act': return Icons.report_problem;
      case 'Unsafe Condition': return Icons.warning;
      default: return Icons.info_outline;
    }
  }
}
