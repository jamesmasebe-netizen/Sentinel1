// Tests for HealthService (lib/features/health/services/health_service.dart) — hygiene_surveys
// coverage. Wave 2b service-layer extraction, mirroring compliance_service_test.dart's pattern.
// This collection had no field-shape bug (unlike first_aid_logs) — this file just verifies the
// extraction preserves exact prior behavior: field shapes, siteId filter, ordering.
//
// FIXED 2026-08-06: createHygieneSurvey now routes through FirestoreService.createDocument
// (offline-queue + audit-log), not a direct Firestore write — see compliance_service_test.dart's
// header comment for the full story. Stream tests seed raw documents directly.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/health/models/hygiene_survey.dart';
import 'package:sentinel1/features/health/services/health_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

HygieneSurvey _buildSurvey({
  String id = '',
  String zoneName = 'Welding Bay 3',
  String location = 'Workshop B',
  String hazardType = 'Noise',
  String readingValue = '92',
  String legalLimit = '85',
  int samplesTaken = 3,
  bool requiresMedicalSurveillance = false,
  DateTime? dateConducted,
  String siteId = _tenantId,
}) {
  return HygieneSurvey(
    id: id,
    zoneName: zoneName,
    location: location,
    hazardType: hazardType,
    readingValue: readingValue,
    legalLimit: legalLimit,
    samplesTaken: samplesTaken,
    requiresMedicalSurveillance: requiresMedicalSurveillance,
    dateConducted: dateConducted ?? DateTime.now(),
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

  Future<void> seedRawSurvey(HygieneSurvey survey, {String tenantId = _tenantId}) async {
    await db.collection('tenants').doc(tenantId).collection('hygiene_surveys').add(survey.toFirestore());
  }

  group('createHygieneSurvey', () {
    test('queues the exact field shape HygieneForm previously wrote inline, via the offline-first path',
        () async {
      await service.createHygieneSurvey(_buildSurvey(
        zoneName: 'Paint Booth',
        hazardType: 'Chemical',
        readingValue: '15',
        legalLimit: '10',
        requiresMedicalSurveillance: true,
      ));

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/hygiene_surveys');
      final data = args[2] as Map<String, dynamic>;
      expect(data.keys.toSet(), {
        'zoneName',
        'location',
        'hazardType',
        'readingValue',
        'legalLimit',
        'samplesTaken',
        'requiresMedicalSurveillance',
        'dateConducted',
        'authorId',
        'siteId',
        'createdAt',
      });
      expect(data['zoneName'], 'Paint Booth');
      expect(data['hazardType'], 'Chemical');
      // readingValue/legalLimit stay raw String, matching HygieneForm's un-parsed text write.
      expect(data['readingValue'], isA<String>());
      expect(data['readingValue'], '15');
      expect(data['legalLimit'], '10');
      expect(data['requiresMedicalSurveillance'], true);
      expect(data['dateConducted'], isA<String>());
      expect(DateTime.tryParse(data['dateConducted'] as String), isNotNull);
    });
  });

  group('streamHygieneSurveys', () {
    test('returns only this tenant\'s surveys, newest first', () async {
      await seedRawSurvey(_buildSurvey(zoneName: 'Older Survey'));
      await Future.delayed(const Duration(milliseconds: 5));
      await seedRawSurvey(_buildSurvey(zoneName: 'Newer Survey'));
      await seedRawSurvey(_buildSurvey(zoneName: 'Other Tenant Survey', siteId: _otherTenantId),
          tenantId: _otherTenantId);

      final surveys = await service.streamHygieneSurveys().first;

      expect(surveys.map((s) => s.zoneName), ['Newer Survey', 'Older Survey']);
    });

    test('a legacy document missing legalLimit falls back to "100", not "0"', () async {
      // Preserves HygieneListItem's previous `data['legalLimit'] ?? "100"` fallback — a missing
      // field must not be misread as a 0 legal limit, which would falsely flag every reading as
      // over threshold.
      await db.collection('tenants').doc(_tenantId).collection('hygiene_surveys').add({
        'zoneName': 'Legacy Zone',
        'hazardType': 'Dust',
        'readingValue': '5',
        'siteId': _tenantId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      final surveys = await service.streamHygieneSurveys().first;

      expect(surveys.single.legalLimit, '100');
    });
  });
}
