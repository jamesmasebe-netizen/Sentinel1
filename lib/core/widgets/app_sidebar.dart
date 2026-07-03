import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddPressed;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      groupAlignment: -0.85, // Align items closer to the top
      leading: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: XMTheme.primaryLight.withValues(alpha: 0.2),
          foregroundColor: XMTheme.primaryDark,
          onPressed: () {
            HapticFeedback.lightImpact();
            onAddPressed();
          },
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: Text('Launchpad'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_balance_outlined),
          selectedIcon: Icon(Icons.account_balance),
          label: Text('Finance'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.local_shipping_outlined),
          selectedIcon: Icon(Icons.local_shipping),
          label: Text('Supply Chain'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.architecture_outlined),
          selectedIcon: Icon(Icons.architecture),
          label: Text('Projects'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.engineering_outlined),
          selectedIcon: Icon(Icons.engineering),
          label: Text('Field Service'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.point_of_sale_outlined),
          selectedIcon: Icon(Icons.point_of_sale),
          label: Text('CRM'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.support_agent_outlined),
          selectedIcon: Icon(Icons.support_agent),
          label: Text('Service'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people_rounded),
          label: Text('HR'),
        ),
      ],
    );
  }
}
