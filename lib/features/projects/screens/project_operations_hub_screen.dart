import 'package:flutter/material.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import '../widgets/custom_gantt_chart.dart';
import 'timesheet_entry_screen.dart';
import 'expense_entry_screen.dart';
import 'package:go_router/go_router.dart';

class ProjectOperationsHubScreen extends ConsumerStatefulWidget {
  const ProjectOperationsHubScreen({super.key});

  @override
  ConsumerState<ProjectOperationsHubScreen> createState() =>
      _ProjectOperationsHubScreenState();
}

class _ProjectOperationsHubScreenState
    extends ConsumerState<ProjectOperationsHubScreen> {
  String? _selectedProjectId;

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Operations Hub'),
        centerTitle: true,
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(child: Text('No active projects found.'));
          }

          // Automatically select first project if none selected
          _selectedProjectId ??= projects.first.id;

          final selectedProject = projects.firstWhere(
            (p) => p.id == _selectedProjectId,
            orElse: () => projects.first,
          );

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Selector
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedProjectId,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down),
                              items:
                                  projects.map((p) {
                                    return DropdownMenuItem(
                                      value: p.id,
                                      child: Text(
                                        '${p.id} - ${p.name}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedProjectId = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Operations',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 800 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildActionCard(
                        context: context,
                        title: 'Gantt Chart',
                        icon: Icons.bar_chart,
                        color: Colors.blueAccent,
                        onTap: () {
                          UIUtils.showSideSheet(
                            context: context,
                            title: 'Gantt Chart: ${selectedProject.name}',
                            builder: (ctx) => Scaffold(
                              appBar: AppBar(
                                title: Text(
                                  'Gantt Chart: ${selectedProject.name}',
                                ),
                              ),
                              body: CustomGanttChart(
                                tasks: selectedProject.tasks,
                                projectId: selectedProject.id,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        context: context,
                        title: 'Timesheet Entry',
                        icon: Icons.access_time,
                        color: Colors.orangeAccent,
                        onTap: () {
                          UIUtils.showSideSheet(
                            context: context,
                            title: 'Timesheet Entry',
                            builder: (ctx) => TimesheetEntryScreen(
                              projectId: selectedProject.id,
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        context: context,
                        title: 'Expense Entry',
                        icon: Icons.attach_money,
                        color: Colors.green,
                        onTap: () {
                          UIUtils.showSideSheet(
                            context: context,
                            title: 'Expense Entry',
                            builder: (ctx) => ExpenseEntryScreen(
                              projectId: selectedProject.id,
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        context: context,
                        title: 'Revenue Recognition',
                        icon: Icons.account_balance,
                        color: Colors.purple,
                        onTap: () {
                          context.push('/revenue-recognition');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: color),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
