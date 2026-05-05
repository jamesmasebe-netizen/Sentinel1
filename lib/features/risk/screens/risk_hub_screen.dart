import 'package:flutter/material.dart';
import 'risk_command_center_screen.dart';
import 'hira_screen.dart';
import 'dynamic_risk_assessment_screen.dart';
import 'bowtie_screen.dart';
import 'strategic_risk_register_screen.dart';

/// Risk Intelligence Hub — tabs for all risk management modules
class RiskHubScreen extends StatelessWidget {
  const RiskHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.dashboard, size: 16), text: 'Command Center'),
              Tab(icon: Icon(Icons.assessment, size: 16), text: 'HIRA'),
              Tab(icon: Icon(Icons.bolt, size: 16), text: 'Dynamic RA'),
              Tab(icon: Icon(Icons.account_tree, size: 16), text: 'Bow-Tie'),
              Tab(icon: Icon(Icons.list_alt, size: 16), text: 'Strategic Register'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                RiskCommandCenterScreen(),
                HiraScreen(),
                DynamicRiskAssessmentScreen(),
                BowtieScreen(),
                StrategicRiskRegisterScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
