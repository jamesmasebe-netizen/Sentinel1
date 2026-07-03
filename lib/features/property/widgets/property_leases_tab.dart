import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../providers/property_providers.dart';
import '../models/property_models.dart';

class PropertyLeasesTab extends ConsumerWidget {
  final Property property;
  const PropertyLeasesTab({super.key, required this.property});

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: XMTheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaseDetail(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildLeaseCard(LeaseInfo lease) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lease.tenantId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        lease.status == 'Active'
                            ? XMTheme.success.withValues(alpha: 0.1)
                            : XMTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(XMTheme.radiusXl),
                  ),
                  child: Text(
                    lease.status.toUpperCase(),
                    style: TextStyle(
                      color:
                          lease.status == 'Active'
                              ? XMTheme.success
                              : XMTheme.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLeaseDetail(
                  Icons.calendar_today_outlined,
                  'Start',
                  lease.startDate.toIso8601String().split('T')[0],
                ),
                const SizedBox(width: 24),
                _buildLeaseDetail(
                  Icons.event_busy_outlined,
                  'End',
                  lease.endDate.toIso8601String().split('T')[0],
                ),
                const SizedBox(width: 24),
                _buildLeaseDetail(
                  Icons.payments_outlined,
                  'Monthly',
                  '\$${(lease.monthlyRent / 1000).toStringAsFixed(0)}k',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leasesAsync = ref.watch(propertyLeasesProvider(property.id));

    return leasesAsync.when(
      data:
          (leases) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionHeader('TENANT LEASES', Icons.description_outlined),
              const SizedBox(height: 16),
              if (leases.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No leases recorded',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...leases.map(
                  (lease) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLeaseCard(lease),
                  ),
                ),
            ],
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
