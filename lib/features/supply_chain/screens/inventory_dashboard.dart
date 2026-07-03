import 'package:flutter/material.dart';

class InventoryDashboard extends StatelessWidget {
  const InventoryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MRP / Inventory Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.warning_amber),
              title: Text('Low Stock Alerts'),
              subtitle: Text('3 items below minimum threshold'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.list_alt),
              title: Text('Material Requirements Planning'),
              subtitle: Text('View upcoming production needs'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.shopping_cart_outlined),
              title: Text('Purchase Orders'),
              subtitle: Text('5 pending approval'),
            ),
          ),
        ],
      ),
    );
  }
}
