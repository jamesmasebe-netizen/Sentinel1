import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ledgerPostingServiceProvider = Provider<LedgerPostingService>((ref) {
  return LedgerPostingService(FirebaseFunctions.instanceFor(region: 'europe-west1'));
});

class LedgerPostingService {
  final FirebaseFunctions _functions;

  LedgerPostingService(this._functions);

  Future<void> postJournalEntry({
    required String tenantId,
    required String date,
    required String description,
    required List<Map<String, dynamic>> lines,
  }) async {
    try {
      final callable = _functions.httpsCallable('postJournalEntry');
      await callable.call({
        'tenantId': tenantId,
        'date': date,
        'description': description,
        'lines': lines,
      });
    } catch (e) {
      throw Exception('Failed to post journal entry: $e');
    }
  }
}
