import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'incidents_register_screen.dart';
import 'capa_screen.dart';
import 'permit_to_work_screen.dart';
import 'bbs_observations_screen.dart';
import 'ppe_compliance_screen.dart';
import 'safety_analytics_screen.dart';
import 'hazard_register_screen.dart';
import 'incident_report_form.dart';

/// Safety Hub — Tab-based screen for all safety operations.
/// All tabs now wired to fully functional Firestore-backed screens.
class SafetyHubScreen extends StatelessWidget {
  const SafetyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Column(
        children: [
          // ─── Header ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Safety & Operations', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(width: 8),
                          Icon(Icons.shield, color: XMTheme.error, size: 22),
                        ],
                      ),
                      Text(
                        'Unified safety management, observations, and controls',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IncidentReportForm()),
                  ),
                  icon: const Icon(Icons.report_problem, size: 18),
                  label: const Text('Quick Report'),
                  style: FilledButton.styleFrom(backgroundColor: XMTheme.error),
                ),
              ],
            ),
          ),

          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.report_problem, size: 16), text: 'Incidents'),
              Tab(icon: Icon(Icons.check_box, size: 16), text: 'CAPA'),
              Tab(icon: Icon(Icons.assignment, size: 16), text: 'Permits'),
              Tab(icon: Icon(Icons.visibility, size: 16), text: 'BBS'),
              Tab(icon: Icon(Icons.warning, size: 16), text: 'Hazards'),
              Tab(icon: Icon(Icons.health_and_safety, size: 16), text: 'PPE'),
              Tab(icon: Icon(Icons.analytics, size: 16), text: 'Analytics'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const IncidentsRegisterScreen(),
                const CAPAScreen(),
                const PermitToWorkScreen(),
                const BBSObservationsScreen(),
                const HazardRegisterScreen(),
                const PPEComplianceScreen(),
                const SafetyAnalyticsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
