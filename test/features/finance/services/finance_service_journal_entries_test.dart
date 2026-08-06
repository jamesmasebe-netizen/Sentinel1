// Tests for FinanceService's JournalEntry/JournalLine creation, reads, and
// streams (the paths not guarded by the immutability check — see
// finance_service_immutability_test.dart for updateJournalEntry/
// deleteJournalEntry/reverseJournalEntry, which is F-311's fix).
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/finance/models/finance_models.dart';

import '../../../helpers/finance_service_fixtures.dart';
import '../../../helpers/finance_service_model_fixtures.dart';

void main() {
  late FinanceTestHarness harness;

  setUp(() {
    harness = FinanceTestHarness.build();
    addTearDown(harness.container.dispose);
  });

  group('createJournalEntry', () {
    test('writes the header and every line under the tenant path', () async {
      final entry = buildTestJournalEntry(id: 'JE-100', status: 'DRAFT');
      final lines = [
        buildTestJournalLine(
            id: 'L1', accountId: 'ACC-100', debitAmount: 100, creditAmount: 0),
        buildTestJournalLine(
            id: 'L2', accountId: 'ACC-200', debitAmount: 0, creditAmount: 100),
      ];

      await harness.service.createJournalEntry(entry, lines);

      final headerRaw = await harness.db
          .collection('tenants')
          .doc(financeTestTenantId)
          .collection('fin_journal_headers')
          .doc('JE-100')
          .get();
      expect(headerRaw.exists, isTrue);
      expect(headerRaw.data(), containsPair('status', 'DRAFT'));

      final linesRaw = await harness.db
          .collection('tenants')
          .doc(financeTestTenantId)
          .collection('fin_journal_headers')
          .doc('JE-100')
          .collection('lines')
          .get();
      expect(linesRaw.docs, hasLength(2));
    });

    test('getJournalEntry round-trips header fields', () async {
      final entry = buildTestJournalEntry(
        id: 'JE-101',
        description: 'Payroll accrual',
        totalDebit: 5000,
        totalCredit: 5000,
      );
      await harness.service.createJournalEntry(entry, []);

      final fetched = await harness.service.getJournalEntry('JE-101');
      expect(fetched, isNotNull);
      expect(fetched!.description, 'Payroll accrual');
      expect(fetched.totalDebit, 5000);
      expect(fetched.totalCredit, 5000);
    });

    test('getJournalEntry returns null for a nonexistent id', () async {
      expect(await harness.service.getJournalEntry('nope'), isNull);
    });

    test('getJournalLines returns every seeded line with correct amounts',
        () async {
      final entry = buildTestJournalEntry(id: 'JE-102');
      final lines = [
        buildTestJournalLine(
            id: 'L1', accountId: 'ACC-A', debitAmount: 40, creditAmount: 0),
        buildTestJournalLine(
            id: 'L2', accountId: 'ACC-B', debitAmount: 0, creditAmount: 40),
      ];
      await harness.service.createJournalEntry(entry, lines);

      final fetchedLines = await harness.service.getJournalLines('JE-102');
      expect(fetchedLines, hasLength(2));
      final byAccount = {for (final l in fetchedLines) l.accountId: l};
      expect(byAccount['ACC-A']!.debitAmount, 40);
      expect(byAccount['ACC-B']!.creditAmount, 40);
    });
  });

  group('streams', () {
    test('streamJournalEntry emits null before creation, then the entry',
        () async {
      final emissions = <JournalEntry?>[];
      final sub =
          harness.service.streamJournalEntry('JE-200').listen(emissions.add);
      addTearDown(sub.cancel);
      await Future.delayed(Duration.zero);
      expect(emissions.last, isNull);

      await harness.service
          .createJournalEntry(buildTestJournalEntry(id: 'JE-200'), []);
      await Future.delayed(Duration.zero);
      expect(emissions.last, isNotNull);
      expect(emissions.last!.id, 'JE-200');
    });

    test('streamJournalLines emits the current line set live', () async {
      await harness.service
          .createJournalEntry(buildTestJournalEntry(id: 'JE-201'), [
        buildTestJournalLine(id: 'L1', accountId: 'ACC-1'),
      ]);

      final emissions = <List<JournalLine>>[];
      final sub = harness.service
          .streamJournalLines('JE-201')
          .listen(emissions.add);
      addTearDown(sub.cancel);
      await Future.delayed(Duration.zero);
      expect(emissions.last.map((l) => l.id), ['L1']);
    });

    test('streamAllJournalEntries emits live updates', () async {
      final emissions = <List<JournalEntry>>[];
      final sub =
          harness.service.streamAllJournalEntries().listen(emissions.add);
      addTearDown(sub.cancel);

      await harness.service
          .createJournalEntry(buildTestJournalEntry(id: 'JE-300'), []);
      await Future.delayed(Duration.zero);
      expect(emissions.last.map((e) => e.id), contains('JE-300'));
    });
  });
}
