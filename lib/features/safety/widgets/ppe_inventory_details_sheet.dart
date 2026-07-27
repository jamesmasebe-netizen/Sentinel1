import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class PPEInventoryDetailsSheet extends ConsumerWidget {
  final String ppeType;

  const PPEInventoryDetailsSheet({super.key, required this.ppeType});

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);
    final role = ref.watch(userRoleProvider);
    final isEditable = role == 'admin' || role == 'executive';

    return StreamBuilder<QuerySnapshot>(
      stream:
          firestore
              .tenantCollection(
                ref.watch(currentTenantIdProvider) ?? "",
                'ppe_inventory',
              )
              .where('siteId', isEqualTo: siteId)
              .where('ppeType', isEqualTo: ppeType)
              .limit(1)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        Map<String, dynamic> inventoryData;
        String? docId;

        if (docs.isEmpty) {
          inventoryData = {
            'ppeType': ppeType,
            'stockLevel': 45,
            'minRequired': 20,
            'supplier': 'Apex Safety Supplies',
            'unitCost': 150.0,
            'lastReordered':
                DateTime.now()
                    .subtract(const Duration(days: 30))
                    .toIso8601String(),
            'siteId': siteId,
          };
          firestore
              .tenantCollection(
                ref.watch(currentTenantIdProvider) ?? "",
                'ppe_inventory',
              )
              .add(inventoryData)
              .then((docRef) {
                docId = docRef.id;
              });
        } else {
          docId = docs.first.id;
          inventoryData = docs.first.data() as Map<String, dynamic>;
        }

        final stock = (inventoryData['stockLevel'] ?? 0) as int;
        final minReq = (inventoryData['minRequired'] ?? 0) as int;
        final supplier = inventoryData['supplier'] ?? 'Unknown';
        final unitCost = (inventoryData['unitCost'] ?? 0.0) as num;
        final lastReordered = inventoryData['lastReordered'] ?? '';

        String stockStatus;
        Color statusColor;
        if (stock == 0) {
          stockStatus = 'OUT OF STOCK';
          statusColor = XMTheme.error;
        } else if (stock < minReq) {
          stockStatus = 'LOW STOCK';
          statusColor = XMTheme.warning;
        } else {
          stockStatus = 'IN STOCK';
          statusColor = XMTheme.success;
        }

        final stockController = TextEditingController(text: stock.toString());
        final minReqController = TextEditingController(text: minReq.toString());
        final supplierController = TextEditingController(text: supplier);
        final costController = TextEditingController(text: unitCost.toString());

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Stock Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  GStatusTag(label: stockStatus, color: statusColor),
                ],
              ),
              const Divider(height: 32),
              if (!isEditable) ...[
                _DetailRow(
                  icon: Icons.inventory_2,
                  label: 'Current Stock',
                  value: '$stock units',
                ),
                _DetailRow(
                  icon: Icons.production_quantity_limits,
                  label: 'Min Required',
                  value: '$minReq units',
                ),
                _DetailRow(
                  icon: Icons.attach_money,
                  label: 'Unit Cost',
                  value: 'R$unitCost',
                ),
                _DetailRow(
                  icon: Icons.business,
                  label: 'Supplier',
                  value: supplier,
                ),
                _DetailRow(
                  icon: Icons.history,
                  label: 'Last Reordered',
                  value: _fmtDate(lastReordered),
                ),
              ] else ...[
                TextFormField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Current Stock Level *',
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: minReqController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Required Level *',
                    prefixIcon: Icon(Icons.production_quantity_limits),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Unit Cost (R) *',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: supplierController,
                  decoration: const InputDecoration(
                    labelText: 'Supplier Name *',
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Stock Levels'),
                    onPressed: () async {
                      final currentStock =
                          int.tryParse(stockController.text) ?? stock;
                      final currentMinReq =
                          int.tryParse(minReqController.text) ?? minReq;
                      final currentCost =
                          double.tryParse(costController.text) ??
                          unitCost.toDouble();
                      final currentSupplier = supplierController.text.trim();

                      if (docId != null) {
                        await firestore
                            .tenantCollection(
                              ref.watch(currentTenantIdProvider) ?? "",
                              'ppe_inventory',
                            )
                            .doc(docId)
                            .update({
                              'stockLevel': currentStock,
                              'minRequired': currentMinReq,
                              'unitCost': currentCost,
                              'supplier': currentSupplier,
                              'updatedAt': DateTime.now().toIso8601String(),
                            });
                      }
                      if (context.mounted) {
                        UIUtils.showToast(
                          context,
                          'Stock levels updated successfully',
                          type: ToastType.success,
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
