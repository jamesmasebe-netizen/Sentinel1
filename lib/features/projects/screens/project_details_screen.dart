import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../models/project_models.dart';
import '../providers/project_providers.dart';
import '../widgets/custom_gantt_chart.dart';
import '../../safety/screens/incident_report_form.dart';
import '../../safety/screens/permit_to_work_screen.dart';
import '../../contractors/screens/contractor_management_screen.dart';
import '../../risk/screens/hira_screen.dart';
import '../widgets/project_tabs/overview_tab.dart';
import '../widgets/project_tabs/workflow_tab.dart';
import '../widgets/project_tabs/timeline_tab.dart';
import '../widgets/project_tabs/safety_tab.dart';
import '../widgets/project_tabs/resources_tab.dart';
import '../widgets/project_tabs/financials_tab.dart';
import '../widgets/project_tabs/expense_form_dialog.dart';

class ProjectDetailsScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailsScreen> createState() =>
      _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen> {
  // Use DefaultTabController dynamically based on role

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectProvider(widget.projectId));
    final currentUser = ref.watch(userProfileProvider).valueOrNull;

    return projectAsync.when(
      data: (project) {
        if (project == null) {
          return const Scaffold(
            body: Center(child: Text('Project not found.')),
          );
        }

        final isLeadOrAdmin =
            currentUser?.uid == project.projectLead ||
            currentUser?.role == 'admin' ||
            currentUser?.role == 'executive' ||
            (currentUser?.uid == null &&
                ref.watch(isMockLoggedInProvider)); // For testing

        final tabs = [
          const Tab(text: 'Overview'),
          const Tab(text: 'Project Workflow'),
          const Tab(text: 'Timeline & Tasks'),
          const Tab(text: 'Safety & Compliance'),
          const Tab(text: 'Resources'),
          if (isLeadOrAdmin) const Tab(text: 'Cost & Budget'),
        ];

        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerLowest,
            appBar: AppBar(
              title: const Text('Project Details'),
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerLowest,
              scrolledUnderElevation: 0,
              bottom: TabBar(isScrollable: true, tabs: tabs),
            ),
            floatingActionButton: _buildQuickAllocateFAB(context, project),
            body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                OverviewTab(project: project),
                WorkflowTab(project: project),
                TimelineTab(project: project),
                SafetyTab(project: project),
                ResourcesTab(project: project),
                if (isLeadOrAdmin) FinancialsTab(project: project),
              ],
            ),
          ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildQuickAllocateFAB(BuildContext context, Project project) {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickAllocateSheet(context, project),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Quick Allocate'),
      backgroundColor: XMTheme.primary,
      foregroundColor: Colors.white,
    );
  }

  void _showQuickAllocateSheet(BuildContext context, Project project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Allocate',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _quickActionChip(
                      ctx,
                      Icons.engineering_rounded,
                      'Allocate Contractor',
                      () {
                        UIUtils.showSideSheet(
                          context: context,
                          title: 'Contractor Management',
                          builder: (ctx) => const ContractorManagementScreen(),
                        );
                      },
                    ),
                    _quickActionChip(
                      ctx,
                      Icons.attach_money_rounded,
                      'Add Expense / PO',
                      () {
                        showExpenseForm(context, project, ref);
                      },
                    ),
                    _quickActionChip(
                      ctx,
                      Icons.add_task_rounded,
                      'Add Project Task',
                      () {
                        UIUtils.showSideSheet(
                          context: context,
                          title: 'Project Timeline',
                          builder:
                              (ctx) => CustomGanttChart(
                                tasks: project.tasks,
                                projectId: project.id,
                              ),
                        );
                      },
                    ),
                    _quickActionChip(
                      ctx,
                      Icons.warning_amber_rounded,
                      'Log Incident',
                      () {
                        UIUtils.showSideSheet(
                          context: context,
                          title: 'Report Incident',
                          builder:
                              (ctx) => const IncidentReportForm(),
                        );
                      },
                    ),
                    _quickActionChip(
                      ctx,
                      Icons.gpp_maybe_rounded,
                      'Add Project Risk',
                      () {
                        UIUtils.showSideSheet(
                          context: context,
                          title: 'HIRA Risk Assessment',
                          builder: (ctx) => const HiraScreen(),
                        );
                      },
                    ),
                    _quickActionChip(
                      ctx,
                      Icons.task_alt_rounded,
                      'Add Permit (PTW)',
                      () {
                        UIUtils.showSideSheet(
                          context: context,
                          title: 'Permit to Work',
                          builder: (ctx) => const PermitToWorkScreen(),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _quickActionChip(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: XMTheme.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
