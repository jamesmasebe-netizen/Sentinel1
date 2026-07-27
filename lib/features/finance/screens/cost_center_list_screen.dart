import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_models.dart';
import '../services/finance_service.dart';
import 'cost_center_detail_screen.dart';

class CostCenterListScreen extends ConsumerWidget {
  const CostCenterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centersAsync = ref.watch(financeServiceProvider).streamCostCenters();
    return Scaffold(
      appBar: AppBar(title: const Text('Cost Centers')),
      body: StreamBuilder<List<CostCenter>>(
        stream: centersAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final centers = snapshot.data ?? [];
          if (centers.isEmpty) {
            return const Center(child: Text('No cost centers found.'));
          }
          return ListView.builder(
            itemCount: centers.length,
            itemBuilder: (context, index) {
              final center = centers[index];
              return ListTile(
                title: Text(center.name),
                subtitle: Text(
                  'Code: ${center.code} | Status: ${center.isActive ? 'Active' : 'Inactive'}',
                ),
                trailing: Text('Budget: \$${center.totalBudget}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => CostCenterDetailScreen(centerId: center.id),
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
          // TODO: Implement Create Cost Center
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
