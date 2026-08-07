// Tests for EquipmentService (lib/features/equipment/services/equipment_service.dart).
// deployEquipment routes through FirestoreService.updateDocument (offline-first), same pattern
// established by safety_service_test.dart: mock OfflineSyncService, let the real
// fake_cloud_firestore-backed AuditLogService write for real as a second, independent check.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/services/audit_log_service.dart';
import 'package:sentinel1/core/services/firestore_service.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/equipment/services/equipment_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

void main() {
  const tenantId = 'tenant-equip-1';
  late FakeFirebaseFirestore firestore;
  late MockOfflineSyncService offlineSync;
  late EquipmentService service;

  setUpAll(() {
    registerFallbackValue(OfflineOperation.update);
  });

  setUp(() {
    firestore = FakeFirebaseFirestore();
    offlineSync = MockOfflineSyncService();
    when(() => offlineSync.queueOperation(
          operation: any(named: 'operation'),
          collection: any(named: 'collection'),
          data: any(named: 'data'),
          documentId: any(named: 'documentId'),
        )).thenAnswer((_) async => 'queued-id');

    final firestoreService = FirestoreService(firestore, offlineSync, AuditLogService(firestore));
    service = EquipmentService(firestoreService, tenantId);
  });

  test('deployEquipment queues an update with status Deployed and the assignee', () async {
    await service.deployEquipment('eq-1', 'emp-1');

    final captured = verify(() => offlineSync.queueOperation(
          operation: OfflineOperation.update,
          collection: captureAny(named: 'collection'),
          data: captureAny(named: 'data'),
          documentId: captureAny(named: 'documentId'),
        )).captured;
    expect(captured[1], {'status': 'Deployed', 'assignedToId': 'emp-1'});
    expect(captured[2], 'eq-1');
  });

  test('also writes a real CREATE audit-log entry with the same data', () async {
    await service.deployEquipment('eq-2', 'emp-2');

    final logs = await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('audit_logs')
        .get();
    expect(logs.docs, hasLength(1));
    expect(logs.docs.single.data()['action'], 'UPDATE');
    expect(logs.docs.single.data()['metadata']['documentId'], 'eq-2');
  });

  test('throws without queuing anything when there is no active tenant', () async {
    final noTenantService = EquipmentService(
      FirestoreService(firestore, offlineSync, AuditLogService(firestore)),
      null,
    );

    await expectLater(
      () => noTenantService.deployEquipment('eq-3', 'emp-3'),
      throwsException,
    );
    verifyNever(() => offlineSync.queueOperation(
          operation: any(named: 'operation'),
          collection: any(named: 'collection'),
          data: any(named: 'data'),
          documentId: any(named: 'documentId'),
        ));
  });
}
