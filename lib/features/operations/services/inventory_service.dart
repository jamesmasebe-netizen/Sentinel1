import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/providers/app_providers.dart';
import '../models/inventory_models.dart';

/// Provider for the InventoryService
final inventoryServiceProvider = Provider<InventoryService?>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final tenantId = ref.watch(currentTenantIdProvider);

  if (tenantId == null) return null;

  return InventoryService(firestoreService, tenantId);
});

/// Stream provider for InventoryItems
final inventoryItemsProvider = StreamProvider<List<InventoryItem>>((ref) {
  final service = ref.watch(inventoryServiceProvider);
  if (service == null) return Stream.value([]);
  return service.streamInventoryItems();
});

/// Stream provider for Warehouses
final warehousesProvider = StreamProvider<List<Warehouse>>((ref) {
  final service = ref.watch(inventoryServiceProvider);
  if (service == null) return Stream.value([]);
  return service.streamWarehouses();
});

/// Service class for Supply Chain & Operations handling Inventory and Warehousing.
class InventoryService {
  final FirestoreService _firestore;
  final String _tenantId;

  InventoryService(this._firestore, this._tenantId);

  // ─── Inventory Items ───

  Stream<List<InventoryItem>> streamInventoryItems() {
    return _firestore.streamCollection<InventoryItem>(
      collection: 'inventory_items',
      tenantId: _tenantId,
      fromFirestore: InventoryItem.fromFirestore,
      orderByField: 'createdAt',
      descending: true,
    );
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    await _firestore.createDocument(
      tenantId: _tenantId,
      collection: 'inventory_items',
      data: item.toFirestore(),
    );
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    if (item.id == null) return;
    await _firestore.updateDocument(
      tenantId: _tenantId,
      collection: 'inventory_items',
      documentId: item.id!,
      data: item.toFirestore(),
    );
  }

  Future<void> deleteInventoryItem(String id) async {
    await _firestore.deleteDocument(
      tenantId: _tenantId,
      collection: 'inventory_items',
      documentId: id,
    );
  }

  // ─── Warehouses ───

  Stream<List<Warehouse>> streamWarehouses() {
    return _firestore.streamCollection<Warehouse>(
      collection: 'warehouses',
      tenantId: _tenantId,
      fromFirestore: Warehouse.fromFirestore,
      orderByField: 'name',
      descending: false,
    );
  }

  Future<void> addWarehouse(Warehouse warehouse) async {
    await _firestore.createDocument(
      tenantId: _tenantId,
      collection: 'warehouses',
      data: warehouse.toFirestore(),
    );
  }

  Future<void> updateWarehouse(Warehouse warehouse) async {
    if (warehouse.id == null) return;
    await _firestore.updateDocument(
      tenantId: _tenantId,
      collection: 'warehouses',
      documentId: warehouse.id!,
      data: warehouse.toFirestore(),
    );
  }

  Future<void> deleteWarehouse(String id) async {
    await _firestore.deleteDocument(
      tenantId: _tenantId,
      collection: 'warehouses',
      documentId: id,
    );
  }
}
