// Tests for BowtieService (lib/features/risk/services/bowtie_service.dart) — the simplest of the
// 4 Risk services (single collection, single read site: bowtie_screen.dart). No field-shape bug
// was found for this sub-feature (FIX_LIST.md F-306 confirms bowtie_form.dart has "no confirmed
// mismatch"), so the field-shape test here verifies the extraction preserves exact prior
// behavior.
//
// createAnalysis() routes through FirestoreService.createDocument (offline-queue + audit-log),
// not a direct write — mirrors ComplianceService.createDocument's fix (this module's reference
// pattern).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/risk/models/bowtie_analysis.dart';
import 'package:sentinel1/features/risk/services/bowtie_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

BowtieAnalysis _buildAnalysis({
  String title = 'Underground Fire Risk',
  String topEvent = 'Fire / Explosion',
  String siteId = _tenantId,
  DateTime? createdAt,
}) {
  return BowtieAnalysis(
    id: '',
    title: title,
    topEvent: topEvent,
    threats: 'Electrical fault',
    consequences: 'Loss of life, asset damage',
    preventiveBarriers: 'Regular inspections',
    mitigationBarriers: 'Fire suppression system',
    status: 'Draft',
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
  late BowtieService service;

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
    service = container.read(bowtieServiceProvider);
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

  Future<void> seedRawDoc(BowtieAnalysis a, {String tenantId = _tenantId}) async {
    await db
        .collection('tenants')
        .doc(tenantId)
        .collection('bowtie_analyses')
        .add(a.toFirestore());
  }

  group('createAnalysis', () {
    test('queues the exact field shape bowtie_form.dart previously wrote inline', () async {
      await service.createAnalysis(_buildAnalysis());

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/bowtie_analyses');
      final data = args[2] as Map<String, dynamic>;

      expect(data.keys.toSet(), {
        'title',
        'topEvent',
        'threats',
        'consequences',
        'preventiveBarriers',
        'mitigationBarriers',
        'status',
        'authorId',
        'siteId',
        'createdAt',
      });
      expect(data['title'], 'Underground Fire Risk');
      expect(data['topEvent'], 'Fire / Explosion');
      // createdAt is an ISO8601 string, not a Timestamp — bowtie_form.dart writes
      // DateTime.now().toIso8601String(), matching every existing on-disk document.
      expect(data['createdAt'], isA<String>());
      expect(DateTime.tryParse(data['createdAt'] as String), isNotNull);
    });

    test('also writes a real CREATE audit-log entry with the same data', () async {
      await service.createAnalysis(_buildAnalysis(title: 'Audited Analysis'));

      final snap =
          await db
              .collection('tenants')
              .doc(_tenantId)
              .collection('audit_logs')
              .where('action', isEqualTo: 'CREATE')
              .get();
      expect(snap.docs, hasLength(1));
      final metadata = snap.docs.single.data()['metadata'] as Map<String, dynamic>;
      expect((metadata['data'] as Map)['title'], 'Audited Analysis');
    });
  });

  group('streamAnalyses', () {
    test('returns only this tenant\'s analyses, newest first', () async {
      await seedRawDoc(
        _buildAnalysis(
          title: 'Older',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      await seedRawDoc(_buildAnalysis(title: 'Newer'));
      await seedRawDoc(
        _buildAnalysis(title: 'Other Tenant', siteId: _otherTenantId),
        tenantId: _otherTenantId,
      );

      final docs = await service.streamAnalyses().first;

      expect(docs.map((d) => d.title), ['Newer', 'Older']);
    });

    test('caps results at 30', () async {
      for (var i = 0; i < 32; i++) {
        await seedRawDoc(_buildAnalysis(title: 'Analysis $i'));
      }

      final docs = await service.streamAnalyses().first;

      expect(docs, hasLength(30));
    });
  });
}
