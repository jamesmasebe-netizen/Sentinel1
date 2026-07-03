import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';
import '../../../../../core/widgets/ds_widgets.dart';

class PermitCard extends StatelessWidget {
  final Map<String, dynamic> p;

  const PermitCard({super.key, required this.p});

  @override
  Widget build(BuildContext context) {
    final status = p['status'] as String;
    Color statusColor = Colors.grey;
    if (status == 'approved' || status == 'active') statusColor = XMTheme.success;
    if (status == 'pending_approval') statusColor = XMTheme.warning;

    return GCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: XMTheme.primary),
          GSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['title'] ?? 'Permit', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('No: ${p['permitNumber'] ?? 'N/A'} • Type: ${p['type'] ?? 'General'}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 9, color: statusColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
