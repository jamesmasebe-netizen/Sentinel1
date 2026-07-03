import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';

class SkillMatrixCard extends StatelessWidget {
  final String employeeName;
  final List<Map<String, dynamic>> skills;

  const SkillMatrixCard({
    super.key,
    required this.employeeName,
    required this.skills,
  });

  Color _profColor(String p) {
    switch (p) {
      case 'Expert':
        return XMTheme.success;
      case 'Advanced':
        return XMTheme.info;
      case 'Intermediate':
        return XMTheme.warning;
      default:
        return XMTheme.error;
    }
  }

  IconData _profIcon(String p) {
    switch (p) {
      case 'Expert':
        return Icons.verified;
      case 'Advanced':
        return Icons.trending_up;
      case 'Intermediate':
        return Icons.horizontal_rule;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${skills.length} skills tracked',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          GSpacing.vMd,
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                skills.map((skill) {
                  final prof = skill['proficiency'] ?? 'Intermediate';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _profColor(prof).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(XMTheme.radiusSm),
                      border: Border.all(
                        color: _profColor(prof).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _profIcon(prof),
                          size: 12,
                          color: _profColor(prof),
                        ),
                        GSpacing.hSm,
                        Text(
                          skill['skill'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _profColor(prof),
                          ),
                        ),
                        GSpacing.hSm,
                        Text(
                          '($prof)',
                          style: TextStyle(
                            fontSize: 9,
                            color: _profColor(prof).withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
