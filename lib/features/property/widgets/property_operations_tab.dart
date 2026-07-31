import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../models/property_models.dart';

class PropertyOperationsTab extends ConsumerWidget {
  final Property property;
  const PropertyOperationsTab({super.key, required this.property});

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: XMTheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOccupancyCard(BuildContext context) {
    double percent = property.occupancy / property.capacity;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${property.occupancy}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                    const Text('Current Souls on Site', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Text('/ ${property.capacity} limit', style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 12,
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(percent > 0.9 ? XMTheme.error : XMTheme.success),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedEventsList(
    BuildContext context,
    WidgetRef ref, {
    required String collection,
    required String label,
    List<String>? statusFilter,
  }) {
    final tenantId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);

    Query<Map<String, dynamic>>? query;
    if (tenantId != null) {
      query = fs.tenantCollection(tenantId, collection).where('location', isEqualTo: property.name);
      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.where('status', whereIn: statusFilter);
      }
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query?.snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.grey.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(XMTheme.radiusLg)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey),
                const SizedBox(width: 12),
                Text('${docs.length} $label linked to "${property.name}"', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                  onPressed: docs.isEmpty
                      ? null
                      : () => UIUtils.showSideSheet(
                            context: context,
                            title: label,
                            builder: (ctx) => ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: docs.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final d = docs[i].data() as Map<String, dynamic>;
                                return ListTile(
                                  title: Text((d['title'] ?? d['type'] ?? 'Untitled').toString()),
                                  subtitle: Text(d['status']?.toString() ?? ''),
                                );
                              },
                            ),
                          ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Live Occupancy', Icons.people_outline),
        _buildOccupancyCard(context),
        const SizedBox(height: 32),
        _buildSectionHeader('Linked Incidents', Icons.warning_amber_rounded),
        const Text('Displaying recent safety events at this location', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        _buildLinkedEventsList(context, ref, collection: 'incidents', label: 'Incidents'),
        const SizedBox(height: 32),
        _buildSectionHeader('Active Permits', Icons.assignment_outlined),
        const SizedBox(height: 16),
        _buildLinkedEventsList(
          context,
          ref,
          collection: 'permits',
          label: 'Active Permits',
          statusFilter: const ['Approved', 'Active'],
        ),
      ],
    );
  }
}
