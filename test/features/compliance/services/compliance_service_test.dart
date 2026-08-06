// Tests for ComplianceService (lib/features/compliance/services/compliance_service.dart) — the
// service layer extracted from the compliance module's previously-inline Firestore calls (Wave
// 2b, 2026-08-06). Used as the reference pattern for extracting emergency/workers_comp/health/
// risk's equivalents.
//
// FIXED 2026-08-06 (found while extracting the Emergency module and mirroring this file as its
// reference): the first version of this service wrote createDocument() directly to Firestore
// (`_docsRef.add(...)`), but RegisterDocForm's original code called
// `firestoreServiceProvider.createDocument(...)` — which, per SafetyService's own earlier
// finding (test/features/safety/services/safety_service_test.dart), routes through
// OfflineSyncService.queueOperation (offline-first) and AuditLogService.logAction (audit trail)
// rather than writing directly. The direct-write version silently dropped both. Fixed by
// injecting FirestoreService and routing createDocument() through it, exactly like
// SafetyService.createCapa — this file's test harness now mirrors
// safety_service_test.dart's pattern (mock OfflineSyncService, real fake_cloud_firestore-backed
// AuditLogService cross-check) instead of asserting a direct write.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/compliance/models/compliance_document.dart';
import 'package:sentinel1/features/compliance/services/compliance_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

ComplianceDocument _buildDoc({
  String id = '',
  String title = 'Forklift Licence',
  String referenceNumber = 'REF-1',
  String documentType = 'Licence',
  String status = 'Current',
  DateTime? expiryDate,
  DateTime? reviewDate,
  String siteId = _tenantId,
}) {
  return ComplianceDocument(
    id: id,
    title: title,
    referenceNumber: referenceNumber,
    documentType: documentType,
    status: status,
    ownerId: 'emp-1',
    expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 200)),
    reviewDate: reviewDate ?? DateTime.now().add(const Duration(days: 100)),
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
  late ComplianceService service;

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
    service = container.read(complianceServiceProvider);
  });

  /// Captures the args OfflineSyncService.queueOperation was called with, in verify-call source
  /// order: [operation, collection, data, documentId].
  List<dynamic> capturedQueueArgs() {
    return verify(() => offlineSync.queueOperation(
          operation: captureAny(named: 'operation'),
          collection: captureAny(named: 'collection'),
          data: captureAny(named: 'data'),
          documentId: captureAny(named: 'documentId'),
        )).captured;
  }

  /// Directly seeds a raw compliance_docs document, bypassing the service — used by the stream
  /// tests below, since createDocument() now queues through the (mocked) offline sync rather
  /// than writing to Firestore synchronously.
  Future<void> seedRawDoc(ComplianceDocument doc, {String tenantId = _tenantId}) async {
    await db
        .collection('tenants')
        .doc(tenantId)
        .collection('compliance_docs')
        .add(doc.toFirestore());
  }

  group('createDocument', () {
    test('queues the exact field shape RegisterDocForm previously wrote inline, via the offline-first path',
        () async {
      await service.createDocument(_buildDoc(
        title: 'Crane Operator Certificate',
        referenceNumber: 'CRANE-042',
        documentType: 'Certificate',
        status: 'Under Review',
      ));

      final args = capturedQueueArgs();
      expect(args[0], OfflineOperation.create);
      expect(args[1], 'tenants/$_tenantId/compliance_docs');
      final data = args[2] as Map<String, dynamic>;

      expect(data.keys.toSet(), {
        'title',
        'referenceNumber',
        'documentType',
        'status',
        'ownerId',
        'expiryDate',
        'reviewDate',
        'authorId',
        'siteId',
        'createdAt',
      });
      expect(data['title'], 'Crane Operator Certificate');
      expect(data['referenceNumber'], 'CRANE-042');
      expect(data['documentType'], 'Certificate');
      expect(data['status'], 'Under Review');
      // Dates are ISO8601 strings, not Timestamps — matching existing on-disk data and the
      // string-comparison range query in streamExpiringDocuments().
      expect(data['expiryDate'], isA<String>());
      expect(DateTime.tryParse(data['expiryDate'] as String), isNotNull);
    });

    test('also writes a real CREATE audit-log entry with the same data (FirestoreService.createDocument\'s own behavior)',
        () async {
      await service.createDocument(_buildDoc(title: 'Audited Doc'));

      final snap = await db
          .collection('tenants')
          .doc(_tenantId)
          .collection('audit_logs')
          .where('action', isEqualTo: 'CREATE')
          .get();
      expect(snap.docs, hasLength(1));
      final metadata = snap.docs.single.data()['metadata'] as Map<String, dynamic>;
      expect(metadata['collection'], 'tenants/$_tenantId/compliance_docs');
      expect((metadata['data'] as Map)['title'], 'Audited Doc');
    });
  });

  group('streamAllDocuments', () {
    test('returns only this tenant\'s documents, newest first', () async {
      await seedRawDoc(_buildDoc(title: 'Older Doc'));
      await Future.delayed(const Duration(milliseconds: 5));
      await seedRawDoc(_buildDoc(title: 'Newer Doc'));
      await seedRawDoc(_buildDoc(title: 'Other Tenant Doc', siteId: _otherTenantId),
          tenantId: _otherTenantId);

      final docs = await service.streamAllDocuments().first;

      expect(docs.map((d) => d.title), ['Newer Doc', 'Older Doc']);
    });
  });

  group('streamExpiringDocuments', () {
    test('includes only documents expiring within 90 days, soonest first, excluding other tenants',
        () async {
      await seedRawDoc(_buildDoc(
        title: 'Expiring Soon',
        expiryDate: DateTime.now().add(const Duration(days: 10)),
      ));
      await seedRawDoc(_buildDoc(
        title: 'Expiring Later This Window',
        expiryDate: DateTime.now().add(const Duration(days: 80)),
      ));
      await seedRawDoc(_buildDoc(
        title: 'Not Expiring Soon',
        expiryDate: DateTime.now().add(const Duration(days: 200)),
      ));

      final docs = await service.streamExpiringDocuments().first;

      expect(docs.map((d) => d.title), ['Expiring Soon', 'Expiring Later This Window']);
    });

    test('a document already past its expiry date is still included (isLessThanOrEqualTo, not a floor)',
        () async {
      await seedRawDoc(_buildDoc(
        title: 'Already Expired',
        expiryDate: DateTime.now().subtract(const Duration(days: 5)),
      ));

      final docs = await service.streamExpiringDocuments().first;

      expect(docs.map((d) => d.title), contains('Already Expired'));
    });
  });
}
