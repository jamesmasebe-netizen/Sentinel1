import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';

class HiraCard extends StatelessWidget {
  final Map<String, dynamic> d;
  final VoidCallback onTap;

  const HiraCard({super.key, required this.d, required this.onTap});

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
    final level = d['riskLevel'] ?? 'Low';
    final score = d['riskScore'] ?? 0;
    
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
                decoration: BoxDecoration(color: getLevelColor(level).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.assessment_rounded, color: getLevelColor(level), size: 22),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['title'] ?? 'Untitled Assessment', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    GSpacing.vXs,
                    Text('Hazard: ${d['hazard'] ?? ''}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              GStatusTag(label: level.toUpperCase(), color: getLevelColor(level), icon: Icons.speed_rounded),
            ],
          ),
          GSpacing.vMd,
          const Divider(height: 1, thickness: 0.5),
          GSpacing.vMd,
          Row(
            children: [
              HiraInfoBadge(label: 'Score: $score', icon: Icons.analytics_rounded, color: theme.colorScheme.primary),
              GSpacing.hSm,
              HiraInfoBadge(label: 'Likelihood: ${d['likelihood']}', icon: Icons.show_chart_rounded),
              GSpacing.hSm,
              HiraInfoBadge(label: 'Severity: ${d['severity']}', icon: Icons.layers_outlined),
            ],
          ),
          if (d['controlMeasure'] != null && d['controlMeasure'].toString().isNotEmpty) ...[
            GSpacing.vMd,
            HiraInfoBadge(label: 'Control: ${d['controlMeasure']}', icon: Icons.shield_outlined, color: XMTheme.success),
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
