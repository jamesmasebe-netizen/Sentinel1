import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';

class TalkFormSheet extends ConsumerStatefulWidget {
  const TalkFormSheet({super.key});

  @override
  ConsumerState<TalkFormSheet> createState() => _TalkFormSheetState();
}

class _TalkFormSheetState extends ConsumerState<TalkFormSheet> {
  bool _isSubmitting = false;
  final _topicCtrl = TextEditingController();
  final _talkLocCtrl = TextEditingController();
  final _attendeesCtrl = TextEditingController();
  final DateTime _talkDate = DateTime.now();

  @override
  void dispose() {
    _topicCtrl.dispose();
    _talkLocCtrl.dispose();
    _attendeesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitTalk() async {
    if (_topicCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Please enter a topic', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');

      final attendees =
          _attendeesCtrl.text
              .split(',')
              .map((a) => a.trim())
              .where((a) => a.isNotEmpty)
              .toList();

      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            tenantId: ref.read(currentTenantIdProvider) ?? '',
            collection: 'toolbox_talks',
            data: {
              'topic': _topicCtrl.text.trim(),
              'date': _talkDate.toIso8601String(),
              'conductorName': profile.displayName,
              'location': _talkLocCtrl.text.trim(),
              'attendees': attendees,
              'authorId': profile.uid,
              'siteId': profile.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );

      if (mounted) {
        Navigator.pop(context); // Close side sheet
        UIUtils.showToast(context, 'Toolbox talk logged successfully');
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _topicCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Talk Topic *',
                    prefixIcon: Icon(Icons.topic_outlined),
                  ),
                ),
                GSpacing.vLg,
                TextFormField(
                  controller: _talkLocCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location / Venue',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                GSpacing.vLg,
                TextFormField(
                  controller: _attendeesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Attendees',
                    hintText: 'Enter names separated by commas',
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                ),
                GSpacing.vMd,
                Text(
                  'Conducted on: ${_talkDate.day}/${_talkDate.month}/${_talkDate.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        UIUtils.buildFormButtons(
          context: context,
          onSave: _submitTalk,
          isSubmitting: _isSubmitting,
        ),
      ],
    );
  }
}
