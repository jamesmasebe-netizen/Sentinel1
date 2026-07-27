import '../models/finance_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chart_of_accounts.dart';

import '../services/finance_service.dart';

final glAccountsStreamProvider = StreamProvider<List<GeneralLedgerAccount>>((ref) {
  final service = ref.watch(financeServiceProvider);
  return service.streamAllGLAccounts();
});

final journalEntriesProvider = StateProvider<List<JournalEntry>>((ref) => []);
final invoicesProvider = StateProvider<List<Invoice>>((ref) => []);

final journalEntryStreamProvider = StreamProvider.family<JournalEntry?, String>(
  (ref, id) {
    final service = ref.watch(financeServiceProvider);
    return service.streamJournalEntry(id);
  },
);

final journalLinesStreamProvider =
    StreamProvider.family<List<JournalLine>, String>((ref, id) {
      final service = ref.watch(financeServiceProvider);
      return service.streamJournalLines(id);
    });

// Using a custom class or tuple for multiple parameters in family.
// We can use a Record type if Dart 3 is used. Since SDK is ^3.7.2, we can use records.
final invoiceStreamProvider =
    StreamProvider.family<Invoice?, ({String id, String type})>((ref, args) {
      final service = ref.watch(financeServiceProvider);
      return service.streamInvoice(args.id, type: args.type);
    });
