// Tests for InventoryService (lib/features/operations/services/inventory_service.dart) — a
// second, distinct service (from the operations module) reading/writing the same inventory_items/
// warehouses collections and the same canonical scm_models.dart types as ScmService
// (supply_chain module, see T3-SUPPLYCHAIN). Confirmed both correctly use the tenant-scoped
// path, so this is architectural redundancy, not a bug — covered here in its own right since
// it's a real, distinct, injectable service class.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/supply_chain/models/scm_models.dart';
import 'package:sentinel1/features/operations/services/inventory_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late InventoryService service;
  const tenantId = 'tenant-ops-inv-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = InventoryService(firestore.collection('tenants').doc(tenantId));
  });

  group('InventoryItem', () {
    test('addInventoryItem generates a real id when none is supplied, findable via streamInventoryItems',
        () async {
      await service.addInventoryItem(InventoryItem(
        id: '',
        sku: 'SKU-100',
        name: 'Widget',
        itemType: 'Finished Good',
        unitOfMeasure: 'each',
        valuationMethod: 'FIFO',
        lifecycleStatus: 'Active',
      ));

      final result = await service.streamInventoryItems().first;

      expect(result, hasLength(1));
      expect(result.single.sku, 'SKU-100');
      expect(result.single.id, isNotEmpty);
    });

    test('updateInventoryItem is a no-op when the item has no id (documents the guard, not a bug)',
        () async {
      await service.updateInventoryItem(InventoryItem(
        id: '',
        sku: 'SKU-101',
        name: 'Widget',
        itemType: 'Finished Good',
        unitOfMeasure: 'each',
        valuationMethod: 'FIFO',
        lifecycleStatus: 'Active',
      ));

      final result = await service.streamInventoryItems().first;
      expect(result, isEmpty);
    });
  });

  group('Warehouse', () {
    test('addWarehouse then streamWarehouses finds it, ordered by name', () async {
      await service.addWarehouse(Warehouse(id: '', name: 'Zebra DC', code: 'ZDC', type: 'Distribution', status: 'Active'));
      await service.addWarehouse(Warehouse(id: '', name: 'Alpha DC', code: 'ADC', type: 'Distribution', status: 'Active'));

      final result = await service.streamWarehouses().first;

      expect(result, hasLength(2));
      expect(result.map((w) => w.name), ['Alpha DC', 'Zebra DC']);
    });

    test('deleteWarehouse removes the doc', () async {
      await service.addWarehouse(Warehouse(id: 'wh-1', name: 'To Delete', code: 'TD', type: 'Distribution', status: 'Active'));

      await service.deleteWarehouse('wh-1');

      final result = await service.streamWarehouses().first;
      expect(result, isEmpty);
    });
  });
}
