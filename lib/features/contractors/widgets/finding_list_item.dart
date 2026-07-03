import 'package:flutter/material.dart';
import '../models/safety_file_models.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';

class FindingListItem extends StatelessWidget {
  final Finding finding;
  final VoidCallback onUpdateTap;

  const FindingListItem({
    super.key,
    required this.finding,
    required this.onUpdateTap,
  });

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Doc: ${finding.documentId}', style: const TextStyle(fontWeight: FontWeight.bold)),
              GStatusTag(
                label: finding.status.name.toUpperCase(),
                color: finding.status == FindingStatus.verifiedClosed ? XMTheme.success :
                       finding.status == FindingStatus.cancelled ? Colors.grey : XMTheme.warning,
              ),
            ],
          ),
          GSpacing.vSm,
          Text('Type: ${finding.type.name}'),
          Text('Description: ${finding.description}'),
          GSpacing.vMd,
          if (finding.status != FindingStatus.verifiedClosed && finding.status != FindingStatus.cancelled)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Update Status'),
                onPressed: onUpdateTap,
              ),
            )
        ],
      ),
    );
  }
}
