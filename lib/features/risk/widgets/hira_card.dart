import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/safety_models.dart';
import '../../../core/widgets/ds_widgets.dart';

class HiraCard extends StatelessWidget {
  final RiskAssessment assessment;
  final VoidCallback onTap;

  const HiraCard({super.key, required this.assessment, required this.onTap});

  static Color getLevelColor(String level) {
    switch (level) {
      case 'Extreme':
        return XMTheme.riskExtreme;
      case 'High':
        return XMTheme.riskHigh;
      case 'Medium':
        return XMTheme.riskMedium;
      default:
        return XMTheme.riskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Fixed 2026-08-06 (same class of bug as FIX_LIST.md F-306): hira_form.dart only ever writes
    // inherentRiskScore/riskRating — riskScore/riskLevel are never written, so these used to read
    // as permanently absent (score always 0, level always 'Low' regardless of the real
    // assessment). risk_matrix_widget.dart's use of riskRating already proved these are the
    // correct, canonical field names.
    final level = assessment.riskRating ?? 'Low';
    final score = assessment.inherentRiskScore ?? 0;

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: getLevelColor(level).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.assessment_rounded,
                  color: getLevelColor(level),
                  size: 22,
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assessment.title.isEmpty
                          ? 'Untitled Assessment'
                          : assessment.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GSpacing.vXs,
                    Text(
                      'Hazard: ${assessment.hazard}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              GStatusTag(
                label: level.toUpperCase(),
                color: getLevelColor(level),
                icon: Icons.speed_rounded,
              ),
            ],
          ),
          GSpacing.vMd,
          const Divider(height: 1, thickness: 0.5),
          GSpacing.vMd,
          Row(
            children: [
              HiraInfoBadge(
                label: 'Score: $score',
                icon: Icons.analytics_rounded,
                color: theme.colorScheme.primary,
              ),
              GSpacing.hSm,
              HiraInfoBadge(
                label: 'Likelihood: ${assessment.likelihood}',
                icon: Icons.show_chart_rounded,
              ),
              GSpacing.hSm,
              HiraInfoBadge(
                label: 'Severity: ${assessment.severity}',
                icon: Icons.layers_outlined,
              ),
            ],
          ),
          if (assessment.controlMeasure != null &&
              assessment.controlMeasure!.isNotEmpty) ...[
            GSpacing.vMd,
            HiraInfoBadge(
              label: 'Control: ${assessment.controlMeasure}',
              icon: Icons.shield_outlined,
              color: XMTheme.success,
            ),
          ],
        ],
      ),
    );
  }
}

class HiraInfoBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const HiraInfoBadge({
    super.key,
    required this.label,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: displayColor),
          GSpacing.hSm,
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: displayColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
