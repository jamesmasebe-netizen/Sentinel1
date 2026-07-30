import 'package:flutter/material.dart';
import '../../../core/utils/ui_utils.dart';
import 'inventory_item_detail_screen.dart';
import 'purchase_order_detail_screen.dart';
import '../widgets/inventory_item_form.dart';
import '../widgets/purchase_order_form.dart';

class InventoryDashboard extends StatelessWidget {
  const InventoryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MRP / Inventory Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: 'New Inventory Item',
            onPressed: () => UIUtils.showSideSheet(
              context: context,
              title: 'New Item',
              builder: (_) => const InventoryItemForm(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.post_add),
            tooltip: 'New Purchase Order',
            onPressed: () => UIUtils.showSideSheet(
              context: context,
              title: 'New PO',
              builder: (_) => const PurchaseOrderForm(),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber),
              title: const Text('Low Stock Alerts'),
              subtitle: const Text('3 items below minimum threshold'),
              onTap: () => UIUtils.showSideSheet(
                context: context,
                title: 'Item Detail',
                builder: (_) => const InventoryItemDetailScreen(itemId: 'MOCK-1'),
              ),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.list_alt),
              title: Text('Material Requirements Planning'),
              subtitle: Text('View upcoming production needs'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Purchase Orders'),
              subtitle: const Text('5 pending approval'),
              onTap: () => UIUtils.showSideSheet(
                context: context,
                title: 'PO Detail',
                builder: (_) => const PurchaseOrderDetailScreen(poId: 'MOCK-PO-1'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
