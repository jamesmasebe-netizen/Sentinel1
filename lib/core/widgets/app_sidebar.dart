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
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shield_outlined),
          selectedIcon: Icon(Icons.shield_rounded),
          label: Text('Safety & Risk'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people_rounded),
          label: Text('People'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.domain_outlined),
          selectedIcon: Icon(Icons.domain_rounded),
          label: Text('Operations'),
        ),
      ],
    );
  }
}
