import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scm_models.dart';

final productsProvider = StateProvider<List<InventoryItem>>((ref) => []);
final purchaseOrdersProvider = StateProvider<List<PurchaseOrder>>((ref) => []);
final warehousesProvider = StateProvider<List<Warehouse>>((ref) => []);
