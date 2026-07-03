import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/purchase_order.dart';
import '../models/warehouse.dart';

final productsProvider = StateProvider<List<Product>>((ref) => []);
final purchaseOrdersProvider = StateProvider<List<PurchaseOrder>>((ref) => []);
final warehousesProvider = StateProvider<List<Warehouse>>((ref) => []);
