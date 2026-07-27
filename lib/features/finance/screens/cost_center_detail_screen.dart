import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_models.dart';
import '../services/finance_service.dart';

class CostCenterDetailScreen extends ConsumerWidget {
  final String centerId;
  const CostCenterDetailScreen({super.key, required this.centerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cost Center Details')),
      body: FutureBuilder<CostCenter?>(
        future: ref.read(financeServiceProvider).getCostCenter(centerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final center = snapshot.data;
          if (center == null) {
            return const Center(child: Text('Cost Center not found.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: ${center.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Code: ${center.code}'),
                Text('Status: ${center.isActive ? 'Active' : 'Inactive'}'),
                const Divider(),
                Text('Total Budget: \$${center.totalBudget}'),
                Text('Total Spend: \$${center.totalSpend}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
