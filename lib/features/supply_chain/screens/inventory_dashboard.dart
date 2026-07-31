import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import 'inventory_item_detail_screen.dart';
import 'purchase_order_detail_screen.dart';
import 'mrp_dashboard_screen.dart';
import '../widgets/inventory_item_form.dart';
import '../widgets/purchase_order_form.dart';
import '../providers/scm_streams_provider.dart';
import '../models/scm_models.dart';

class InventoryDashboard extends ConsumerWidget {
  const InventoryDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inventoryItemsListStreamProvider);
    final posAsync = ref.watch(purchaseOrdersListStreamProvider);

    final lowStockItems = itemsAsync.valueOrNull
            ?.where((i) => i.stockLevel <= i.reorderPoint)
            .toList() ??
        [];
    final pendingPOs = posAsync.valueOrNull
            ?.where((po) => po.status == 'Draft')
            .toList() ??
        [];

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
              subtitle: Text(
                itemsAsync.isLoading
                    ? 'Loading...'
                    : '${lowStockItems.length} item(s) at or below reorder point',
              ),
              onTap: () => UIUtils.showSideSheet(
                context: context,
                title: 'Low Stock Items',
                builder: (_) => _InventoryItemListSheet(items: lowStockItems),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Material Requirements Planning'),
              subtitle: const Text('View upcoming production needs'),
              onTap: () => UIUtils.showSideSheet(
                context: context,
                title: 'MRP Dashboard',
                builder: (_) => const MrpDashboardScreen(),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Purchase Orders'),
              subtitle: Text(
                posAsync.isLoading
                    ? 'Loading...'
                    : '${pendingPOs.length} pending approval',
              ),
              onTap: () => UIUtils.showSideSheet(
                context: context,
                title: 'Pending Purchase Orders',
                builder: (_) => _PurchaseOrderListSheet(orders: pendingPOs),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryItemListSheet extends StatelessWidget {
  final List<InventoryItem> items;
  const _InventoryItemListSheet({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items at or below reorder point'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = items[i];
        return ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: Text(item.name),
          subtitle: Text('${item.sku} — ${item.stockLevel.toStringAsFixed(0)} in stock (reorder at ${item.reorderPoint.toStringAsFixed(0)})'),
          onTap: () => UIUtils.showSideSheet(
            context: context,
            title: item.name,
            builder: (_) => InventoryItemDetailScreen(itemId: item.id),
          ),
        );
      },
    );
  }
}

class _PurchaseOrderListSheet extends StatelessWidget {
  final List<PurchaseOrder> orders;
  const _PurchaseOrderListSheet({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('No purchase orders pending approval'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final po = orders[i];
        return ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(po.poNumber),
          subtitle: Text('Status: ${po.status}'),
          onTap: () => UIUtils.showSideSheet(
            context: context,
            title: po.poNumber,
            builder: (_) => PurchaseOrderDetailScreen(poId: po.id),
          ),
        );
      },
    );
  }
}
