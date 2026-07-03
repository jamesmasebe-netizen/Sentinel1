import os

file_path = '/Users/jamesmasebe/Desktop/Sentinel1/lib/features/projects/screens/project_details_screen.dart'
with open(file_path, 'r') as f:
    lines = f.readlines()

tabs_dir = '/Users/jamesmasebe/Desktop/Sentinel1/lib/features/projects/widgets/project_tabs'
os.makedirs(tabs_dir, exist_ok=True)

def get_lines(start, end):
    return "".join(lines[start-1:end])

common_imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
"""

# 1. Timeline Tab
timeline_imports = common_imports + "import '../custom_gantt_chart.dart';\n\n"
timeline_class = """class TimelineTab extends ConsumerWidget {
  final Project project;
  const TimelineTab({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
""" + get_lines(757, 761) + "\n}\n"

with open(os.path.join(tabs_dir, 'timeline_tab.dart'), 'w') as f:
    f.write(timeline_imports + timeline_class)

# 2. Financials Tab
financials_imports = common_imports + "\n"
financials_class = """class FinancialsTab extends ConsumerWidget {
  final Project project;
  const FinancialsTab({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
""" + get_lines(173, 318).replace("Widget _buildFinancialsTab(Project project) {", "").replace("    final cpi = project.costPerformanceIndex;", "    final cpi = project.costPerformanceIndex;") + "\n" + get_lines(320, 339) + "\n}\n"

# Add showExpenseForm outside the class
financials_class += "\n" + get_lines(1401, 1498).replace("void _showExpenseForm(BuildContext context, Project project)", "void showExpenseForm(BuildContext context, Project project, WidgetRef ref)")

# Replace _showExpenseForm with showExpenseForm inside FinancialsTab
financials_class = financials_class.replace("_showExpenseForm(context, project);", "showExpenseForm(context, project, ref);")
financials_class = financials_class.replace("ref.read", "ref.read")

with open(os.path.join(tabs_dir, 'financials_tab.dart'), 'w') as f:
    f.write(financials_imports + financials_class)


# 3. Overview Tab
overview_imports = common_imports + """import '../../../safety/screens/incidents_register_screen.dart';
import '../../../safety/screens/incident_report_form.dart';
import '../../../safety/screens/capa_screen.dart';
import '../../../safety/screens/permit_to_work_screen.dart';
import '../../../people/widgets/employee_selector.dart';
import '../../../people/providers/employee_providers.dart';
\n"""

overview_class = """class OverviewTab extends ConsumerWidget {
  final Project project;
  const OverviewTab({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
""" + get_lines(342, 553) + "\n" + get_lines(555, 597) + "\n" + get_lines(599, 613) + "\n" + get_lines(1572, 1681).replace("void _showEditProjectDetailsDialog(BuildContext context, Project project)", "void showEditProjectDetailsDialog(BuildContext context, Project project, WidgetRef ref)") + "\n" + get_lines(1683, 1744).replace("void _showEditDescriptionDialog(BuildContext context, Project project)", "void showEditDescriptionDialog(BuildContext context, Project project, WidgetRef ref)") + "\n" + get_lines(1746, 1874).replace("void _showEditContactsDialog(BuildContext context, Project project)", "void showEditContactsDialog(BuildContext context, Project project, WidgetRef ref)") + "\n}\n"

overview_class = overview_class.replace("_showEditProjectDetailsDialog(context, project)", "showEditProjectDetailsDialog(context, project, ref)")
overview_class = overview_class.replace("_showEditDescriptionDialog(context, project)", "showEditDescriptionDialog(context, project, ref)")
overview_class = overview_class.replace("_showEditContactsDialog(context, project)", "showEditContactsDialog(context, project, ref)")

with open(os.path.join(tabs_dir, 'overview_tab.dart'), 'w') as f:
    f.write(overview_imports + overview_class)


# 4. Workflow Tab
workflow_imports = common_imports + """import '../../../people/widgets/employee_selector.dart';
import '../../../people/providers/employee_providers.dart';
\n"""

workflow_class = """class WorkflowTab extends ConsumerWidget {
  final Project project;
  const WorkflowTab({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
""" + get_lines(616, 681) + "\n" + get_lines(683, 731).replace("void _showApprovalDialog(BuildContext context, Project project, ProjectStage stage)", "void _showApprovalDialog(BuildContext context, Project project, ProjectStage stage, WidgetRef ref)") + "\n" + get_lines(733, 754).replace("void _handleStageApproval(BuildContext context, Project project, ProjectStage stage, String approverId)", "void _handleStageApproval(BuildContext context, Project project, ProjectStage stage, String approverId, WidgetRef ref)") + "\n}\n"

workflow_class = workflow_class.replace("_showApprovalDialog(context, project, stage)", "_showApprovalDialog(context, project, stage, ref)")
workflow_class = workflow_class.replace("_handleStageApproval(context, project, stage, approverName);", "_handleStageApproval(context, project, stage, approverName, ref);")

with open(os.path.join(tabs_dir, 'workflow_tab.dart'), 'w') as f:
    f.write(workflow_imports + workflow_class)


# 5. Safety Tab
safety_imports = common_imports + "import '../../../risk/screens/hira_screen.dart';\n\n"

safety_class = """class SafetyTab extends ConsumerWidget {
  final Project project;
  const SafetyTab({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
""" + get_lines(764, 1013) + "\n" + get_lines(1015, 1080) + "\n}\n"

with open(os.path.join(tabs_dir, 'safety_tab.dart'), 'w') as f:
    f.write(safety_imports + safety_class)

# 6. Contractors Tab
contractors_imports = common_imports + "import '../../../contractors/screens/contractor_management_screen.dart';\n\n"

contractors_class = """class ContractorsTab extends ConsumerWidget {
  final Project project;
  const ContractorsTab({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
""" + get_lines(1085, 1317) + "\n" + get_lines(1319, 1341) + "\n" + get_lines(1343, 1345) + "\n" + get_lines(1347, 1397) + "\n" + get_lines(1500, 1570).replace("void _showAssignContractorDialog(BuildContext context, Project project)", "void showAssignContractorDialog(BuildContext context, Project project, WidgetRef ref)") + "\n}\n\n" + get_lines(1879, 2067)

contractors_class = contractors_class.replace("_showAssignContractorDialog(context, project)", "showAssignContractorDialog(context, project, ref)")

with open(os.path.join(tabs_dir, 'contractors_tab.dart'), 'w') as f:
    f.write(contractors_imports + contractors_class)

# 7. Main ProjectDetailsScreen
main_imports = get_lines(1, 20) + """
import '../widgets/project_tabs/overview_tab.dart';
import '../widgets/project_tabs/workflow_tab.dart';
import '../widgets/project_tabs/timeline_tab.dart';
import '../widgets/project_tabs/safety_tab.dart';
import '../widgets/project_tabs/contractors_tab.dart';
import '../widgets/project_tabs/financials_tab.dart';
"""

main_class = get_lines(21, 73) + """
                OverviewTab(project: project),
                WorkflowTab(project: project),
                TimelineTab(project: project),
                SafetyTab(project: project),
                ContractorsTab(project: project),
                if (isLeadOrAdmin) FinancialsTab(project: project),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

""" + get_lines(90, 123) + """
                _quickActionChip(ctx, Icons.attach_money_rounded, 'Add Expense / PO', () {
                  showExpenseForm(context, project, ref);
                }),
""" + get_lines(126, 170) + "\n}\n"

with open(file_path, 'w') as f:
    f.write(main_imports + main_class)

print("Files generated and main file updated successfully.")
