import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class NewProjectHeader extends StatelessWidget {
  const NewProjectHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        color: XMTheme.primary.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: XMTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_business_rounded, color: XMTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Project',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Project methodology — stages auto-configured',
                    style: TextStyle(fontSize: 12, color: XMTheme.secondaryLight)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }
}
