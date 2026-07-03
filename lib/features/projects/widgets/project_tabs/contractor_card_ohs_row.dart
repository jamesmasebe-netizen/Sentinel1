import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';

class ContractorCardOhsRow extends StatelessWidget {
  final String ohsStatus;
  final Color ohsColor;
  final Map<String, dynamic>? submission;
  final double ohsScore;
  final VoidCallback onViewFile;

  const ContractorCardOhsRow({
    super.key,
    required this.ohsStatus,
    required this.ohsColor,
    required this.submission,
    required this.ohsScore,
    required this.onViewFile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          ohsStatus == 'Approved'
              ? Icons.verified_rounded
              : Icons.pending_actions_rounded,
          size: 16,
          color: ohsColor,
        ),
        const SizedBox(width: 6),
        Text(
          'OHS File:',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: ohsColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            ohsStatus,
            style: TextStyle(
              fontSize: 11,
              color: ohsColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (submission != null) ...[
          const SizedBox(width: 10),
          Text(
            'Score: ${ohsScore.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const Spacer(),
        TextButton.icon(
          onPressed: onViewFile,
          icon: const Icon(Icons.folder_open_rounded, size: 14),
          label: const Text('View File', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
            foregroundColor: XMTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
        ),
      ],
    );
  }
}
