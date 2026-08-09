// Widget tests for DocumentReviewDialog (T3-WIDGETS) — lib/features/contractors/widgets/document_review_dialog.dart.
// See docs/testing/TEST_STRATEGY.md §8.
//
// Real, pre-existing gaps, flagged not fixed: both writes here bypass FirestoreService entirely
// (no offline queue, no audit log — a direct db.tenantCollection(...).update()/.add() call), and
// _submitReview has no try/catch at all — a write failure would leave the dialog open with an
// unhandled exception and no user-visible feedback (unlike every other target screen in this
// pass, which at minimum shows an error SnackBar/toast).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/features/contractors/models/safety_file_models.dart';
import 'package:sentinel1/features/contractors/widgets/document_review_dialog.dart';

import '../../../helpers/widget_test_harness.dart';

const _tenantId = 'sentinel-dev';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  Future<void> seedDocument(ContractorDocument doc) async {
    await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('contractor_documents')
        .doc(doc.id)
        .set(doc.toMap());
  }

  Future<void> openDialog(WidgetTester tester, ProviderContainer container, ContractorDocument doc) async {
    await tester.pumpWidget(hostedDialogTrigger(
      container,
      (context) => DocumentReviewDialog.show(context, doc),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('golden path with feedback: updates the document AND creates a findings doc', (
    tester,
  ) async {
    final doc = ContractorDocument(
      id: 'doc-1',
      submissionId: 'sub-1',
      name: 'Method Statement.pdf',
      url: 'https://example.test/doc.pdf',
      status: 'Pending',
    );
    await seedDocument(doc);

    final container = buildLoggedInContainer(firestore: firestore);
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

    final docSnap = await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('contractor_documents')
        .doc('doc-1')
        .get();
    expect(docSnap.data()!['status'], 'Resolved');
    expect(docSnap.data()!['feedback'], 'Missing emergency contact section.');

    final findings = await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('findings')
        .get();
    expect(findings.docs, hasLength(1));
    final finding = findings.docs.single.data();
    expect(finding['submissionId'], 'sub-1');
    expect(finding['documentId'], 'doc-1');
    expect(finding['description'], 'Missing emergency contact section.');
    expect(finding['reportedBy'], 'Developer Admin'); // dev-admin mock profile's displayName
    expect(finding['reviewerUid'], 'dev-admin-123');

    // Advance past the dialog route's exit transition so it's actually detached, not mid-animation.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DocumentReviewDialog), findsNothing); // dialog closed
  });

  testWidgets('empty-feedback guard: updates the document status but creates no findings doc', (
    tester,
  ) async {
    final doc = ContractorDocument(
      id: 'doc-2',
      submissionId: 'sub-1',
      name: 'Induction Register.pdf',
      url: 'https://example.test/doc2.pdf',
      status: 'Pending',
    );
    await seedDocument(doc);

    final container = buildLoggedInContainer(firestore: firestore);
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

    final docSnap = await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('contractor_documents')
        .doc('doc-2')
        .get();
    expect(docSnap.data()!['status'], 'Rejected');

    final findings = await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('findings')
        .get();
    expect(findings.docs, isEmpty);
  });
}
