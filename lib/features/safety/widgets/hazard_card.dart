import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';

class HazardCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const HazardCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled';
    final desc = data['description'] ?? '';
    final location = data['location'] ?? 'Unknown location';
    final severity = data['severity'] ?? 'Medium';
    final reportedBy = data['reportedByName'] ?? 'Unknown';

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _sevColor(severity).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_amber_rounded, color: _sevColor(severity), size: 20),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(location, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              GStatusTag(label: severity, color: _sevColor(severity)),
            ],
          ),
          GSpacing.vMd,
          Text(
            desc,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          GSpacing.vMd,
          Row(
            children: [
              _MiniInfo(icon: Icons.person_outline, label: reportedBy),
              GSpacing.hMd,
              _MiniInfo(icon: Icons.calendar_today_rounded, label: UIUtils.formatTimestamp(data['createdAt'])),
            ],
          ),
        ],
      ),
    );
  }

  Color _sevColor(String severity) {
    switch (severity) {
      case 'Critical':
        return XMTheme.severityCritical;
      case 'High':
        return XMTheme.severityMajor;
      case 'Medium':
        return XMTheme.severityModerate;
      case 'Low':
        return XMTheme.severityMinor;
      default:
        return XMTheme.severityNegligible;
    }
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurfaceVariant;
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
