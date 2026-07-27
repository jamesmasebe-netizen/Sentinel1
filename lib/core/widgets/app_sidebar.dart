import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

class AppSidebar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onDestinationSelected;
  final VoidCallback onAddPressed;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.onDestinationSelected,
    required this.onAddPressed,
  });

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildItem(String title, IconData icon, String route) {
    final isSelected = currentRoute.startsWith(route);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: isSelected,
        selectedTileColor: XMTheme.primaryLight.withValues(alpha: 0.1),
        leading: Icon(
          icon,
          color: isSelected ? XMTheme.primaryDark : Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? XMTheme.primaryDark : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => onDestinationSelected(route),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onAddPressed();
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Quick Action'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: XMTheme.primaryLight.withValues(alpha: 0.2),
                  foregroundColor: XMTheme.primaryDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildItem('Launchpad', Icons.grid_view_rounded, '/launchpad'),
                _buildGroupTitle('FINANCE'),
                _buildItem('Finance', Icons.account_balance_outlined, '/finance'),
                _buildGroupTitle('SUPPLY CHAIN MANAGEMENT'),
                _buildItem('Supply Chain', Icons.local_shipping_outlined, '/supply-chain'),
                _buildItem('Equipment', Icons.precision_manufacturing_outlined, '/equipment'),
                _buildItem('Property & Facilities', Icons.business_outlined, '/properties'),
                _buildItem('Environment', Icons.eco_outlined, '/environment'),
                _buildGroupTitle('HUMAN RESOURCES'),
                _buildItem('HR & Payroll', Icons.people_outline, '/people'),
                _buildItem('Training', Icons.model_training, '/training'),
                _buildItem('Workers Comp', Icons.personal_injury_outlined, '/workers-comp'),
                _buildItem('Occupational Health', Icons.medical_services_outlined, '/health'),
                _buildItem('Safety', Icons.health_and_safety_outlined, '/safety'),
                _buildItem('Compliance', Icons.fact_check_outlined, '/compliance'),
                _buildGroupTitle('PROJECT OPERATIONS'),
                _buildItem('Projects', Icons.architecture_outlined, '/projects'),
                _buildItem('Project Ops', Icons.construction_outlined, '/projects-ops'),
                _buildItem('Contractors', Icons.handyman_outlined, '/contractors'),
                _buildItem('Risk', Icons.warning_amber_rounded, '/risk'),
                _buildGroupTitle('CUSTOMER ENGAGEMENT'),
                _buildItem('CRM', Icons.point_of_sale_outlined, '/crm'),
                _buildItem('Customer Service', Icons.support_agent_outlined, '/customer-service'),
                _buildItem('Field Service', Icons.engineering_outlined, '/field-service'),
                _buildItem('Emergency', Icons.emergency_outlined, '/emergency'),
                _buildGroupTitle('SYSTEM ADMINISTRATION'),
                _buildItem('Command Center', Icons.dashboard_outlined, '/operations'),
                _buildItem('AI Chat', Icons.smart_toy_outlined, '/ai'),
                _buildItem('Global Settings', Icons.settings_outlined, '/settings'),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
