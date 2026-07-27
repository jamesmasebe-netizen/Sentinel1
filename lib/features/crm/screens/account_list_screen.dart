import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/crm_providers.dart';
import 'account_detail_screen.dart';

class AccountListScreen extends ConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccounts = ref.watch(accountsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: asyncAccounts.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts found.'));
          }
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.business)),
                title: Text(account.name),
                subtitle: Text('${account.industry} • ${account.status}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => AccountDetailScreen(accountId: account.id),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
