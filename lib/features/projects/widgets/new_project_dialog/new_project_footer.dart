import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class NewProjectFooter extends StatelessWidget {
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const NewProjectFooter({
    super.key,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: saving ? null : onCancel,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon:
                saving
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.rocket_launch_rounded, size: 18),
            label: Text(saving ? 'Creating...' : 'Initiate Project'),
            style: FilledButton.styleFrom(backgroundColor: XMTheme.primary),
          ),
        ],
      ),
    );
  }
}
