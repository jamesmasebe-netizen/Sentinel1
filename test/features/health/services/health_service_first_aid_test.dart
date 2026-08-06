// Tests for HealthService (lib/features/health/services/health_service.dart) — first_aid_logs
// coverage. Wave 2b service-layer extraction, mirroring compliance_service_test.dart's pattern
// (see docs/testing/TEST_STRATEGY.md §3 for the ProviderContainer/override convention).
//
// FIXED 2026-08-06: createFirstAidEntry now routes through FirestoreService.createDocument
// (offline-queue + audit-log), not a direct Firestore write — see compliance_service_test.dart's
// header comment for the full story of why. Stream tests below seed raw documents directly
// (bypassing the service) since createFirstAidEntry no longer writes to Firestore synchronously.
//
// Includes the regression-guard test for the real bug fixed as part of this extraction (same
// class as FIX_LIST.md's F-306, a reader expecting a field the writer never populated):
// FirstAidListItem read `data['employeeName']`, but FirstAidForm only ever wrote `patientId` (a
// raw employee id) — every First Aid log entry displayed "Unknown" regardless of who the
// patient actually was. FirstAidForm now resolves the patient's name from the same
// EmployeeSelector-backed employee list already used to pick `patientId`, and writes it as
// `employeeName` at create time (matching how medical_records already does this).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/health/models/first_aid_entry.dart';
import 'package:sentinel1/features/health/services/health_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

FirstAidEntry _buildEntry({
  String id = '',
  String patientId = 'emp-1',
  String employeeName = 'Alice Smith',
  String firstAiderId = 'emp-2',
  String description = 'Minor cut on hand',
  String treatment = 'Cleaned and bandaged',
  String actionTaken = 'Returned to work',
  bool referredToMedical = false,
  DateTime? date,
  String siteId = _tenantId,
}) {
  return FirstAidEntry(
    id: id,
    patientId: patientId,
    employeeName: employeeName,
    firstAiderId: firstAiderId,
    description: description,
    treatment: treatment,
    actionTaken: actionTaken,
    referredToMedical: referredToMedical,
    date: date ?? DateTime.now(),
    authorId: 'author-1',
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
  late HealthService service;

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
    service = container.read(healthServiceProvider);
  });

  List<dynamic> capturedQueueArgs() {
    return verify(() => offlineSync.queueOperation(
          operation: captureAny(named: 'operation'),
          collection: captureAny(named: 'collection'),
          data: captureAny(named: 'data'),
          documentId: captureAny(named: 'documentId'),
        )).captured;
  }

  Future<void> seedRawEntry(FirstAidEntry entry, {String tenantId = _tenantId}) async {
    await db.collection('tenants').doc(tenantId).collection('first_aid_logs').add(entry.toFirestore());
  }

  group('createFirstAidEntry', () {
    test('queues the exact field shape FirstAidForm previously wrote inline, via the offline-first path',
        () async {
      await service.createFirstAidEntry(_buildEntry(
        description: 'Twisted ankle on stairwell',
        treatment: 'Ice pack applied, elevated',
      ));

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/first_aid_logs');
      final data = args[2] as Map<String, dynamic>;
      expect(data.keys.toSet(), {
        'patientId',
        'employeeName',
        'firstAiderId',
        'description',
        'treatment',
        'actionTaken',
        'referredToMedical',
        'date',
        'authorId',
        'siteId',
        'createdAt',
      });
      expect(data['description'], 'Twisted ankle on stairwell');
      expect(data['treatment'], 'Ice pack applied, elevated');
      // Dates are ISO8601 strings, not Timestamps — matching existing on-disk data.
      expect(data['date'], isA<String>());
      expect(DateTime.tryParse(data['date'] as String), isNotNull);
    });

    test(
        'REGRESSION GUARD: the queued entry carries a real, non-empty employeeName — not just '
        'the raw patientId (the bug fixed in this extraction)', () async {
      await service.createFirstAidEntry(_buildEntry(
        patientId: 'emp-77',
        employeeName: 'Bongani Dlamini',
      ));

      final data = capturedQueueArgs()[2] as Map<String, dynamic>;
      expect(data['patientId'], 'emp-77');
      expect(data['employeeName'], 'Bongani Dlamini');
      expect(data['employeeName'], isNot(isEmpty));
      expect(data['employeeName'], isNot(equals(data['patientId'])));
    });
  });

  group('streamFirstAidLog', () {
    test('returns only this tenant\'s entries, newest first', () async {
      await seedRawEntry(_buildEntry(description: 'Older Entry'));
      await Future.delayed(const Duration(milliseconds: 5));
      await seedRawEntry(_buildEntry(description: 'Newer Entry'));
      await seedRawEntry(_buildEntry(description: 'Other Tenant Entry', siteId: _otherTenantId),
          tenantId: _otherTenantId);

      final entries = await service.streamFirstAidLog().first;

      expect(entries.map((e) => e.description), ['Newer Entry', 'Older Entry']);
    });

    test('surfaces a real employeeName for a newly-shaped entry (not "Unknown")', () async {
      await seedRawEntry(_buildEntry(patientId: 'emp-77', employeeName: 'Bongani Dlamini'));

      final entries = await service.streamFirstAidLog().first;

      expect(entries.single.employeeName, 'Bongani Dlamini');
      expect(entries.single.employeeName, isNot('Unknown'));
    });

    test('a legacy document missing employeeName falls back to "Unknown", not a crash', () async {
      // Simulates a pre-fix document written before this extraction shipped — proves
      // fromFirestore's fallback still degrades gracefully for old data, without masking the
      // fact that *new* writes now always populate the field.
      await db.collection('tenants').doc(_tenantId).collection('first_aid_logs').add({
        'patientId': 'emp-legacy',
        'firstAiderId': 'emp-2',
        'description': 'Legacy entry, no employeeName field',
        'siteId': _tenantId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      final entries = await service.streamFirstAidLog().first;

      expect(entries.single.employeeName, 'Unknown');
    });
  });
}
