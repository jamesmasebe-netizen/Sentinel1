// Tests for HealthService (lib/features/health/services/health_service.dart) — hygiene_surveys
// coverage. Wave 2b service-layer extraction, mirroring compliance_service_test.dart's pattern.
// This collection had no field-shape bug (unlike first_aid_logs) — this file just verifies the
// extraction preserves exact prior behavior: field shapes, siteId filter, ordering.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/features/health/models/hygiene_survey.dart';
import 'package:sentinel1/features/health/services/health_service.dart';

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
  late FakeFirebaseFirestore db;
  late ProviderContainer container;
  late HealthService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(db),
      currentTenantIdProvider.overrideWithValue(_tenantId),
    ]);
    addTearDown(container.dispose);
    service = container.read(healthServiceProvider);
  });

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> rawDocs() async {
    final snap =
        await db.collection('tenants').doc(_tenantId).collection('hygiene_surveys').get();
    return snap.docs;
  }

  group('createHygieneSurvey', () {
    test('writes the exact field shape HygieneForm previously wrote inline', () async {
      await service.createHygieneSurvey(_buildSurvey(
        zoneName: 'Paint Booth',
        hazardType: 'Chemical',
        readingValue: '15',
        legalLimit: '10',
        requiresMedicalSurveillance: true,
      ));

      final docs = await rawDocs();
      expect(docs, hasLength(1));
      final data = docs.single.data();
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
      await service.createHygieneSurvey(_buildSurvey(zoneName: 'Older Survey'));
      await Future.delayed(const Duration(milliseconds: 5));
      await service.createHygieneSurvey(_buildSurvey(zoneName: 'Newer Survey'));
      await db
          .collection('tenants')
          .doc(_otherTenantId)
          .collection('hygiene_surveys')
          .add(_buildSurvey(zoneName: 'Other Tenant Survey', siteId: _otherTenantId)
              .toFirestore());

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
