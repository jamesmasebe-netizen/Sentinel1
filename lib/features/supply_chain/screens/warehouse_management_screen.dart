import 'package:flutter/material.dart';

class WarehouseManagementScreen extends StatelessWidget {
  const WarehouseManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warehouse Management')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.location_on_outlined),
              title: Text('Bin Locations'),
              subtitle: Text('Manage shelves and bins'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.move_up),
              title: Text('Stock Movements'),
              subtitle: Text('Internal transfers and putaway'),
            ),
          ),
          Card(
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
