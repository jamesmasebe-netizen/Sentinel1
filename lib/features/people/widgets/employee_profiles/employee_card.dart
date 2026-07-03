import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/ds_widgets.dart';

class EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  
  const EmployeeCard({super.key, required this.data, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Active';
    Color statusColor = XMTheme.statusDraft;
    switch (status) {
      case 'Active':
        statusColor = XMTheme.success;
        break;
      case 'On Leave':
        statusColor = XMTheme.info;
        break;
      case 'Terminated':
        statusColor = XMTheme.error;
        break;
    }

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: XMTheme.primary.withValues(alpha: 0.1),
              child: Text(
                (data['fullName'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: XMTheme.primary,
                ),
              ),
            ),
            GSpacing.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['fullName'] ?? '',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${data['jobTitle'] ?? ''} • ${data['department'] ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            GStatusTag(label: status, color: statusColor),
            GSpacing.hSm,
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
