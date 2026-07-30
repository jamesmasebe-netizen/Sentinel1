import 'package:flutter/material.dart';
import '../../../core/utils/ui_utils.dart';
import 'inventory_dashboard.dart';
import 'warehouse_management_screen.dart';
import 'asset_management_screen.dart';

class SupplyChainHubScreen extends StatelessWidget {
  const SupplyChainHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supply Chain & Assets'), elevation: 0),
      body: GridView.count(
        padding: const EdgeInsets.all(16.0),
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          _buildCard(
            context,
            'Inventory / MRP',
            Icons.inventory_2_outlined,
            const InventoryDashboard(),
          ),
          _buildCard(
            context,
            'Warehouse Mgmt',
            Icons.warehouse_outlined,
            const WarehouseManagementScreen(),
          ),
          _buildCard(
            context,
            'Enterprise Asset Mgmt',
            Icons.precision_manufacturing_outlined,
            const AssetManagementScreen(),
          ),
          _buildCard(
            context,
            'Vendor Performance',
            Icons.assessment_outlined,
            const Scaffold(
              body: Center(child: Text('Vendor Performance — Coming Soon')),
            ),
          ),
          _buildCard(
            context,
            'Bin Locations',
            Icons.grid_view_outlined,
            const Scaffold(
              body: Center(child: Text('Bin Locations — Coming Soon')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          UIUtils.showSideSheet(
            context: context,
            title: title,
            builder: (context) => screen,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
