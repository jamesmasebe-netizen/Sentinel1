import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

/// Strategic Risk Register — corporate-level risks with likelihood × impact scoring.
class StrategicRiskRegisterScreen extends ConsumerStatefulWidget {
  const StrategicRiskRegisterScreen({super.key});
  @override
  ConsumerState<StrategicRiskRegisterScreen> createState() =>
      _StrategicRiskRegisterScreenState();
}

class _StrategicRiskRegisterScreenState
    extends ConsumerState<StrategicRiskRegisterScreen> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _mitigationCtrl = TextEditingController();
  String _category = 'Operational';
  String _likelihood = 'Possible';
  String _impact = 'Significant';
  String _status = 'Open';
  bool _isSubmitting = false;

  static const _categories = [
    'Operational',
    'Financial',
    'Regulatory',
    'Reputational',
    'Strategic',
    'Environmental',
  ];
  static const _likelihoods = [
    'Rare',
    'Unlikely',
    'Possible',
    'Likely',
    'Almost Certain',
  ];
  static const _impacts = [
    'Negligible',
    'Minor',
    'Moderate',
    'Significant',
    'Severe',
  ];
  static const _statuses = ['Open', 'Mitigating', 'Monitoring', 'Closed'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _ownerCtrl.dispose();
    _mitigationCtrl.dispose();
    super.dispose();
  }

  int _riskScore() =>
      (_likelihoods.indexOf(_likelihood) + 1) * (_impacts.indexOf(_impact) + 1);

  String _riskRating(int score) {
    if (score >= 16) return 'Critical';
    if (score >= 10) return 'High';
    if (score >= 5) return 'Medium';
    return 'Low';
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Please enter a risk title', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      final score = _riskScore();
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            collection: 'strategic_risks',
            data: {
              'title': _titleCtrl.text.trim(),
              'description': _descriptionCtrl.text.trim(),
              'category': _category,
              'owner': _ownerCtrl.text.trim(),
              'likelihood': _likelihood,
              'impact': _impact,
              'riskScore': score,
              'riskRating': _riskRating(score),
              'mitigation': _mitigationCtrl.text.trim(),
              'status': _status,
              'authorId': profile.uid,
              'siteId': profile.siteId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'Strategic risk successfully registered');
        _titleCtrl.clear();
        _descriptionCtrl.clear();
        _ownerCtrl.clear();
        _mitigationCtrl.clear();
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
              Text('Corporate Risks', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'New Strategic Risk',
                  builder: (ctx) => _buildForm(context),
                ),
                icon: const Icon(Icons.shield_rounded, size: 18),
                label: const Text('Add Risk'),
              ),
            ],
          ),
        ),

        // ─── List ───
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('strategic_risks')
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
                      Icon(Icons.shield_outlined, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                      GSpacing.vMd,
                      Text('No strategic risks registered', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final rating = d['riskRating'] ?? 'Low';
                  final score = d['riskScore'] ?? 0;
                  final status = d['status'] ?? 'Open';

                  return GCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GStatusTag(label: '$rating ($score)'.toUpperCase(), color: _ratingColor(rating), icon: Icons.speed_rounded),
                            GSpacing.hSm,
                            GStatusTag(label: (d['category'] ?? 'Operational').toUpperCase(), color: theme.colorScheme.secondary),
                            const Spacer(),
                            GStatusTag(label: status.toUpperCase(), color: _statusColor(status), icon: _statusIcon(status)),
                          ],
                        ),
                        GSpacing.vMd,
                        Text(d['title'] ?? 'Untitled Risk', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        if (d['description']?.toString().isNotEmpty ?? false) ...[
                          GSpacing.vSm,
                          Text(d['description'], style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                        GSpacing.vMd,
                        const Divider(height: 1, thickness: 0.5),
                        GSpacing.vMd,
                        Row(
                          children: [
                            if (d['owner']?.toString().isNotEmpty ?? false) ...[
                              Icon(Icons.person_outline_rounded, size: 16, color: theme.colorScheme.primary),
                              GSpacing.hSm,
                              Text(d['owner'], style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                               GSpacing.hLg,
                            ],
                            Icon(Icons.analytics_outlined, size: 16, color: theme.colorScheme.outline),
                            GSpacing.hSm,
                            Text('L: ${d['likelihood']} • I: ${d['impact']}', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
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
                  labelText: 'Risk Title *',
                  hintText: 'e.g., Supply Chain Disruption',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide context for this strategic risk...',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              GSpacing.vMd,
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items:
                          _categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: const TextStyle(fontSize: 13)),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setLocalState(() => _category = v!),
                    ),
                  ),
                  GSpacing.hMd,
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items:
                          _statuses
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s, style: const TextStyle(fontSize: 13)),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setLocalState(() => _status = v!),
                    ),
                  ),
                ],
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _ownerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Risk Owner',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              GSpacing.vLg,
              Text(
                'Risk Assessment (Likelihood × Impact)',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              GSpacing.vMd,
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _likelihood,
                      decoration: const InputDecoration(labelText: 'Likelihood'),
                      items:
                          _likelihoods
                              .map(
                                (l) => DropdownMenuItem(
                                  value: l,
                                  child: Text(l, style: const TextStyle(fontSize: 13)),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setLocalState(() => _likelihood = v!),
                    ),
                  ),
                  GSpacing.hMd,
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _impact,
                      decoration: const InputDecoration(labelText: 'Impact'),
                      items:
                          _impacts
                              .map(
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(i, style: const TextStyle(fontSize: 13)),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setLocalState(() => _impact = v!),
                    ),
                  ),
                ],
              ),
              GSpacing.vMd,
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _ratingColor(_riskRating(_riskScore())).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _ratingColor(_riskRating(_riskScore())).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      color: _ratingColor(_riskRating(_riskScore())),
                    ),
                    GSpacing.hMd,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calculated Risk Score: ${_riskScore()}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _ratingColor(_riskRating(_riskScore())),
                          ),
                        ),
                        Text(
                          'Rating: ${_riskRating(_riskScore()).toUpperCase()}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _ratingColor(_riskRating(_riskScore())),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GSpacing.vLg,
              TextFormField(
                controller: _mitigationCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mitigation Strategy',
                  prefixIcon: Icon(Icons.shield_outlined),
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
                          : const Icon(Icons.save_rounded),
                  label: Text(_isSubmitting ? 'SAVING...' : 'REGISTER RISK'),
                ),
              ),
              GSpacing.vXl,
            ],
          ),
        );
      }
    );
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'Critical':
        return XMTheme.riskExtreme;
      case 'High':
        return XMTheme.riskHigh;
      case 'Medium':
        return XMTheme.riskMedium;
      default:
        return XMTheme.riskLow;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return XMTheme.error;
      case 'Mitigating':
        return XMTheme.warning;
      case 'Monitoring':
        return XMTheme.info;
      case 'Closed':
        return XMTheme.success;
      default:
        return XMTheme.primary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Open':
        return Icons.error_outline_rounded;
      case 'Mitigating':
        return Icons.shield_outlined;
      case 'Monitoring':
        return Icons.visibility_outlined;
      case 'Closed':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

