// Tests for EmergencyService's `emergency_contacts` methods (lib/features/emergency/services/
// emergency_service.dart), extracted from EmergencyContactFormCard/EmergencyContactsTab's
// previously-inline Firestore calls, including the tab's `_seedDefaults` loop (now
// `seedDefaultContacts`) (Wave 2b, 2026-08-06). Unlike `emergency_drills`/`emergency_equipment`,
// this collection DOES carry a `siteId` field and `streamContacts()` filters on it, preserved
// exactly as the previous inline query did.
//
// FIXED 2026-08-06: createContact (and therefore seedDefaultContacts, which calls it 4 times) now
// routes through FirestoreService.createDocument (offline-queue + audit-log), not a direct
// Firestore write — see test/features/compliance/services/compliance_service_test.dart's header
// comment for the full story. Stream tests seed raw documents directly; seedDefaultContacts is
// verified via the 4 captured queue calls rather than reading Firestore back.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/emergency/models/emergency_contact.dart';
import 'package:sentinel1/features/emergency/services/emergency_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

EmergencyContact _buildContact({
  String id = '',
  String name = 'SHE Manager',
  String number = '082 000 0000',
  String authorId = 'author-1',
  String siteId = _tenantId,
}) {
  return EmergencyContact(
    id: id,
    name: name,
    number: number,
    authorId: authorId,
    siteId: siteId,
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

  Future<void> seedRawContact(EmergencyContact contact, {String tenantId = _tenantId}) async {
    await db
        .collection('tenants')
        .doc(tenantId)
        .collection('emergency_contacts')
        .add(contact.toFirestore());
  }

  group('createContact', () {
    test('queues the exact field shape EmergencyContactFormCard previously wrote inline, via the offline-first path',
        () async {
      await service.createContact(_buildContact(name: 'Site Security', number: '10111'));

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/emergency_contacts');
      final data = args[2] as Map<String, dynamic>;
      expect(data.keys.toSet(), {
        'name',
        'number',
        'authorId',
        'siteId',
        'createdAt',
      });
      expect(data['name'], 'Site Security');
      expect(data['number'], '10111');
      expect(data['siteId'], _tenantId);
      expect(data['createdAt'], isA<String>());
      expect(DateTime.tryParse(data['createdAt'] as String), isNotNull);
    });
  });

  group('streamContacts', () {
    test('returns only this tenant\'s contacts filtered by siteId, oldest first', () async {
      await seedRawContact(_buildContact(name: 'First Added'));
      await Future.delayed(const Duration(milliseconds: 5));
      await seedRawContact(_buildContact(name: 'Second Added'));
      // A contact at this tenant's path but with a mismatched siteId must be excluded — the
      // service filters on siteId in addition to the tenant-scoped path, same as the previous
      // inline query did.
      await seedRawContact(_buildContact(name: 'Wrong SiteId', siteId: 'some-other-site'));
      // A contact belonging to another tenant entirely must not leak in either.
      await seedRawContact(_buildContact(name: 'Other Tenant', siteId: _otherTenantId),
          tenantId: _otherTenantId);

      final contacts = await service.streamContacts().first;

      expect(contacts.map((c) => c.name), ['First Added', 'Second Added']);
    });
  });

  group('seedDefaultContacts', () {
    test('queues exactly 4 default contacts with the expected shape and values', () async {
      await service.seedDefaultContacts(authorId: 'author-42');

      final calls = verify(() => offlineSync.queueOperation(
            operation: captureAny(named: 'operation'),
            collection: captureAny(named: 'collection'),
            data: captureAny(named: 'data'),
            documentId: captureAny(named: 'documentId'),
          )).captured;
      // captured is a flat list of [operation, collection, data, documentId] per call.
      final dataMaps = <Map<String, dynamic>>[
        for (var i = 2; i < calls.length; i += 4) calls[i] as Map<String, dynamic>,
      ];
      expect(dataMaps, hasLength(4));

      final byName = {for (final d in dataMaps) d['name'] as String: d};
      expect(byName.keys.toSet(), {
        'Fire Department',
        'Ambulance / EMS',
        'Police / SAPS',
        'Poison Information',
      });
      expect(byName['Fire Department']!['number'], '10111');
      expect(byName['Ambulance / EMS']!['number'], '10177');
      expect(byName['Police / SAPS']!['number'], '10111');
      expect(byName['Poison Information']!['number'], '0800 111 990');

      for (final data in dataMaps) {
        expect(data.keys.toSet(), {'name', 'number', 'authorId', 'siteId', 'createdAt'});
        expect(data['authorId'], 'author-42');
        expect(data['siteId'], _tenantId);
        expect(data['createdAt'], isA<String>());
      }
    });

    test('seeded contacts are visible via streamContacts once actually persisted', () async {
      // seedDefaultContacts only queues (offline-first) — simulate the queue having synced by
      // seeding the same 4 contacts directly, proving streamContacts would surface them once
      // OfflineSyncService's real background sync has run.
      for (final c in EmergencyService.defaultContacts) {
        await seedRawContact(_buildContact(name: c['name']!, number: c['number']!, authorId: 'author-1'));
      }

      final contacts = await service.streamContacts().first;

      expect(contacts, hasLength(4));
      expect(contacts.map((c) => c.name), contains('Fire Department'));
    });
  });
}
