// Tests for StrategicRiskService (lib/features/risk/services/strategic_risk_service.dart) — the
// last of the 4 Risk services. Like bowtie_form.dart, strategic_risk_form.dart has no confirmed
// field-shape bug, so the field-shape test here verifies the extraction preserves exact prior
// behavior for both the register screen's filtered/ordered/limited query and RiskMatrixWidget's
// unfiltered one.
//
// createRisk() routes through FirestoreService.createDocument (offline-queue + audit-log), not a
// direct write — mirrors ComplianceService.createDocument's fix (this module's reference
// pattern).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/risk/models/strategic_risk.dart';
import 'package:sentinel1/features/risk/services/strategic_risk_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

StrategicRisk _buildRisk({
  String title = 'Supply Chain Disruption',
  int riskScore = 12,
  String riskRating = 'High',
  String siteId = _tenantId,
  DateTime? createdAt,
}) {
  return StrategicRisk(
    id: '',
    title: title,
    description: 'Key supplier concentration risk',
    category: 'Operational',
    owner: 'emp-owner',
    likelihood: 'Possible',
    impact: 'Significant',
    riskScore: riskScore,
    riskRating: riskRating,
    mitigation: 'Diversify supplier base',
    status: 'Open',
    authorId: 'user-1',
    siteId: siteId,
    createdAt: createdAt ?? DateTime.now(),
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
  late StrategicRiskService service;

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
    service = container.read(strategicRiskServiceProvider);
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

  Future<void> seedRawDoc(StrategicRisk r, {String tenantId = _tenantId}) async {
    await db
        .collection('tenants')
        .doc(tenantId)
        .collection('strategic_risks')
        .add(r.toFirestore());
  }

  group('createRisk', () {
    test('queues the exact field shape strategic_risk_form.dart previously wrote inline', () async {
      await service.createRisk(_buildRisk());

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/strategic_risks');
      final data = args[2] as Map<String, dynamic>;

      expect(data.keys.toSet(), {
        'title',
        'description',
        'category',
        'owner',
        'likelihood',
        'impact',
        'riskScore',
        'riskRating',
        'mitigation',
        'status',
        'authorId',
        'siteId',
        'createdAt',
      });
      expect(data['riskScore'], 12);
      expect(data['riskRating'], 'High');
      expect(data['createdAt'], isA<String>());
      expect(DateTime.tryParse(data['createdAt'] as String), isNotNull);
    });

    test('also writes a real CREATE audit-log entry with the same data', () async {
      await service.createRisk(_buildRisk(title: 'Audited Risk'));

      final snap =
          await db
              .collection('tenants')
              .doc(_tenantId)
              .collection('audit_logs')
              .where('action', isEqualTo: 'CREATE')
              .get();
      expect(snap.docs, hasLength(1));
      final metadata = snap.docs.single.data()['metadata'] as Map<String, dynamic>;
      expect((metadata['data'] as Map)['title'], 'Audited Risk');
    });
  });

  group('streamRisks', () {
    test('returns only this tenant\'s strategic risks, newest first', () async {
      await seedRawDoc(
        _buildRisk(
          title: 'Older',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      await seedRawDoc(_buildRisk(title: 'Newer'));
      await seedRawDoc(
        _buildRisk(title: 'Other Tenant', siteId: _otherTenantId),
        tenantId: _otherTenantId,
      );

      final docs = await service.streamRisks().first;

      expect(docs.map((d) => d.title), ['Newer', 'Older']);
    });
  });

  group('streamAllRisks', () {
    test('feeds RiskMatrixWidget: includes every document under the tenant path, unfiltered by siteId field', () async {
      await seedRawDoc(_buildRisk(title: 'Site A', siteId: 'site-a'));
      await seedRawDoc(_buildRisk(title: 'Site B', siteId: 'site-b'));

      final docs = await service.streamAllRisks().first;

      expect(docs.map((d) => d.title).toSet(), {'Site A', 'Site B'});
    });

    test('does not include another tenant\'s documents', () async {
      await seedRawDoc(_buildRisk(title: 'Mine'));
      await seedRawDoc(
        _buildRisk(title: 'Not Mine', siteId: _otherTenantId),
        tenantId: _otherTenantId,
      );

      final docs = await service.streamAllRisks().first;

      expect(docs.map((d) => d.title), ['Mine']);
    });
  });
}
