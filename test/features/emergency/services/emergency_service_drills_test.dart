// Tests for EmergencyService's `emergency_drills` methods (lib/features/emergency/services/
// emergency_service.dart), extracted from DrillFormCard/EmergencyDrillsTab's previously-inline
// Firestore calls (Wave 2b, 2026-08-06). This collection has no `siteId` field at all — every
// document already lives at the tenant-scoped `tenants/{tenantId}/emergency_drills` path, so
// `streamDrills()` has no additional where-filter, unlike `emergency_contacts`.
//
// FIXED 2026-08-06: createDrill now routes through FirestoreService.createDocument (offline-queue
// + audit-log), not a direct Firestore write — see
// test/features/compliance/services/compliance_service_test.dart's header comment for the full
// story. Stream tests seed raw documents directly.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/emergency/models/emergency_drill.dart';
import 'package:sentinel1/features/emergency/services/emergency_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

EmergencyDrill _buildDrill({
  String id = '',
  String drillType = 'Fire',
  String dateConducted = '',
  int durationMinutes = 15,
  String evaluatorName = 'Jane Evaluator',
  String scenarioDescription = 'Building evacuation scenario',
  String areasForImprovement = 'Faster assembly point headcount',
  String authorId = 'author-1',
}) {
  return EmergencyDrill(
    id: id,
    drillType: drillType,
    dateConducted: dateConducted,
    durationMinutes: durationMinutes,
    evaluatorName: evaluatorName,
    scenarioDescription: scenarioDescription,
    areasForImprovement: areasForImprovement,
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

  Future<void> seedRawDrill(EmergencyDrill drill, {String tenantId = _tenantId}) async {
    await db.collection('tenants').doc(tenantId).collection('emergency_drills').add(drill.toFirestore());
  }

  group('createDrill', () {
    test('queues the exact field shape DrillFormCard previously wrote inline, via the offline-first path',
        () async {
      await service.createDrill(_buildDrill(
        drillType: 'Medical',
        durationMinutes: 30,
        evaluatorName: 'Dr. Smith',
        scenarioDescription: 'Cardiac arrest simulation',
        areasForImprovement: 'Quicker AED retrieval',
      ));

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/emergency_drills');
      final data = args[2] as Map<String, dynamic>;
      expect(data.keys.toSet(), {
        'drillType',
        'dateConducted',
        'durationMinutes',
        'evaluatorName',
        'scenarioDescription',
        'areasForImprovement',
        'authorId',
        'createdAt',
      });
      expect(data['drillType'], 'Medical');
      expect(data['durationMinutes'], 30);
      expect(data['evaluatorName'], 'Dr. Smith');
      expect(data['scenarioDescription'], 'Cardiac arrest simulation');
      expect(data['areasForImprovement'], 'Quicker AED retrieval');
      // createdAt is an ISO8601 string, not a Timestamp, matching every other module's convention.
      expect(data['createdAt'], isA<String>());
      expect(DateTime.tryParse(data['createdAt'] as String), isNotNull);
    });

    test('no siteId field is queued — this collection relies purely on the tenant-scoped path',
        () async {
      await service.createDrill(_buildDrill());

      final data = capturedQueueArgs()[2] as Map<String, dynamic>;
      expect(data.containsKey('siteId'), isFalse);
    });

    test('includes propertyId/propertyName when set (2026-08-12 multi-site addition)', () async {
      await service.createDrill(EmergencyDrill(
        id: '',
        drillType: 'Fire',
        authorId: 'author-1',
        propertyId: 'prop-1',
        propertyName: 'Warehouse B',
        createdAt: DateTime.now(),
      ));

      final data = capturedQueueArgs()[2] as Map<String, dynamic>;
      expect(data['propertyId'], 'prop-1');
      expect(data['propertyName'], 'Warehouse B');
    });
  });

  group('streamDrills', () {
    test('returns only this tenant\'s drills, newest first', () async {
      await seedRawDrill(_buildDrill(drillType: 'Fire'));
      await Future.delayed(const Duration(milliseconds: 5));
      await seedRawDrill(_buildDrill(drillType: 'Evacuation'));
      await seedRawDrill(_buildDrill(drillType: 'Security'), tenantId: _otherTenantId);

      final drills = await service.streamDrills().first;

      expect(drills.map((d) => d.drillType), ['Evacuation', 'Fire']);
    });
  });
}
