import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../models/property_models.dart';
import '../../../core/widgets/ds_widgets.dart';

class PropertyCard extends StatelessWidget {
  final Property property;

  const PropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat('ASSETS', property.totalAssets.toString(), Icons.inventory_2_outlined),
                    _buildMiniStat('COMPLIANCE', '${property.complianceScore}%', Icons.verified_user_outlined),
                    _buildMiniStat('OCCUPANCY', '${(occupancyPercent * 100).toInt()}%', Icons.people_outline),
                  ],
                ),
                const SizedBox(height: 8),
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
