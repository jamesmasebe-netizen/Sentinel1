import 'package:flutter/material.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../models/scm_models.dart';
import '../services/scm_service.dart';
import '../providers/scm_streams_provider.dart';
import '../widgets/production_order_form.dart';

class ProductionOrderScreen extends ConsumerWidget {
  const ProductionOrderScreen({super.key});

  Future<void> _handleAction(BuildContext context, WidgetRef ref, ProductionOrder order, String action) async {
    final service = ref.read(scmServiceProvider);
    try {
      switch (action) {
        case 'start':
          await service.updateProductionOrder(
            ProductionOrder(
              id: order.id,
              orderNumber: order.orderNumber,
              itemId: order.itemId,
              bomRef: order.bomRef,
              targetQuantity: order.targetQuantity,
              completedQuantity: order.completedQuantity,
              status: 'IN_PROGRESS',
              warehouseId: order.warehouseId,
              plannedStartDate: order.plannedStartDate,
              completedAt: order.completedAt,
              createdAt: order.createdAt,
            ),
          );
          if (context.mounted) UIUtils.showToast(context, 'Assembly started', type: ToastType.success);
          break;
        case 'complete':
          await service.completeProductionOrder(order, completedQuantity: order.targetQuantity);
          if (context.mounted) {
            UIUtils.showToast(context, 'Order marked as Completed. Inventory updated.', type: ToastType.success);
          }
          break;
        case 'cancel':
          await service.updateProductionOrder(
            ProductionOrder(
              id: order.id,
              orderNumber: order.orderNumber,
              itemId: order.itemId,
              bomRef: order.bomRef,
              targetQuantity: order.targetQuantity,
              completedQuantity: order.completedQuantity,
              status: 'CANCELLED',
              warehouseId: order.warehouseId,
              plannedStartDate: order.plannedStartDate,
              completedAt: order.completedAt,
              createdAt: order.createdAt,
            ),
          );
          if (context.mounted) UIUtils.showToast(context, 'Order cancelled', type: ToastType.success);
          break;
      }
    } catch (e) {
      if (context.mounted) {
        UIUtils.showToast(context, 'Error updating order: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(productionOrdersListStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          GHeader(
            title: 'Manufacturing & Assembly',
            trailing: ElevatedButton.icon(
              onPressed: () => UIUtils.showSideSheet(
                context: context,
                title: 'New Production Order',
                builder: (_) => const ProductionOrderForm(),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New Order'),
            ),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (orders) {
                if (orders.isEmpty) {
                  return const GEmptyChartState(message: 'No production orders yet');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.withValues(alpha: 0.1),
                          child: const Icon(Icons.precision_manufacturing, color: Colors.orange),
                        ),
                        title: Text(
                          order.itemId != null
                              ? '${order.orderNumber} - ${order.itemId}'
                              : order.orderNumber,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Target Quantity: ${order.targetQuantity.toStringAsFixed(0)}'),
                            Text('Status: ${order.status}'),
                            if (order.bomRef != null)
                              Text(
                                'BOM Ref: ${order.bomRef}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: order.status == 'COMPLETED' || order.status == 'CANCELLED'
                            ? null
                            : PopupMenuButton<String>(
                                onSelected: (value) => _handleAction(context, ref, order, value),
                                itemBuilder: (context) => [
                                  if (order.status == 'PLANNED')
                                    const PopupMenuItem(value: 'start', child: Text('Start Assembly')),
                                  const PopupMenuItem(value: 'complete', child: Text('Complete Order')),
                                  const PopupMenuItem(value: 'cancel', child: Text('Cancel Order')),
                                ],
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
