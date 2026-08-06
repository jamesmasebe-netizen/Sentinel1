// Tests for SafetyService.createCapa's default-field-filling behavior:
// status/createdBy/createdById/siteId/tenantId/createdAt fall back to the
// service's own _userId/_tenantId (or 'Open'/now()) only when the caller's
// data map doesn't already supply them.
//
// Constructed via safetyServiceProvider (per TEST_STRATEGY.md's Riverpod
// override convention) rather than `SafetyService(...)` directly — its
// constructor deps (FirestoreService, tenantId, userId) come from
// firestoreServiceProvider/currentTenantIdProvider/userProfileProvider, so
// those are what get overridden, letting safetyServiceProvider's own
// construction logic run for real.
//
// A real finding worth flagging: FirestoreService.createDocument does NOT
// write directly to Firestore. It calls OfflineSyncService.queueOperation,
// which writes to a local Hive queue box and only fires an unawaited
// _syncPendingOperations() in the background — so a fresh
// fake_cloud_firestore instance would show *nothing* at
// tenants/{tenantId}/capas right after createCapa() resolves; the returned
// "docRef" is actually the local queue item's id (a millisecond timestamp
// string), not a Firestore document id. OfflineSyncService also needs Hive
// boxes opened via initialize() before its queue can be touched at all, so
// it's mocked here (mocktail) rather than exercised for real — Hive/offline
// sync is its own component, out of scope for a SafetyService test.
//
// What *is* real and Firestore-backed here: FirestoreService.createDocument
// unconditionally calls AuditLogService.logAction first, which writes a real
// document to tenants/{tenantId}/audit_logs via fake_cloud_firestore, whose
// `metadata.data` field is the exact capaData map SafetyService.createCapa
// built. That's used as a second, independent verification path alongside
// the mocktail-captured argument to OfflineSyncService.queueOperation.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/models/user_profile.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/safety/services/safety_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';
const _userId = 'user-1';

void main() {
  setUpAll(() {
    registerFallbackValue(OfflineOperation.create);
    registerFallbackValue(<String, dynamic>{});
  });

  late FakeFirebaseFirestore db;
  late MockOfflineSyncService offlineSync;
  late ProviderContainer container;

  setUp(() async {
    db = FakeFirebaseFirestore();
    offlineSync = MockOfflineSyncService();
    when(() => offlineSync.queueOperation(
          operation: any(named: 'operation'),
          collection: any(named: 'collection'),
          data: any(named: 'data'),
          documentId: any(named: 'documentId'),
        )).thenAnswer((_) async => 'queued-op-1');

    container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(db),
      offlineSyncServiceProvider.overrideWithValue(offlineSync),
      currentTenantIdProvider.overrideWithValue(_tenantId),
      userProfileProvider.overrideWith((ref) => Stream.value(
            const UserProfile(
              uid: _userId,
              email: 'user1@sentinel.test',
              displayName: 'Test User',
              role: 'safety_manager',
              tenantId: _tenantId,
            ),
          )),
    ]);
    addTearDown(container.dispose);

    // safetyServiceProvider reads userProfileProvider synchronously via
    // ref.read(...).valueOrNull, so the StreamProvider's first value must
    // already be delivered before container.read(safetyServiceProvider).
    await container.read(userProfileProvider.future);
  });

  SafetyService service() => container.read(safetyServiceProvider);

  /// Captures the args OfflineSyncService.queueOperation was called with,
  /// in verify-call source order: [operation, collection, data, documentId].
  List<dynamic> capturedQueueArgs() {
    return verify(() => offlineSync.queueOperation(
          operation: captureAny(named: 'operation'),
          collection: captureAny(named: 'collection'),
          data: captureAny(named: 'data'),
          documentId: captureAny(named: 'documentId'),
        )).captured;
  }

  /// Reads back the single CREATE audit-log entry FirestoreService.
  /// createDocument writes for real (not mocked) via fake_cloud_firestore,
  /// and returns its logged `data` map — an independent check on the same
  /// capaData the mocked queueOperation call also received.
  Future<Map<String, dynamic>> readLoggedCapaData() async {
    final snap = await db
        .collection('tenants')
        .doc(_tenantId)
        .collection('audit_logs')
        .where('action', isEqualTo: 'CREATE')
        .get();
    expect(snap.docs, hasLength(1));
    final metadata = snap.docs.single.data()['metadata'] as Map<String, dynamic>;
    expect(metadata['collection'], 'tenants/$_tenantId/capas');
    return Map<String, dynamic>.from(metadata['data'] as Map);
  }

  group('createCapa — all defaults (caller omits every default-able field)', () {
    test('fills status/createdBy/createdById/siteId/tenantId/createdAt from '
        "the service's own userId/tenantId, and preserves caller fields",
        () async {
      final docId = await service().createCapa({
        'title': 'Fix guardrail',
        'incidentId': 'INC-1',
      });

      expect(docId, 'queued-op-1');

      final args = capturedQueueArgs();
      expect(args[0], OfflineOperation.create);
      expect(args[1], 'tenants/$_tenantId/capas');
      final capaData = args[2] as Map<String, dynamic>;

      expect(capaData['title'], 'Fix guardrail');
      expect(capaData['incidentId'], 'INC-1');
      expect(capaData['status'], 'Open');
      expect(capaData['createdBy'], _userId);
      expect(capaData['createdById'], _userId);
      expect(capaData['siteId'], _tenantId);
      expect(capaData['tenantId'], _tenantId);

      final createdAt = DateTime.parse(capaData['createdAt'] as String);
      expect(DateTime.now().difference(createdAt).inSeconds.abs(), lessThan(5),
          reason: 'createdAt should default to roughly DateTime.now()');

      // Independent cross-check via the real Firestore-backed audit log.
      final logged = await readLoggedCapaData();
      expect(logged['status'], 'Open');
      expect(logged['createdBy'], _userId);
      expect(logged['createdById'], _userId);
      expect(logged['siteId'], _tenantId);
      expect(logged['tenantId'], _tenantId);
    });
  });

  group('createCapa — caller supplies everything', () {
    test('does not override any caller-supplied default-able field',
        () async {
      final callerData = {
        'title': 'Pre-filled CAPA',
        'status': 'Closed',
        'createdBy': 'other-user@site.test',
        'createdById': 'other-user-id',
        'siteId': 'other-site',
        'tenantId': 'other-tenant-in-doc',
        'createdAt': '2020-01-01T00:00:00.000',
      };

      await service().createCapa(callerData);

      final args = capturedQueueArgs();
      final capaData = args[2] as Map<String, dynamic>;

      expect(capaData['status'], 'Closed');
      expect(capaData['createdBy'], 'other-user@site.test');
      expect(capaData['createdById'], 'other-user-id');
      expect(capaData['siteId'], 'other-site');
      expect(capaData['tenantId'], 'other-tenant-in-doc');
      expect(capaData['createdAt'], '2020-01-01T00:00:00.000');

      // The Firestore *path* createDocument writes to always uses the
      // service's own tenantId (the tenantId param, not data['tenantId']) —
      // a caller-supplied data['tenantId'] only affects the document body,
      // never which tenant's collection it lands in.
      expect(args[1], 'tenants/$_tenantId/capas');

      final logged = await readLoggedCapaData();
      expect(logged['status'], 'Closed');
      expect(logged['tenantId'], 'other-tenant-in-doc');
    });
  });
}
