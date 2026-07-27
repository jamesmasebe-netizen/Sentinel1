import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/supply_chain/models/scm_models.dart';
import '../../features/supply_chain/services/scm_service.dart';

final fieldToInventoryAutomationProvider = Provider<FieldToInventoryAutomation>(
  (ref) {
    return FieldToInventoryAutomation(ref.watch(scmServiceProvider));
  },
);

class FieldToInventoryAutomation {
  final ScmService scmService;

  FieldToInventoryAutomation(this.scmService);

  Future<void> consumeInventoryForWorkOrder(
    String workOrderId,
    String inventoryItemId,
    double quantity,
  ) async {
    final item = await scmService.getInventoryItem(inventoryItemId);
    if (item != null) {
      final updatedStock = item.stockLevel - quantity;
      final updatedItem = InventoryItem(
        id: item.id,
        sku: item.sku,
        name: item.name,
        itemType: item.itemType,
        unitOfMeasure: item.unitOfMeasure,
        valuationMethod: item.valuationMethod,
        lifecycleStatus: item.lifecycleStatus,
        stockLevel: updatedStock,
      );
      await scmService.updateInventoryItem(updatedItem);
    }
  }
}
