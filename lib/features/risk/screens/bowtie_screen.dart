import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

/// Bow-Tie Analysis — register for threat/barrier/consequence chains.
class BowtieScreen extends ConsumerStatefulWidget {
  const BowtieScreen({super.key});
  @override
  ConsumerState<BowtieScreen> createState() => _BowtieScreenState();
}

class _BowtieScreenState extends ConsumerState<BowtieScreen> {
  final _titleCtrl = TextEditingController();
  final _threatCtrl = TextEditingController();
  final _consequenceCtrl = TextEditingController();
  final _preventiveCtrl = TextEditingController();
  final _mitigationCtrl = TextEditingController();
  String _topEvent = '';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _threatCtrl.dispose();
    _consequenceCtrl.dispose();
    _preventiveCtrl.dispose();
    _mitigationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _topEvent.isEmpty) {
      UIUtils.showToast(context, 'Title and top event are required', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            collection: 'bowtie_analyses',
            data: {
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
            },
          );
      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'Bow-Tie analysis successfully created');
        _titleCtrl.clear();
        _threatCtrl.clear();
        _consequenceCtrl.clear();
        _preventiveCtrl.clear();
        _mitigationCtrl.clear();
        _topEvent = '';
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Column(
      children: [
        // ─── Actions Bar ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Text('Threat Analysis', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'New Bow-Tie Analysis',
                  builder: (ctx) => _buildForm(context),
                ),
                icon: const Icon(Icons.account_tree_rounded, size: 18),
                label: const Text('New Analysis'),
              ),
            ],
          ),
        ),

        // ─── List ───
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('bowtie_analyses')
                .where('siteId', isEqualTo: siteId)
                .orderBy('createdAt', descending: true)
                .limit(30)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_tree_outlined, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                      GSpacing.vMd,
                      Text('No bow-tie analyses found', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _BowTieCard(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Analysis Title *',
                  hintText: 'e.g., Underground Fire Risk',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              GSpacing.vMd,
              DropdownButtonFormField<String>(
                value: _topEvent.isEmpty ? null : _topEvent,
                decoration: const InputDecoration(
                  labelText: 'Top Event (Center) *',
                  prefixIcon: Icon(Icons.crisis_alert_rounded),
                ),
                items:
                    [
                          'Fire / Explosion',
                          'Structural Collapse',
                          'Chemical Release',
                          'Electrical Contact',
                          'Fall from Height',
                          'Vehicle Incident',
                          'Confined Space Emergency',
                        ]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, style: const TextStyle(fontSize: 13)),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setLocalState(() => _topEvent = v ?? ''),
              ),
              GSpacing.vLg,
              const Divider(),
              GSpacing.vLg,
              Text(
                'Left Side: Threats & Prevention',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: XMTheme.riskHigh,
                ),
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _threatCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Threats',
                  hintText: 'What could trigger the event?',
                  prefixIcon: Icon(Icons.warning_amber_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _preventiveCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Preventive Barriers',
                  hintText: 'How do we stop it from happening?',
                  prefixIcon: Icon(Icons.shield_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              GSpacing.vLg,
              const Divider(),
              GSpacing.vLg,
              Text(
                'Right Side: Mitigation & Consequences',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: XMTheme.success,
                ),
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _mitigationCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Mitigation Barriers',
                  hintText: 'How do we minimize the impact?',
                  prefixIcon: Icon(Icons.healing_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _consequenceCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Consequences',
                  hintText: 'What happens if we fail?',
                  prefixIcon: Icon(Icons.dangerous_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              GSpacing.vXl,
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon:
                      _isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                          : const Icon(Icons.account_tree_rounded),
                  label: Text(_isSubmitting ? 'SAVING...' : 'REGISTER ANALYSIS'),
                ),
              ),
              GSpacing.vXl,
            ],
          ),
        );
      }
    );
  }
}

class _BowTieCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BowTieCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = data['status'] ?? 'Draft';

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.account_tree_rounded, size: 18, color: theme.colorScheme.primary),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'] ?? 'Untitled Analysis', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(UIUtils.formatTimestamp(data['createdAt']), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              GStatusTag(label: status.toUpperCase(), color: theme.colorScheme.primary),
            ],
          ),
          GSpacing.vLg,
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                _buildExpressiveRow(context, 'THREATS & PREVENTION', data['threats'], data['preventiveBarriers'], XMTheme.riskHigh, Icons.shield_rounded, true),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: XMTheme.riskExtreme, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      data['topEvent']?.toUpperCase() ?? 'TOP EVENT',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
                  ),
                ),
                _buildExpressiveRow(context, 'MITIGATION & RECOVERY', data['mitigationBarriers'], data['consequences'], XMTheme.success, Icons.healing_rounded, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpressiveRow(BuildContext context, String title, String? val1, String? val2, Color color, IconData icon, bool isTop) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            GSpacing.hSm,
            Text(title, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: color, letterSpacing: 1.1)),
          ],
        ),
        GSpacing.vSm,
        Text(
          '${val1 ?? "N/A"} • ${val2 ?? "N/A"}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface, height: 1.4),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

