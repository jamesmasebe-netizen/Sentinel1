import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';
import '../../../../../core/widgets/ds_widgets.dart';

class RiskAssessmentCard extends StatelessWidget {
  final Map<String, dynamic> risk;

  const RiskAssessmentCard({super.key, required this.risk});

  @override
  Widget build(BuildContext context) {
    final rating = risk['rating'] as String;
    Color badgeColor = Colors.grey;
    if (rating == 'High' || rating == 'Critical' || rating == 'Extreme') {
      badgeColor = XMTheme.error;
    }
    if (rating == 'Medium') badgeColor = XMTheme.warning;
    if (rating == 'Low' || rating == 'Safe') badgeColor = XMTheme.success;

    return GCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: XMTheme.primary),
          GSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  risk['title'] ?? 'Unnamed Assessment',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: XMTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        risk['type'] ?? 'HIRA',
                        style: const TextStyle(
                          fontSize: 9,
                          color: XMTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rating,
                        style: TextStyle(
                          fontSize: 9,
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
