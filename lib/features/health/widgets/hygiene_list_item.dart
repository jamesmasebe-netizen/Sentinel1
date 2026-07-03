import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/ds_widgets.dart';

class HygieneListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const HygieneListItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reading = double.tryParse(data['readingValue']?.toString() ?? '0') ?? 0;
    final limit = double.tryParse(data['legalLimit']?.toString() ?? '100') ?? 100;
    final isOver = reading > limit;
    final color = isOver ? XMTheme.error : XMTheme.info;

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['zoneName'] ?? 'Unknown Zone', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text(data['hazardType'] ?? 'Unknown Hazard', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              GStatusTag(
                label: isOver ? 'THRESHOLD EXCEEDED' : 'WITHIN LIMITS',
                color: isOver ? XMTheme.error : XMTheme.success,
              ),
            ],
          ),
          GSpacing.vMd,
          Row(
            children: [
              SurveyMetric(label: 'READING', value: '${data['readingValue'] ?? "0"}', color: color),
              GSpacing.hLg,
              SurveyMetric(label: 'LEGAL LIMIT', value: '${data['legalLimit'] ?? "0"}', color: theme.colorScheme.outline),
              const Spacer(),
              if (data['requiresMedicalSurveillance'] == true)
                const TinyBadge(label: 'SURVEILLANCE REQ', color: XMTheme.warning, icon: Icons.medical_services_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class SurveyMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const SurveyMetric({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 8, letterSpacing: 1, color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class TinyBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const TinyBadge({super.key, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          GSpacing.hXs,
          Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
