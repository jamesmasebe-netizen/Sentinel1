import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../models/property_models.dart';
import '../providers/property_providers.dart';
import 'property_asset_form.dart';

class PropertyAssetsTab extends ConsumerWidget {
  final Property property;

  const PropertyAssetsTab({super.key, required this.property});

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, VoidCallback onAdd) {
    return Row(
      children: [
        Icon(icon, color: XMTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: XMTheme.primary,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.add, color: XMTheme.primary),
          onPressed: onAdd,
        ),
      ],
    );
  }

  Widget _buildAssetCard(AssetInfo asset) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: XMTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(XMTheme.radiusSm),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: XMTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    asset.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Condition: ',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        asset.condition,
                        style: TextStyle(
                          color:
                              asset.condition == 'Good' ||
                                      asset.condition == 'Excellent'
                                  ? XMTheme.success
                                  : XMTheme.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        asset.condition == 'Operational' ||
                                asset.condition == 'Good'
                            ? XMTheme.success.withValues(alpha: 0.1)
                            : XMTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(XMTheme.radiusXl),
                  ),
                  child: Text(
                    asset.condition.toUpperCase(),
                    style: TextStyle(
                      color:
                          asset.condition == 'Operational' ||
                                  asset.condition == 'Good'
                              ? XMTheme.success
                              : XMTheme.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
    final assetsAsync = ref.watch(propertyAssetsProvider(property.id));

    return assetsAsync.when(
      data:
          (assets) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionHeader(
                context,
                'CRITICAL ASSETS',
                Icons.inventory_2_outlined,
                () => UIUtils.showSideSheet(
                  context: context,
                  title: 'Add Asset',
                  builder: (_) => PropertyAssetForm(propertyId: property.id),
                ),
              ),
              const SizedBox(height: 16),
              if (assets.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No assets recorded',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...assets.map(
                  (asset) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAssetCard(asset),
                  ),
                ),
            ],
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
