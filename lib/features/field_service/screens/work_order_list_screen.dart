import 'package:flutter/material.dart';
import 'work_order_details_screen.dart';

class WorkOrderListScreen extends StatelessWidget {
  const WorkOrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for work orders
    final workOrders = [
      {
        'id': 'WO-2026-101',
        'title': 'Turbine 4 Inspection',
        'status': 'Pending',
        'requiresPtw': true,
        'ptwCompleted': false,
      },
      {
        'id': 'WO-2026-102',
        'title': 'Routine Maintenance - Sector 7',
        'status': 'In Progress',
        'requiresPtw': false,
        'ptwCompleted': true,
      },
      {
        'id': 'WO-2026-103',
        'title': 'High Voltage Cable Repair',
        'status': 'Pending',
        'requiresPtw': true,
        'ptwCompleted': true,
      },
      {
        'id': 'WO-2026-104',
        'title': 'Emergency Valve Replacement',
        'status': 'Critical',
        'requiresPtw': true,
        'ptwCompleted': false,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Orders'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: workOrders.length,
        itemBuilder: (context, index) {
          final order = workOrders[index];
          final bool requiresPtw = order['requiresPtw'] as bool;
          final bool ptwCompleted = order['ptwCompleted'] as bool;
          final bool ptwActionNeeded = requiresPtw && !ptwCompleted;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color:
                    ptwActionNeeded ? Colors.red.shade300 : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => WorkOrderDetailsScreen(
                          workOrderId: order['id'] as String,
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
                          order['id'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Chip(
                          label: Text(
                            order['status'] as String,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor:
                              order['status'] == 'Critical'
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order['title'] as String,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
