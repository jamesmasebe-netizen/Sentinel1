// Widget tests for JournalEntryForm (T3-WIDGETS) — lib/features/finance/widgets/journal_entry_form.dart,
// NOT lib/features/finance/screens/journal_entry_form.dart (a 14-line Scaffold+AppBar pass-through
// with no logic, not worth a dedicated test). See docs/testing/TEST_STRATEGY.md §8.
//
// FIXED 2026 (this pass): this screen previously bypassed UIUtils.showToast for a raw
// ScaffoldMessenger.showSnackBar (both the balance-mismatch guard and the save success/error
// paths). Now uses UIUtils.showToast like every other target screen in this pass — the message
// text itself is unchanged (UIUtils.showToast still renders it as a Text widget), so the
// find.text/find.textContaining assertions below needed no changes.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/features/finance/providers/finance_providers.dart';
import 'package:sentinel1/features/finance/services/ledger_posting_service.dart';
import 'package:sentinel1/features/finance/widgets/journal_entry_form.dart';

import '../../../helpers/finance_service_model_fixtures.dart';
import '../../../helpers/widget_test_harness.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock implements HttpsCallableResult<dynamic> {}

const _tenantId = 'sentinel-dev';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    when(() => mockFunctions.httpsCallable('postJournalEntry')).thenReturn(mockCallable);
  });

  // JournalEntryForm's body is a single long ListView with ~20 fields before the per-line Cards
  // and the Save button. Flutter's Sliver machinery only mounts elements within the viewport +
  // cache extent, so at the default 800x600 test surface most of this form is never actually
  // built into the element tree, regardless of scroll position — find.text()/find.widgetWithText()
  // silently find nothing rather than erroring, which reads as a wrong-selector bug until you
  // realize it's a too-small viewport. Use a tall surface so the whole form is "visible" at once
  // instead of interleaving scrollUntilVisible() calls between every field.
  Future<void> useTallSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<void> seedGLAccounts() async {
    await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('fin_chart_of_accounts')
        .doc('ACC-100')
        .set(buildTestGLAccount(id: 'ACC-100', accountNumber: '1000', name: 'Cash').toJson());
    await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('fin_chart_of_accounts')
        .doc('ACC-400')
        .set(buildTestGLAccount(id: 'ACC-400', accountNumber: '4000', name: 'Revenue', type: 'REVENUE')
            .toJson());
  }

  testWidgets('create golden path: balances two real accounts, posts via the Cloud Function, fires onSaved', (
    tester,
  ) async {
    await useTallSurface(tester);
    await seedGLAccounts();
    when(() => mockCallable.call(any())).thenAnswer((_) async {
      final result = MockHttpsCallableResult();
      when(() => result.data).thenReturn({'journalId': 'JRNL-001'});
      return result;
    });

    var savedCalled = false;
    final container = buildLoggedInContainer(firestore: firestore, extraOverrides: [
      ledgerPostingServiceProvider.overrideWithValue(LedgerPostingService(mockFunctions)),
    ]);
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);
    await container.read(glAccountsStreamProvider.future);

    await tester.pumpWidget(hostedDirectly(
      container,
      JournalEntryForm(onSaved: () => savedCalled = true),
    ));
    await tester.pump(); // let the pre-warmed stream providers' data land in the tree

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description').first,
      'Office supplies purchase',
    );

    // Line 0: pick the Cash account, enter Debit 100.
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Account').at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1000 - Cash').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Debit').at(0), '100');

    // Line 1: pick the Revenue account, enter Credit 100.
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Account').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4000 - Revenue').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Credit').at(1), '100');

    await tester.tap(find.text('Save Journal Entry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final captured = verify(() => mockCallable.call(captureAny())).captured.single as Map;
    expect(captured['tenantId'], _tenantId);
    expect(captured['description'], 'Office supplies purchase');
    final lines = captured['lines'] as List;
    expect(lines, hasLength(2));
    expect(lines[0], {'accountId': 'ACC-100', 'debit': 100.0, 'credit': 0.0});
    expect(lines[1], {'accountId': 'ACC-400', 'debit': 0.0, 'credit': 100.0});

    expect(find.text('Journal Entry Saved!'), findsOneWidget);
    expect(savedCalled, isTrue);

    // The create path never touches fin_journal_headers directly — the Cloud Function owns that
    // write transactionally; only the (unmocked) callable was invoked above.
    final headers = await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('fin_journal_headers')
        .get();
    expect(headers.docs, isEmpty);
  });

  testWidgets('balance-mismatch guard: blocks save, never calls the callable, shows the error toast', (
    tester,
  ) async {
    await useTallSurface(tester);
    final container = buildLoggedInContainer(firestore: firestore, extraOverrides: [
      ledgerPostingServiceProvider.overrideWithValue(LedgerPostingService(mockFunctions)),
    ]);
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);

    await tester.pumpWidget(hostedDirectly(container, const JournalEntryForm()));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextFormField, 'Description').first, 'Unbalanced entry');
    await tester.enterText(find.widgetWithText(TextFormField, 'Debit').at(0), '100');
    // Credit left at 0 on both default lines — total debit (100) != total credit (0).

    await tester.tap(find.text('Save Journal Entry'));
    await tester.pump();

    expect(find.text('Total Debit must equal Total Credit.'), findsOneWidget);
    verifyNever(() => mockCallable.call(any()));
  });

  testWidgets('edit golden path: updates a mutable DRAFT entry via FinanceService, not the callable', (
    tester,
  ) async {
    await useTallSurface(tester);
    final entry = buildTestJournalEntry(id: 'JE-existing', status: 'DRAFT', description: 'Original');
    final line = buildTestJournalLine(accountId: 'ACC-100', debitAmount: 0, creditAmount: 0);
    await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('fin_journal_headers')
        .doc('JE-existing')
        .set(entry.toJson());

    var savedCalled = false;
    final container = buildLoggedInContainer(firestore: firestore, extraOverrides: [
      ledgerPostingServiceProvider.overrideWithValue(LedgerPostingService(mockFunctions)),
    ]);
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);

    await tester.pumpWidget(hostedDirectly(
      container,
      JournalEntryForm(
        initialEntry: entry,
        initialLines: [line],
        onSaved: () => savedCalled = true,
      ),
    ));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextFormField, 'Description').first, 'Corrected description');
    await tester.tap(find.text('Save Journal Entry'));
    await tester.pump();
    // The edit path does two sequential fake_cloud_firestore ops (a .get() inside
    // _assertMutable, then .update()) before the SnackBar fires — more hops than the create
    // path's single mocked Cloud Function call, so give it a couple more pump cycles.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    verifyNever(() => mockCallable.call(any()));
    expect(find.text('Journal Entry Saved!'), findsOneWidget);
    expect(savedCalled, isTrue);

    final doc = await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('fin_journal_headers')
        .doc('JE-existing')
        .get();
    expect(doc.data()!['description'], 'Corrected description');
  });

  testWidgets('immutable-entry guard: a POSTED entry rejects the edit, doc unchanged, no onSaved', (
    tester,
  ) async {
    await useTallSurface(tester);
    final entry = buildTestJournalEntry(id: 'JE-posted', status: 'POSTED', description: 'Posted entry');
    final line = buildTestJournalLine(accountId: 'ACC-100', debitAmount: 0, creditAmount: 0);
    await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('fin_journal_headers')
        .doc('JE-posted')
        .set(entry.toJson());

    var savedCalled = false;
    final container = buildLoggedInContainer(firestore: firestore, extraOverrides: [
      ledgerPostingServiceProvider.overrideWithValue(LedgerPostingService(mockFunctions)),
    ]);
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);

    await tester.pumpWidget(hostedDirectly(
      container,
      JournalEntryForm(
        initialEntry: entry,
        initialLines: [line],
        onSaved: () => savedCalled = true,
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('Save Journal Entry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Error:'), findsOneWidget);
    expect(find.textContaining('Posted/reversed entries are immutable'), findsOneWidget);
    expect(savedCalled, isFalse);

    final doc = await firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('fin_journal_headers')
        .doc('JE-posted')
        .get();
    expect(doc.data()!['description'], 'Posted entry'); // unchanged
  });
}
