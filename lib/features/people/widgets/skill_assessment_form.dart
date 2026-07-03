import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

class SkillAssessmentForm extends ConsumerStatefulWidget {
  final VoidCallback onCancel;
  const SkillAssessmentForm({super.key, required this.onCancel});

  @override
  ConsumerState<SkillAssessmentForm> createState() => _SkillAssessmentFormState();
}

class _SkillAssessmentFormState extends ConsumerState<SkillAssessmentForm> {
  final _employeeCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  String _proficiency = 'Intermediate';
  final String _verifiedBy = '';
  bool _isSubmitting = false;

  static const _proficiencies = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert',
  ];
  static const _defaultSkills = [
    'LOTO Procedure',
    'First Aid',
    'Fire Safety',
    'Working at Heights',
    'Confined Space Entry',
    'Forklift Operation',
    'Crane Operation',
    'Fall Protection',
    'Hazmat Handling',
    'Scaffolding Inspection',
  ];

  @override
  void dispose() {
    _employeeCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_employeeCtrl.text.isEmpty || _skillCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Please fill employee and skill', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(
        tenantId: ref.read(currentTenantIdProvider) ?? '',
        collection: 'skills_matrix',
        data: {
          'employeeName': _employeeCtrl.text.trim(),
          'skill': _skillCtrl.text.trim(),
          'proficiency': _proficiency,
          'verifiedBy': _verifiedBy,
          'lastAssessed': DateTime.now().toIso8601String(),
          'siteId': profile.tenantId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        UIUtils.showToast(context, 'Skill entry added', type: ToastType.success);
        widget.onCancel();
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
    return GCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Skill Assessment',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _employeeCtrl,
            decoration: const InputDecoration(
              labelText: 'Employee Name *',
              prefixIcon: Icon(Icons.person),
              isDense: true,
            ),
          ),
          GSpacing.vMd,
          Autocomplete<String>(
            optionsBuilder:
                (v) => _defaultSkills.where(
                  (s) => s.toLowerCase().contains(v.text.toLowerCase()),
                ),
            fieldViewBuilder: (context, ctrl, fn, onSubmit) {
              return TextFormField(
                controller: ctrl,
                focusNode: fn,
                decoration: const InputDecoration(
                  labelText: 'Skill / Competency *',
                  prefixIcon: Icon(Icons.build),
                  isDense: true,
                ),
              );
            },
            onSelected: (v) => _skillCtrl.text = v,
          ),
          GSpacing.vMd,
          DropdownButtonFormField<String>(
            value: _proficiency,
            decoration: const InputDecoration(
              labelText: 'Proficiency Level',
              isDense: true,
            ),
            items:
                _proficiencies
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
            onChanged: (v) => setState(() => _proficiency = v!),
          ),
          GSpacing.vLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon:
                  _isSubmitting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.save, size: 18),
              label: Text(_isSubmitting ? 'Saving...' : 'Save Assessment'),
            ),
          ),
        ],
      ),
    );
  }
}
