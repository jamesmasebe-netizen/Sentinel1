import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ledgerPostingServiceProvider = Provider<LedgerPostingService>((ref) {
  return LedgerPostingService(FirebaseFunctions.instanceFor(region: 'europe-west1'));
});

class LedgerPostingService {
  final FirebaseFunctions _functions;

  LedgerPostingService(this._functions);

  /// Posts a journal entry via the `postJournalEntry` Cloud Function, which
  /// validates debits == credits and updates account balances transactionally
  /// server-side before anything is written — checks the direct client write
  /// path (`FinanceService.createJournalEntry`) doesn't perform. Returns the
  /// real, server-generated journal entry ID.
  Future<String> postJournalEntry({
    required String tenantId,
    required String date,
    required String description,
    required List<Map<String, dynamic>> lines,
  }) async {
    try {
      final callable = _functions.httpsCallable('postJournalEntry');
      final result = await callable.call({
        'tenantId': tenantId,
        'date': date,
        'description': description,
        'lines': lines,
      });
      return result.data['journalId'] as String;
    } catch (e) {
      throw Exception('Failed to post journal entry: $e');
    }
  }
}
