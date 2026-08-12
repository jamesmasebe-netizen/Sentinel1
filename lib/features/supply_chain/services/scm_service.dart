import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scm_models.dart';
import '../../../core/providers/app_providers.dart';

final scmServiceProvider = Provider<ScmService>((ref) {
  return ScmService(ref.watch(tenantDocProvider));
});

class ScmService {
  final DocumentReference _tenantDoc;

  ScmService(this._tenantDoc);

  // ==========================================
  // INVENTORY ITEMS (Collection: inventory_items)
  // ==========================================
  CollectionReference<Map<String, dynamic>> get _inventoryRef =>
      _tenantDoc.collection('inventory_items');

  Future<List<InventoryItem>> getInventoryItems() async {
    final snap = await _inventoryRef.get();
    return snap.docs
        .map((doc) => InventoryItem.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<InventoryItem?> getInventoryItem(String id) async {
    final doc = await _inventoryRef.doc(id).get();
    if (!doc.exists) return null;
    return InventoryItem.fromJson(doc.data()!, doc.id);
  }

  Future<void> createInventoryItem(InventoryItem item) async {
    await _inventoryRef.doc(item.id).set(item.toJson());
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await _inventoryRef.doc(item.id).update(item.toJson());
  }

  Future<void> deleteInventoryItem(String id) async {
    await _inventoryRef.doc(id).delete();
  }

  // ==========================================
  // INVENTORY TRANSACTIONS (Sub-collection: inventory_items/{itemId}/transactions)
  // ==========================================
  CollectionReference<Map<String, dynamic>> _transactionsRef(String itemId) =>
      _inventoryRef.doc(itemId).collection('transactions');

  Future<void> createInventoryTransaction(String itemId, InventoryTransaction txn) async {
    await _transactionsRef(itemId).doc(txn.id).set(txn.toJson());
  }

  Stream<List<InventoryTransaction>> streamInventoryTransactions(String itemId) {
    return _transactionsRef(itemId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => InventoryTransaction.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  // ==========================================
  // WAREHOUSES (Collection: warehouses)
  // ==========================================
  CollectionReference<Map<String, dynamic>> get _warehousesRef =>
      _tenantDoc.collection('warehouses');

  Future<List<Warehouse>> getWarehouses() async {
    final snap = await _warehousesRef.get();
    return snap.docs
        .map((doc) => Warehouse.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<Warehouse?> getWarehouse(String id) async {
    final doc = await _warehousesRef.doc(id).get();
    if (!doc.exists) return null;
    return Warehouse.fromJson(doc.data()!, doc.id);
  }

  Future<void> createWarehouse(Warehouse warehouse) async {
    await _warehousesRef.doc(warehouse.id).set(warehouse.toJson());
  }

  Future<void> updateWarehouse(Warehouse warehouse) async {
    await _warehousesRef.doc(warehouse.id).update(warehouse.toJson());
  }

  Future<void> deleteWarehouse(String id) async {
    await _warehousesRef.doc(id).delete();
  }

  // ==========================================
  // PURCHASE ORDERS (Collection: purchase_orders)
  // ==========================================
  CollectionReference<Map<String, dynamic>> get _purchaseOrdersRef =>
      _tenantDoc.collection('purchase_orders');

  Future<List<PurchaseOrder>> getPurchaseOrders() async {
    final snap = await _purchaseOrdersRef.get();
    return snap.docs
        .map((doc) => PurchaseOrder.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<PurchaseOrder?> getPurchaseOrder(String id) async {
    final doc = await _purchaseOrdersRef.doc(id).get();
    if (!doc.exists) return null;
    return PurchaseOrder.fromJson(doc.data()!, doc.id);
  }

  Future<void> createPurchaseOrder(PurchaseOrder po) async {
    await _purchaseOrdersRef.doc(po.id).set(po.toJson());
  }

  Future<void> updatePurchaseOrder(PurchaseOrder po) async {
    await _purchaseOrdersRef.doc(po.id).update(po.toJson());
  }

  Future<void> deletePurchaseOrder(String id) async {
    await _purchaseOrdersRef.doc(id).delete();
  }

  // ==========================================
  // PURCHASE ORDER LINES (Sub-collection: po_lines)
  // ==========================================
  CollectionReference<Map<String, dynamic>> _poLinesRef(String poId) =>
      _purchaseOrdersRef.doc(poId).collection('po_lines');

  Future<List<PurchaseOrderLine>> getPurchaseOrderLines(String poId) async {
    final snap = await _poLinesRef(poId).get();
    return snap.docs
        .map((doc) => PurchaseOrderLine.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<PurchaseOrderLine?> getPurchaseOrderLine(
    String poId,
    String lineId,
  ) async {
    final doc = await _poLinesRef(poId).doc(lineId).get();
    if (!doc.exists) return null;
    return PurchaseOrderLine.fromJson(doc.data()!, doc.id);
  }

  Future<void> createPurchaseOrderLine(
    String poId,
    PurchaseOrderLine line,
  ) async {
    await _poLinesRef(poId).doc(line.id).set(line.toJson());
  }

  Future<void> updatePurchaseOrderLine(
    String poId,
    PurchaseOrderLine line,
  ) async {
    await _poLinesRef(poId).doc(line.id).update(line.toJson());
  }

  Future<void> deletePurchaseOrderLine(String poId, String lineId) async {
    await _poLinesRef(poId).doc(lineId).delete();
  }

  // Asset/getAssets/getAsset/createAsset/updateAsset/deleteAsset/streamAssets removed 2026-08-12
  // — confirmed fully dead (zero callers anywhere in lib/); equipment/models/equipment_models.dart's
  // EquipmentModel is the real, live asset-tracking model.

  // ==========================================
  // SALES ORDERS (Collection: sales_orders)
  // ==========================================
  CollectionReference<Map<String, dynamic>> get _salesOrdersRef =>
      _tenantDoc.collection('sales_orders');

  Future<List<SalesOrder>> getSalesOrders() async {
    final snap = await _salesOrdersRef.get();
    return snap.docs
        .map((doc) => SalesOrder.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<SalesOrder?> getSalesOrder(String id) async {
    final doc = await _salesOrdersRef.doc(id).get();
    if (!doc.exists) return null;
    return SalesOrder.fromJson(doc.data()!, doc.id);
  }

  Future<void> createSalesOrder(SalesOrder so) async {
    await _salesOrdersRef.doc(so.id).set(so.toJson());
  }

  Future<void> updateSalesOrder(SalesOrder so) async {
    await _salesOrdersRef.doc(so.id).update(so.toJson());
  }

  Future<void> deleteSalesOrder(String id) async {
    await _salesOrdersRef.doc(id).delete();
  }

  Stream<List<SalesOrder>> streamSalesOrders() {
    return _salesOrdersRef.snapshots().map(
      (snap) =>
          snap.docs
              .map((doc) => SalesOrder.fromJson(doc.data(), doc.id))
              .toList(),
    );
  }

  // ==========================================
  // SALES ORDER LINES (Sub-collection: so_lines)
  // ==========================================
  CollectionReference<Map<String, dynamic>> _soLinesRef(String soId) =>
      _salesOrdersRef.doc(soId).collection('so_lines');

  Future<List<SalesOrderLine>> getSalesOrderLines(String soId) async {
    final snap = await _soLinesRef(soId).get();
    return snap.docs
        .map((doc) => SalesOrderLine.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<SalesOrderLine?> getSalesOrderLine(String soId, String lineId) async {
    final doc = await _soLinesRef(soId).doc(lineId).get();
    if (!doc.exists) return null;
    return SalesOrderLine.fromJson(doc.data()!, doc.id);
  }

  Future<void> createSalesOrderLine(String soId, SalesOrderLine line) async {
    await _soLinesRef(soId).doc(line.id).set(line.toJson());
  }

  Future<void> updateSalesOrderLine(String soId, SalesOrderLine line) async {
    await _soLinesRef(soId).doc(line.id).update(line.toJson());
  }

  Future<void> deleteSalesOrderLine(String soId, String lineId) async {
    await _soLinesRef(soId).doc(lineId).delete();
  }

  // ==========================================
  // TRANSFER ORDERS (Collection: transfer_orders)
  // ==========================================
  CollectionReference<Map<String, dynamic>> get _transferOrdersRef =>
      _tenantDoc.collection('transfer_orders');

  Future<List<TransferOrder>> getTransferOrders() async {
    final snap = await _transferOrdersRef.get();
    return snap.docs
        .map((doc) => TransferOrder.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<TransferOrder?> getTransferOrder(String id) async {
    final doc = await _transferOrdersRef.doc(id).get();
    if (!doc.exists) return null;
    return TransferOrder.fromJson(doc.data()!, doc.id);
  }

  Future<void> createTransferOrder(TransferOrder to) async {
    await _transferOrdersRef.doc(to.id).set(to.toJson());
  }

  Future<void> updateTransferOrder(TransferOrder to) async {
    await _transferOrdersRef.doc(to.id).update(to.toJson());
  }

  Future<void> deleteTransferOrder(String id) async {
    await _transferOrdersRef.doc(id).delete();
  }

  Stream<List<TransferOrder>> streamTransferOrders() {
    return _transferOrdersRef.snapshots().map(
      (snap) =>
          snap.docs
              .map((doc) => TransferOrder.fromJson(doc.data(), doc.id))
              .toList(),
    );
  }

  // ==========================================
  // MRP SUGGESTIONS (Collection: mrp_suggestions)
  // ==========================================
  CollectionReference<Map<String, dynamic>> get _mrpSuggestionsRef =>
      _tenantDoc.collection('mrp_suggestions');

  /// Marks a suggestion as acted on, once a Purchase/Production Order has been created from it
  /// (mrp_dashboard_screen.dart) — mrpSuggestionsStreamProvider shows every suggestion regardless
  /// of status, so without this a converted suggestion would keep reappearing as if still open.
  Future<void> markMrpSuggestionConverted(String id) async {
    await _mrpSuggestionsRef.doc(id).update({'status': 'CONVERTED'});
  }

  // ==========================================
  // PRODUCTION ORDERS (Collection: production_orders)
  // ==========================================
  CollectionReference<Map<String, dynamic>> get _productionOrdersRef =>
      _tenantDoc.collection('production_orders');

  Future<List<ProductionOrder>> getProductionOrders() async {
    final snap = await _productionOrdersRef.get();
    return snap.docs
        .map((doc) => ProductionOrder.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<ProductionOrder?> getProductionOrder(String id) async {
    final doc = await _productionOrdersRef.doc(id).get();
    if (!doc.exists) return null;
    return ProductionOrder.fromJson(doc.data()!, doc.id);
  }

  Future<void> createProductionOrder(ProductionOrder order) async {
    await _productionOrdersRef.doc(order.id).set(order.toJson());
  }

  Future<void> updateProductionOrder(ProductionOrder order) async {
    await _productionOrdersRef.doc(order.id).update(order.toJson());
  }

  Future<void> deleteProductionOrder(String id) async {
    await _productionOrdersRef.doc(id).delete();
  }

  Stream<List<ProductionOrder>> streamProductionOrders() {
    return _productionOrdersRef.snapshots().map(
      (snap) => snap.docs
          .map((doc) => ProductionOrder.fromJson(doc.data(), doc.id))
          .toList(),
    );
  }

  /// Marks a production order Completed and — unlike the screen's old mock "Complete Order" action,
  /// which claimed "Inventory updated" without touching any real data — actually increments the
  /// produced item's stock level by the completed quantity AND writes a matching
  /// InventoryTransaction, all in a single transaction so the writes can't partially apply.
  Future<void> completeProductionOrder(
    ProductionOrder order, {
    required double completedQuantity,
  }) async {
    final orderRef = _productionOrdersRef.doc(order.id);
    final itemRef = order.itemId != null ? _inventoryRef.doc(order.itemId) : null;
    final txnRef = order.itemId != null ? _transactionsRef(order.itemId!).doc() : null;

    await _tenantDoc.firestore.runTransaction((txn) async {
      // All reads must happen before any writes in a Firestore transaction.
      final itemSnap = itemRef != null ? await txn.get(itemRef) : null;

      txn.update(orderRef, {
        'status': 'COMPLETED',
        'completed_quantity': completedQuantity,
        'completed_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });

      if (itemRef != null && itemSnap != null && itemSnap.exists) {
        final currentStock = (itemSnap.data()?['stock_level'] as num?)?.toDouble() ?? 0.0;
        final newStock = currentStock + completedQuantity;
        txn.update(itemRef, {'stock_level': newStock});

        if (txnRef != null) {
          txn.set(
            txnRef,
            InventoryTransaction(
              id: txnRef.id,
              type: 'PRODUCTION',
              quantity: completedQuantity,
              resultingStockLevel: newStock,
              referenceId: order.id,
              note: 'Production order ${order.orderNumber} completed',
              createdAt: DateTime.now(),
            ).toJson(),
          );
        }
      }
    });
  }

  // ==========================================
  // REACTIVE STREAMS
  // ==========================================
  Stream<List<InventoryItem>> streamInventoryItems() {
    return _inventoryRef.snapshots().map(
      (snap) =>
          snap.docs
              .map((doc) => InventoryItem.fromJson(doc.data(), doc.id))
              .toList(),
    );
  }

  Stream<List<Warehouse>> streamWarehouses() {
    return _warehousesRef.snapshots().map(
      (snap) =>
          snap.docs
              .map((doc) => Warehouse.fromJson(doc.data(), doc.id))
              .toList(),
    );
  }

  Stream<List<PurchaseOrder>> streamPurchaseOrders() {
    return _purchaseOrdersRef.snapshots().map(
      (snap) =>
          snap.docs
              .map((doc) => PurchaseOrder.fromJson(doc.data(), doc.id))
              .toList(),
    );
  }

  // ==========================================
  // WAREHOUSE BIN LOCATIONS (Collection: warehouseBinLocations)
  // ==========================================
  CollectionReference<Map<String, dynamic>> get _binLocationsRef =>
      _tenantDoc.collection('warehouseBinLocations');

  Future<List<WarehouseBinLocation>> getBinLocations() async {
    final snap = await _binLocationsRef.get();
    return snap.docs
        .map((doc) => WarehouseBinLocation.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<WarehouseBinLocation?> getBinLocation(String id) async {
    final doc = await _binLocationsRef.doc(id).get();
    if (!doc.exists) return null;
    return WarehouseBinLocation.fromJson(doc.data()!, doc.id);
  }

  Future<void> createBinLocation(WarehouseBinLocation bin) async {
    await _binLocationsRef.doc(bin.id).set(bin.toJson());
  }

  Future<void> updateBinLocation(WarehouseBinLocation bin) async {
    await _binLocationsRef.doc(bin.id).update(bin.toJson());
  }

  Future<void> deleteBinLocation(String id) async {
    await _binLocationsRef.doc(id).delete();
  }

  Stream<List<WarehouseBinLocation>> streamBinLocations() {
    return _binLocationsRef.snapshots().map(
      (snap) =>
          snap.docs
              .map((doc) => WarehouseBinLocation.fromJson(doc.data(), doc.id))
              .toList(),
    );
  }

  // ==========================================
  // VENDOR PERFORMANCE METRICS (Collection: vendorPerformanceMetrics)
  // ==========================================
  CollectionReference<Map<String, dynamic>> get _vendorMetricsRef =>
      _tenantDoc.collection('vendorPerformanceMetrics');

  Future<List<VendorPerformanceMetric>> getVendorPerformanceMetrics() async {
    final snap = await _vendorMetricsRef.get();
    return snap.docs
        .map((doc) => VendorPerformanceMetric.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<VendorPerformanceMetric?> getVendorPerformanceMetric(String id) async {
    final doc = await _vendorMetricsRef.doc(id).get();
    if (!doc.exists) return null;
    return VendorPerformanceMetric.fromJson(doc.data()!, doc.id);
  }

  Future<void> createVendorPerformanceMetric(
    VendorPerformanceMetric metric,
  ) async {
    await _vendorMetricsRef.doc(metric.id).set(metric.toJson());
  }

  Future<void> updateVendorPerformanceMetric(
    VendorPerformanceMetric metric,
  ) async {
    await _vendorMetricsRef.doc(metric.id).update(metric.toJson());
  }

  Future<void> deleteVendorPerformanceMetric(String id) async {
    await _vendorMetricsRef.doc(id).delete();
  }

  Stream<List<VendorPerformanceMetric>> streamVendorPerformanceMetrics() {
    return _vendorMetricsRef.snapshots().map(
      (snap) =>
          snap.docs
              .map(
                (doc) => VendorPerformanceMetric.fromJson(doc.data(), doc.id),
              )
              .toList(),
    );
  }
}
