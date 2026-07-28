import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/ui_utils.dart';
import '../providers/finance_providers.dart';
import 'chart_of_accounts_view.dart';
import 'journal_entry_form.dart';

class FinanceHubScreen extends ConsumerWidget {
  const FinanceHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalEntriesAsync = ref.watch(journalEntriesStreamProvider);
    final accountsAsync = ref.watch(glAccountsStreamProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('Finance Hub (General Ledger)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'General Ledger Overview',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    accountsAsync.when(
                      data: (accounts) => Text('Total Accounts: ${accounts.length}'),
                      loading: () => const Text('Total Accounts: Loading...'),
                      error: (err, st) => const Text('Total Accounts: Error loading'),
                    ),
                    journalEntriesAsync.when(
                      data: (entries) => Text('Total Journal Entries: ${entries.length}'),
                      loading: () => const Text('Total Journal Entries: Loading...'),
                      error: (err, st) => const Text('Total Journal Entries: Error loading'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      () => UIUtils.showSideSheet(
                        context: context,
                        title: 'Chart of Accounts',
                        builder: (ctx) => const ChartOfAccountsView(),
                      ),
                  icon: const Icon(Icons.account_balance),
                  label: const Text('Chart of Accounts'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      () => UIUtils.showSideSheet(
                        context: context,
                        title: 'New Journal Entry',
                        builder: (ctx) => const JournalEntryForm(),
                      ),
                  icon: const Icon(Icons.add_card),
                  label: const Text('New Journal Entry'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Journal Entries',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: journalEntriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Error loading entries: $err')),
                data: (journalEntries) {
                  if (journalEntries.isEmpty) {
                    return const Center(child: Text('No journal entries yet.'));
                  }
                  return ListView.builder(
                    itemCount: journalEntries.length,
                    itemBuilder: (context, index) {
                      final entry = journalEntries.reversed.toList()[index];
                      return ListTile(
                        title: Text(entry.description),
                        subtitle: Text(
                          'Account: ${entry.id} • Date: ${entry.transactionDate.toLocal().toString().split(' ')[0]}',
                        ),
                        trailing: Text(
                          currencyFormatter.format(entry.totalDebit),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                entry.totalDebit < 0
                                    ? Colors.red
                                    : Colors.green,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
