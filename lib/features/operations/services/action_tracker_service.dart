import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../models/action_tracker_models.dart';

/// Provider for the ActionTrackerService
final actionTrackerServiceProvider = Provider<ActionTrackerService>((ref) {
  return ActionTrackerService(ref.watch(tenantDocProvider));
});

/// Stream provider for all ActionItems
final actionItemsProvider = StreamProvider<List<ActionItem>>((ref) {
  final service = ref.watch(actionTrackerServiceProvider);
  return service.streamActionItems();
});

/// Stream provider for ActionItems filtered by status
final actionItemsByStatusProvider =
    StreamProvider.family<List<ActionItem>, String>((ref, status) {
      final service = ref.watch(actionTrackerServiceProvider);
      return service.streamActionItemsByStatus(status);
    });

/// Service class for managing Action Tracker items in Firestore.
class ActionTrackerService {
  final DocumentReference _tenantDoc;

  ActionTrackerService(this._tenantDoc);

  CollectionReference get _actionItemsCol =>
      _tenantDoc.collection('actionItems');

  // ─── Create ───

  Future<void> createActionItem(ActionItem item) async {
    final docRef = _actionItemsCol.doc(item.id.isNotEmpty ? item.id : null);
    final data = item.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  // ─── Update ───

  Future<void> updateActionItem(ActionItem item) async {
    final data = item.toJson();
    data.remove('createdAt'); // Don't override createdAt
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _actionItemsCol.doc(item.id).update(data);
  }

  // ─── Delete ───

  Future<void> deleteActionItem(String itemId) async {
    await _actionItemsCol.doc(itemId).delete();
  }

  // ─── Stream All ───

  Stream<List<ActionItem>> streamActionItems() {
    return _actionItemsCol
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map(
                    (doc) => ActionItem.fromJson(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // ─── Stream by Status ───

  Stream<List<ActionItem>> streamActionItemsByStatus(String status) {
    return _actionItemsCol
        .where('status', isEqualTo: status)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map(
                    (doc) => ActionItem.fromJson(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // ─── Get Single ───

  Future<ActionItem?> getActionItem(String itemId) async {
    final doc = await _actionItemsCol.doc(itemId).get();
    if (!doc.exists) return null;
    return ActionItem.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }
}
