// Widget tests for DocumentReviewDialog (T3-WIDGETS) — lib/features/contractors/widgets/document_review_dialog.dart.
// See docs/testing/TEST_STRATEGY.md §8.
//
// FIXED 2026 (this pass): both writes here previously bypassed FirestoreService entirely (a direct
// db.tenantCollection(...).update()/.add() call, no offline queue, no audit log), and _submitReview
// had no try/catch at all. Now routed through ContractorReviewService ->
// FirestoreService.createDocument/updateDocument (see contractor_review_service_test.dart for the
// service-level field-shape coverage) with a try/catch + error toast. Per widget_test_harness.dart's
// buildMockOfflineSync() convention, assertions here verify the CAPTURED queueOperation call args,
// not a document landing in the fake Firestore — nothing actually reaches Firestore once a screen
// is routed through FirestoreService.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/contractors/models/safety_file_models.dart';
import 'package:sentinel1/features/contractors/widgets/document_review_dialog.dart';

import '../../../helpers/widget_test_harness.dart';

const _tenantId = 'sentinel-dev';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockOfflineSyncService offlineSync;

  setUpAll(() {
    registerFallbackValue(OfflineOperation.create);
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    firestore = FakeFirebaseFirestore();
    offlineSync = buildMockOfflineSync();
  });

  List<List<dynamic>> capturedQueueArgs() {
    final calls = verify(() => offlineSync.queueOperation(
          operation: captureAny(named: 'operation'),
          collection: captureAny(named: 'collection'),
          data: captureAny(named: 'data'),
          documentId: captureAny(named: 'documentId'),
        )).captured;
    return List.generate(calls.length ~/ 4, (i) => calls.sublist(i * 4, i * 4 + 4));
  }

  Future<void> openDialog(WidgetTester tester, ProviderContainer container, ContractorDocument doc) async {
    await tester.pumpWidget(hostedDialogTrigger(
      container,
      (context) => DocumentReviewDialog.show(context, doc),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('golden path with feedback: queues the document update AND a findings create', (
    tester,
  ) async {
    final doc = ContractorDocument(
      id: 'doc-1',
      submissionId: 'sub-1',
      name: 'Method Statement.pdf',
      url: 'https://example.test/doc.pdf',
      status: 'Pending',
    );

    final container = buildLoggedInContainer(
      firestore: firestore,
      extraOverrides: [offlineSyncServiceProvider.overrideWithValue(offlineSync)],
    );
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);

    await openDialog(tester, container, doc);

    // Change status to Resolved.
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Document Status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolved').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Finding Description / Feedback'),
      'Missing emergency contact section.',
    );

    await tester.tap(find.text('Submit Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final calls = capturedQueueArgs();
    expect(calls, hasLength(2));

    final docUpdate = calls[0];
    expect(docUpdate[0], OfflineOperation.update);
    expect(docUpdate[1], 'tenants/$_tenantId/contractor_documents');
    expect(docUpdate[3], 'doc-1');
    final docData = docUpdate[2] as Map<String, dynamic>;
    expect(docData['status'], 'Resolved');
    expect(docData['feedback'], 'Missing emergency contact section.');

    final findingCreate = calls[1];
    expect(findingCreate[0], OfflineOperation.create);
    expect(findingCreate[1], 'tenants/$_tenantId/findings');
    final findingData = findingCreate[2] as Map<String, dynamic>;
    expect(findingData['submissionId'], 'sub-1');
    expect(findingData['documentId'], 'doc-1');
    expect(findingData['description'], 'Missing emergency contact section.');
    expect(findingData['reportedBy'], 'Developer Admin'); // dev-admin mock profile's displayName
    expect(findingData['reviewerUid'], 'dev-admin-123');

    // Advance past the dialog route's exit transition so it's actually detached, not mid-animation.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DocumentReviewDialog), findsNothing); // dialog closed
  });

  testWidgets('empty-feedback guard: queues only the document update, no findings create', (
    tester,
  ) async {
    final doc = ContractorDocument(
      id: 'doc-2',
      submissionId: 'sub-1',
      name: 'Induction Register.pdf',
      url: 'https://example.test/doc2.pdf',
      status: 'Pending',
    );

    final container = buildLoggedInContainer(
      firestore: firestore,
      extraOverrides: [offlineSyncServiceProvider.overrideWithValue(offlineSync)],
    );
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);

    await openDialog(tester, container, doc);

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Document Status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rejected').last);
    await tester.pumpAndSettle();
    // Feedback left blank.

    await tester.tap(find.text('Submit Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final calls = capturedQueueArgs();
    expect(calls, hasLength(1));
    expect(calls[0][1], 'tenants/$_tenantId/contractor_documents');
    final docData = calls[0][2] as Map<String, dynamic>;
    expect(docData['status'], 'Rejected');
  });

  testWidgets('write failure shows an error toast and keeps the dialog open', (tester) async {
    final doc = ContractorDocument(
      id: 'doc-3',
      submissionId: 'sub-1',
      name: 'Risk Assessment.pdf',
      url: 'https://example.test/doc3.pdf',
      status: 'Pending',
    );

    final failingOfflineSync = MockOfflineSyncService();
    when(() => failingOfflineSync.queueOperation(
          operation: any(named: 'operation'),
          collection: any(named: 'collection'),
          data: any(named: 'data'),
          documentId: any(named: 'documentId'),
        )).thenThrow(Exception('queue full'));

    final container = buildLoggedInContainer(
      firestore: firestore,
      extraOverrides: [offlineSyncServiceProvider.overrideWithValue(failingOfflineSync)],
    );
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);

    await openDialog(tester, container, doc);

    await tester.tap(find.text('Submit Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Error submitting review'), findsOneWidget);
    expect(find.byType(DocumentReviewDialog), findsOneWidget); // dialog stays open
  });
}
