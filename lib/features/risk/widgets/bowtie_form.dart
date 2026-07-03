// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

class BowTieForm extends ConsumerStatefulWidget {
  const BowTieForm({super.key});

  @override
  ConsumerState<BowTieForm> createState() => _BowTieFormState();
}

class _BowTieFormState extends ConsumerState<BowTieForm> {
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

  Future<void> _submit(BuildContext formCtx) async {
    if (_titleCtrl.text.isEmpty || _topEvent.isEmpty) {
      UIUtils.showToast(
        context,
        'Title and top event are required',
        type: ToastType.error,
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            tenantId: ref.read(currentTenantIdProvider) ?? '',
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
              'siteId': profile.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (formCtx.mounted) {
        Navigator.pop(formCtx);
        UIUtils.showToast(context, 'Bow-Tie analysis successfully created');
        _titleCtrl.clear();
        _threatCtrl.clear();
        _consequenceCtrl.clear();
        _preventiveCtrl.clear();
        _mitigationCtrl.clear();
        _topEvent = '';
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
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 13),
                            ),
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
                          : const Icon(Icons.account_tree_rounded),
                  label: Text(
                    _isSubmitting ? 'SAVING...' : 'REGISTER ANALYSIS',
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
