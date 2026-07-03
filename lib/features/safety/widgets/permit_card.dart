import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

class PermitCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool canApprove;
  final Function(String) onStatusUpdate;

  const PermitCard({
    super.key,
    required this.docId,
    required this.data,
    required this.canApprove,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? 'General';
    final status = data['status'] ?? 'Requested';
    final location = data['location'] ?? 'Site';
    final applicant = data['applicantName'] ?? 'Unknown';
    final loto = data['lotoRequired'] == true;

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _showPermitDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _typeColor(type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_typeIcon(type), color: _typeColor(type), size: 20),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      location,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              GStatusTag(label: status, color: _statusColor(status)),
            ],
          ),
          GSpacing.vMd,
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              PermitMiniInfo(icon: Icons.person_outline, label: applicant),
              if (data['validFrom'] != null)
                PermitMiniInfo(
                  icon: Icons.access_time,
                  label: _fmtDate(data['validFrom']),
                ),
              if (loto)
                PermitMiniInfo(
                  icon: Icons.lock_outline,
                  label: 'LOTO',
                  color: XMTheme.error,
                ),
            ],
          ),
          if (status == 'Requested' && canApprove) ...[
            GSpacing.vMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => onStatusUpdate('Rejected'),
                  style: TextButton.styleFrom(foregroundColor: XMTheme.error),
                  child: const Text('Reject'),
                ),
                GSpacing.hMd,
                FilledButton(
                  onPressed: () => onStatusUpdate('Approved'),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showPermitDetail(BuildContext context) {
    UIUtils.showSideSheet(
      context: context,
      title: 'Permit Details',
      builder: (ctx) {
        final type = data['type'] ?? 'General';
        final status = data['status'] ?? 'Requested';
        final location = data['location'] ?? 'Site';
        final applicant = data['applicantName'] ?? 'Unknown';
        final loto = data['lotoRequired'] == true;
        final notes = data['notes'] ?? 'No notes provided.';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notes/Description',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(notes, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 24),
              PermitDetailRow(
                icon: Icons.person_outline,
                label: 'Applicant',
                value: applicant,
              ),
              PermitDetailRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: location,
              ),
              PermitDetailRow(
                icon: Icons.category_outlined,
                label: 'Type',
                value: type,
              ),
              PermitDetailRow(
                icon: Icons.flag_outlined,
                label: 'Status',
                value: status,
              ),
              if (data['validFrom'] != null)
                PermitDetailRow(
                  icon: Icons.access_time,
                  label: 'Valid From',
                  value: _fmtDate(data['validFrom']),
                ),
              if (data['validTo'] != null)
                PermitDetailRow(
                  icon: Icons.access_time,
                  label: 'Valid To',
                  value: _fmtDate(data['validTo']),
                ),
              PermitDetailRow(
                icon: Icons.lock_outline,
                label: 'LOTO Required',
                value: loto ? 'Yes' : 'No',
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Hot Work':
        return Icons.local_fire_department;
      case 'Working at Height':
        return Icons.height;
      case 'Confined Space':
        return Icons.meeting_room;
      case 'Electrical':
        return Icons.bolt;
      case 'Excavation':
        return Icons.construction;
      default:
        return Icons.assignment;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Hot Work':
        return XMTheme.error;
      case 'Working at Height':
        return XMTheme.warning;
      case 'Confined Space':
        return XMTheme.info;
      case 'Electrical':
        return const Color(0xFFF59E0B);
      case 'Excavation':
        return const Color(0xFF8B5CF6);
      default:
        return XMTheme.primary;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Requested':
        return XMTheme.statusDraft;
      case 'Approved':
        return XMTheme.success;
      case 'Active':
        return XMTheme.info;
      case 'Rejected':
        return XMTheme.error;
      case 'Closed':
        return XMTheme.statusClosed;
      default:
        return XMTheme.statusDraft;
    }
  }
}

class PermitMiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const PermitMiniInfo({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: c)),
      ],
    );
  }
}

class PermitDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const PermitDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
