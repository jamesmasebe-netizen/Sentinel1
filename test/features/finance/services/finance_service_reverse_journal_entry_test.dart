// Tests for reverseJournalEntry — the F-311-mandated correction path for
// POSTED entries. Covers: rejection cases (not found / not POSTED, incl.
// re-reversing an already-REVERSED entry), the original entry's status flip
// with amounts left untouched, and the new reversing entry's exact field
// shape + debit/credit swap — the same "assert exact keys, not just
// presence" discipline TEST_STRATEGY.md mandates for postJournalEntry,
// applied here since this method hand-builds a new document from scratch.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/finance_service_fixtures.dart';
import '../../../helpers/finance_service_model_fixtures.dart';

void main() {
  late FinanceTestHarness harness;

  setUp(() {
    harness = FinanceTestHarness.build();
    addTearDown(harness.container.dispose);
  });

  group('rejection cases', () {
    test('throws for a nonexistent id', () async {
      await expectLater(
        () => harness.service.reverseJournalEntry('missing'),
        throwsA(isA<StateError>()),
      );
    });

    test('throws for a DRAFT (not POSTED) entry, no new doc created',
        () async {
      await harness.service.createJournalEntry(
          buildTestJournalEntry(id: 'JE-D1', status: 'DRAFT'), []);

      await expectLater(
        () => harness.service.reverseJournalEntry('JE-D1'),
        throwsA(isA<StateError>()),
      );

      final all = await harness.db
          .collection('tenants')
          .doc(financeTestTenantId)
          .collection('fin_journal_headers')
          .get();
      expect(all.docs, hasLength(1));
    });

    test('throws re-reversing an already-REVERSED entry', () async {
      await harness.service.createJournalEntry(
          buildTestJournalEntry(id: 'JE-R1', status: 'REVERSED'), []);

      await expectLater(
        () => harness.service.reverseJournalEntry('JE-R1'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('successful reversal', () {
    test('flips original status to REVERSED, leaves its amounts untouched',
        () async {
      await harness.service.createJournalEntry(
        buildTestJournalEntry(
          id: 'JE-P1',
          status: 'POSTED',
          totalDebit: 300,
          totalCredit: 300,
        ),
        [],
      );

      await harness.service.reverseJournalEntry('JE-P1');

      final originalRaw =
          await readTenantDoc(harness.db, 'fin_journal_headers', 'JE-P1');
      expect(originalRaw.data()!['status'], 'REVERSED');
      expect(originalRaw.data()!['total_debit'], 300);
      expect(originalRaw.data()!['total_credit'], 300);
    });

    test('new reversing entry has exact expected field keys and swapped '
        'debit/credit totals', () async {
      await harness.service.createJournalEntry(
        buildTestJournalEntry(
          id: 'JE-P2',
          status: 'POSTED',
          sourceModule: 'AP',
          description: 'Vendor payment',
          currencyCode: 'EUR',
          totalDebit: 750,
          totalCredit: 750,
        ),
        [],
      );

      await harness.service.reverseJournalEntry('JE-P2');

      final match = await harness.db
          .collection('tenants')
          .doc(financeTestTenantId)
          .collection('fin_journal_headers')
          .where('reverses_journal_id', isEqualTo: 'JE-P2')
          .get();
      expect(match.docs, hasLength(1));
      final data = match.docs.single.data();

      // Exact key set — guards against a hand-built map drifting from
      // JournalEntry.toJson()'s snake_case keys (the postJournalEntry bug
      // class TEST_STRATEGY.md calls out).
      expect(data.keys.toSet(), {
        'transaction_date',
        'source_module',
        'type',
        'description',
        'status',
        'currency_code',
        'total_debit',
        'total_credit',
        'reverses_journal_id',
      });
      expect(data['type'], 'REVERSAL');
      expect(data['status'], 'DRAFT');
      expect(data['source_module'], 'AP');
      expect(data['currency_code'], 'EUR');
      expect(data['description'], contains('Reversal of JE-P2'));
      // The core invariant: totals are swapped, not copied.
      expect(data['total_debit'], 750); // = original total_credit
      expect(data['total_credit'], 750); // = original total_debit
      expect(data['transaction_date'], isA<Timestamp>());
    });

    test('reversal lines swap debit/credit per line and preserve accountId',
        () async {
      await harness.service.createJournalEntry(
        buildTestJournalEntry(id: 'JE-P3', status: 'POSTED'),
        [
          buildTestJournalLine(
              id: 'L1', accountId: 'ACC-DR', debitAmount: 60, creditAmount: 0),
          buildTestJournalLine(
              id: 'L2', accountId: 'ACC-CR', debitAmount: 0, creditAmount: 60),
        ],
      );

      await harness.service.reverseJournalEntry('JE-P3');

      final headerMatch = await harness.db
          .collection('tenants')
          .doc(financeTestTenantId)
          .collection('fin_journal_headers')
          .where('reverses_journal_id', isEqualTo: 'JE-P3')
          .get();
      final newLines = await headerMatch.docs.single.reference
          .collection('lines')
          .get();
      expect(newLines.docs, hasLength(2));

      final byAccount = {
        for (final d in newLines.docs) d.data()['account_id']: d.data(),
      };
      expect(byAccount['ACC-DR']!.keys.toSet(),
          {'account_id', 'debit_amount', 'credit_amount'});
      expect(byAccount['ACC-DR']!['debit_amount'], 0);
      expect(byAccount['ACC-DR']!['credit_amount'], 60);
      expect(byAccount['ACC-CR']!['debit_amount'], 60);
      expect(byAccount['ACC-CR']!['credit_amount'], 0);
    });
  });
}
