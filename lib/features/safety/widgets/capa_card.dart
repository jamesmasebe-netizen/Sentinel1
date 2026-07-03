import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import 'capa_status_badge.dart';
import 'mini_chip.dart';
import 'capa_detail_row.dart';

class CAPACard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final Future<void> Function(String) onStatusUpdate;

  const CAPACard({
    super.key,
    required this.docId,
    required this.data,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Open';
    final assignee = data['assignedToName'] ?? 'Unassigned';
    final description = data['description'] ?? 'No description';
    final dueDateStr = data['dueDate'];
    final isOverdue = _isOverdue(dueDateStr, status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(
          color:
              isOverdue
                  ? XMTheme.error.withValues(alpha: 0.4)
                  : Colors.transparent,
          width: isOverdue ? 1.5 : 0,
        ),
      ),
      child: InkWell(
        onTap: () => _showCAPADetail(context),
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.check_box,
                    color: _statusColor(status),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CAPAStatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                MiniChip(icon: Icons.person, label: assignee),
                if (dueDateStr != null)
                  MiniChip(
                    icon: Icons.calendar_today,
                    label: _formatDate(dueDateStr),
                    color: isOverdue ? XMTheme.error : null,
                  ),
                if (isOverdue)
                  MiniChip(
                    icon: Icons.warning,
                    label: 'OVERDUE',
                    color: XMTheme.error,
                  ),
              ],
            ),
            if (data['rca'] != null && data['rca'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'RCA: ${data['rca']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Status actions
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'Open')
                  TextButton(
                    onPressed: () => onStatusUpdate('In Progress'),
                    child: const Text('Start', style: TextStyle(fontSize: 12)),
                  ),
                if (status == 'In Progress')
                  TextButton(
                    onPressed: () => onStatusUpdate('Completed'),
                    child: const Text(
                      'Complete',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                if (status == 'Completed')
                  TextButton(
                    onPressed: () => onStatusUpdate('Verified'),
                    child: const Text('Verify', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showCAPADetail(BuildContext context) {
    UIUtils.showSideSheet(
      context: context,
      title: 'CAPA Details',
      builder: (ctx) {
        final status = data['status'] ?? 'Open';
        final description = data['description'] ?? 'No description';
        final rootCause = data['rca'] ?? 'Not specified';
        final assignee = data['assignedToName'] ?? 'Unassigned';
        final actionRequired = data['actionRequired'] ?? 'Not specified';
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 24),
              CAPADetailRow(icon: Icons.analytics_outlined, label: 'Root Cause (RCA)', value: rootCause),
              CAPADetailRow(icon: Icons.person_outline, label: 'Assignee', value: assignee),
              CAPADetailRow(icon: Icons.checklist, label: 'Action Required', value: actionRequired),
              CAPADetailRow(icon: Icons.flag_outlined, label: 'Status', value: status),
              if (data['dueDate'] != null)
                CAPADetailRow(icon: Icons.calendar_today, label: 'Due Date', value: _formatDate(data['dueDate'])),
            ],
          ),
        );
      },
    );
  }

  bool _isOverdue(String? dueDateStr, String status) {
    if (dueDateStr == null || status == 'Completed' || status == 'Verified') {
      return false;
    }
    try {
      return DateTime.parse(dueDateStr).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return XMTheme.statusOpen;
      case 'In Progress':
        return XMTheme.statusInProgress;
      case 'Completed':
        return XMTheme.statusResolved;
      case 'Verified':
        return XMTheme.statusClosed;
      default:
        return XMTheme.statusDraft;
    }
  }
}
