import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../providers/project_providers.dart';
import '../widgets/dashboard_kpis.dart';
import '../widgets/dashboard_prince2_overview.dart';
import '../widgets/new_project_dialog.dart';
import '../widgets/project_list_item.dart';

class ProjectDashboardScreen extends ConsumerStatefulWidget {
  const ProjectDashboardScreen({super.key});

  @override
  ConsumerState<ProjectDashboardScreen> createState() =>
      _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState
    extends ConsumerState<ProjectDashboardScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const NewProjectDialog(),
            ),
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
              subtitle: 'Project management and SHEQ tracking.',
            ),
          ),

          projectsAsync.when(
            data: (projects) {
              final activeProjects =
                  projects.where((p) => p.status != 'Completed').toList();
              final avgSafetyScore =
                  projects.isEmpty
                      ? 0.0
                      : projects.fold(0.0, (s, p) => s + p.safetyFileScore) /
                          projects.length;
              final highRiskCount =
                  projects
                      .where(
                        (p) =>
                            ref.watch(projectRiskLevelProvider(p)) ==
                                'Critical' ||
                            ref.watch(projectRiskLevelProvider(p)) == 'High',
                      )
                      .length;
              final totalBudget = projects.fold(0.0, (s, p) => s + p.budget);
              final totalNcrs = projects.fold(0, (s, p) => s + p.totalNcrs);
              final onTrackCount =
                  projects
                      .where(
                        (p) => p.overallProgress >= 0.5 && p.status == 'Active',
                      )
                      .length;

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      DashboardKPIs(
                        active: activeProjects.length,
                        highRisk: highRiskCount,
                        budget: totalBudget,
                        avgSafety: avgSafetyScore,
                      ),
                      const SizedBox(height: 20),
                      DashboardPrince2Overview(
                        projects: projects,
                        avgSafety: avgSafetyScore,
                        totalNcrs: totalNcrs,
                        highRisk: highRiskCount,
                        onTrack: onTrackCount,
                      ),
                      const SizedBox(height: 20),
                      _buildFilterRow(),
                    ],
                  ),
                ),
              );
            },
            loading:
                () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (e, _) =>
                    SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),

          projectsAsync.when(
            data: (projects) {
              var filtered = projects;
              if (_searchQuery.isNotEmpty) {
                filtered =
                    filtered
                        .where(
                          (p) => p.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                        )
                        .toList();
              }
              if (_statusFilter != 'All') {
                filtered =
                    filtered.where((p) => p.status == _statusFilter).toList();
              }

              if (filtered.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(
                      child: Text('No projects found matching criteria.'),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final project = filtered[index];
                    final riskLevel = ref.watch(
                      projectRiskLevelProvider(project),
                    );

                    return ProjectListItem(
                      project: project,
                      riskLevel: riskLevel,
                    );
                  }, childCount: filtered.length),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error:
                (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
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
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Status',
            ),
            items:
                ['All', 'Draft', 'Active', 'On Hold', 'Completed']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
            onChanged: (v) => setState(() => _statusFilter = v!),
          ),
        ),
      ],
    );
  }
}
