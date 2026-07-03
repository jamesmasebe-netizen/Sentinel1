import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chart_of_accounts.dart';
import '../models/journal_entry.dart';
import '../models/invoice.dart';

final chartOfAccountsProvider = StateProvider<List<ChartOfAccounts>>(
  (ref) => [],
);
final journalEntriesProvider = StateProvider<List<JournalEntry>>((ref) => []);
final invoicesProvider = StateProvider<List<Invoice>>((ref) => []);
