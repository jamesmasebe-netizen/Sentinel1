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

  // ==========================================
  // ASSETS (Collection: assets)
  // ==========================================
  CollectionReference<Map<String, dynamic>> get _assetsRef =>
      _tenantDoc.collection('assets');

  Future<List<Asset>> getAssets() async {
    final snap = await _assetsRef.get();
    return snap.docs.map((doc) => Asset.fromJson(doc.data(), doc.id)).toList();
  }

  Future<Asset?> getAsset(String id) async {
    final doc = await _assetsRef.doc(id).get();
    if (!doc.exists) return null;
    return Asset.fromJson(doc.data()!, doc.id);
  }

  Future<void> createAsset(Asset asset) async {
    await _assetsRef.doc(asset.id).set(asset.toJson());
  }

  Future<void> updateAsset(Asset asset) async {
    await _assetsRef.doc(asset.id).update(asset.toJson());
  }

  Future<void> deleteAsset(String id) async {
    await _assetsRef.doc(id).delete();
  }

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

  Stream<List<Asset>> streamAssets() {
    return _assetsRef.snapshots().map(
      (snap) =>
          snap.docs.map((doc) => Asset.fromJson(doc.data(), doc.id)).toList(),
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
