import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/property_card.dart';
import '../widgets/property_map_card.dart';
import '../../../config/theme.dart';
import '../providers/property_providers.dart';
import '../models/property_models.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

class PropertyHubScreen extends ConsumerStatefulWidget {
  const PropertyHubScreen({super.key});

  @override
  ConsumerState<PropertyHubScreen> createState() => _PropertyHubScreenState();
}

class _PropertyHubScreenState extends ConsumerState<PropertyHubScreen> {

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            GHeader(
              title: 'Property & Facility Hub',
              subtitle: 'Manage and track real-estate assets across the enterprise',
              trailing: ElevatedButton.icon(
                onPressed: () {
                  UIUtils.showToast(context, 'Add Property form opened');
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Property'),
              ),
            ),
            GSpacing.vLg,

            // Top Stats Row
            propertiesAsync.when(
              data: (properties) => _buildStatsRow(properties),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
            ),
            GSpacing.vLg,

            // Map View Card
            PropertyMapCard(propertiesAsync: propertiesAsync),
            GSpacing.vLg,

            // Property List Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Asset Portfolio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    UIUtils.showToast(context, 'Viewing all assets');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            GSpacing.vMd,

            // Property Grid/List
            propertiesAsync.when(
              data: (properties) {
                final width = MediaQuery.of(context).size.width;
                final crossAxisCount = width > 1200 ? 3 : (width > 800 ? 2 : 1);
                final childAspectRatio = width > 800 ? 1.4 : 1.1;
                
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: properties.length,
                  itemBuilder: (context, index) => PropertyCard(property: properties[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(List<Property> properties) {
    int criticalCount = properties.where((p) => p.status.contains('Critical')).length;
    double avgOccupancy = properties.isEmpty 
        ? 0 
        : (properties.fold(0, (sum, p) => sum + p.occupancy) / properties.fold(0, (sum, p) => sum + p.capacity)) * 100;
    double avgCompliance = properties.isEmpty
        ? 0
        : properties.fold(0.0, (sum, p) => sum + p.complianceScore) / properties.length;

    return Row(
      children: [
        _buildStatItem('Total Assets', properties.length.toString(), Icons.domain, XMTheme.primary),
        GSpacing.hMd,
        _buildStatItem('Avg. Compliance', '${avgCompliance.toStringAsFixed(1)}%', Icons.fact_check_outlined, XMTheme.primary),
        GSpacing.hMd,
        _buildStatItem('Avg. Occupancy', '${avgOccupancy.toStringAsFixed(1)}%', Icons.people_outline, XMTheme.success),
        GSpacing.hMd,
        _buildStatItem('Critical Alerts', criticalCount.toString(), Icons.warning_amber_rounded, XMTheme.error),
      ],
    );
  }


  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: GCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            GSpacing.hMd,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

