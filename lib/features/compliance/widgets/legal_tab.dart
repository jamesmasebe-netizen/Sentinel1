import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

class LegalTab extends StatelessWidget {
  const LegalTab({super.key});

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      UIUtils.showToast(context, 'Could not open link', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reqs = [
      (
        'Occupational Health and Safety Act 85 of 1993',
        'Primary OHS legislation',
        Icons.gavel_rounded,
        XMTheme.riskExtreme,
        'https://www.gov.za/documents/occupational-health-and-safety-act',
      ),
      (
        'COIDA — Compensation for Injuries',
        'Workplace injury framework',
        Icons.health_and_safety_rounded,
        XMTheme.riskHigh,
        'https://www.gov.za/documents/compensation-occupational-injuries-and-diseases-act',
      ),
      (
        'General Safety Regulations (GSR)',
        'Workplace safety standards',
        Icons.rule_folder_rounded,
        XMTheme.riskMedium,
        'https://www.labour.gov.za/DocumentCenter/Regulations/Occupational%20Health%20and%20Safety/General%20Safety%20Regulations.pdf',
      ),
      (
        'Hazardous Chemical Substances Regulations',
        'Chemical safety management',
        Icons.science_rounded,
        XMTheme.error,
        'https://www.labour.gov.za/DocumentCenter/Regulations/Occupational%20Health%20and%20Safety/Hazardous%20Chemical%20Substances%20Regulations.pdf',
      ),
      (
        'Construction Regulations 2014',
        'Construction management',
        Icons.construction_rounded,
        XMTheme.warning,
        'https://www.labour.gov.za/DocumentCenter/Regulations/Occupational%20Health%20and%20Safety/Construction%20Regulations%202014.pdf',
      ),
      (
        'National Environmental Management Act (NEMA)',
        'Environmental compliance',
        Icons.eco_rounded,
        XMTheme.success,
        'https://www.gov.za/documents/national-environmental-management-act',
      ),
      (
        'ISO 45001:2018',
        'Occupational Health & Safety',
        Icons.verified_rounded,
        theme.colorScheme.primary,
        'https://www.iso.org/standard/63787.html',
      ),
      (
        'ISO 14001:2015',
        'Environmental Management',
        Icons.nature_people_rounded,
        XMTheme.success,
        'https://www.iso.org/standard/60857.html',
      ),
      (
        'ISO 9001:2015',
        'Quality Management',
        Icons.stars_rounded,
        theme.colorScheme.tertiary,
        'https://www.iso.org/standard/62085.html',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reqs.length,
      itemBuilder: (ctx, i) {
        final r = reqs[i];
        return GCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          onTap: () => _openLink(context, r.$5),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: r.$4.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(r.$3, color: r.$4, size: 24),
              ),
              GSpacing.hLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.$1,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    GSpacing.vSm,
                    Text(
                      r.$2,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                color: theme.colorScheme.outlineVariant,
                size: 18,
              ),
            ],
          ),
        );
      },
    );
  }
}
