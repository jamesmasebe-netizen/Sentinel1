import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Offline-first sync service
/// All writes go to local queue first, then sync to Firestore when online.
/// "No one can come back to say they didn't have network."
class OfflineSyncService {
  static const String _queueBoxName = 'offline_queue';
  static const String _cacheBoxName = 'data_cache';

  late Box<String> _queueBox;
  late Box<String> _cacheBox;
  final FirebaseFirestore _firestore;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;

  // Stream controllers for UI updates
  final _pendingCountController = StreamController<int>.broadcast();
  final _syncStatusController = StreamController<SyncStatus>.broadcast();

  Stream<int> get pendingCount => _pendingCountController.stream;
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  OfflineSyncService(this._firestore);

  /// Initialize offline storage and connectivity listener
  Future<void> initialize() async {
    _queueBox = await Hive.openBox<String>(_queueBoxName);
    _cacheBox = await Hive.openBox<String>(_cacheBoxName);

    // Listen for connectivity changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        _syncPendingOperations();
      }
      _updateStatus();
    });

    // Initial sync attempt
    _syncPendingOperations();
    _updateStatus();
  }

  /// Queue a write operation for offline-first processing
  Future<String> queueOperation({
    required OfflineOperation operation,
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    final queueItem = QueuedOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operation: operation,
      collection: collection,
      documentId: documentId,
      data: data,
      timestamp: DateTime.now(),
      status: QueueItemStatus.pending,
      retryCount: 0,
    );

    await _queueBox.put(queueItem.id, jsonEncode(queueItem.toJson()));
    _updateStatus();

    // Try immediate sync
    _syncPendingOperations();

    return queueItem.id;
  }

  /// Sync all pending operations to Firestore
  Future<void> _syncPendingOperations() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    final keys = _queueBox.keys.toList();

    for (final key in keys) {
      final json = _queueBox.get(key);
      if (json == null) continue;

      final item = QueuedOperation.fromJson(jsonDecode(json));
      if (item.status == QueueItemStatus.completed) {
        await _queueBox.delete(key);
        continue;
      }

      try {
        await _executeOperation(item);
        await _queueBox.delete(key);
      } catch (e) {
        // Update retry count
        final updated = item.copyWith(
          retryCount: item.retryCount + 1,
          status: item.retryCount >= 5
              ? QueueItemStatus.failed
              : QueueItemStatus.pending,
          lastError: e.toString(),
        );
        await _queueBox.put(key, jsonEncode(updated.toJson()));
      }
    }

    _isSyncing = false;
    _updateStatus();
  }

  /// Public method to manually retry syncing all pending operations.
  void retrySync() {
    _syncPendingOperations();
  }

  /// Execute a single queued operation against Firestore
  Future<void> _executeOperation(QueuedOperation item) async {
    switch (item.operation) {
      case OfflineOperation.create:
        if (item.documentId != null) {
          await _firestore
              .collection(item.collection)
              .doc(item.documentId)
              .set(item.data);
        } else {
          await _firestore.collection(item.collection).add(item.data);
        }
        break;
      case OfflineOperation.update:
        if (item.documentId == null) throw Exception('Document ID required for update');
        await _firestore
            .collection(item.collection)
            .doc(item.documentId)
            .update(item.data);
        break;
      case OfflineOperation.delete:
        if (item.documentId == null) throw Exception('Document ID required for delete');
        await _firestore
            .collection(item.collection)
            .doc(item.documentId)
            .delete();
        break;
    }
  }

  /// Cache data locally for offline reads
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    await _cacheBox.put(key, jsonEncode(data));
  }

  /// Read cached data
  Map<String, dynamic>? getCachedData(String key) {
    final json = _cacheBox.get(key);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  /// Get list of pending operations for the UI queue viewer
  List<QueuedOperation> getPendingOperations() {
    return _queueBox.values
        .map((json) => QueuedOperation.fromJson(jsonDecode(json)))
        .where((op) => op.status != QueueItemStatus.completed)
        .toList();
  }

  /// Retry a specific failed operation
  Future<void> retryOperation(String operationId) async {
    final json = _queueBox.get(operationId);
    if (json == null) return;

    final item = QueuedOperation.fromJson(jsonDecode(json));
    final updated = item.copyWith(
      status: QueueItemStatus.pending,
      retryCount: 0,
    );
    await _queueBox.put(operationId, jsonEncode(updated.toJson()));
    _syncPendingOperations();
  }

  /// Delete a failed operation from the queue
  Future<void> removeOperation(String operationId) async {
    await _queueBox.delete(operationId);
    _updateStatus();
  }

  void _updateStatus() {
    final pending = getPendingOperations();
    final pendingCount = pending.where((op) => op.status == QueueItemStatus.pending).length;
    final failedCount = pending.where((op) => op.status == QueueItemStatus.failed).length;

    _pendingCountController.add(pendingCount + failedCount);

    if (pendingCount == 0 && failedCount == 0) {
      _syncStatusController.add(SyncStatus.synced);
    } else if (failedCount > 0) {
      _syncStatusController.add(SyncStatus.error);
    } else {
      _syncStatusController.add(SyncStatus.pending);
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _pendingCountController.close();
    _syncStatusController.close();
  }
}

// ─── Enums & Data Classes ───

enum OfflineOperation { create, update, delete }
enum QueueItemStatus { pending, syncing, completed, failed }
enum SyncStatus { synced, syncing, pending, error }

class QueuedOperation {
  final String id;
  final OfflineOperation operation;
  final String collection;
  final String? documentId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final QueueItemStatus status;
  final int retryCount;
  final String? lastError;

  const QueuedOperation({
    required this.id,
    required this.operation,
    required this.collection,
    this.documentId,
    required this.data,
    required this.timestamp,
    required this.status,
    required this.retryCount,
    this.lastError,
  });

  factory QueuedOperation.fromJson(Map<String, dynamic> json) => QueuedOperation(
    id: json['id'],
    operation: OfflineOperation.values.firstWhere((e) => e.name == json['operation']),
    collection: json['collection'],
    documentId: json['documentId'],
    data: Map<String, dynamic>.from(json['data']),
    timestamp: DateTime.parse(json['timestamp']),
    status: QueueItemStatus.values.firstWhere((e) => e.name == json['status']),
    retryCount: json['retryCount'] ?? 0,
    lastError: json['lastError'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'operation': operation.name,
    'collection': collection,
    'documentId': documentId,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
    'retryCount': retryCount,
    'lastError': lastError,
  };

  QueuedOperation copyWith({
    QueueItemStatus? status,
    int? retryCount,
    String? lastError,
  }) => QueuedOperation(
    id: id,
    operation: operation,
    collection: collection,
    documentId: documentId,
    data: data,
    timestamp: timestamp,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError ?? this.lastError,
  );
}
