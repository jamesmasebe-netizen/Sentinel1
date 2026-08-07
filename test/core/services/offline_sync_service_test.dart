// Tests for OfflineSyncService (lib/core/services/offline_sync_service.dart) — the offline-first
// write queue every FirestoreService.createDocument/updateDocument/deleteDocument call routes
// through, and the one piece of real logic `settings`' offline_queue_screen.dart/
// offline_queue_widgets.dart depend on (the `settings` feature directory itself has no
// services/providers of its own, same shape T3-AUTH found for `core/services/auth_service.dart`).
//
// Connectivity is mocked via connectivity_plus's documented ConnectivityPlatform test seam (same
// pattern as T2-BILLING's UrlLauncherPlatform mock) rather than skipped. Hive is backed by a real
// temp-directory box (Hive.init, not Hive.initFlutter — the latter needs path_provider's platform
// channel, the former is pure dart:io and needs no plugin mocking).
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';

class MockConnectivityPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements ConnectivityPlatform {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(<String, dynamic>{});
    final mockConnectivity = MockConnectivityPlatform();
    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => const Stream.empty());
    ConnectivityPlatform.instance = mockConnectivity;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('offline_sync_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('QueuedOperation serialization', () {
    test('toJson/fromJson round-trips every field exactly', () {
      final original = QueuedOperation(
        id: 'op-1',
        operation: OfflineOperation.update,
        collection: 'tenants/t1/incidents',
        documentId: 'doc-1',
        data: {'status': 'Closed'},
        timestamp: DateTime.parse('2026-01-01T00:00:00.000Z'),
        status: QueueItemStatus.failed,
        retryCount: 3,
        lastError: 'permission-denied',
      );

      final restored = QueuedOperation.fromJson(original.toJson());

      expect(restored.id, 'op-1');
      expect(restored.operation, OfflineOperation.update);
      expect(restored.collection, 'tenants/t1/incidents');
      expect(restored.documentId, 'doc-1');
      expect(restored.data, {'status': 'Closed'});
      expect(restored.timestamp, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(restored.status, QueueItemStatus.failed);
      expect(restored.retryCount, 3);
      expect(restored.lastError, 'permission-denied');
    });

    test('copyWith only overrides status/retryCount/lastError, keeping everything else', () {
      final original = QueuedOperation(
        id: 'op-1',
        operation: OfflineOperation.create,
        collection: 'tenants/t1/incidents',
        data: const {'a': 1},
        timestamp: DateTime.parse('2026-01-01T00:00:00.000Z'),
        status: QueueItemStatus.pending,
        retryCount: 0,
      );

      final updated = original.copyWith(status: QueueItemStatus.syncing, retryCount: 1);

      expect(updated.id, original.id);
      expect(updated.collection, original.collection);
      expect(updated.data, original.data);
      expect(updated.status, QueueItemStatus.syncing);
      expect(updated.retryCount, 1);
    });
  });

  group('cacheData / getCachedData', () {
    test('round-trips cached data through the local Hive box', () async {
      final service = OfflineSyncService(FakeFirebaseFirestore());
      await service.initialize();

      await service.cacheData('dashboard-summary', {'openIncidents': 4});

      expect(service.getCachedData('dashboard-summary'), {'openIncidents': 4});
    });

    test('returns null for a key that was never cached', () async {
      final service = OfflineSyncService(FakeFirebaseFirestore());
      await service.initialize();

      expect(service.getCachedData('never-cached'), isNull);
    });
  });

  group('queue lifecycle', () {
    test('a successfully-synced operation is removed from the queue and actually written to Firestore',
        () async {
      final firestore = FakeFirebaseFirestore();
      final service = OfflineSyncService(firestore);
      await service.initialize();

      await service.queueOperation(
        operation: OfflineOperation.create,
        collection: 'tenants/t1/incidents',
        data: {'title': 'Spill reported'},
      );
      // The immediate sync attempt inside queueOperation is fire-and-forget; give the event loop
      // a turn to let the fake_cloud_firestore write (and the queue-box delete that follows it)
      // actually complete before asserting.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(service.getPendingOperations(), isEmpty);
      final written = await firestore.collection('tenants/t1/incidents').get();
      expect(written.docs, hasLength(1));
      expect(written.docs.single.data()['title'], 'Spill reported');
    });

    test('a create that keeps failing is marked failed after 5 retries, retryOperation resets it, removeOperation deletes it',
        () async {
      final firestore = MockFirebaseFirestore();
      when(() => firestore.collection(any())).thenThrow(Exception('offline'));

      final service = OfflineSyncService(firestore);
      await service.initialize();

      final id = await service.queueOperation(
        operation: OfflineOperation.create,
        collection: 'tenants/t1/incidents',
        data: {'title': 'Never syncs'},
      );
      // queueOperation's own immediate sync attempt is fire-and-forget; let it fail once before
      // driving explicit retries, so the loop below isn't racing an in-flight hidden attempt.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Drive failed sync sweeps (retrySync is the same public entry point the "Retry" button in
      // SyncStatusHeader calls) well past the failed threshold (status flips to `failed` only once
      // retryCount was already >= 5 going into an attempt, i.e. on the 6th+ failure) — loop
      // generously rather than pinning the exact boundary, and assert the resulting range below.
      for (var i = 0; i < 8; i++) {
        service.retrySync();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      final failedOp = service.getPendingOperations().singleWhere((o) => o.id == id);
      expect(failedOp.status, QueueItemStatus.failed);
      expect(failedOp.retryCount, greaterThanOrEqualTo(5));
      expect(failedOp.lastError, contains('offline'));

      await service.retryOperation(id);
      // retryOperation resets status/retryCount then immediately re-attempts sync, which will
      // fail again (same broken mock) and land back on pending (first failure, count 1) rather
      // than failed — assert the reset took effect before that next sweep re-increments it.
      final afterRetry = service.getPendingOperations().singleWhere((o) => o.id == id);
      expect(afterRetry.retryCount, lessThan(5));
      // Let retryOperation's own fire-and-forget re-sync attempt (which will fail again against
      // the same broken mock) finish before removing — otherwise its delayed catch-block write
      // can land after removeOperation's delete and resurrect the entry.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await service.removeOperation(id);
      expect(service.getPendingOperations().where((o) => o.id == id), isEmpty);
    });
  });
}
