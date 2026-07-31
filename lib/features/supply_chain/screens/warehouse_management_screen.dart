import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import 'transfer_order_detail_screen.dart';
import 'bin_locations_screen.dart';
import 'wms_scanner_screen.dart';
import '../widgets/transfer_order_form.dart';
import '../providers/scm_streams_provider.dart';
import '../models/scm_models.dart';

class WarehouseManagementScreen extends ConsumerWidget {
  const WarehouseManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(transferOrdersListStreamProvider);
    final transfers = transfersAsync.valueOrNull ?? [];

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
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Bin Locations'),
              subtitle: const Text('Manage shelves and bins'),
              onTap: () => UIUtils.showSideSheet(
                context: context,
                title: 'Bin Locations',
                builder: (_) => const BinLocationsScreen(),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.move_up),
              title: const Text('Stock Movements'),
              subtitle: Text(
                transfersAsync.isLoading
                    ? 'Loading...'
                    : '${transfers.length} transfer order(s)',
              ),
              onTap: () => UIUtils.showSideSheet(
                context: context,
                title: 'Stock Movements',
                builder: (_) => _TransferOrderListSheet(orders: transfers),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Barcode Scanning'),
              subtitle: const Text('Scan items for receiving or picking'),
              onTap: () => UIUtils.showSideSheet(
                context: context,
                title: 'Barcode Scanning',
                builder: (_) => const WmsScannerScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferOrderListSheet extends StatelessWidget {
  final List<TransferOrder> orders;
  const _TransferOrderListSheet({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('No transfer orders recorded'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final order = orders[i];
        return ListTile(
          leading: const Icon(Icons.swap_horiz),
          title: Text(order.orderNumber),
          subtitle: Text('${order.sourceLocation} → ${order.destinationLocation} · ${order.status}'),
          onTap: () => UIUtils.showSideSheet(
            context: context,
            title: order.orderNumber,
            builder: (_) => TransferOrderDetailScreen(transferId: order.id),
          ),
        );
      },
    );
  }
}
