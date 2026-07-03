import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';

class PPERow extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEmployeeTap;
  final VoidCallback onPPETap;

  const PPERow({
    super.key,
    required this.data,
    required this.onEmployeeTap,
    required this.onPPETap,
  });

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Unknown';
    Color statusColor;
    switch (status) {
      case 'Compliant':
        statusColor = XMTheme.success;
      case 'Non-Compliant':
        statusColor = XMTheme.error;
      case 'Expired':
        statusColor = XMTheme.warning;
      default:
        statusColor = XMTheme.statusDraft;
    }

    return GCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: onEmployeeTap,
              borderRadius: BorderRadius.circular(4),
              child: Text(
                data['employeeName'] ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: onPPETap,
              borderRadius: BorderRadius.circular(4),
              child: Text(
                data['ppeType'] ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GStatusTag(label: status, color: statusColor),
            ),
          ),
          GSpacing.hSm,
          Expanded(
            flex: 3,
            child: Text(
              _fmtDate(data['expiryDate']),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
