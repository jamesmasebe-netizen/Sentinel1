import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../supply_chain/models/scm_models.dart';

/// Provider for the InventoryService
final inventoryServiceProvider = Provider<InventoryService>((ref) {
  return InventoryService(ref.watch(tenantDocProvider));
});

/// Stream provider for InventoryItems
final inventoryItemsProvider = StreamProvider<List<InventoryItem>>((ref) {
  final service = ref.watch(inventoryServiceProvider);
  return service.streamInventoryItems();
});

/// Stream provider for Warehouses
final warehousesProvider = StreamProvider<List<Warehouse>>((ref) {
  final service = ref.watch(inventoryServiceProvider);
  return service.streamWarehouses();
});

/// Service class for Supply Chain & Operations handling Inventory and Warehousing.
/// Uses the canonical models from supply_chain/models/scm_models.dart.
class InventoryService {
  final DocumentReference _tenantDoc;

  InventoryService(this._tenantDoc);

  // ─── Inventory Items ───

  Stream<List<InventoryItem>> streamInventoryItems() {
    return _tenantDoc
        .collection('inventory_items')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((doc) => InventoryItem.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    final docId =
        item.id.isNotEmpty
            ? item.id
            : _tenantDoc.collection('inventory_items').doc().id;
    await _tenantDoc
        .collection('inventory_items')
        .doc(docId)
        .set(item.toJson());
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    if (item.id.isEmpty) return;
    await _tenantDoc
        .collection('inventory_items')
        .doc(item.id)
        .update(item.toJson());
  }

  Future<void> deleteInventoryItem(String id) async {
    await _tenantDoc.collection('inventory_items').doc(id).delete();
  }

  // ─── Warehouses ───

  Stream<List<Warehouse>> streamWarehouses() {
    return _tenantDoc
        .collection('warehouses')
        .orderBy('name', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((doc) => Warehouse.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  Future<void> addWarehouse(Warehouse warehouse) async {
    final docId =
        warehouse.id.isNotEmpty
            ? warehouse.id
            : _tenantDoc.collection('warehouses').doc().id;
    await _tenantDoc
        .collection('warehouses')
        .doc(docId)
        .set(warehouse.toJson());
  }

  Future<void> updateWarehouse(Warehouse warehouse) async {
    if (warehouse.id.isEmpty) return;
    await _tenantDoc
        .collection('warehouses')
        .doc(warehouse.id)
        .update(warehouse.toJson());
  }

  Future<void> deleteWarehouse(String id) async {
    await _tenantDoc.collection('warehouses').doc(id).delete();
  }
}
