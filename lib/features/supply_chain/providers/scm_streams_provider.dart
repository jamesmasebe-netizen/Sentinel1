import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scm_models.dart';
import '../../../core/providers/app_providers.dart';

final inventoryItemStreamProvider =
    StreamProvider.family<InventoryItem?, String>((ref, id) {
      final tenantDoc = ref.watch(tenantDocProvider);
      return tenantDoc
          .collection('inventory_items')
          .doc(id)
          .snapshots()
          .map(
            (snap) =>
                snap.exists
                    ? InventoryItem.fromJson(snap.data()!, snap.id)
                    : null,
          );
    });

final purchaseOrderStreamProvider =
    StreamProvider.family<PurchaseOrder?, String>((ref, id) {
      final tenantDoc = ref.watch(tenantDocProvider);
      return tenantDoc
          .collection('purchase_orders')
          .doc(id)
          .snapshots()
          .map(
            (snap) =>
                snap.exists
                    ? PurchaseOrder.fromJson(snap.data()!, snap.id)
                    : null,
          );
    });

final purchaseOrderLinesStreamProvider =
    StreamProvider.family<List<PurchaseOrderLine>, String>((ref, poId) {
      final tenantDoc = ref.watch(tenantDocProvider);
      return tenantDoc
          .collection('purchase_orders')
          .doc(poId)
          .collection('po_lines')
          .snapshots()
          .map(
            (snap) =>
                snap.docs
                    .map(
                      (doc) => PurchaseOrderLine.fromJson(doc.data(), doc.id),
                    )
                    .toList(),
          );
    });

final transferOrderStreamProvider =
    StreamProvider.family<TransferOrder?, String>((ref, id) {
      final tenantDoc = ref.watch(tenantDocProvider);
      return tenantDoc
          .collection('transfer_orders')
          .doc(id)
          .snapshots()
          .map(
            (snap) =>
                snap.exists
                    ? TransferOrder.fromJson(snap.data()!, snap.id)
                    : null,
          );
    });

final mrpSuggestionsStreamProvider = StreamProvider<List<MrpSuggestion>>((ref) {
  final tenantDoc = ref.watch(tenantDocProvider);
  return tenantDoc
      .collection('mrp_suggestions')
      .snapshots()
      .map(
        (snap) =>
            snap.docs
                .map((doc) => MrpSuggestion.fromJson(doc.data(), doc.id))
                .toList(),
      );
});
