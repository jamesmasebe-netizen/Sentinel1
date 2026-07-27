import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/field_service_models.dart';
import '../services/field_service_service.dart';

class CustomerAssetDetailScreen extends ConsumerWidget {
  final String assetId;

  const CustomerAssetDetailScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(fieldServiceServiceProvider);

    return StreamBuilder<CustomerAsset?>(
      stream: service.streamCustomerAsset(assetId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final asset = snapshot.data;
        if (asset == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Asset Details')),
            body: const Center(child: Text('Asset not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(asset.assetName),
            elevation: 0,
            actions: [
              Chip(
                label: Text(
                  asset.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor:
                    asset.status == 'ACTIVE' ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainInfoCard(asset),
                const SizedBox(height: 24),
                _buildWarrantySection(asset),
                const SizedBox(height: 24),
                if (asset.iotDeviceId != null) _buildIotSection(asset),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainInfoCard(CustomerAsset asset) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(
                Icons.precision_manufacturing,
                size: 40,
                color: Colors.blueGrey,
              ),
              title: const Text(
                'Customer ID',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              subtitle: Text(
                asset.customerId,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.category, color: Colors.blue),
              title: const Text(
                'Category ID',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              subtitle: Text(
                asset.categoryId ?? 'N/A',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (asset.installationDate != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.build_circle, color: Colors.orange),
                title: const Text(
                  'Installation Date',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                subtitle: Text(
                  DateFormat.yMMMd().format(asset.installationDate!),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantySection(CustomerAsset asset) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_user, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Warranty Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Date',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        asset.warrantyStartDate != null
                            ? DateFormat.yMMMd().format(
                              asset.warrantyStartDate!,
                            )
                            : 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End Date',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        asset.warrantyEndDate != null
                            ? DateFormat.yMMMd().format(asset.warrantyEndDate!)
                            : 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIotSection(CustomerAsset asset) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.sensors, size: 40, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connected IoT Device',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Device ID: ${asset.iotDeviceId}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              // Navigation to IoT device details if needed
            },
          ),
        ],
      ),
    );
  }
}
