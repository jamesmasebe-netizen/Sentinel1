import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../supply_chain/models/scm_models.dart';
import '../providers/scm_streams_provider.dart';
import 'package:intl/intl.dart';
import '../../../core/bpf/bpf_ribbon_widget.dart';
import '../../../core/bpf/procure_to_pay_bpf.dart';
import '../widgets/purchase_order_line_form.dart';
import '../../../core/utils/ui_utils.dart';

class PurchaseOrderDetailScreen extends ConsumerWidget {
  final String poId;

  const PurchaseOrderDetailScreen({super.key, required this.poId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poAsync = ref.watch(purchaseOrderStreamProvider(poId));
    final linesAsync = ref.watch(purchaseOrderLinesStreamProvider(poId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Order Detail'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // Print action
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // More actions
            },
          ),
        ],
      ),
      body: poAsync.when(
        data: (po) {
          if (po == null) {
            return const Center(child: Text('Purchase Order not found'));
          }
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                _buildHeaderCard(context, po),
                BpfRibbonWidget(
                  bpfTypeId: 'procure_to_pay',
                  recordType: 'purchase_order',
                  recordId: po.id,
                  definition: procureToPayDefinition,
                ),
                const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.list_alt), text: 'PO Lines'),
                    Tab(icon: Icon(Icons.info_outline), text: 'Details'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildLinesTab(context, linesAsync, po.id),
                      _buildDetailsTab(context, po),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, PurchaseOrder po) {
    final formatCurrency = NumberFormat.simpleCurrency(name: po.currency);
    return Container(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PO: ${po.poNumber}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Chip(
                label: Text(po.status.toUpperCase()),
                backgroundColor: _getStatusColor(
                  po.status,
                ).withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: _getStatusColor(po.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHeaderMetric(
                  context,
                  'Total Amount',
                  formatCurrency.format(po.totalAmount),
                  Icons.monetization_on_outlined,
                ),
              ),
              Expanded(
                child: _buildHeaderMetric(
                  context,
                  'Order Date',
                  po.orderDate != null
                      ? DateFormat.yMMMd().format(po.orderDate!)
                      : 'N/A',
                  Icons.calendar_today_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'submitted':
      case 'approved':
        return Colors.blue;
      case 'received':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildHeaderMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinesTab(
    BuildContext context,
    AsyncValue<List<PurchaseOrderLine>> linesAsync,
    String poId,
  ) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          UIUtils.showSideSheet(
            context: context,
            title: 'Add Line Item',
            builder: (context) => PurchaseOrderLineForm(poId: poId),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: linesAsync.when(
      data: (lines) {
        if (lines.isEmpty) {
          return const Center(child: Text('No order lines found.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: lines.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final line = lines[index];
            final subTotal = line.quantityOrdered * line.unitPrice;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory, color: Colors.grey),
              ),
              title: Text(
                'Item: ${line.itemId ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Ordered: ${line.quantityOrdered} | Received: ${line.quantityReceived}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.simpleCurrency().format(subTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${NumberFormat.simpleCurrency().format(line.unitPrice)} ea',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context, PurchaseOrder po) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          context,
          title: 'Order Information',
          children: [
            _buildInfoRow('Vendor ID', po.vendorId ?? 'N/A'),
            _buildInfoRow('Destination Warehouse', po.warehouseId ?? 'N/A'),
            _buildInfoRow(
              'Expected Delivery',
              po.expectedDeliveryDate != null
                  ? DateFormat.yMMMd().format(po.expectedDeliveryDate!)
                  : 'Not set',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
