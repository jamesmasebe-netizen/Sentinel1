import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../utils/ui_utils.dart';

class QuickActionsSheet {
  static void show(BuildContext context) {
    UIUtils.showAppBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(XMTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: XMTheme.spacingMd),
            _QuickActionTile(
              icon: Icons.report_problem,
              color: XMTheme.error,
              title: 'Incident Report',
              subtitle: 'Log a safety incident or near-miss',
              onTap: () {
                Navigator.pop(context);
                context.go('/safety');
              },
            ),
            _QuickActionTile(
              icon: Icons.assignment,
              color: XMTheme.warning,
              title: 'Permit to Work',
              subtitle: 'Create a new PTW request',
              onTap: () {
                Navigator.pop(context);
                context.go('/safety');
              },
            ),
            _QuickActionTile(
              icon: Icons.warning,
              color: XMTheme.info,
              title: 'Hazard Observation',
              subtitle: 'Report a workplace hazard',
              onTap: () {
                Navigator.pop(context);
                context.go('/safety');
              },
            ),
            _QuickActionTile(
              icon: Icons.monitor_heart,
              color: XMTheme.success,
              title: 'Health Check',
              subtitle: 'Log a medical or occupational health entry',
              onTap: () {
                Navigator.pop(context);
                context.go('/people');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: XMTheme.secondaryLight),
      ),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}
