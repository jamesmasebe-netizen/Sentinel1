import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../providers/project_providers.dart';
import '../models/project_models.dart';

class ProjectDashboardScreen extends ConsumerStatefulWidget {
  const ProjectDashboardScreen({super.key});

  @override
  ConsumerState<ProjectDashboardScreen> createState() => _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends ConsumerState<ProjectDashboardScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          UIUtils.showToast(context, 'Create New Project Flow coming soon');
        },
        backgroundColor: XMTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: GHeader(
              title: 'Project Portfolio',
              subtitle: 'PRINCE2 compliant project management and SHEQ tracking.',
            ),
          ),

          projectsAsync.when(
            data: (projects) {
              final activeProjects = projects.where((p) => p.status != 'Completed').toList();
              final avgSafetyScore = projects.isEmpty ? 0.0 : projects.fold(0.0, (s, p) => s + p.safetyFileScore) / projects.length;
              final highRiskCount = projects.where((p) => ref.watch(projectRiskLevelProvider(p)) == 'Critical' || ref.watch(projectRiskLevelProvider(p)) == 'High').length;

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildKPIs(context, activeProjects.length, avgSafetyScore, highRiskCount),
                      GSpacing.vLg,
                      _buildRiskHeatmap(context, projects),
                      GSpacing.vLg,
                      _buildFilterRow(),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),

          projectsAsync.when(
             data: (projects) {
               var filtered = projects;
               if (_searchQuery.isNotEmpty) {
                 filtered = filtered.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
               }
               if (_statusFilter != 'All') {
                 filtered = filtered.where((p) => p.status == _statusFilter).toList();
               }

               if (filtered.isEmpty) {
                 return const SliverToBoxAdapter(
                   child: Padding(
                     padding: EdgeInsets.all(48.0),
                     child: Center(child: Text('No projects found matching criteria.')),
                   )
                 );
               }

               return SliverPadding(
                 padding: const EdgeInsets.symmetric(horizontal: 24),
                 sliver: SliverList(
                   delegate: SliverChildBuilderDelegate(
                     (context, index) {
                       final project = filtered[index];
                       final riskLevel = ref.watch(projectRiskLevelProvider(project));

                       return GCard(
                         margin: const EdgeInsets.only(bottom: 12),
                         onTap: () {
                           context.push('/projects/${project.id}');
                         },
                         padding: const EdgeInsets.all(16),
                         child: Row(
                           children: [
                             Container(
                               width: 48,
                               height: 48,
                               decoration: BoxDecoration(
                                 color: XMTheme.primary.withValues(alpha: 0.1),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: const Icon(Icons.account_tree_rounded, color: XMTheme.primary),
                             ),
                             GSpacing.hMd,
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Row(
                                     children: [
                                       Expanded(
                                         child: Text(
                                           project.name,
                                           style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                             fontWeight: FontWeight.bold,
                                           ),
                                           maxLines: 1,
                                           overflow: TextOverflow.ellipsis,
                                         ),
                                       ),
                                       GStatusTag(
                                         label: riskLevel,
                                         color: _getRiskColor(riskLevel),
                                       ),
                                     ],
                                   ),
                                   GSpacing.vXs,
                                   Text(
                                     'ID: ${project.id} • ${project.category}',
                                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                       color: Theme.of(context).colorScheme.onSurfaceVariant,
                                     ),
                                   ),
                                   GSpacing.vSm,
                                   Row(
                                     children: [
                                       const Icon(Icons.shield_rounded, size: 14, color: XMTheme.success),
                                       GSpacing.hXs,
                                       Text(
                                         'Safety: ${project.safetyFileScore}%',
                                         style: Theme.of(context).textTheme.bodySmall,
                                       ),
                                       GSpacing.hMd,
                                       const Icon(Icons.assignment_late_rounded, size: 14, color: XMTheme.warning),
                                       GSpacing.hXs,
                                       Text(
                                         'NCRs: ${project.totalNcrs}',
                                         style: Theme.of(context).textTheme.bodySmall,
                                       ),
                                       const Spacer(),
                                       Text(
                                         '${(project.overallProgress * 100).toStringAsFixed(0)}% Complete',
                                         style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                           fontWeight: FontWeight.bold,
                                           color: XMTheme.primary,
                                         ),
                                       ),
                                     ],
                                   ),
                                   GSpacing.vXs,
                                   LinearProgressIndicator(
                                     value: project.overallProgress,
                                     backgroundColor: XMTheme.primary.withValues(alpha: 0.1),
                                     valueColor: const AlwaysStoppedAnimation<Color>(XMTheme.primary),
                                     borderRadius: BorderRadius.circular(4),
                                   ),
                                 ],
                               ),
                             ),
                           ],
                         ),
                       );
                     },
                     childCount: filtered.length,
                   ),
                 ),
               );
             },
             loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
             error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          const SliverToBoxAdapter(child: GSpacing.vXl),
        ],
      ),
    );
  }

  Widget _buildKPIs(BuildContext context, int active, double avgScore, int highRisk) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _kpiCard('Active Projects', active.toString(), Icons.analytics_rounded, XMTheme.primary, isWide),
            if (isWide) GSpacing.hMd else GSpacing.vMd,
            _kpiCard('Avg Safety Score', '${avgScore.toStringAsFixed(1)}%', Icons.shield_rounded, XMTheme.success, isWide),
            if (isWide) GSpacing.hMd else GSpacing.vMd,
            _kpiCard('High Risk Projects', highRisk.toString(), Icons.warning_rounded, XMTheme.error, isWide),
          ],
        );
      }
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, bool expand) {
    final card = GCard(
      padding: const EdgeInsets.all(16),
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
          GSpacing.hMd,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
    if (expand) return Expanded(child: card);
    return card;
  }

  Widget _buildRiskHeatmap(BuildContext context, List<Project> projects) {
    return GCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Risk vs Budget Heatmap',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          GSpacing.vSm,
          Text(
            'Granular view of highest-risk and highest-spend projects requiring management attention.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          GSpacing.vLg,
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Theme.of(context).colorScheme.outline),
                bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            child: Stack(
              children: [
                const Positioned(bottom: -20, left: 0, child: Text('Low Budget', style: TextStyle(fontSize: 10))),
                const Positioned(bottom: -20, right: 0, child: Text('High Budget', style: TextStyle(fontSize: 10))),
                const Positioned(bottom: 0, left: -25, child: RotatedBox(quarterTurns: -1, child: Text('Low Risk', style: TextStyle(fontSize: 10)))),
                const Positioned(top: 0, left: -25, child: RotatedBox(quarterTurns: -1, child: Text('High Risk', style: TextStyle(fontSize: 10)))),

                // Example plotting logic based on actual data
                ...projects.map((p) {
                   final riskLevel = ref.watch(projectRiskLevelProvider(p));
                   double yPos = 180; // default Low
                   if (riskLevel == 'Medium') yPos = 120;
                   if (riskLevel == 'High') yPos = 60;
                   if (riskLevel == 'Critical') yPos = 10;

                   // Simple budget normalization for demo
                   double maxBudget = 1000000;
                   double xPos = ((p.budget / maxBudget).clamp(0.0, 1.0)) * (MediaQuery.sizeOf(context).width - 100);

                   return Positioned(
                     left: xPos,
                     top: yPos,
                     child: Tooltip(
                       message: '${p.name}\nBudget: \$${p.budget}\nRisk: $riskLevel',
                       child: Container(
                         width: riskLevel == 'Critical' ? 16 : 12,
                         height: riskLevel == 'Critical' ? 16 : 12,
                         decoration: BoxDecoration(
                           color: _getRiskColor(riskLevel).withValues(alpha: 0.8),
                           shape: BoxShape.circle,
                           border: Border.all(color: Colors.white, width: 2),
                         ),
                       ),
                     ),
                   );
                })
              ],
            ),
          )
        ],
      )
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            decoration: const InputDecoration(
              hintText: 'Search projects...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        GSpacing.hMd,
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Status',
            ),
            items: ['All', 'Draft', 'Active', 'On Hold', 'Completed']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _statusFilter = v!),
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Critical': return XMTheme.error;
      case 'High': return Colors.orange;
      case 'Medium': return XMTheme.warning;
      case 'Low': return XMTheme.success;
      default: return XMTheme.info;
    }
  }
}
