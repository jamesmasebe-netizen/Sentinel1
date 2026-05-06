import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

/// Baseline HIRA (Hazard Identification & Risk Assessment) — full CRUD register.
class HiraScreen extends ConsumerStatefulWidget {
  const HiraScreen({super.key});
  @override
  ConsumerState<HiraScreen> createState() => _HiraScreenState();
}

class _HiraScreenState extends ConsumerState<HiraScreen> {
  final _titleCtrl = TextEditingController();
  final _hazardCtrl = TextEditingController();
  final _consequenceCtrl = TextEditingController();
  String _likelihood = 'Possible';
  String _severity = 'Major';
  String _controlMeasure = '';
  bool _isSubmitting = false;

  static const _likelihoods = [
    'Rare',
    'Unlikely',
    'Possible',
    'Likely',
    'Almost Certain',
  ];
  static const _severities = [
    'Negligible',
    'Minor',
    'Moderate',
    'Major',
    'Catastrophic',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _hazardCtrl.dispose();
    _consequenceCtrl.dispose();
    super.dispose();
  }

  int _riskScore(String likelihood, String severity) {
    final l = _likelihoods.indexOf(likelihood) + 1;
    final s = _severities.indexOf(severity) + 1;
    return l * s;
  }

  String _riskLevel(int score) {
    if (score >= 16) return 'Extreme';
    if (score >= 10) return 'High';
    if (score >= 5) return 'Medium';
    return 'Low';
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _hazardCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Title and hazard are required', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      final score = _riskScore(_likelihood, _severity);
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            collection: 'risk_assessments',
            data: {
              'title': _titleCtrl.text.trim(),
              'hazard': _hazardCtrl.text.trim(),
              'consequence': _consequenceCtrl.text.trim(),
              'likelihood': _likelihood,
              'severity': _severity,
              'riskScore': score,
              'riskLevel': _riskLevel(score),
              'controlMeasure': _controlMeasure,
              'status': 'Active',
              'assessorId': profile.uid,
              'siteId': profile.siteId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'HIRA assessment successfully recorded');
        _titleCtrl.clear();
        _hazardCtrl.clear();
        _consequenceCtrl.clear();
        _controlMeasure = '';
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
              Text('Assessment History', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'New HIRA Assessment',
                  builder: (ctx) => _buildForm(context),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Assessment'),
              ),
            ],
          ),
        ),

        // ─── Assessment List ───
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('risk_assessments')
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
                      Icon(Icons.assessment_outlined, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                      GSpacing.vMd,
                      Text('No HIRA records found', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final level = d['riskLevel'] ?? 'Low';
                  final score = d['riskScore'] ?? 0;
                  return GCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    onTap: () {},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: _levelColor(level).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.assessment_rounded, color: _levelColor(level), size: 22),
                            ),
                            GSpacing.hMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d['title'] ?? 'Untitled Assessment', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  GSpacing.vXs,
                                  Text('Hazard: ${d['hazard'] ?? ''}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            GStatusTag(label: level.toUpperCase(), color: _levelColor(level), icon: Icons.speed_rounded),
                          ],
                        ),
                        GSpacing.vMd,
                        const Divider(height: 1, thickness: 0.5),
                        GSpacing.vMd,
                        Row(
                          children: [
                            _InfoBadge(label: 'Score: $score', icon: Icons.analytics_rounded, color: theme.colorScheme.primary),
                            GSpacing.hSm,
                            _InfoBadge(label: 'Likelihood: ${d['likelihood']}', icon: Icons.show_chart_rounded),
                            GSpacing.hSm,
                            _InfoBadge(label: 'Severity: ${d['severity']}', icon: Icons.layers_outlined),
                          ],
                        ),
                        if (d['controlMeasure'] != null && d['controlMeasure'].toString().isNotEmpty) ...[
                          GSpacing.vMd,
                          _InfoBadge(label: 'Control: ${d['controlMeasure']}', icon: Icons.shield_outlined, color: XMTheme.success),
                        ],
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
              Text('Assessment Core Details', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              GSpacing.vMd,
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Assessment Title',
                  hintText: 'e.g., Working at Heights - Main Factory',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _hazardCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Hazard Description',
                  hintText: 'Describe what could go wrong...',
                  prefixIcon: Icon(Icons.warning_amber_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _consequenceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Potential Consequence',
                  hintText: 'e.g., Serious injury, equipment damage',
                  prefixIcon: Icon(Icons.dangerous_outlined),
                ),
              ),
              GSpacing.vLg,
              Text('Risk Matrix Evaluation', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              GSpacing.vMd,
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _likelihood,
                      decoration: const InputDecoration(labelText: 'Likelihood'),
                      items: _likelihoods.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) => setLocalState(() => _likelihood = v!),
                    ),
                  ),
                  GSpacing.hMd,
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _severity,
                      decoration: const InputDecoration(labelText: 'Severity'),
                      items: _severities.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) => setLocalState(() => _severity = v!),
                    ),
                  ),
                ],
              ),
              GSpacing.vMd,
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _levelColor(_riskLevel(_riskScore(_likelihood, _severity))).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _levelColor(_riskLevel(_riskScore(_likelihood, _severity))).withValues(alpha: 0.2), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _levelColor(_riskLevel(_riskScore(_likelihood, _severity))).withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(Icons.speed_rounded, color: _levelColor(_riskLevel(_riskScore(_likelihood, _severity))), size: 28),
                    ),
                    GSpacing.hMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calculated Risk Exposure', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                          GSpacing.vXs,
                          Text('Score: ${_riskScore(_likelihood, _severity)} — ${_riskLevel(_riskScore(_likelihood, _severity)).toUpperCase()}',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: _levelColor(_riskLevel(_riskScore(_likelihood, _severity))))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              GSpacing.vLg,
              Text('Control Strategy', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              GSpacing.vMd,
              DropdownButtonFormField<String>(
                value: _controlMeasure.isEmpty ? null : _controlMeasure,
                decoration: const InputDecoration(
                  labelText: 'Primary Control Measure',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                items: ['Elimination', 'Substitution', 'Engineering Controls', 'Administrative Controls', 'PPE']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setLocalState(() => _controlMeasure = v ?? ''),
              ),
              GSpacing.vXl,
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSubmitting ? 'PROCESSING...' : 'AUTHORIZE HIRA RECORD', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ),
              ),
              GSpacing.vXxl,
            ],
          ),
        );
      },
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Extreme':
        return XMTheme.riskExtreme;
      case 'High':
        return XMTheme.riskHigh;
      case 'Medium':
        return XMTheme.riskMedium;
      default:
        return XMTheme.riskLow;
    }
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  
  const _InfoBadge({
    required this.label, 
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ?? theme.colorScheme.onSurfaceVariant;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: displayColor),
          GSpacing.hSm,
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: displayColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

