import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';

class ProductionOrderScreen extends ConsumerStatefulWidget {
  const ProductionOrderScreen({super.key});

  @override
  ConsumerState<ProductionOrderScreen> createState() => _ProductionOrderScreenState();
}

class _ProductionOrderScreenState extends ConsumerState<ProductionOrderScreen> {
  // In a real app, this would be a stream from Firestore
  final List<Map<String, dynamic>> _mockProductionOrders = [
    {
      'id': 'PO-1001',
      'item': 'Drone Assembly Kit A',
      'qty': 10,
      'status': 'IN_PROGRESS',
      'bom_id': 'BOM-DRONE-A',
    },
    {
      'id': 'PO-1002',
      'item': 'Battery Pack V2',
      'qty': 50,
      'status': 'PLANNED',
      'bom_id': 'BOM-BATT-V2',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GHeader(
            title: 'Manufacturing & Assembly',
            trailing: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New Production Order coming soon')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Order'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mockProductionOrders.length,
              itemBuilder: (context, index) {
                final po = _mockProductionOrders[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: const Icon(Icons.precision_manufacturing, color: Colors.orange),
                    ),
                    title: Text('${po['id']} - ${po['item']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target Quantity: ${po['qty']}'),
                        Text('Status: ${po['status']}'),
                        Text('BOM Ref: ${po['bom_id']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'complete') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order marked as Completed. Inventory updated.')),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'start', child: Text('Start Assembly')),
                        const PopupMenuItem(value: 'complete', child: Text('Complete Order')),
                        const PopupMenuItem(value: 'cancel', child: Text('Cancel Order')),
                      ],
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
