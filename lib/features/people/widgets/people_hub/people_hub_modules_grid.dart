import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../screens/employee_profiles_screen.dart';
import '../../../training/screens/training_screen.dart';
import '../../screens/skills_matrix_screen.dart';
import '../../screens/competency_passport_screen.dart';
import '../../../health/screens/occupational_health_screen.dart';
import '../../../workers_comp/screens/workers_comp_screen.dart';
import '../../screens/ohs_appointments_screen.dart';
import '../../screens/leave_management_screen.dart';
import '../../screens/recruitment_dashboard_screen.dart';
import '../../screens/payroll_dashboard_screen.dart';
import '../../screens/okr_dashboard_screen.dart';
import 'people_hub_module_card.dart';

class PeopleHubModulesGrid extends StatelessWidget {
  const PeopleHubModulesGrid({super.key});

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
          mainAxisExtent: 140, // Fixed height for cards
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildListDelegate([
          PeopleHubModuleCard(
            title: 'Employee Profiles',
            subtitle: 'Directory, roles, and employment history.',
            icon: Icons.badge_rounded,
            color: XMTheme.primary,
            onTap:
                () => _openModule(
                  context,
                  'Employee Profiles',
                  const EmployeeProfilesScreen(),
                ),
          ),
          PeopleHubModuleCard(
            title: 'Training & Inductions',
            subtitle: 'Manage courses, certificates, and expirations.',
            icon: Icons.school_rounded,
            color: XMTheme.success,
            onTap:
                () => _openModule(
                  context,
                  'Training & Inductions',
                  const TrainingScreen(),
                ),
          ),
          PeopleHubModuleCard(
            title: 'Skills Matrix',
            subtitle: 'Gap analysis and organizational capability.',
            icon: Icons.grid_view_rounded,
            color: XMTheme.info,
            onTap:
                () => _openModule(
                  context,
                  'Skills Matrix',
                  const SkillsMatrixScreen(),
                ),
          ),
          PeopleHubModuleCard(
            title: 'Competency Passport',
            subtitle: 'Digital worker verification.',
            icon: Icons.card_membership_rounded,
            color: const Color(0xFF8B5CF6), // Purple
            onTap:
                () => _openModule(
                  context,
                  'Competency Passport',
                  const CompetencyPassportScreen(),
                ),
          ),
          PeopleHubModuleCard(
            title: 'Occupational Health',
            subtitle: 'Medical surveillance and exposure tracking.',
            icon: Icons.medical_services_rounded,
            color: XMTheme.secondary,
            onTap:
                () => _openModule(
                  context,
                  'Occupational Health',
                  const OccupationalHealthScreen(),
                ),
          ),
          PeopleHubModuleCard(
            title: "Worker's Comp",
            subtitle: 'Injury claims and return-to-work programs.',
            icon: Icons.healing_rounded,
            color: XMTheme.error,
            onTap:
                () => _openModule(
                  context,
                  "Worker's Comp",
                  const WorkersCompScreen(),
                ),
          ),
          PeopleHubModuleCard(
            title: 'Leave & Time-Off',
            subtitle: 'Manage vacation, sick leave, and approvals.',
            icon: Icons.event_available_rounded,
            color: XMTheme.primary,
            onTap:
                () => _openModule(
                  context,
                  'Leave Management',
                  const LeaveManagementScreen(),
                ),
          ),
          PeopleHubModuleCard(
            title: 'Recruitment & ATS',
            subtitle: 'Job requisitions and candidate tracking.',
            icon: Icons.work_outline_rounded,
            color: XMTheme.info,
            onTap:
                () => _openModule(
                  context,
                  'Recruitment Dashboard',
                  const RecruitmentDashboardScreen(),
                ),
          ),
          PeopleHubModuleCard(
            title: 'Payroll & Comp',
            subtitle: 'Salary ledgers and payslip generation.',
            icon: Icons.account_balance_wallet_rounded,
            color: XMTheme.success,
            onTap:
                () => _openModule(
                  context,
                  'Payroll Dashboard',
                  const PayrollDashboardScreen(),
                ),
          ),
          PeopleHubModuleCard(
            title: 'Performance & Goals',
            subtitle: '360-reviews and OKR tracking.',
            icon: Icons.star_border_rounded,
            color: XMTheme.warning,
            onTap:
                () => _openModule(
                  context,
                  'Performance Reviews (OKRs)',
                  const OkrDashboardScreen(),
                ),
          ),
          PeopleHubModuleCard(
            title: 'OHS Legal Appointments',
            subtitle: 'Section 16.1, 16.2, and 8.2.i mandates.',
            icon: Icons.gavel_rounded,
            color: XMTheme.secondary,
            onTap:
                () => _openModule(
                  context,
                  'OHS Legal Appointments',
                  const OHSAppointmentsScreen(),
                ),
          ),
        ]),
      ),
    );
  }
}
