import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_models.dart';
import '../services/finance_service.dart';
import 'budget_plan_detail_screen.dart';

class BudgetPlanListScreen extends ConsumerWidget {
  const BudgetPlanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(financeServiceProvider).streamBudgetPlans();
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Plans')),
      body: StreamBuilder<List<BudgetPlan>>(
        stream: plansAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final plans = snapshot.data ?? [];
          if (plans.isEmpty) {
            return const Center(child: Text('No budget plans found.'));
          }
          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return ListTile(
                title: Text(plan.name),
                subtitle: Text(
                  'Fiscal Year: ${plan.fiscalYear} | Status: ${plan.status}',
                ),
                trailing: Text('\$${plan.plannedAmount}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BudgetPlanDetailScreen(planId: plan.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement Create Budget Plan
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
