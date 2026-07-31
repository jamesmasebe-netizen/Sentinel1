import 'package:flutter/material.dart';
import '../../../core/utils/ui_utils.dart';
import '../../property/screens/property_hub_screen.dart';
import '../../equipment/screens/equipment_management_screen.dart';

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
          const Card(
            child: ListTile(
              leading: Icon(Icons.build_circle_outlined),
              title: Text('Preventative Maintenance'),
              subtitle: Text('Schedule and track maintenance tasks'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.history),
              title: Text('Asset Lifecycle'),
              subtitle: Text('Depreciation and lifecycle tracking'),
            ),
          ),
        ],
      ),
    );
  }
}
