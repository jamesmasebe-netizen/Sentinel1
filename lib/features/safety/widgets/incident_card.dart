import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import 'incident_status_colors.dart';
import 'mini_info.dart';
import 'incident_detail_sheet.dart';

class IncidentCard extends ConsumerWidget {
  final String docId;
  final Map<String, dynamic> data;
  final void Function(String) onStatusUpdate;

  const IncidentCard({
    super.key,
    required this.docId,
    required this.data,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final severity = data['severity'] ?? 'Minor';
    final status = data['status'] ?? 'Open';
    final type = data['type'] ?? 'Unknown';
    final title = data['title'] ?? 'Untitled';
    final reporter = data['reporterName'] ?? 'Unknown';
    final dateStr = data['dateOfIncident'] ?? data['createdAt'] ?? '';
    final isAnonymous = data['isAnonymous'] == true;

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => showIncidentDetail(context, ref, docId, data),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: getSevColor(severity).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.report_problem,
                  color: getSevColor(severity),
                  size: 18,
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${type.toString().replaceAll('_', ' ')} • ${isAnonymous ? "Anonymous" : reporter}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              GStatusTag(label: status, color: getStatusColor(status)),
            ],
          ),
          GSpacing.vMd,
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              MiniInfo(
                icon: Icons.warning_amber_rounded,
                label: severity,
                color: getSevColor(severity),
              ),
              if (data['location'] != null &&
                  data['location'].toString().isNotEmpty)
                MiniInfo(
                  icon: Icons.location_on_outlined,
                  label: data['location'],
                ),
              if (dateStr.isNotEmpty)
                MiniInfo(
                  icon: Icons.access_time_rounded,
                  label: UIUtils.formatTimestamp(dateStr),
                ),
              if (data['totalCost'] != null && (data['totalCost'] as num) > 0)
                MiniInfo(
                  icon: Icons.attach_money_rounded,
                  label: 'R${data['totalCost']}',
                  color: XMTheme.warning,
                ),
            ],
          ),
          if (status != 'Closed') ...[
            GSpacing.vSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'Open')
                  TextButton.icon(
                    onPressed: () => onStatusUpdate('Investigating'),
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text(
                      'Investigate',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                if (status == 'Investigating')
                  TextButton.icon(
                    onPressed: () => onStatusUpdate('Resolved'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text(
                      'Resolve',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                if (status == 'Resolved')
                  TextButton.icon(
                    onPressed: () => onStatusUpdate('Closed'),
                    icon: const Icon(Icons.lock, size: 16),
                    label: const Text('Close', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
