import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chart_of_accounts.dart';
import '../providers/finance_providers.dart';

class ChartOfAccountsView extends ConsumerStatefulWidget {
  const ChartOfAccountsView({super.key});

  @override
  ConsumerState<ChartOfAccountsView> createState() =>
      _ChartOfAccountsViewState();
}

class _ChartOfAccountsViewState extends ConsumerState<ChartOfAccountsView> {
  void _addAccount() {
    showDialog(
      context: context,
      builder: (context) {
        final nameCtrl = TextEditingController();
        final codeCtrl = TextEditingController();
        final typeCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Code'),
              ),
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Type (e.g. Asset, Liability)',
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
                final newAccount = ChartOfAccounts(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  code: codeCtrl.text,
                  type: typeCtrl.text,
                );
                ref
                    .read(chartOfAccountsProvider.notifier)
                    .update((state) => [...state, newAccount]);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(chartOfAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chart of Accounts')),
      body:
          accounts.isEmpty
              ? const Center(child: Text('No accounts yet.'))
              : ListView.builder(
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return ListTile(
                    title: Text(account.name),
                    subtitle: Text('${account.code} - ${account.type}'),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
        child: const Icon(Icons.add),
      ),
    );
  }
}
