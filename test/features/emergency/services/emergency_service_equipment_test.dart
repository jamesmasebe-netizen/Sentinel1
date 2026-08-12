// Tests for EmergencyService's `emergency_equipment` methods (lib/features/emergency/services/
// emergency_service.dart), extracted from EquipmentFormCard/EmergencyEquipmentTab's
// previously-inline Firestore calls (Wave 2b, 2026-08-06). Like `emergency_drills`, this
// collection has no `siteId` field — tenant scoping is purely via the Firestore path.
//
// FIXED 2026-08-06: createEquipment now routes through FirestoreService.createDocument
// (offline-queue + audit-log), not a direct Firestore write — see
// test/features/compliance/services/compliance_service_test.dart's header comment for the full
// story. Stream tests seed raw documents directly.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/emergency/models/emergency_equipment.dart';
import 'package:sentinel1/features/emergency/services/emergency_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

EmergencyEquipment _buildEquipment({
  String id = '',
  String equipmentType = 'Extinguisher',
  String location = 'Warehouse A - North Wall',
  String nextInspectionDate = '2026-12-01',
  String status = 'Operational',
  String authorId = 'author-1',
}) {
  return EmergencyEquipment(
    id: id,
    equipmentType: equipmentType,
    location: location,
    nextInspectionDate: nextInspectionDate,
    status: status,
    authorId: authorId,
    createdAt: DateTime.now(),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(OfflineOperation.create);
    registerFallbackValue(<String, dynamic>{});
  });

  late FakeFirebaseFirestore db;
  late MockOfflineSyncService offlineSync;
  late ProviderContainer container;
  late EmergencyService service;

  setUp(() {
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
    ]);
    addTearDown(container.dispose);
    service = container.read(emergencyServiceProvider);
  });

  List<dynamic> capturedQueueArgs() {
    return verify(() => offlineSync.queueOperation(
          operation: captureAny(named: 'operation'),
          collection: captureAny(named: 'collection'),
          data: captureAny(named: 'data'),
          documentId: captureAny(named: 'documentId'),
        )).captured;
  }

  Future<void> seedRawEquipment(EmergencyEquipment equipment, {String tenantId = _tenantId}) async {
    await db
        .collection('tenants')
        .doc(tenantId)
        .collection('emergency_equipment')
        .add(equipment.toFirestore());
  }

  group('createEquipment', () {
    test('queues the exact field shape EquipmentFormCard previously wrote inline, via the offline-first path',
        () async {
      await service.createEquipment(_buildEquipment(
        equipmentType: 'AED',
        location: 'Reception',
        nextInspectionDate: '2027-01-15',
        status: 'Needs Inspection',
      ));

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/emergency_equipment');
      final data = args[2] as Map<String, dynamic>;
      expect(data.keys.toSet(), {
        'equipmentType',
        'location',
        'nextInspectionDate',
        'status',
        'authorId',
        'createdAt',
      });
      expect(data['equipmentType'], 'AED');
      expect(data['location'], 'Reception');
      expect(data['nextInspectionDate'], '2027-01-15');
      expect(data['status'], 'Needs Inspection');
      expect(data['createdAt'], isA<String>());
      expect(DateTime.tryParse(data['createdAt'] as String), isNotNull);
    });

    test('no siteId field is queued — this collection relies purely on the tenant-scoped path',
        () async {
      await service.createEquipment(_buildEquipment());

      final data = capturedQueueArgs()[2] as Map<String, dynamic>;
      expect(data.containsKey('siteId'), isFalse);
    });

    test('includes propertyId/propertyName when set (2026-08-12 multi-site addition)', () async {
      await service.createEquipment(EmergencyEquipment(
        id: '',
        equipmentType: 'Extinguisher',
        status: 'Operational',
        authorId: 'author-1',
        propertyId: 'prop-1',
        propertyName: 'Main Site',
        createdAt: DateTime.now(),
      ));

      final data = capturedQueueArgs()[2] as Map<String, dynamic>;
      expect(data['propertyId'], 'prop-1');
      expect(data['propertyName'], 'Main Site');
    });
  });

  group('streamEquipment', () {
    test('returns only this tenant\'s equipment, newest first', () async {
      await seedRawEquipment(_buildEquipment(equipmentType: 'Extinguisher'));
      await Future.delayed(const Duration(milliseconds: 5));
      await seedRawEquipment(_buildEquipment(equipmentType: 'Spill Kit'));
      await seedRawEquipment(_buildEquipment(equipmentType: 'First Aid Kit'), tenantId: _otherTenantId);

      final equipment = await service.streamEquipment().first;

      expect(equipment.map((e) => e.equipmentType), ['Spill Kit', 'Extinguisher']);
    });
  });
}
