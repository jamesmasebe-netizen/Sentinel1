// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../../people/widgets/employee_selector.dart';

class StrategicRiskForm extends ConsumerStatefulWidget {
  const StrategicRiskForm({super.key});

  @override
  ConsumerState<StrategicRiskForm> createState() => _StrategicRiskFormState();
}

class _StrategicRiskFormState extends ConsumerState<StrategicRiskForm> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _mitigationCtrl = TextEditingController();
  String? _ownerId;
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

  Future<void> _submit(BuildContext formCtx) async {
    if (_titleCtrl.text.isEmpty) {
      UIUtils.showToast(
        context,
        'Please enter a risk title',
        type: ToastType.error,
      );
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
            tenantId: ref.read(currentTenantIdProvider) ?? '',
            collection: 'strategic_risks',
            data: {
              'title': _titleCtrl.text.trim(),
              'description': _descriptionCtrl.text.trim(),
              'category': _category,
              'owner': _ownerId ?? '',
              'likelihood': _likelihood,
              'impact': _impact,
              'riskScore': score,
              'riskRating': _riskRating(score),
              'mitigation': _mitigationCtrl.text.trim(),
              'status': _status,
              'authorId': profile.uid,
              'siteId': profile.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (formCtx.mounted) {
        Navigator.pop(formCtx);
        UIUtils.showToast(context, 'Strategic risk successfully registered');
        _titleCtrl.clear();
        _descriptionCtrl.clear();
        _mitigationCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                  child: Text(
                                    c,
                                    style: const TextStyle(fontSize: 13),
                                  ),
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
                                  child: Text(
                                    s,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setLocalState(() => _status = v!),
                    ),
                  ),
                ],
              ),
              GSpacing.vMd,
              EmployeeSelector(
                label: 'Risk Owner',
                value: _ownerId,
                onChanged: (val) => setLocalState(() => _ownerId = val),
              ),
              GSpacing.vLg,
              Text(
                'Risk Assessment (Likelihood × Impact)',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              GSpacing.vMd,
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _likelihood,
                      decoration: const InputDecoration(
                        labelText: 'Likelihood',
                      ),
                      items:
                          _likelihoods
                              .map(
                                (l) => DropdownMenuItem(
                                  value: l,
                                  child: Text(
                                    l,
                                    style: const TextStyle(fontSize: 13),
                                  ),
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
                                  child: Text(
                                    i,
                                    style: const TextStyle(fontSize: 13),
                                  ),
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
                  color: _ratingColor(
                    _riskRating(_riskScore()),
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _ratingColor(
                      _riskRating(_riskScore()),
                    ).withValues(alpha: 0.2),
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
                  onPressed: _isSubmitting ? null : () => _submit(context),
                  icon:
                      _isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.save_rounded),
                  label: Text(_isSubmitting ? 'SAVING...' : 'REGISTER RISK'),
                ),
              ),
              GSpacing.vXl,
            ],
          ),
        );
      },
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
}
