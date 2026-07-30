import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'incidents_register_screen.dart';
import 'capa_screen.dart';
import 'permit_to_work_screen.dart';
import 'hazard_register_screen.dart';
import 'bbs_observations_screen.dart';
import 'ppe_compliance_screen.dart';
import 'safety_analytics_screen.dart';
import 'incident_report_form.dart';
import 'qr_scanner_screen.dart';
import '../widgets/safety_metrics_header.dart';
import '../widgets/module_card.dart';

/// Safety & Risk Hub Dashboard — Material 3 Expressive
class SafetyHubScreen extends ConsumerWidget {
  const SafetyHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        GHeader(
          title: 'Safety & Risk Hub',
          subtitle:
              'Unified command center for organizational safety, risk assessments, and compliance.',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  UIUtils.showSideSheet(
                    context: context,
                    title: 'Scan Passport',
                    builder: (ctx) => const QrScannerScreen(),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Passport'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  UIUtils.showSideSheet(
                    context: context,
                    title: 'Report Incident',
                    builder: (ctx) => const IncidentReportForm(),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: XMTheme.error,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_alert_rounded, size: 18),
                label: const Text('Report Incident'),
              ),
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              // High-level Metrics Row
              const SafetyMetricsHeader(),

              // Main Interactive Modules Grid
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.2,
                  ),
                  delegate: SliverChildListDelegate([
                    ModuleCard(
                      title: 'Incidents Register',
                      subtitle: 'Real-time incident tracking and reporting.',
                      icon: Icons.assignment_late_rounded,
                      color: XMTheme.error,
                      onTap:
                          () => _openModule(
                            context,
                            'Incidents Register',
                            const IncidentsRegisterScreen(),
                          ),
                    ),
                    ModuleCard(
                      title: 'Permit to Work',
                      subtitle: 'Manage and approve hazardous work permits.',
                      icon: Icons.vpn_key_rounded,
                      color: XMTheme.primary,
                      onTap:
                          () => _openModule(
                            context,
                            'Permit to Work',
                            const PermitToWorkScreen(),
                          ),
                    ),
                    ModuleCard(
                      title: 'Hazard Register',
                      subtitle: 'Report and track workplace hazards.',
                      icon: Icons.warning_amber_rounded,
                      color: XMTheme.warning,
                      onTap:
                          () => _openModule(
                            context,
                            'Hazard Register',
                            const HazardRegisterScreen(),
                          ),
                    ),
                    ModuleCard(
                      title: 'CAPA Management',
                      subtitle: 'Corrective and Preventive Actions.',
                      icon: Icons.fact_check_rounded,
                      color: XMTheme.success,
                      onTap:
                          () => _openModule(
                            context,
                            'CAPA Management',
                            const CAPAScreen(),
                          ),
                    ),
                    ModuleCard(
                      title: 'BBS Observations',
                      subtitle: 'Behavioral-based safety program.',
                      icon: Icons.visibility_rounded,
                      color: XMTheme.info,
                      onTap:
                          () => _openModule(
                            context,
                            'BBS Observations',
                            const BBSObservationsScreen(),
                          ),
                    ),
                    ModuleCard(
                      title: 'PPE Compliance',
                      subtitle: 'Track equipment issuance and compliance.',
                      icon: Icons.health_and_safety_rounded,
                      color: XMTheme.primary,
                      onTap:
                          () => _openModule(
                            context,
                            'PPE Compliance',
                            const PPEComplianceScreen(),
                          ),
                    ),
                    ModuleCard(
                      title: 'Safety Analytics',
                      subtitle: 'Performance indicators and safety trends.',
                      icon: Icons.analytics_rounded,
                      color: XMTheme.warning,
                      onTap:
                          () => _openModule(
                            context,
                            'Safety Analytics',
                            const SafetyAnalyticsScreen(),
                          ),
                    ),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(child: GSpacing.vXl),
            ],
          ),
        ),
      ],
    );
  }

  // Opens a module inside a massive side-sheet rather than routing away
  void _openModule(BuildContext context, String title, Widget child) {
    UIUtils.showSideSheet(
      context: context,
      title: title,
      builder: (ctx) => child,
    );
  }
}
