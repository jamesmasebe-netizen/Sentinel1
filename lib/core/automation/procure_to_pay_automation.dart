import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../features/supply_chain/services/scm_service.dart';
import '../../features/finance/services/finance_service.dart';
import '../../features/supply_chain/models/scm_models.dart';
import '../../features/finance/models/finance_models.dart';

final procureToPayAutomationProvider = Provider<ProcureToPayAutomation>((ref) {
  final scmService = ref.watch(scmServiceProvider);
  final financeService = ref.watch(financeServiceProvider);
  return ProcureToPayAutomation(scmService, financeService);
});

class ProcureToPayAutomation {
  final ScmService _scmService;
  final FinanceService _financeService;
  final _uuid = const Uuid();

  ProcureToPayAutomation(this._scmService, this._financeService);

  /// Triggers the cross-module automation when a Purchase Order is received.
  Future<void> triggerPoReceived(PurchaseOrder po) async {
    // 1. Ensure the PO is marked as 'Received'
    if (po.status != 'Received') {
      final updatedPo = PurchaseOrder(
        id: po.id,
        poNumber: po.poNumber,
        vendorId: po.vendorId,
        warehouseId: po.warehouseId,
        status: 'Received',
        orderDate: po.orderDate,
        expectedDeliveryDate: po.expectedDeliveryDate,
        currency: po.currency,
        totalAmount: po.totalAmount,
      );
      await _scmService.updatePurchaseOrder(updatedPo);
    }

    // 2. Automatically generate an AP Invoice in Finance
    final invoiceId = _uuid.v4();
    final invoice = Invoice(
      id: invoiceId,
      invoiceType: 'AP',
      vendorId: po.vendorId,
      invoiceNumber: 'AP-${po.poNumber}',
      invoiceDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      status: 'DRAFT',
      currencyCode: po.currency,
      grossAmount: po.totalAmount,
      taxAmount: 0.0,
      netAmount: po.totalAmount,
    );

    await _financeService.createInvoice(invoice);

    // 3. Increment the corresponding InventoryItem stock level
    final lines = await _scmService.getPurchaseOrderLines(po.id);
    for (final line in lines) {
      if (line.itemId != null) {
        final item = await _scmService.getInventoryItem(line.itemId!);
        if (item != null) {
          final incrementAmount =
              line.quantityReceived > 0
                  ? line.quantityReceived
                  : line.quantityOrdered;

          final updatedItem = InventoryItem(
            id: item.id,
            sku: item.sku,
            name: item.name,
            description: item.description,
            itemType: item.itemType,
            unitOfMeasure: item.unitOfMeasure,
            weight: item.weight,
            dimensions: item.dimensions,
            valuationMethod: item.valuationMethod,
            standardCost: item.standardCost,
            leadTimeDays: item.leadTimeDays,
            safetyStock: item.safetyStock,
            reorderPoint: item.reorderPoint,
            isConfigurable: item.isConfigurable,
            isActive: item.isActive,
            lifecycleStatus: item.lifecycleStatus,
            createdAt: item.createdAt,
            updatedAt: DateTime.now(),
            stockLevel: item.stockLevel + incrementAmount,
          );
          await _scmService.updateInventoryItem(updatedItem);
        }
      }
    }
  }
}
