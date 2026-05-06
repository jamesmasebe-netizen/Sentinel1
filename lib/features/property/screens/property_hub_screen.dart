import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../providers/property_providers.dart';
import '../models/property_models.dart';
import '../../../core/widgets/ds_widgets.dart';

class PropertyHubScreen extends ConsumerStatefulWidget {
  const PropertyHubScreen({super.key});

  @override
  ConsumerState<PropertyHubScreen> createState() => _PropertyHubScreenState();
}

class _PropertyHubScreenState extends ConsumerState<PropertyHubScreen> {
  final LatLng _initialPosition = const LatLng(-26.1075, 28.0567); // JHB focus

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
                onPressed: () {},
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
            _buildMapCard(propertiesAsync),
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
                  onPressed: () {},
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
                  itemBuilder: (context, index) => _buildPropertyCard(properties[index]),
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

  Widget _buildMapCard(AsyncValue<List<Property>> propertiesAsync) {
    return GCard(
      padding: EdgeInsets.zero,
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(XMTheme.radiusXl),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(XMTheme.radiusXl),
        child: propertiesAsync.when(
          data: (properties) {
            final markers = properties.map((p) => Marker(
              markerId: MarkerId(p.id),
              position: LatLng(p.lat, p.lng),
              infoWindow: InfoWindow(title: p.name, snippet: p.type),
              onTap: () => context.push('/property/${p.id}'),
            )).toSet();

            return GoogleMap(
              initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 10),
              markers: markers,
              myLocationEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Icon(Icons.map_outlined, size: 64, color: Colors.grey)),
        ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    double occupancyPercent = (property.occupancy / property.capacity);
    Color statusColor = property.status == 'Optimal' 
        ? XMTheme.success 
        : (property.status.contains('Critical') ? XMTheme.error : XMTheme.warning);

    return GCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/property/${property.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Thumbnail
            Container(
              height: 120,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80&w=400'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GStatusTag(label: property.status.toUpperCase(), color: statusColor),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    property.address,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  GSpacing.vMd,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('ASSETS', property.totalAssets.toString(), Icons.inventory_2_outlined),
                      _buildMiniStat('COMPLIANCE', '${property.complianceScore}%', Icons.verified_user_outlined),
                      _buildMiniStat('OCCUPANCY', '${(occupancyPercent * 100).toInt()}%', Icons.people_outline),
                    ],
                  ),
                  GSpacing.vMd,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: property.complianceScore / 100,
                      minHeight: 4,
                      backgroundColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        property.complianceScore > 80 ? XMTheme.success : (property.complianceScore > 60 ? XMTheme.warning : XMTheme.error)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: Colors.grey),
            GSpacing.hXs,
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
        GSpacing.vXs,
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: XMTheme.primary)),
      ],
    );
  }

}
