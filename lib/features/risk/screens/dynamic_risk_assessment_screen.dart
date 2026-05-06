import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

/// Dynamic Risk Assessment — on-the-spot task risk evaluation with hazard/control chip lists.
class DynamicRiskAssessmentScreen extends ConsumerStatefulWidget {
  const DynamicRiskAssessmentScreen({super.key});
  @override
  ConsumerState<DynamicRiskAssessmentScreen> createState() => _DRAState();
}

class _DRAState extends ConsumerState<DynamicRiskAssessmentScreen> {
  final _taskCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _hazardCtrl = TextEditingController();
  final _controlCtrl = TextEditingController();
  List<String> _hazards = [], _controls = [];
  bool _isSafe = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _taskCtrl.dispose();
    _locCtrl.dispose();
    _hazardCtrl.dispose();
    _controlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_taskCtrl.text.isEmpty || _hazards.isEmpty || _controls.isEmpty) {
      UIUtils.showToast(context, 'Please fill task, hazards & controls', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            collection: 'dynamic_risk_assessments',
            data: {
              'taskDescription': _taskCtrl.text.trim(),
              'location': _locCtrl.text.trim(),
              'hazardsIdentified': _hazards,
              'controlsApplied': _controls,
              'isSafeToProceed': _isSafe,
              'authorId': profile.uid,
              'authorName': profile.displayName,
              'siteId': profile.siteId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'Dynamic Risk Assessment submitted successfully');
        _taskCtrl.clear();
        _locCtrl.clear();
        _hazards = [];
        _controls = [];
        _isSafe = false;
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
              Text('Live Assessments', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'New Dynamic Assessment',
                  builder: (ctx) => _buildForm(context),
                ),
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text('New Assessment'),
              ),
            ],
          ),
        ),

        // ─── Assessment List ───
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('dynamic_risk_assessments')
                .where('siteId', isEqualTo: siteId)
                .orderBy('createdAt', descending: true)
                .limit(50)
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
                      Icon(Icons.assignment_turned_in_outlined, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                      GSpacing.vMd,
                      Text('No dynamic assessments yet', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return _DRACard(data: data);
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
              Text(
                'Assessment Details',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _taskCtrl,
                decoration: const InputDecoration(
                  labelText: 'Task Description *',
                  hintText: 'What task are you about to perform?',
                  prefixIcon: Icon(Icons.assignment_rounded),
                ),
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _locCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  prefixIcon: Icon(Icons.location_on_rounded),
                ),
              ),
              GSpacing.vLg,
              Text(
                'Hazards Identified',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              GSpacing.vSm,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hazardCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Add hazard...',
                        isDense: true,
                      ),
                    ),
                  ),
                  GSpacing.hMd,
                  IconButton.filledTonal(
                    onPressed: () {
                      if (_hazardCtrl.text.isNotEmpty) {
                        setLocalState(() {
                          _hazards.add(_hazardCtrl.text.trim());
                          _hazardCtrl.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              GSpacing.vSm,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _hazards
                        .asMap()
                        .entries
                        .map(
                          (e) => Chip(
                            label: Text(e.value, style: const TextStyle(fontSize: 12)),
                            onDeleted: () => setLocalState(() => _hazards.removeAt(e.key)),
                            backgroundColor: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        )
                        .toList(),
              ),
              GSpacing.vLg,
              Text(
                'Controls Applied',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              GSpacing.vSm,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _controlCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Add control...',
                        isDense: true,
                      ),
                    ),
                  ),
                  GSpacing.hMd,
                  IconButton.filledTonal(
                    onPressed: () {
                      if (_controlCtrl.text.isNotEmpty) {
                        setLocalState(() {
                          _controls.add(_controlCtrl.text.trim());
                          _controlCtrl.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              GSpacing.vSm,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _controls
                        .asMap()
                        .entries
                        .map(
                          (e) => Chip(
                            label: Text(e.value, style: const TextStyle(fontSize: 12)),
                            onDeleted: () => setLocalState(() => _controls.removeAt(e.key)),
                            backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        )
                        .toList(),
              ),
              GSpacing.vLg,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: _isSafe 
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                      : theme.colorScheme.errorContainer.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text(
                    'I confirm it is safe to proceed with the task',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _isSafe ? theme.colorScheme.primary : theme.colorScheme.error,
                    ),
                  ),
                  value: _isSafe,
                  onChanged: (v) => setLocalState(() => _isSafe = v!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              GSpacing.vXl,
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: (_isSubmitting || !_isSafe) ? null : _submit,
                  icon:
                      _isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                          : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(_isSubmitting ? 'SUBMITTING...' : 'COMPLETE ASSESSMENT'),
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

class _DRACard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DRACard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hazards = (data['hazardsIdentified'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final controls = (data['controlsApplied'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final isSafe = data['isSafeToProceed'] == true;

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (isSafe ? XMTheme.success : XMTheme.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(isSafe ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isSafe ? XMTheme.success : XMTheme.error, size: 22),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['taskDescription'] ?? 'Untitled Assessment', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    GSpacing.vXs,
                    Text(UIUtils.formatTimestamp(data['createdAt']), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              GStatusTag(label: isSafe ? 'SAFE' : 'UNSAFE', color: isSafe ? XMTheme.success : XMTheme.error),
            ],
          ),
          GSpacing.vMd,
          if (data['location'] != null && data['location'].toString().isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: theme.colorScheme.primary),
                GSpacing.hSm,
                Text(data['location'], style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            GSpacing.vMd,
          ],
          const Divider(height: 1, thickness: 0.5),
          GSpacing.vMd,
          Text('HAZARDS IDENTIFIED', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.error, letterSpacing: 1.1)),
          GSpacing.vSm,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hazards.map((h) => _TinyBadge(label: h, color: theme.colorScheme.error)).toList(),
          ),
          GSpacing.vMd,
          Text('CONTROLS APPLIED', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 1.1)),
          GSpacing.vSm,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controls.map((c) => _TinyBadge(label: c, color: theme.colorScheme.primary)).toList(),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TinyBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

