import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import 'action_tracker_screen.dart';
import '../../property/screens/property_hub_screen.dart';
import '../../environment/screens/environmental_screen.dart';
import '../../contractors/screens/contractor_management_screen.dart';

/// Operations & Assets Hub Dashboard — Material 3 Expressive
class OperationsHubScreen extends StatelessWidget {
  const OperationsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          UIUtils.showToast(context, 'Quick Add: Action Item coming soon');
        },
        backgroundColor: XMTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.assignment_add),
        label: const Text('Add Action'),
      ),
      body: CustomScrollView(
        slivers: [
          // Dashboard Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operations & Assets Hub',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track organizational assets, environmental compliance, actions, and contractors.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // High-level Metrics Row
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricCard(context, 'Open Actions', '45', Icons.pending_actions_rounded, XMTheme.warning, isWide),
                      if (isWide) const SizedBox(width: 16),
                      if (!isWide) const SizedBox(height: 16),
                      _buildMetricCard(context, 'Properties', '12', Icons.domain_rounded, XMTheme.primary, isWide),
                      if (isWide) const SizedBox(width: 16),
                      if (!isWide) const SizedBox(height: 16),
                      _buildMetricCard(context, 'Active Contractors', '8', Icons.engineering_rounded, XMTheme.success, isWide),
                      if (isWide) const SizedBox(width: 16),
                      if (!isWide) const SizedBox(height: 16),
                      _buildMetricCard(context, 'Env Alerts', '2', Icons.eco_rounded, XMTheme.error, isWide),
                    ],
                  );
                },
              ),
            ),
          ),

          // Main Interactive Modules Grid
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisExtent: 140, // Fixed height for cards
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildListDelegate([
                _buildModuleCard(
                  context,
                  title: 'Action Tracker',
                  subtitle: 'Manage CAPA, tasks, and operational items.',
                  icon: Icons.checklist_rounded,
                  color: XMTheme.primary,
                  onTap: () => _openModule(context, 'Action Tracker', const ActionTrackerScreen()),
                ),
                _buildModuleCard(
                  context,
                  title: 'Property Portfolio',
                  subtitle: 'Manage facilities and real-estate assets.',
                  icon: Icons.domain_rounded,
                  color: XMTheme.info,
                  onTap: () => _openModule(context, 'Property Portfolio', const PropertyHubScreen()),
                ),
                _buildModuleCard(
                  context,
                  title: 'Environmental',
                  subtitle: 'Compliance, waste, and emissions tracking.',
                  icon: Icons.eco_rounded,
                  color: XMTheme.success,
                  onTap: () => _openModule(context, 'Environmental', const EnvironmentalScreen()),
                ),
                _buildModuleCard(
                  context,
                  title: 'Contractors',
                  subtitle: 'Vendor compliance and permit management.',
                  icon: Icons.engineering_rounded,
                  color: XMTheme.warning,
                  onTap: () => _openModule(context, 'Contractors', const ContractorManagementScreen()),
                ),
              ]),
            ),
          ),
          
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // Opens a module inside a massive side-sheet rather than routing away
  void _openModule(BuildContext context, String title, Widget child) {
    final width = MediaQuery.sizeOf(context).width * 0.85; 
    
    UIUtils.showSideSheet(
      context: context,
      title: title,
      width: width.clamp(400.0, 1200.0), // Cap max width
      builder: (ctx) => child,
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color, bool isWide) {
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(XMTheme.radiusLg), // 24px squircle
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isWide) {
      return Expanded(child: card);
    }
    return card;
  }

  Widget _buildModuleCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'Open Module',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
