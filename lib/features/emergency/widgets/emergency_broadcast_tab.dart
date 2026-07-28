import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';

class EmergencyBroadcastTab extends ConsumerStatefulWidget {
  const EmergencyBroadcastTab({super.key});

  @override
  ConsumerState<EmergencyBroadcastTab> createState() =>
      _EmergencyBroadcastTabState();
}

class _EmergencyBroadcastTabState
    extends ConsumerState<EmergencyBroadcastTab> {
  bool _isSending = false;

  Future<void> _openBroadcastDialog() async {
    final messageCtrl = TextEditingController();
    String emergencyType = 'Fire';

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogCtx) => StatefulBuilder(
            builder:
                (dialogCtx, setDialogState) => AlertDialog(
                  title: const Text('Send Emergency Broadcast'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: emergencyType,
                        decoration: const InputDecoration(
                          labelText: 'Emergency Type',
                        ),
                        items:
                            ['Fire', 'Medical', 'Security', 'Evacuation', 'Other']
                                .map(
                                  (t) =>
                                      DropdownMenuItem(value: t, child: Text(t)),
                                )
                                .toList(),
                        onChanged:
                            (v) => setDialogState(() => emergencyType = v!),
                      ),
                      GSpacing.vMd,
                      TextField(
                        controller: messageCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Message to broadcast',
                          hintText: 'e.g. Evacuate Building B immediately via the north stairwell.',
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed:
                          messageCtrl.text.trim().isEmpty
                              ? null
                              : () => Navigator.pop(dialogCtx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: XMTheme.error,
                      ),
                      child: const Text('Send Now'),
                    ),
                  ],
                ),
          ),
    );

    if (confirmed != true || !mounted) return;

    final siteId = ref.read(currentTenantIdProvider);
    if (siteId == null) {
      UIUtils.showToast(context, 'No active tenant', type: ToastType.error);
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref
          .read(NotificationService.provider)
          .sendEmergencyBroadcast(
            siteId: siteId,
            message: messageCtrl.text.trim(),
            emergencyType: emergencyType,
          );
      if (mounted) {
        UIUtils.showToast(context, 'Emergency broadcast sent to all personnel');
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Broadcast failed: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: XMTheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign, size: 80, color: XMTheme.error),
          ),
          GSpacing.vLg,
          Text(
            'Emergency Broadcast',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          GSpacing.vSm,
          Text(
            'Send push notifications and SMS alerts to all personnel on site immediately.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          GSpacing.vLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSending ? null : _openBroadcastDialog,
              icon:
                  _isSending
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.send),
              label: Text(_isSending ? 'Sending...' : 'Send Emergency Broadcast'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: XMTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
