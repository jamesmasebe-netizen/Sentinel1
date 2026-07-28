// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/searchable_multi_select.dart';
import '../../people/widgets/employee_selector.dart';
import '../../people/providers/employee_providers.dart';

class DRAForm extends ConsumerStatefulWidget {
  const DRAForm({super.key});

  @override
  ConsumerState<DRAForm> createState() => _DRAFormState();
}

class _DRAFormState extends ConsumerState<DRAForm> {
  final _taskCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _hazardCtrl = TextEditingController();
  final _controlCtrl = TextEditingController();
  List<String> _hazards = [], _controls = [];
  List<String> _teamMembers = [];
  String? _approverId;
  DateTime? _reviewDate;
  bool _isSafe = false;
  bool _isSubmitting = false;

  // Same risk-matrix pattern as hira_form.dart, so DRA gets a real riskLevel
  // instead of leaving risk_command_center_screen.dart's KPI grid always at 0.
  String _likelihood = 'Possible';
  String _severity = 'Major';
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

  @override
  void dispose() {
    _taskCtrl.dispose();
    _locCtrl.dispose();
    _hazardCtrl.dispose();
    _controlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext formCtx) async {
    if (_taskCtrl.text.isEmpty || _hazards.isEmpty || _controls.isEmpty) {
      UIUtils.showToast(
        context,
        'Please fill task, hazards & controls',
        type: ToastType.error,
      );
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
            tenantId: ref.read(currentTenantIdProvider) ?? '',
            collection: 'dynamic_risk_assessments',
            data: {
              'type': 'dra',
              'title': 'DRA: ${_taskCtrl.text.trim()}',
              'description': _hazards.join(', '),
              'activity': _taskCtrl.text.trim(),
              'area': _locCtrl.text.trim(),
              // taskDescription/location/task are the field names dra_card.dart and
              // risk_command_center_screen.dart actually read (2 different keys for the
              // same concept, verified directly) — see docs/fixes/FIX_LIST.md F-306.
              'taskDescription': _taskCtrl.text.trim(),
              'location': _locCtrl.text.trim(),
              'task': _taskCtrl.text.trim(),
              'likelihood': _likelihood,
              'severity': _severity,
              'riskLevel': _riskLevel(score),
              'status': 'Pending',
              'hazardsIdentified': _hazards,
              'controlsApplied': _controls,
              'teamMembers': _teamMembers,
              'approverId': _approverId,
              'reviewDate': _reviewDate?.toIso8601String(),
              'isSafeToProceed': _isSafe,
              'assessedBy': profile.uid,
              'authorName': profile.displayName,
              'siteId': profile.tenantId,
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
      if (formCtx.mounted) {
        Navigator.pop(formCtx);
        UIUtils.showToast(
          context,
          'Dynamic Risk Assessment submitted successfully',
        );
        _taskCtrl.clear();
        _locCtrl.clear();
        _hazards = [];
        _controls = [];
        _isSafe = false;
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
              Text(
                'Assessment Details',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                'Risk Matrix Evaluation',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
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
                      value: _severity,
                      decoration: const InputDecoration(labelText: 'Severity'),
                      items:
                          _severities
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
                      onChanged: (v) => setLocalState(() => _severity = v!),
                    ),
                  ),
                ],
              ),
              GSpacing.vLg,
              Text(
                'Hazards Identified',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                            label: Text(
                              e.value,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onDeleted:
                                () => setLocalState(
                                  () => _hazards.removeAt(e.key),
                                ),
                            backgroundColor: theme.colorScheme.errorContainer
                                .withValues(alpha: 0.3),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                        .toList(),
              ),
              GSpacing.vLg,
              Text(
                'Controls Applied',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                            label: Text(
                              e.value,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onDeleted:
                                () => setLocalState(
                                  () => _controls.removeAt(e.key),
                                ),
                            backgroundColor: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                        .toList(),
              ),
              GSpacing.vLg,
              Text(
                'Approval & Review',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              GSpacing.vMd,
              EmployeeSelector(
                label: 'Approver',
                value: _approverId,
                onChanged: (val) => setLocalState(() => _approverId = val),
              ),
              GSpacing.vMd,
              ref.watch(employeesProvider).when(
                data: (employees) {
                  final options = employees.map((e) => e.id).toList();
                  final labels = {for (var e in employees) e.id: e.fullName};
                  return SearchableStringMultiSelect(
                    label: 'Team Members',
                    hintText: 'Search team members...',
                    availableItems: options,
                    itemLabels: labels,
                    selectedItems: _teamMembers,
                    onChanged: (vals) => setLocalState(() => _teamMembers = vals),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => Text('Error loading employees: $e'),
              ),
              GSpacing.vMd,
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Next Review Date'),
                subtitle: Text(
                  _reviewDate != null ? '${_reviewDate!.toLocal()}'.split(' ')[0] : 'Select Date',
                ),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (d != null) setLocalState(() => _reviewDate = d);
                },
              ),
              GSpacing.vLg,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      _isSafe
                          ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.1,
                          )
                          : theme.colorScheme.errorContainer.withValues(
                            alpha: 0.05,
                          ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text(
                    'I confirm it is safe to proceed with the task',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          _isSafe
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                    ),
                  ),
                  value: _isSafe,
                  onChanged: (v) => setLocalState(() => _isSafe = v!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              GSpacing.vXl,
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed:
                      (_isSubmitting || !_isSafe)
                          ? null
                          : () => _submit(context),
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
                          : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _isSubmitting ? 'SUBMITTING...' : 'COMPLETE ASSESSMENT',
                  ),
                ),
              ),
              GSpacing.vXl,
            ],
          ),
        );
      },
    );
  }
}
