import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'offline_sync_service.dart';

/// Generic Firestore service with offline-first writes and siteId filtering.
/// All reads use Firestore streams (real-time). All writes go through OfflineSyncService.
class FirestoreService {
  final FirebaseFirestore _firestore;
  final OfflineSyncService _offlineSync;

  FirestoreService(this._firestore, this._offlineSync);

  // ─── READ OPERATIONS (Real-time streams with siteId filtering) ───

  /// Stream a collection filtered by siteId, with optional ordering
  Stream<List<T>> streamCollection<T>({
    required String collection,
    required String siteId,
    required T Function(DocumentSnapshot) fromFirestore,
    String? orderByField,
    bool descending = true,
    int? limit,
    List<QueryFilter>? filters,
  }) {
    Query query = _firestore
        .collection(collection)
        .where('siteId', isEqualTo: siteId);

    if (filters != null) {
      for (final filter in filters) {
        switch (filter.operator) {
          case FilterOp.equals:
            query = query.where(filter.field, isEqualTo: filter.value);
            break;
          case FilterOp.notEquals:
            query = query.where(filter.field, isNotEqualTo: filter.value);
            break;
          case FilterOp.greaterThan:
            query = query.where(filter.field, isGreaterThan: filter.value);
            break;
          case FilterOp.lessThan:
            query = query.where(filter.field, isLessThan: filter.value);
            break;
          case FilterOp.arrayContains:
            query = query.where(filter.field, arrayContains: filter.value);
            break;
          case FilterOp.whereIn:
            query = query.where(filter.field, whereIn: filter.value as List);
            break;
        }
      }
    }

    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => fromFirestore(doc)).toList(),
    );
  }

  /// Stream a single document
  Stream<T?> streamDocument<T>({
    required String collection,
    required String documentId,
    required T Function(DocumentSnapshot) fromFirestore,
  }) {
    return _firestore
        .collection(collection)
        .doc(documentId)
        .snapshots()
        .map((doc) => doc.exists ? fromFirestore(doc) : null);
  }

  /// One-time fetch of a collection
  Future<List<T>> getCollection<T>({
    required String collection,
    required String siteId,
    required T Function(DocumentSnapshot) fromFirestore,
    String? orderByField,
    bool descending = true,
    int? limit,
  }) async {
    Query query = _firestore
        .collection(collection)
        .where('siteId', isEqualTo: siteId);

    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// One-time fetch of a single document
  Future<T?> getDocument<T>({
    required String collection,
    required String documentId,
    required T Function(DocumentSnapshot) fromFirestore,
  }) async {
    final doc = await _firestore.collection(collection).doc(documentId).get();
    return doc.exists ? fromFirestore(doc) : null;
  }

  // ─── WRITE OPERATIONS (Offline-first via queue) ───

  /// Create a document (offline-first)
  Future<String> createDocument({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    return _offlineSync.queueOperation(
      operation: OfflineOperation.create,
      collection: collection,
      data: data,
      documentId: documentId,
    );
  }

  /// Update a document (offline-first)
  Future<String> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    return _offlineSync.queueOperation(
      operation: OfflineOperation.update,
      collection: collection,
      data: data,
      documentId: documentId,
    );
  }

  /// Delete a document (offline-first)
  Future<String> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    return _offlineSync.queueOperation(
      operation: OfflineOperation.delete,
      collection: collection,
      data: {},
      documentId: documentId,
    );
  }

  // ─── DIRECT OPERATIONS (bypass offline queue, for real-time needs) ───

  /// Direct Firestore write (skips offline queue)
  Future<DocumentReference> directCreate({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    return _firestore.collection(collection).add(data);
  }

  /// Direct Firestore update
  Future<void> directUpdate({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collection).doc(documentId).update(data);
  }

  /// Batch write for multiple operations
  Future<void> batchWrite(List<BatchOperation> operations) async {
    final batch = _firestore.batch();
    for (final op in operations) {
      final ref = _firestore.collection(op.collection).doc(op.documentId);
      switch (op.type) {
        case BatchOpType.set:
          batch.set(ref, op.data);
          break;
        case BatchOpType.update:
          batch.update(ref, op.data);
          break;
        case BatchOpType.delete:
          batch.delete(ref);
          break;
      }
    }
    await batch.commit();
  }

  /// Get a count of documents in a collection
  Future<int> getCount({
    required String collection,
    required String siteId,
    List<QueryFilter>? filters,
  }) async {
    Query query = _firestore
        .collection(collection)
        .where('siteId', isEqualTo: siteId);

    if (filters != null) {
      for (final filter in filters) {
        if (filter.operator == FilterOp.equals) {
          query = query.where(filter.field, isEqualTo: filter.value);
        }
      }
    }

    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }
}

// ─── Helper Classes ───

class QueryFilter {
  final String field;
  final FilterOp operator;
  final dynamic value;

  const QueryFilter({
    required this.field,
    required this.operator,
    required this.value,
  });
}

enum FilterOp {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  arrayContains,
  whereIn,
}

class BatchOperation {
  final BatchOpType type;
  final String collection;
  final String? documentId;
  final Map<String, dynamic> data;

  const BatchOperation({
    required this.type,
    required this.collection,
    this.documentId,
    this.data = const {},
  });
}

enum BatchOpType { set, update, delete }
