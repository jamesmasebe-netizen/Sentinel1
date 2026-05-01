import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'dynamic_risk_assessment_screen.dart';

/// Risk Intelligence Hub — tabs for risk management modules
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
          Expanded(
            child: TabBarView(
              children: [
                _RiskTab(title: 'Risk Command Center', icon: Icons.dashboard, color: XMTheme.riskExtreme),
                _RiskTab(title: 'Baseline Risk (HIRA)', icon: Icons.assessment, color: XMTheme.riskHigh),
                const DynamicRiskAssessmentScreen(),
                _RiskTab(title: 'Bow-Tie Analysis', icon: Icons.account_tree, color: XMTheme.primary),
                _RiskTab(title: 'Strategic Risk Register', icon: Icons.list_alt, color: XMTheme.secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _RiskTab({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Coming soon', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
