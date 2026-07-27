import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scm_streams_provider.dart';
import '../models/scm_models.dart';
import 'package:intl/intl.dart';

class TransferOrderDetailScreen extends ConsumerWidget {
  final String transferId;

  const TransferOrderDetailScreen({super.key, required this.transferId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toAsync = ref.watch(transferOrderStreamProvider(transferId));

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Order Detail'), elevation: 0),
      body: toAsync.when(
        data: (toData) {
          if (toData == null) {
            return const Center(child: Text('Transfer Order not found'));
          }
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                _buildHeaderCard(context, toData),
                const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.info_outline), text: 'Details'),
                    Tab(icon: Icon(Icons.local_shipping), text: 'Tracking'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildDetailsTab(context, toData),
                      _buildTrackingTab(context, toData),
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

  Widget _buildHeaderCard(BuildContext context, TransferOrder toData) {
    final status = toData.status;
    final transferDate = toData.orderDate;

    return Container(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TO: ${toData.id}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Chip(
                label: Text(status.toUpperCase()),
                backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHeaderMetric(
                  context,
                  'From',
                  toData.sourceLocation.isNotEmpty ? toData.sourceLocation : 'N/A',
                  Icons.store,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.arrow_forward, color: Colors.grey),
              ),
              Expanded(
                child: _buildHeaderMetric(
                  context,
                  'To',
                  toData.destinationLocation.isNotEmpty ? toData.destinationLocation : 'N/A',
                  Icons.store_mall_directory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHeaderMetric(
                  context,
                  'Transfer Date',
                  transferDate != null
                      ? DateFormat.yMMMd().format(transferDate)
                      : 'N/A',
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in transit':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHeaderMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsTab(BuildContext context, TransferOrder toData) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
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
                  'Transfer Information',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  'Order Number',
                  toData.orderNumber.isNotEmpty ? toData.orderNumber : 'N/A',
                ),
                _buildInfoRow(
                  'Source Warehouse',
                  toData.sourceLocation.isNotEmpty ? toData.sourceLocation : 'N/A',
                ),
                _buildInfoRow(
                  'Destination Warehouse',
                  toData.destinationLocation.isNotEmpty ? toData.destinationLocation : 'N/A',
                ),
                _buildInfoRow('Status', toData.status),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingTab(BuildContext context, TransferOrder toData) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tracking Information not available yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
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
