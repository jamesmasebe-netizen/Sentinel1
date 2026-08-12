// Widget tests for SafetyFileSubmissionView (T3-WIDGETS) — lib/features/contractors/widgets/safety_file_submission_view.dart.
// See docs/testing/TEST_STRATEGY.md §8.
//
// Real, pre-existing architectural deviation, flagged not fixed: this screen's entire read layer
// is raw nested StreamBuilder<QuerySnapshot> widgets reading Firestore directly, not the Riverpod
// StreamProvider convention used everywhere else in the app — see T3-CONTRACTORS in
// docs/testing/TEST_BACKLOG.md. _updateFindingStatus (FindingUpdateDialog's callback) was fixed in
// a later pass: it now routes through ContractorReviewService -> FirestoreService instead of a
// direct db.tenantCollection(...).update() call — see contractor_review_service_test.dart.
//
// Fixed 2026 (this pass), not just worked around: `_functions` was a class-FIELD initializer
// (`FirebaseFunctions.instanceFor(...)`), which ran the instant createState() built the State
// object — i.e. on the very first pumpWidget(), before any provider override could intercept it,
// requiring a real Firebase.initializeApp() unconditionally just to construct the widget at all.
// Converted to a lazy getter, only evaluated inside _generateReport() (Download Report tapped) —
// tests below never tap that button, so Firebase Core is never touched. Separately,
// contractorPrescreenServiceProvider (a different provider, watched unconditionally by AiPreScreenBadge
// the instant ANY document row renders) hardcodes FirebaseFirestore.instance/FirebaseFunctions.instance
// directly rather than routing through firestoreProvider — this one required a provider override
// instead (see the golden-path test below), not a source change, since ContractorPrescreenService already
// takes both as constructor params.
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/features/contractors/services/contractor_prescreen_service.dart';
import 'package:sentinel1/features/contractors/widgets/document_review_dialog.dart';
import 'package:sentinel1/features/contractors/widgets/safety_file_submission_view.dart';

import '../../../helpers/widget_test_harness.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock implements HttpsCallableResult<dynamic> {}

const _tenantId = 'sentinel-dev';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  Future<void> seedSubmission({
    String id = 'sub-1',
    String contractorId = 'contractor-1',
    String projectId = 'project-1',
  }) async {
    await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('safety_file_submissions')
        .doc(id)
        .set({
      'contractorId': contractorId,
      'projectId': projectId,
      'siteId': _tenantId,
      'status': 'underReview',
      'createdAt': DateTime(2026, 1, 1),
      'updatedAt': DateTime(2026, 1, 1),
      'score': 0.0,
    });
  }

  Future<void> seedDocument({
    required String id,
    required String submissionId,
    String name = 'Method Statement.pdf',
  }) async {
    await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('contractor_documents')
        .doc(id)
        .set({
      'submissionId': submissionId,
      'name': name,
      'url': 'https://example.test/$id.pdf',
      'status': 'Pending',
      'feedback': null,
    });
  }

  testWidgets('empty state: no matching submission renders the empty-state text', (tester) async {
    final container = buildLoggedInContainer(firestore: firestore);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SafetyFileSubmissionView(contractorId: 'contractor-1', projectId: 'project-1'),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('No Safety File Submission for this project yet.'), findsOneWidget);
  });

  testWidgets('golden path with tenant-scoping proof: renders only this submission\'s documents/findings, '
      'not a decoy from a different submission', (tester) async {
    await seedSubmission(id: 'sub-1', contractorId: 'contractor-1', projectId: 'project-1');
    await seedDocument(id: 'doc-1', submissionId: 'sub-1', name: 'Method Statement.pdf');
    // Decoy: a document/finding under a DIFFERENT submissionId — must never render here.
    await seedDocument(id: 'doc-decoy', submissionId: 'sub-OTHER', name: 'Decoy Document.pdf');
    await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('findings')
        .doc('finding-decoy')
        .set({
      'submissionId': 'sub-OTHER',
      'documentId': 'doc-decoy',
      'requirementId': 0,
      'status': 'open',
      'type': 'observation',
      'description': 'Decoy finding',
      'contractorAction': '',
      'reviewerUid': 'someone',
      'reviewerName': 'Someone',
      'createdAt': DateTime(2026, 1, 1),
      'modifiedBy': 'someone',
      'modifiedAt': DateTime(2026, 1, 1),
      'statusHistory': [],
    });

    final mockFunctions = MockFirebaseFunctions();
    final container = buildLoggedInContainer(firestore: firestore, extraOverrides: [
      contractorPrescreenServiceProvider.overrideWithValue(
        ContractorPrescreenService(firestore, mockFunctions, _tenantId),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SafetyFileSubmissionView(contractorId: 'contractor-1', projectId: 'project-1'),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Safety File Submission'), findsOneWidget);
    expect(find.text('Method Statement.pdf'), findsOneWidget);
    expect(find.text('Decoy Document.pdf'), findsNothing);
    expect(find.text('No findings recorded.'), findsOneWidget); // sub-1 itself has none
  });

  testWidgets('AI Pre-Screen tap invokes the callable with the right documentId/documentUrl/tenantId', (
    tester,
  ) async {
    await seedSubmission();
    await seedDocument(id: 'doc-1', submissionId: 'sub-1');

    final mockFunctions = MockFirebaseFunctions();
    final mockCallable = MockHttpsCallable();
    when(() => mockFunctions.httpsCallable('prescreenContractorDocument')).thenReturn(mockCallable);
    when(() => mockCallable.call(any())).thenAnswer((_) async => MockHttpsCallableResult());

    final container = buildLoggedInContainer(firestore: firestore, extraOverrides: [
      contractorPrescreenServiceProvider.overrideWithValue(
        ContractorPrescreenService(firestore, mockFunctions, _tenantId),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SafetyFileSubmissionView(contractorId: 'contractor-1', projectId: 'project-1'),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('AI Pre-Screen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final captured = verify(() => mockCallable.call(captureAny())).captured.single as Map;
    expect(captured['documentId'], 'doc-1');
    expect(captured['documentUrl'], 'https://example.test/doc-1.pdf');
    expect(captured['tenantId'], _tenantId);
  });

  testWidgets('"Review" opens the real DocumentReviewDialog', (tester) async {
    await seedSubmission();
    await seedDocument(id: 'doc-1', submissionId: 'sub-1', name: 'Site Induction Log.pdf');

    final mockFunctions = MockFirebaseFunctions();
    final container = buildLoggedInContainer(firestore: firestore, extraOverrides: [
      contractorPrescreenServiceProvider.overrideWithValue(
        ContractorPrescreenService(firestore, mockFunctions, _tenantId),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SafetyFileSubmissionView(contractorId: 'contractor-1', projectId: 'project-1'),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentReviewDialog), findsOneWidget);
    expect(find.text('Review Document: Site Induction Log.pdf'), findsOneWidget);
  });
}
