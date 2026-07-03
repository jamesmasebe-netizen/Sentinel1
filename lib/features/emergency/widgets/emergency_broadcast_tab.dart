import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';

class EmergencyBroadcastTab extends StatelessWidget {
  const EmergencyBroadcastTab({super.key});

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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          GSpacing.vSm,
          Text(
            'Send push notifications and SMS alerts to all personnel on site immediately.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          GSpacing.vLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                UIUtils.showToast(context, 'Broadcast system initialized. Configure in FCM.');
              },
              icon: const Icon(Icons.send),
              label: const Text('Initialize Test Broadcast'),
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
