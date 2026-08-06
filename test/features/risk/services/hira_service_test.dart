// Tests for HiraService.createAssessment (lib/features/risk/services/hira_service.dart) — one of
// the 4 focused services extracted from the risk module's previously-inline Firestore calls
// (Wave 2b, 2026-08-06), built around the existing (and, until this pass, unused/broken)
// `RiskAssessment` model in lib/core/models/safety_models.dart. See hira_service_stream_test.dart
// for streamAssessments/streamAllAssessments coverage, split out to respect the 200-line file
// threshold (AGENTS.md §4).
//
// createAssessment() routes through FirestoreService.createDocument (offline-queue + audit-log),
// not a direct write — mirrors ComplianceService.createDocument's fix (this module's reference
// pattern) for the same real bug: hira_form.dart's original code called
// `firestoreServiceProvider.createDocument(...)`, and a direct-write service would have silently
// dropped both the offline queue and the audit trail.
//
// Includes the regression-guard test for the HIRA field-name bug fix: `hira_card.dart` and
// `hira_screen.dart`'s detail dialog used to read `riskLevel`/`riskScore` — fields
// `hira_form.dart` never wrote — so every card permanently showed "LOW"/"0". The fix reads
// `riskRating`/`inherentRiskScore` instead, the fields the writer actually populates.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/models/safety_models.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/risk/services/hira_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';

RiskAssessment _buildAssessment({
  String title = 'Working at Heights',
  String hazard = 'Fall from scaffold',
  int inherentRiskScore = 12,
  String riskRating = 'High',
  String siteId = _tenantId,
}) {
  return RiskAssessment(
    siteId: siteId,
    title: title,
    description: hazard,
    hazard: hazard,
    consequence: 'Serious injury',
    likelihood: 'Possible',
    severity: 'Major',
    inherentRiskScore: inherentRiskScore,
    riskRating: riskRating,
    controlMeasure: 'Engineering Controls',
    residualRiskLevel: 'Medium',
    teamMembers: const ['emp-1', 'emp-2'],
    approverId: 'emp-approver',
    reviewDate: DateTime(2027, 1, 1),
    status: 'active',
    assessorId: 'user-1',
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
  late HiraService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    offlineSync = MockOfflineSyncService();
    when(
      () => offlineSync.queueOperation(
        operation: any(named: 'operation'),
        collection: any(named: 'collection'),
        data: any(named: 'data'),
        documentId: any(named: 'documentId'),
      ),
    ).thenAnswer((_) async => 'queued-op-1');

    container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        offlineSyncServiceProvider.overrideWithValue(offlineSync),
        currentTenantIdProvider.overrideWithValue(_tenantId),
      ],
    );
    addTearDown(container.dispose);
    service = container.read(hiraServiceProvider);
  });

  List<dynamic> capturedQueueArgs() {
    return verify(
      () => offlineSync.queueOperation(
        operation: captureAny(named: 'operation'),
        collection: captureAny(named: 'collection'),
        data: captureAny(named: 'data'),
        documentId: captureAny(named: 'documentId'),
      ),
    ).captured;
  }

  group('createAssessment', () {
    test('queues the exact field shape hira_form.dart previously wrote inline', () async {
      await service.createAssessment(_buildAssessment());

      final args = capturedQueueArgs();
      expect(args[0], OfflineOperation.create);
      expect(args[1], 'tenants/$_tenantId/risk_assessments');
      final data = args[2] as Map<String, dynamic>;

      expect(data.keys.toSet(), {
        'siteId',
        'type',
        'title',
        'description',
        'hazard',
        'consequence',
        'likelihood',
        'severity',
        'inherentRiskScore',
        'riskRating',
        'controlMeasure',
        'residualRiskLevel',
        'teamMembers',
        'approverId',
        'reviewDate',
        'status',
        'assessedBy',
        'createdAt',
      });
      expect(data['type'], 'hira');
      expect(data['inherentRiskScore'], 12);
      expect(data['riskRating'], 'High');
      // assessedBy, not assessorId — the real key hira_form.dart writes.
      expect(data['assessedBy'], 'user-1');
      expect(data['reviewDate'], isA<String>());
    });

    test('also writes a real CREATE audit-log entry with the same data', () async {
      await service.createAssessment(_buildAssessment(title: 'Audited HIRA'));

      final snap =
          await db
              .collection('tenants')
              .doc(_tenantId)
              .collection('audit_logs')
              .where('action', isEqualTo: 'CREATE')
              .get();
      expect(snap.docs, hasLength(1));
      final metadata = snap.docs.single.data()['metadata'] as Map<String, dynamic>;
      expect(metadata['collection'], 'tenants/$_tenantId/risk_assessments');
      expect((metadata['data'] as Map)['title'], 'Audited HIRA');
    });

    test('regression guard: queued data matches the field names hira_card.dart now reads', () async {
      // Direct regression test for the F-306-class bug fix: hira_card.dart/hira_screen.dart used
      // to read the never-written `riskLevel`/`riskScore` keys.
      await service.createAssessment(
        _buildAssessment(riskRating: 'Extreme', inherentRiskScore: 20),
      );

      final data = capturedQueueArgs()[2] as Map<String, dynamic>;
      expect(data.containsKey('riskLevel'), isFalse);
      expect(data.containsKey('riskScore'), isFalse);
      expect(data['riskRating'], 'Extreme');
      expect(data['inherentRiskScore'], 20);
    });
  });
}
