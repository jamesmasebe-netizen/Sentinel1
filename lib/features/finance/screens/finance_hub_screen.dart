import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_providers.dart';
import 'chart_of_accounts_view.dart';
import 'journal_entry_form.dart';

class FinanceHubScreen extends ConsumerWidget {
  const FinanceHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalEntries = ref.watch(journalEntriesProvider);
    final accounts = ref.watch(chartOfAccountsProvider);

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
                    Text('Total Accounts: ${accounts.length}'),
                    Text('Total Journal Entries: ${journalEntries.length}'),
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
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChartOfAccountsView(),
                        ),
                      ),
                  icon: const Icon(Icons.account_balance),
                  label: const Text('Chart of Accounts'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const JournalEntryForm(),
                        ),
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
              child:
                  journalEntries.isEmpty
                      ? const Center(child: Text('No journal entries yet.'))
                      : ListView.builder(
                        itemCount: journalEntries.length,
                        itemBuilder: (context, index) {
                          final entry = journalEntries.reversed.toList()[index];
                          return ListTile(
                            title: Text(entry.description),
                            subtitle: Text(
                              'Account: ${entry.accountId} • Date: ${entry.date.toLocal().toString().split(' ')[0]}',
                            ),
                            trailing: Text(
                              '\$${entry.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    entry.amount < 0
                                        ? Colors.red
                                        : Colors.green,
                              ),
                            ),
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
