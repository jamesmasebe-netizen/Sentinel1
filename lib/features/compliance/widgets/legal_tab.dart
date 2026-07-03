import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';

class LegalTab extends StatelessWidget {
  const LegalTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reqs = [
      ('Occupational Health and Safety Act 85 of 1993', 'Primary OHS legislation', Icons.gavel_rounded, XMTheme.riskExtreme),
      ('COIDA — Compensation for Injuries', 'Workplace injury framework', Icons.health_and_safety_rounded, XMTheme.riskHigh),
      ('General Safety Regulations (GSR)', 'Workplace safety standards', Icons.rule_folder_rounded, XMTheme.riskMedium),
      ('Hazardous Chemical Substances Regulations', 'Chemical safety management', Icons.science_rounded, XMTheme.error),
      ('Construction Regulations 2014', 'Construction management', Icons.construction_rounded, XMTheme.warning),
      ('National Environmental Management Act (NEMA)', 'Environmental compliance', Icons.eco_rounded, XMTheme.success),
      ('ISO 45001:2018', 'Occupational Health & Safety', Icons.verified_rounded, theme.colorScheme.primary),
      ('ISO 14001:2015', 'Environmental Management', Icons.nature_people_rounded, XMTheme.success),
      ('ISO 9001:2015', 'Quality Management', Icons.stars_rounded, theme.colorScheme.tertiary),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reqs.length,
      itemBuilder: (ctx, i) {
        final r = reqs[i];
        return GCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: r.$4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(r.$3, color: r.$4, size: 24),
              ),
              GSpacing.hLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.$1, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, height: 1.2)),
                    GSpacing.vSm,
                    Text(r.$2, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, color: theme.colorScheme.outlineVariant, size: 18),
            ],
          ),
        );
      },
    );
  }
}
