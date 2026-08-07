// Tests for ScmService (lib/features/supply_chain/services/scm_service.dart) — representative
// CRUD coverage for InventoryItem, PurchaseOrder+lines, Asset, TransferOrder, and
// WarehouseBinLocation. SalesOrder+so_lines already has dedicated coverage in
// scm_service_so_lines_test.dart (added earlier this session alongside the mrpEngine fix).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/supply_chain/models/scm_models.dart';
import 'package:sentinel1/features/supply_chain/services/scm_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ScmService service;
  const tenantId = 'tenant-scm-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = ScmService(firestore.collection('tenants').doc(tenantId));
  });

  group('InventoryItem', () {
    test('createInventoryItem then getInventoryItem round-trips', () async {
      await service.createInventoryItem(InventoryItem(
        id: 'item-1',
        sku: 'SKU-001',
        name: 'Steel Bolt',
        itemType: 'Raw Material',
        unitOfMeasure: 'each',
        valuationMethod: 'FIFO',
        lifecycleStatus: 'Active',
      ));

      final result = await service.getInventoryItem('item-1');

      expect(result, isNotNull);
      expect(result!.sku, 'SKU-001');
    });

    test('streamInventoryItems returns only this tenant\'s items', () async {
      await service.createInventoryItem(InventoryItem(
        id: 'item-2',
        sku: 'SKU-002',
        name: 'Item A',
        itemType: 'Raw Material',
        unitOfMeasure: 'each',
        valuationMethod: 'FIFO',
        lifecycleStatus: 'Active',
      ));
      await firestore
          .collection('tenants')
          .doc('other-tenant')
          .collection('inventory_items')
          .doc('item-3')
          .set({'sku': 'SKU-003'});

      final result = await service.streamInventoryItems().first;

      expect(result, hasLength(1));
      expect(result.single.sku, 'SKU-002');
    });
  });

  group('PurchaseOrder + lines', () {
    test('createPurchaseOrder then createPurchaseOrderLine nests the line under the order', () async {
      await service.createPurchaseOrder(PurchaseOrder(
        id: 'po-1',
        poNumber: 'PO-001',
        status: 'Draft',
      ));
      await service.createPurchaseOrderLine('po-1', PurchaseOrderLine(
        id: 'line-1',
        itemId: 'item-1',
        quantityOrdered: 10,
        unitPrice: 5.0,
      ));

      final lines = await service.getPurchaseOrderLines('po-1');

      expect(lines, hasLength(1));
      expect(lines.single.quantityOrdered, 10);
    });
  });

  group('Asset', () {
    test('createAsset then getAsset round-trips', () async {
      await service.createAsset(Asset(
        id: 'asset-1',
        assetTag: 'AST-001',
        name: 'Forklift',
        category: 'Heavy Equipment',
        status: 'InUse',
      ));

      final result = await service.getAsset('asset-1');

      expect(result, isNotNull);
      expect(result!.name, 'Forklift');
    });
  });

  group('TransferOrder', () {
    test('createTransferOrder then streamTransferOrders finds it', () async {
      await service.createTransferOrder(TransferOrder(
        id: 'to-1',
        orderNumber: 'TO-001',
        sourceLocation: 'WH-A',
        destinationLocation: 'WH-B',
        status: 'Pending',
      ));

      final result = await service.streamTransferOrders().first;

      expect(result, hasLength(1));
      expect(result.single.sourceLocation, 'WH-A');
    });
  });

  group('WarehouseBinLocation', () {
    test('createBinLocation then getBinLocation round-trips', () async {
      await service.createBinLocation(WarehouseBinLocation(
        id: 'bin-1',
        warehouseId: 'WH-A',
        binCode: 'A-01-01',
        aisle: 'A',
        rack: '01',
        level: '01',
        zone: 'Receiving',
      ));

      final result = await service.getBinLocation('bin-1');

      expect(result, isNotNull);
      expect(result!.binCode, 'A-01-01');
    });
  });
}
