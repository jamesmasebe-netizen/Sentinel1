// Tests for DraService.createAssessment + the legacy-field fallback parser
// (lib/features/risk/services/dra_service.dart). See dra_service_stream_test.dart for
// streamSiteAssessments/streamAllSiteAssessments coverage and dra_service_kpi_test.dart for the
// derived-metric coverage (draKpiCountsProvider, streamOpenAssessmentsCount,
// streamControlStrength) — both split out to respect the 200-line file threshold (AGENTS.md §4).
//
// createAssessment() routes through FirestoreService.createDocument (offline-queue + audit-log),
// not a direct write — mirrors ComplianceService.createDocument's fix (this module's reference
// pattern). The dual-write test is the direct regression guard for docs/fixes/FIX_LIST.md F-306:
// dra_form.dart intentionally writes both the legacy (`activity`/`area`) and correct
// (`taskDescription`/`location`/`task`) keys, preserved exactly by
// DynamicRiskAssessment.toFirestore() — not cleaned up as part of this extraction.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/risk/models/dynamic_risk_assessment.dart';
import 'package:sentinel1/features/risk/services/dra_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';

DynamicRiskAssessment _buildAssessment({
  String title = 'DRA: Confined space entry',
  String taskDescription = 'Confined space entry',
  String location = 'Tank Farm B',
  String status = 'Pending',
  String? riskLevel = 'High',
  String siteId = _tenantId,
}) {
  return DynamicRiskAssessment(
    siteId: siteId,
    title: title,
    description: 'Low oxygen, entrapment',
    taskDescription: taskDescription,
    location: location,
    likelihood: 'Possible',
    severity: 'Major',
    riskLevel: riskLevel,
    status: status,
    hazardsIdentified: const ['Low oxygen', 'Entrapment'],
    controlsApplied: const ['Gas monitor', 'Standby rescue'],
    teamMembers: const ['emp-1'],
    approverId: 'emp-approver',
    reviewDate: DateTime(2027, 1, 1),
    isSafeToProceed: true,
    assessedBy: 'user-1',
    authorName: 'Jane Assessor',
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
  late DraService service;

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
    service = container.read(draServiceProvider);
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
    test('dual-writes legacy activity/area alongside taskDescription/location/task (F-306)', () async {
      await service.createAssessment(_buildAssessment());

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/dynamic_risk_assessments');
      final data = args[2] as Map<String, dynamic>;

      expect(data.keys.toSet(), {
        'type',
        'title',
        'description',
        'activity',
        'area',
        'taskDescription',
        'location',
        'task',
        'likelihood',
        'severity',
        'riskLevel',
        'status',
        'hazardsIdentified',
        'controlsApplied',
        'teamMembers',
        'approverId',
        'reviewDate',
        'isSafeToProceed',
        'assessedBy',
        'authorName',
        'siteId',
        'createdAt',
      });
      expect(data['activity'], 'Confined space entry');
      expect(data['taskDescription'], 'Confined space entry');
      expect(data['task'], 'Confined space entry');
      expect(data['area'], 'Tank Farm B');
      expect(data['location'], 'Tank Farm B');
      expect(data['authorName'], 'Jane Assessor');
    });

    test('also writes a real CREATE audit-log entry with the same data', () async {
      await service.createAssessment(_buildAssessment(title: 'Audited DRA'));

      final snap =
          await db
              .collection('tenants')
              .doc(_tenantId)
              .collection('audit_logs')
              .where('action', isEqualTo: 'CREATE')
              .get();
      expect(snap.docs, hasLength(1));
      final metadata = snap.docs.single.data()['metadata'] as Map<String, dynamic>;
      expect((metadata['data'] as Map)['title'], 'Audited DRA');
    });
  });

  group('fromFirestore legacy fallback', () {
    test('parses a pre-F-306 document that only has activity/area, not taskDescription/location', () async {
      final legacyRef = await db
          .collection('tenants')
          .doc(_tenantId)
          .collection('dynamic_risk_assessments')
          .add({
            'type': 'dra',
            'title': 'Legacy DRA',
            'activity': 'Legacy task text',
            'area': 'Legacy location text',
            'siteId': _tenantId,
            'status': 'Pending',
            'isSafeToProceed': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
      final snap = await legacyRef.get();

      final assessment = DynamicRiskAssessment.fromFirestore(
        snap.data()!,
        snap.id,
      );

      expect(assessment.taskDescription, 'Legacy task text');
      expect(assessment.location, 'Legacy location text');
    });
  });
}
