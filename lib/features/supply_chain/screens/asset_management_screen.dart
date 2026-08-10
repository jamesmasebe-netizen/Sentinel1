import 'package:flutter/material.dart';
import '../../../core/utils/ui_utils.dart';
import '../../property/screens/property_hub_screen.dart';
import '../../equipment/screens/equipment_management_screen.dart';
import '../../equipment/screens/asset_lifecycle_screen.dart';

class AssetManagementScreen extends StatelessWidget {
  const AssetManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enterprise Asset Management')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Property Management'),
              subtitle: const Text('Manage real estate and facilities'),
              onTap: () => UIUtils.showSideSheet(
                context: context,
                title: 'Property Management',
                builder: (_) => const PropertyHubScreen(),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.precision_manufacturing),
              title: const Text('Equipment Tracking'),
              subtitle: const Text('Track machinery and heavy equipment'),
              onTap: () => UIUtils.showSideSheet(
                context: context,
                title: 'Equipment Tracking',
                builder: (_) => const EquipmentManagementScreen(),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.build_circle_outlined),
              title: const Text('Preventative Maintenance'),
              subtitle: const Text('Schedule and track maintenance tasks'),
              onTap: () => UIUtils.showSideSheet(
                context: context,
                title: 'Preventative Maintenance',
                builder: (_) => const EquipmentManagementScreen(initialTabIndex: 2),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Asset Lifecycle'),
              subtitle: const Text('Depreciation and lifecycle tracking'),
              onTap: () => UIUtils.showSideSheet(
                context: context,
                title: 'Asset Lifecycle',
                builder: (_) => const AssetLifecycleScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
