import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../models/finance_models.dart';
import '../providers/finance_providers.dart';
import '../services/finance_service.dart';

class ChartOfAccountsView extends ConsumerStatefulWidget {
  const ChartOfAccountsView({super.key});

  @override
  ConsumerState<ChartOfAccountsView> createState() =>
      _ChartOfAccountsViewState();
}

class _ChartOfAccountsViewState extends ConsumerState<ChartOfAccountsView> {
  /// Net balance per accountId, summed from POSTED journal entries' lines.
  /// Not a stored field — recomputed whenever the posted-entries set changes.
  /// See F-316: a stored `currentBalance` was deliberately removed from
  /// `GeneralLedgerAccount` to avoid a value that could drift from the
  /// ledger's own truth.
  Future<Map<String, double>> _computeBalances(List<JournalEntry> entries) async {
    final service = ref.read(financeServiceProvider);
    final balances = <String, double>{};
    for (final entry in entries) {
      if (entry.status.toUpperCase() != 'POSTED') continue;
      final lines = await service.getJournalLines(entry.id);
      for (final line in lines) {
        balances[line.accountId] =
            (balances[line.accountId] ?? 0) + line.debitAmount - line.creditAmount;
      }
    }
    return balances;
  }

  double _signedBalance(GeneralLedgerAccount acc, Map<String, double> balances) {
    final net = balances[acc.id] ?? 0.0;
    final type = acc.type.toLowerCase();
    // Asset/expense accounts have a normal debit balance (net = debit - credit
    // is already correctly signed); liability/equity/revenue accounts have a
    // normal credit balance, so the raw net must be flipped — matching
    // postJournalEntry's own sign convention in firebase/functions/src/index.ts.
    if (type == 'asset' || type == 'expense') return net;
    return -net;
  }

  void _addAccount() {
    showDialog(
      context: context,
      builder: (context) {
        final nameCtrl = TextEditingController();
        final codeCtrl = TextEditingController();
        final typeCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('New GL Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Account Name'),
              ),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Account Code (e.g. 1000)'),
              ),
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Type (asset, liability, equity, revenue, expense)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = codeCtrl.text.trim();
                final name = nameCtrl.text.trim();
                if (code.isEmpty || name.isEmpty) {
                  UIUtils.showToast(
                    context,
                    'Account code and name are required',
                    type: ToastType.error,
                  );
                  return;
                }
                final id = '$code-${name.replaceAll(' ', '')}';
                final existing = await ref
                    .read(financeServiceProvider)
                    .getGeneralLedgerAccount(id);
                if (existing != null) {
                  if (context.mounted) {
                    UIUtils.showToast(
                      context,
                      'An account with ID "$id" already exists',
                      type: ToastType.error,
                    );
                  }
                  return;
                }
                final newAccount = GeneralLedgerAccount(
                  id: id,
                  accountNumber: code,
                  name: name,
                  type: typeCtrl.text.trim(),
                  currencyCode: 'USD',
                  isActive: true,
                  isReconciliationAccount: false,
                );
                await ref
                    .read(financeServiceProvider)
                    .createGeneralLedgerAccount(newAccount);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(glAccountsStreamProvider);
    final journalEntriesAsync = ref.watch(journalEntriesStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          GHeader(
            title: 'Omni-Graph: Chart of Accounts',
            trailing: ElevatedButton.icon(
              onPressed: _addAccount,
              icon: const Icon(Icons.add),
              label: const Text('New GL Account'),
            ),
          ),
          Expanded(
            child: accountsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Center(child: Text('No GL accounts found.'));
                }
                return FutureBuilder<Map<String, double>>(
                  future: _computeBalances(journalEntriesAsync.valueOrNull ?? []),
                  builder: (context, balanceSnap) {
                    final balances = balanceSnap.data ?? const {};
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                          columns: const [
                            DataColumn(label: Text('Code')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Balance')),
                            DataColumn(label: Text('Status')),
                          ],
                          rows: accounts.map((acc) {
                            final balance = _signedBalance(acc, balances);
                            return DataRow(cells: [
                              DataCell(Text(acc.accountNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(acc.name)),
                              DataCell(Chip(label: Text(acc.type.toUpperCase(), style: const TextStyle(fontSize: 10)))),
                              DataCell(Text('\$${balance.toStringAsFixed(2)}')),
                              DataCell(
                                Icon(
                                  acc.isActive ? Icons.check_circle : Icons.cancel,
                                  color: acc.isActive ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                              ),
                            ]);
                          }).toList(),
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
    );
  }
}
