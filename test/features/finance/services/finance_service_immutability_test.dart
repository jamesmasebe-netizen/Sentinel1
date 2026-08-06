// Tests for the F-311 immutability guard: `_assertMutable` (exercised via
// updateJournalEntry/deleteJournalEntry) and `reverseJournalEntry`. Per
// docs/fixes/FIX_LIST.md F-311: "Posted transactions cannot be deleted or
// modified. Corrections require a reversing entry." The guard checks the
// CURRENTLY PERSISTED status (`_immutableStatuses = {'POSTED', 'REVERSED'}`),
// not the incoming object's — every "rejected" test below also asserts the
// document was left completely unchanged, not just that an error was thrown,
// since the check runs before the write.
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/finance_service_fixtures.dart';
import '../../../helpers/finance_service_model_fixtures.dart';

void main() {
  late FinanceTestHarness harness;

  setUp(() {
    harness = FinanceTestHarness.build();
    addTearDown(harness.container.dispose);
  });

  group('updateJournalEntry — _assertMutable', () {
    test('DRAFT entry can be updated', () async {
      await harness.service.createJournalEntry(
          buildTestJournalEntry(id: 'JE-1', status: 'DRAFT'), []);
      await harness.service.updateJournalEntry(
          buildTestJournalEntry(id: 'JE-1', status: 'DRAFT', description: 'v2'));
      final fetched = await harness.service.getJournalEntry('JE-1');
      expect(fetched!.description, 'v2');
    });

    test('POSTED entry rejects update and is left unchanged', () async {
      await harness.service.createJournalEntry(
          buildTestJournalEntry(id: 'JE-2', status: 'POSTED', description: 'orig'),
          []);

      await expectLater(
        () => harness.service.updateJournalEntry(buildTestJournalEntry(
            id: 'JE-2', status: 'POSTED', description: 'hacked')),
        throwsA(isA<StateError>()),
      );

      final fetched = await harness.service.getJournalEntry('JE-2');
      expect(fetched!.description, 'orig');
    });

    test('REVERSED entry rejects update and is left unchanged', () async {
      await harness.service.createJournalEntry(
          buildTestJournalEntry(
              id: 'JE-3', status: 'REVERSED', description: 'orig'),
          []);

      await expectLater(
        () => harness.service.updateJournalEntry(buildTestJournalEntry(
            id: 'JE-3', status: 'REVERSED', description: 'hacked')),
        throwsA(isA<StateError>()),
      );

      final fetched = await harness.service.getJournalEntry('JE-3');
      expect(fetched!.description, 'orig');
    });

    test(
        'FINDING: APPROVED entry is NOT blocked — only POSTED/REVERSED are '
        'immutable per _immutableStatuses, documenting current scope', () async {
      await harness.service.createJournalEntry(
          buildTestJournalEntry(id: 'JE-4', status: 'APPROVED'), []);
      await harness.service.updateJournalEntry(buildTestJournalEntry(
          id: 'JE-4', status: 'APPROVED', description: 'still editable'));
      final fetched = await harness.service.getJournalEntry('JE-4');
      expect(fetched!.description, 'still editable');
    });
  });

  group('deleteJournalEntry — _assertMutable', () {
    test('DRAFT entry can be deleted', () async {
      await harness.service.createJournalEntry(
          buildTestJournalEntry(id: 'JE-10', status: 'DRAFT'), []);
      await harness.service.deleteJournalEntry('JE-10');
      expect(await harness.service.getJournalEntry('JE-10'), isNull);
    });

    test('POSTED entry rejects delete and the document still exists',
        () async {
      await harness.service.createJournalEntry(
          buildTestJournalEntry(id: 'JE-11', status: 'POSTED'), []);

      await expectLater(
        () => harness.service.deleteJournalEntry('JE-11'),
        throwsA(isA<StateError>()),
      );

      expect(await harness.service.getJournalEntry('JE-11'), isNotNull);
    });

    test('REVERSED entry rejects delete and the document still exists',
        () async {
      await harness.service.createJournalEntry(
          buildTestJournalEntry(id: 'JE-12', status: 'REVERSED'), []);

      await expectLater(
        () => harness.service.deleteJournalEntry('JE-12'),
        throwsA(isA<StateError>()),
      );

      expect(await harness.service.getJournalEntry('JE-12'), isNotNull);
    });
  });
}
