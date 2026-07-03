import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../screens/action_tracker_screen.dart';
import '../../property/screens/property_hub_screen.dart';
import '../../environment/screens/environmental_screen.dart';
import '../../contractors/screens/contractor_management_screen.dart';
import '../../projects/screens/project_dashboard_screen.dart';
import '../screens/integrations_hub_screen.dart';
import 'hub_cards.dart';

class OperationsHubModules extends StatelessWidget {
  const OperationsHubModules({super.key});

  void _openModule(BuildContext context, String title, Widget child) {
    final width = MediaQuery.sizeOf(context).width * 0.85;
    UIUtils.showSideSheet(
      context: context,
      title: title,
      width: width.clamp(400.0, 1200.0),
      builder: (ctx) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          mainAxisExtent: 140,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildListDelegate([
          ModuleCard(
            title: 'Projects',
            subtitle: 'Project management, SHEQ metrics, and Gantt charts.',
            icon: Icons.account_tree_rounded,
            color: XMTheme.primary,
            onTap: () => _openModule(context, 'Project Management', const ProjectDashboardScreen()),
          ),
          ModuleCard(
            title: 'Action Tracker',
            subtitle: 'Manage CAPA, tasks, and operational items.',
            icon: Icons.checklist_rounded,
            color: XMTheme.info,
            onTap: () => _openModule(context, 'Action Tracker', const ActionTrackerScreen()),
          ),
          ModuleCard(
            title: 'Property Portfolio',
            subtitle: 'Manage facilities and real-estate assets.',
            icon: Icons.domain_rounded,
            color: XMTheme.secondary,
            onTap: () => _openModule(context, 'Property Portfolio', const PropertyHubScreen()),
          ),
          ModuleCard(
            title: 'Environmental',
            subtitle: 'Compliance, waste, and emissions tracking.',
            icon: Icons.eco_rounded,
            color: XMTheme.success,
            onTap: () => _openModule(context, 'Environmental', const EnvironmentalScreen()),
          ),
          ModuleCard(
            title: 'Contractors',
            subtitle: 'Vendor compliance and permit management.',
            icon: Icons.engineering_rounded,
            color: XMTheme.warning,
            onTap: () => _openModule(context, 'Contractors', const ContractorManagementScreen()),
          ),
          ModuleCard(
            title: 'Gateways & Integrations',
            subtitle: 'Manage external API connections and webhooks.',
            icon: Icons.hub_rounded,
            color: Colors.deepPurple,
            onTap: () => _openModule(context, 'Integrations', const IntegrationsHubScreen()),
          ),
        ]),
      ),
    );
  }
}
