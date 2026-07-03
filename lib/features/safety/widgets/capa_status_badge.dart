import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class CAPAStatusBadge extends StatelessWidget {
  final String status;
  const CAPAStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Open':
        color = XMTheme.statusOpen;
        break;
      case 'In Progress':
        color = XMTheme.statusInProgress;
        break;
      case 'Completed':
        color = XMTheme.statusResolved;
        break;
      case 'Verified':
        color = XMTheme.statusClosed;
        break;
      default:
        color = XMTheme.statusDraft;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          XMTheme.radiusXl,
        ), // Fully rounded pill
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
