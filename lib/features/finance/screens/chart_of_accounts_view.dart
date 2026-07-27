import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _isConsolidated = false;

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
              onPressed: () {
                final newAccount = GeneralLedgerAccount(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  accountNumber: codeCtrl.text,
                  name: nameCtrl.text,
                  type: typeCtrl.text,
                  currencyCode: 'USD',
                  isActive: true,
                  isReconciliationAccount: false,
                );
                ref.read(financeServiceProvider).createGeneralLedgerAccount(newAccount);
                Navigator.pop(context);
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

    return Scaffold(
      body: Column(
        children: [
          GHeader(
            title: 'Omni-Graph: Chart of Accounts',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Multi-Entity Consolidation'),
                Switch(
                  value: _isConsolidated,
                  onChanged: (val) {
                    setState(() {
                      _isConsolidated = val;
                    });
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _addAccount,
                  icon: const Icon(Icons.add),
                  label: const Text('New GL Account'),
                ),
              ],
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
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                      columns: const [
                        DataColumn(label: Text('Code')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Balance')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: accounts.map((acc) {
                        return DataRow(cells: [
                          DataCell(Text(acc.accountNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(acc.name)),
                          DataCell(Chip(label: Text(acc.type.toUpperCase(), style: const TextStyle(fontSize: 10)))),
                          DataCell(Text('\$0.00')),
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
            ),
          ),
        ],
      ),
    );
  }
}
