import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/crm_providers.dart';

class AccountDetailScreen extends ConsumerWidget {
  final String accountId;
  const AccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccount = ref.watch(accountStreamProvider(accountId));

    return Scaffold(
      appBar: AppBar(title: const Text('Account Detail')),
      body: asyncAccount.when(
        data: (account) {
          if (account == null) {
            return const Center(child: Text('Account not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Industry: ${account.industry}'),
                      Text('Revenue: \$${account.annualRevenue}'),
                      Text('Employees: ${account.employeeCount}'),
                      Text('Status: ${account.status}'),
                      Text('Health: ${account.relationshipHealth}'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
