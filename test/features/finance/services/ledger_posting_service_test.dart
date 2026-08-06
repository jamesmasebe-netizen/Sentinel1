// Tests for LedgerPostingService, the thin client wrapper around the
// `postJournalEntry` Cloud Function. Covers: the exact payload shape sent to
// the callable, error propagation when the callable throws, and correct
// extraction of `journalId` from a successful response.
//
// Context: `postJournalEntry` previously shipped with a field-shape bug on
// the Cloud Functions side (camelCase/`date` written, snake_case expected by
// the Dart model) — see docs/testing/TEST_STRATEGY.md. This file locks down
// the *client* side of that contract: the exact keys this service sends.
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/features/finance/services/ledger_posting_service.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<dynamic> {}

void main() {
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late ProviderContainer container;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    when(() => mockFunctions.httpsCallable('postJournalEntry'))
        .thenReturn(mockCallable);

    container = ProviderContainer(
      overrides: [
        ledgerPostingServiceProvider
            .overrideWithValue(LedgerPostingService(mockFunctions)),
      ],
    );
    addTearDown(container.dispose);
  });

  LedgerPostingService service() =>
      container.read(ledgerPostingServiceProvider);

  group('postJournalEntry payload shape', () {
    test('sends exactly tenantId/date/description/lines to the callable',
        () async {
      final mockResult = MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn({'journalId': 'JRNL-001'});
      when(() => mockCallable.call(any()))
          .thenAnswer((_) async => mockResult);

      final lines = [
        {'accountId': 'ACC-100', 'debit': 500.0, 'credit': 0.0},
        {'accountId': 'ACC-200', 'debit': 0.0, 'credit': 500.0},
      ];

      await service().postJournalEntry(
        tenantId: 'tenant-1',
        date: '2026-01-15',
        description: 'Office supplies purchase',
        lines: lines,
      );

      final captured =
          verify(() => mockCallable.call(captureAny())).captured.single
              as Map;

      // Exact key set — a payload with extra/missing/renamed keys must fail
      // this test (this is the shape the Cloud Function's `data.*` reads).
      expect(captured.keys.toSet(), {
        'tenantId',
        'date',
        'description',
        'lines',
      });
      expect(captured['tenantId'], 'tenant-1');
      expect(captured['date'], '2026-01-15');
      expect(captured['description'], 'Office supplies purchase');
      expect(captured['lines'], lines);
    });

    test('forwards the lines list unmodified, including nested map shape',
        () async {
      final mockResult = MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn({'journalId': 'JRNL-002'});
      when(() => mockCallable.call(any()))
          .thenAnswer((_) async => mockResult);

      final lines = [
        {'accountId': 'ACC-300', 'debit': 0.0, 'credit': 250.5, 'memo': 'x'},
      ];

      await service().postJournalEntry(
        tenantId: 'tenant-2',
        date: '2026-02-01',
        description: 'Adjustment',
        lines: lines,
      );

      final captured =
          verify(() => mockCallable.call(captureAny())).captured.single
              as Map;
      expect(captured['lines'], isA<List<Map<String, dynamic>>>());
      expect((captured['lines'] as List).single, lines.single);
    });
  });

  group('error propagation', () {
    test('wraps a thrown callable error in an Exception with a useful message',
        () async {
      // Simulates what a real `FirebaseFunctionsException` from the callable
      // looks like when its message is interpolated (`$e`) by the service's
      // catch block — the exact exception type doesn't matter here since the
      // service's `catch (e)` is untyped; what matters is the wrapped
      // message is preserved and prefixed usefully.
      when(() => mockCallable.call(any())).thenThrow(
        Exception('[failed-precondition] Debits and credits are not balanced'),
      );

      await expectLater(
        () => service().postJournalEntry(
          tenantId: 'tenant-1',
          date: '2026-01-15',
          description: 'Unbalanced entry',
          lines: const [],
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            allOf(
              contains('Failed to post journal entry'),
              contains('Debits and credits are not balanced'),
            ),
          ),
        ),
      );
    });

    test('propagates a generic thrown error as an Exception too', () async {
      when(() => mockCallable.call(any())).thenThrow(StateError('boom'));

      await expectLater(
        () => service().postJournalEntry(
          tenantId: 'tenant-1',
          date: '2026-01-15',
          description: 'desc',
          lines: const [],
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('successful response', () {
    test('extracts and returns journalId from result.data', () async {
      final mockResult = MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn({
        'journalId': 'JRNL-2026-000042',
        'balanced': true,
      });
      when(() => mockCallable.call(any()))
          .thenAnswer((_) async => mockResult);

      final journalId = await service().postJournalEntry(
        tenantId: 'tenant-1',
        date: '2026-01-15',
        description: 'Office supplies purchase',
        lines: const [
          {'accountId': 'ACC-100', 'debit': 500.0, 'credit': 0.0},
        ],
      );

      expect(journalId, 'JRNL-2026-000042');
    });
  });
}
