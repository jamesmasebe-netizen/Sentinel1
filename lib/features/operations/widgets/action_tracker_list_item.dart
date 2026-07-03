import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../models/action_tracker_models.dart';

class ActionTrackerListItem extends StatelessWidget {
  final ActionItem item;
  final Function(ActionItem, String) onUpdateStatus;

  const ActionTrackerListItem({
    super.key,
    required this.item,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _typeColor(item.type),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          GSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.type} • ${item.assignee} • ${_fmtDate(item.dueDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            initialValue: item.status,
            onSelected: (v) => onUpdateStatus(item, v),
            itemBuilder: (_) => ['Pending', 'In Progress', 'Completed']
                .map(
                  (s) => PopupMenuItem(
                    value: s,
                    child: Text(
                      s,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                )
                .toList(),
            child: GStatusTag(
              label: item.status,
              color: _statusColor(item.status),
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Incident':
        return XMTheme.error;
      case 'CAPA':
        return XMTheme.warning;
      case 'Permit':
        return XMTheme.primary;
      case 'Observation':
        return XMTheme.info;
      case 'DRA':
        return XMTheme.secondary;
      case 'Hazard':
        return XMTheme.severityMajor;
      default:
        return XMTheme.statusDraft;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
      case 'Open':
        return XMTheme.warning;
      case 'In Progress':
        return XMTheme.primary;
      case 'Completed':
      case 'Closed':
        return XMTheme.success;
      default:
        return XMTheme.statusDraft;
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
