// Tests for ContractorReviewService (lib/features/contractors/services/contractor_review_service.dart)
// — the service layer extracted from DocumentReviewDialog/SafetyFileSubmissionView's previously-inline
// Firestore calls, following the PropertyService/EnvironmentService reference pattern.
//
// FIXED 2026 (real, live gaps): both writes previously went straight to Firestore
// (`db.tenantCollection(...).update()/.add()`), bypassing FirestoreService entirely — no
// offline-queue/audit-log safety net, unlike every other module in this pass. DocumentReviewDialog's
// _submitReview also had no try/catch at all. Now both route through
// FirestoreService.createDocument/updateDocument, with FieldValue.serverTimestamp()/arrayUnion()
// swapped for ISO 8601 strings + client-side array append (FieldValue sentinels aren't
// JSON-serializable, and the offline queue JSON-encodes every queued write — see
// OfflineSyncService.queueOperation).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/contractors/models/safety_file_models.dart';
import 'package:sentinel1/features/contractors/services/contractor_review_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';

void main() {
  setUpAll(() {
    registerFallbackValue(OfflineOperation.create);
    registerFallbackValue(<String, dynamic>{});
  });

  late FakeFirebaseFirestore db;
  late MockOfflineSyncService offlineSync;
  late ProviderContainer container;
  late ContractorReviewService service;

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
    service = container.read(contractorReviewServiceProvider);
  });

  List<List<dynamic>> capturedQueueArgs() {
    final calls = verify(() => offlineSync.queueOperation(
          operation: captureAny(named: 'operation'),
          collection: captureAny(named: 'collection'),
          data: captureAny(named: 'data'),
          documentId: captureAny(named: 'documentId'),
        )).captured;
    // mocktail flattens captured args into one list across all calls, 4 per call.
    return List.generate(calls.length ~/ 4, (i) => calls.sublist(i * 4, i * 4 + 4));
  }

  final doc = ContractorDocument(
    id: 'doc-1',
    submissionId: 'sub-1',
    name: 'Method Statement.pdf',
    url: 'https://example.test/doc.pdf',
    status: 'Pending',
  );

  group('submitDocumentReview', () {
    test('with feedback: queues the document update AND a findings create, with ISO date strings', () async {
      await service.submitDocumentReview(
        document: doc,
        status: 'Resolved',
        feedback: 'Missing emergency contact section.',
        findingStatus: FindingStatus.open,
        reviewerUid: 'user-1',
        reviewerName: 'Jane Reviewer',
      );

      final calls = capturedQueueArgs();
      expect(calls, hasLength(2));

      final docUpdate = calls[0];
      expect(docUpdate[0], OfflineOperation.update);
      expect(docUpdate[1], 'tenants/$_tenantId/contractor_documents');
      expect(docUpdate[3], 'doc-1');
      final docData = docUpdate[2] as Map<String, dynamic>;
      expect(docData['status'], 'Resolved');
      expect(docData['feedback'], 'Missing emergency contact section.');
      // The dead write-only 'findings' array-union mirror (never read by any model/screen) is
      // dropped rather than reconstructed with a read-modify-write — see service doc comment.
      expect(docData.containsKey('findings'), isFalse);

      final findingCreate = calls[1];
      expect(findingCreate[0], OfflineOperation.create);
      expect(findingCreate[1], 'tenants/$_tenantId/findings');
      final findingData = findingCreate[2] as Map<String, dynamic>;
      expect(findingData['submissionId'], 'sub-1');
      expect(findingData['documentId'], 'doc-1');
      expect(findingData['siteId'], _tenantId);
      expect(findingData['description'], 'Missing emergency contact section.');
      expect(findingData['reviewerUid'], 'user-1');
      expect(findingData['reviewerName'], 'Jane Reviewer');
      expect(findingData['createdAt'], isA<String>()); // ISO string, not FieldValue
      expect(findingData['modifiedAt'], isA<String>());
      final history = findingData['statusHistory'] as List;
      expect(history, hasLength(1));
      expect(history.single['status'], 'open');
    });

    test('empty feedback: queues only the document update, no findings doc', () async {
      await service.submitDocumentReview(
        document: doc,
        status: 'Rejected',
        feedback: '',
        findingStatus: FindingStatus.open,
        reviewerUid: 'user-1',
        reviewerName: 'Jane Reviewer',
      );

      final calls = capturedQueueArgs();
      expect(calls, hasLength(1));
      expect(calls[0][1], 'tenants/$_tenantId/contractor_documents');
    });
  });

  group('updateFindingStatus', () {
    test('appends to the existing statusHistory client-side and writes ISO date strings', () async {
      final finding = Finding(
        findingId: 'finding-1',
        submissionId: 'sub-1',
        documentId: 'doc-1',
        requirementId: 0,
        status: FindingStatus.open,
        siteId: _tenantId,
        type: FindingType.observation,
        description: 'desc',
        contractorAction: '',
        reviewerUid: 'user-1',
        reviewerName: 'Jane Reviewer',
        createdAt: DateTime(2026, 1, 1),
        modifiedBy: 'user-1',
        modifiedAt: DateTime(2026, 1, 1),
        statusHistory: [
          {'status': 'open', 'timestamp': '2026-01-01T00:00:00.000', 'comment': 'Initial review finding', 'userId': 'user-1'},
        ],
      );

      await service.updateFindingStatus(
        finding: finding,
        newStatus: FindingStatus.addressed,
        comment: 'Fixed by contractor',
        userId: 'user-2',
      );

      final calls = capturedQueueArgs();
      expect(calls, hasLength(1));
      expect(calls[0][0], OfflineOperation.update);
      expect(calls[0][1], 'tenants/$_tenantId/findings');
      expect(calls[0][3], 'finding-1');
      final data = calls[0][2] as Map<String, dynamic>;
      expect(data['status'], 'addressed');
      expect(data['modifiedBy'], 'user-2');
      expect(data['modifiedAt'], isA<String>());
      final history = data['statusHistory'] as List;
      expect(history, hasLength(2)); // original entry preserved + new one appended
      expect(history[0]['comment'], 'Initial review finding');
      expect(history[1]['status'], 'addressed');
      expect(history[1]['comment'], 'Fixed by contractor');
      expect(history[1]['userId'], 'user-2');
    });
  });
}
