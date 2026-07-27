import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../supply_chain/models/scm_models.dart';
import '../providers/scm_streams_provider.dart';

class InventoryItemDetailScreen extends ConsumerWidget {
  final String itemId;

  const InventoryItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(inventoryItemStreamProvider(itemId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Item Detail'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit item action
            },
          ),
        ],
      ),
      body: itemAsync.when(
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Inventory Item not found'));
          }
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                _buildHeaderCard(context, item),
                const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.info_outline), text: 'Details'),
                    Tab(icon: Icon(Icons.history), text: 'Transactions'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildDetailsTab(context, item),
                      const Center(
                        child: Text('Transactions History (Coming soon)'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, InventoryItem item) {
    return Container(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.inventory_2, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${item.sku}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(item.lifecycleStatus),
                      backgroundColor:
                          item.isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color:
                            item.isActive ? Colors.green[800] : Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(item.itemType),
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      labelStyle: TextStyle(color: Colors.blue[800]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context, InventoryItem item) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          context,
          title: 'General Information',
          children: [
            _buildInfoRow('Description', item.description),
            _buildInfoRow('Unit of Measure', item.unitOfMeasure),
            _buildInfoRow('Configurable', item.isConfigurable ? 'Yes' : 'No'),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          context,
          title: 'Stock Control',
          children: [
            _buildInfoRow('Lead Time', '${item.leadTimeDays} Days'),
            _buildInfoRow('Safety Stock', item.safetyStock.toString()),
            _buildInfoRow('Reorder Point', item.reorderPoint.toString()),
            _buildInfoRow('Valuation Method', item.valuationMethod),
          ],
        ),
        if (item.dimensions != null || item.weight != null)
          const SizedBox(height: 16),
        if (item.dimensions != null || item.weight != null)
          _buildSectionCard(
            context,
            title: 'Physical Properties',
            children: [
              if (item.weight != null)
                _buildInfoRow(
                  'Weight',
                  '${item.weight!['value']} ${item.weight!['unit']}',
                ),
              if (item.dimensions != null)
                _buildInfoRow(
                  'Dimensions',
                  '${item.dimensions!['length']}x${item.dimensions!['width']}x${item.dimensions!['height']} ${item.dimensions!['unit']}',
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
