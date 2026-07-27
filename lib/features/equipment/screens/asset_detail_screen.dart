import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/bpf/bpf_ribbon_widget.dart';
import '../../../core/bpf/asset_lifecycle_bpf.dart';
import '../models/equipment_models.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import 'package:intl/intl.dart';
import '../widgets/loto_badge.dart';

class AssetDetailScreen extends ConsumerWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(currentTenantIdProvider);
    if (tenantId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final docFuture = FirebaseFirestore.instance
        .tenantCollection(tenantId, 'equipment')
        .doc(assetId)
        .get();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Detail'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: docFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Asset not found'));
          }

          final asset = EquipmentModel.fromFirestore(snapshot.data!);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(context, asset),
              BpfRibbonWidget(
                bpfTypeId: 'asset_lifecycle',
                recordType: 'equipment',
                recordId: asset.id ?? assetId,
                definition: assetLifecycleDefinition,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildDetailsSection(asset),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, EquipmentModel asset) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                asset.equipmentName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              GStatusTag(
                label: asset.status,
                color: asset.status == 'Operational'
                    ? Colors.green
                    : (asset.status == 'Under Maintenance' ? Colors.orange : Colors.red),
              ),
            ],
          ),
          if (asset.status == 'Locked Out') ...[
            const SizedBox(height: 8),
            LotoBadge(status: asset.status),
          ],
          const SizedBox(height: 8),
          Text(
            '${asset.category} • ${asset.manufacturer}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(EquipmentModel asset) {
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
            const Text(
              'Asset Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Asset Tag', asset.assetTag),
            _buildInfoRow('Location', asset.location),
            if (asset.assignedToId != null && asset.assignedToId!.isNotEmpty)
              _buildInfoRow('Assigned To', asset.assignedToId!),
            _buildInfoRow('Next Inspection', DateFormat('yMMMd').format(asset.nextInspectionDate)),
            _buildInfoRow('Days Until Inspection', '${asset.daysUntilInspection}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
