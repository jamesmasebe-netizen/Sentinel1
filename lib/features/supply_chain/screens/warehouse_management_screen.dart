import 'package:flutter/material.dart';
import '../../../core/utils/ui_utils.dart';
import 'transfer_order_detail_screen.dart';
import '../widgets/transfer_order_form.dart';

class WarehouseManagementScreen extends StatelessWidget {
  const WarehouseManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_road),
            tooltip: 'New Transfer Order',
            onPressed: () => UIUtils.showSideSheet(
              context: context,
              title: 'New Transfer Order',
              builder: (_) => const TransferOrderForm(),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.location_on_outlined),
              title: Text('Bin Locations'),
              subtitle: Text('Manage shelves and bins'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.move_up),
              title: const Text('Stock Movements'),
              subtitle: const Text('Internal transfers and putaway'),
              onTap: () => UIUtils.showSideSheet(
                context: context,
                title: 'Transfer Order Detail',
                builder: (_) => const TransferOrderDetailScreen(transferId: 'MOCK-TO-1'),
              ),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.qr_code_scanner),
              title: Text('Barcode Scanning'),
              subtitle: Text('Scan items for receiving or picking'),
            ),
          ),
        ],
      ),
    );
  }
}
