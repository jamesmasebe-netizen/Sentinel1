import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';

class MaintenanceLogDialog extends StatelessWidget {
  const MaintenanceLogDialog({super.key});

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
              color: XMTheme.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.engineering_outlined, size: 80, color: XMTheme.warning),
          ),
          GSpacing.vLg,
          Text(
            'Maintenance Hub',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          GSpacing.vSm,
          Text(
            'View and manage work orders for on-site equipment maintenance.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          GSpacing.vLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                UIUtils.showToast(context, 'Connecting to Work Order Management...');
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Work Orders'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ),
        ],
      ),
    );
  }
}
