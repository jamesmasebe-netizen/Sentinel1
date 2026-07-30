import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'work_order_details_screen.dart';
import '../providers/field_service_providers.dart';
import '../widgets/work_order_form.dart';
import '../models/field_service_models.dart';

class WorkOrderListScreen extends ConsumerWidget {
  const WorkOrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workOrdersAsyncValue = ref.watch(workOrdersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Orders'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: workOrdersAsyncValue.when(
        data: (workOrders) {
          if (workOrders.isEmpty) {
            return const Center(child: Text('No Work Orders found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: workOrders.length,
            itemBuilder: (context, index) {
              final order = workOrders[index];
              // Safety checks are now part of safetyRequirements
              // Since we don't have the explicit fields from the dummy data, let's infer or default to true/false
              final bool requiresPtw = order.safetyRequirements?['ptwRequired'] ?? false;
              // Assuming if it's required, we check if they're completed. The model doesn't have ptwCompleted directly.
              // For UI purposes, let's assume not completed if required for now.
              final bool ptwCompleted = false; 
              final bool ptwActionNeeded = requiresPtw && !ptwCompleted;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: ptwActionNeeded
                        ? Colors.red.shade300
                        : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkOrderDetailsScreen(
                          workOrderId: order.id,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.workOrderNumber.isNotEmpty ? order.workOrderNumber : order.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Chip(
                              label: Text(
                                order.status,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: order.status.toUpperCase() == 'CRITICAL'
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.description ?? 'No description provided',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (ptwActionNeeded)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Safety PTW (Permit to Work) MUST be completed before starting.',
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (requiresPtw && ptwCompleted)
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Safety PTW Approved',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Create Work Order')),
                body: const WorkOrderForm(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
