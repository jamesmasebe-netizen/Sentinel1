import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_models.dart';
import '../services/finance_service.dart';

class BudgetPlanDetailScreen extends ConsumerWidget {
  final String planId;
  const BudgetPlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Plan Details')),
      body: FutureBuilder<BudgetPlan?>(
        future: ref.read(financeServiceProvider).getBudgetPlan(planId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final plan = snapshot.data;
          if (plan == null) {
            return const Center(child: Text('Plan not found.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: ${plan.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Fiscal Year: ${plan.fiscalYear}'),
                Text('Fiscal Period: ${plan.fiscalPeriod}'),
                Text('Status: ${plan.status}'),
                const Divider(),
                Text('Planned Amount: \$${plan.plannedAmount}'),
                Text('Actual Amount: \$${plan.actualAmount}'),
                Text(
                  'Variance: \$${plan.variance} (${plan.variancePercentage}%)',
                ),
                const SizedBox(height: 16),
                Text('Notes: ${plan.notes}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
