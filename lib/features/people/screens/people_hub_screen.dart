import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import 'employee_profiles_screen.dart';
import '../../training/screens/training_screen.dart';
import 'skills_matrix_screen.dart';
import 'competency_passport_screen.dart';
import '../../health/screens/occupational_health_screen.dart';
import '../../workers_comp/screens/workers_comp_screen.dart';

/// People & Health Hub Dashboard — Material 3 Expressive
class PeopleHubScreen extends StatelessWidget {
  const PeopleHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          UIUtils.showToast(context, 'Quick Add: Employee coming soon');
        },
        backgroundColor: XMTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Employee'),
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
                    'People & Health Hub',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage workforce competency, training compliance, and occupational health.',
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
                      _buildMetricCard(context, 'Active Employees', '142', Icons.people_rounded, XMTheme.primary, isWide),
                      if (isWide) const SizedBox(width: 16),
                      if (!isWide) const SizedBox(height: 16),
                      _buildMetricCard(context, 'Training Compliance', '94%', Icons.school_rounded, XMTheme.success, isWide),
                      if (isWide) const SizedBox(width: 16),
                      if (!isWide) const SizedBox(height: 16),
                      _buildMetricCard(context, 'Health Assessments', '12 Due', Icons.medical_services_rounded, XMTheme.warning, isWide),
                      if (isWide) const SizedBox(width: 16),
                      if (!isWide) const SizedBox(height: 16),
                      _buildMetricCard(context, 'Workers Comp', '2 Open', Icons.healing_rounded, XMTheme.error, isWide),
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
                  title: 'Employee Profiles',
                  subtitle: 'Directory, roles, and employment history.',
                  icon: Icons.badge_rounded,
                  color: XMTheme.primary,
                  onTap: () => _openModule(context, 'Employee Profiles', const EmployeeProfilesScreen()),
                ),
                _buildModuleCard(
                  context,
                  title: 'Training & Inductions',
                  subtitle: 'Manage courses, certificates, and expirations.',
                  icon: Icons.school_rounded,
                  color: XMTheme.success,
                  onTap: () => _openModule(context, 'Training & Inductions', const TrainingScreen()),
                ),
                _buildModuleCard(
                  context,
                  title: 'Skills Matrix',
                  subtitle: 'Gap analysis and organizational capability.',
                  icon: Icons.grid_view_rounded,
                  color: XMTheme.info,
                  onTap: () => _openModule(context, 'Skills Matrix', const SkillsMatrixScreen()),
                ),
                _buildModuleCard(
                  context,
                  title: 'Competency Passport',
                  subtitle: 'Digital worker verification.',
                  icon: Icons.card_membership_rounded,
                  color: const Color(0xFF8B5CF6), // Purple
                  onTap: () => _openModule(context, 'Competency Passport', const CompetencyPassportScreen()),
                ),
                _buildModuleCard(
                  context,
                  title: 'Occupational Health',
                  subtitle: 'Medical surveillance and exposure tracking.',
                  icon: Icons.medical_services_rounded,
                  color: XMTheme.secondary,
                  onTap: () => _openModule(context, 'Occupational Health', const OccupationalHealthScreen()),
                ),
                _buildModuleCard(
                  context,
                  title: "Worker's Comp",
                  subtitle: 'Injury claims and return-to-work programs.',
                  icon: Icons.healing_rounded,
                  color: XMTheme.error,
                  onTap: () => _openModule(context, "Worker's Comp", const WorkersCompScreen()),
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
