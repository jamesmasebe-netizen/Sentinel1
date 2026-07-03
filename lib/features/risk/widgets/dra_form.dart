// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

class DRAForm extends ConsumerStatefulWidget {
  final String tenantId;
  const DRAForm({super.key, required this.tenantId});

  @override
  ConsumerState<DRAForm> createState() => _DRAFormState();
}

class _DRAFormState extends ConsumerState<DRAForm> {
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

  Future<void> _submit(BuildContext formCtx) async {
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
            tenantId: widget.tenantId,
            collection: 'dynamic_risk_assessments',
            data: {
              'taskDescription': _taskCtrl.text.trim(),
              'location': _locCtrl.text.trim(),
              'hazardsIdentified': _hazards,
              'controlsApplied': _controls,
              'isSafeToProceed': _isSafe,
              'authorId': profile.uid,
              'authorName': profile.displayName,
              'siteId': profile.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (formCtx.mounted) {
        Navigator.pop(formCtx);
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
                  onPressed: (_isSubmitting || !_isSafe) ? null : () => _submit(context),
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
