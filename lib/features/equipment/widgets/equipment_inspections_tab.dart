import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/ds_widgets.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class EquipmentInspectionsTab extends ConsumerWidget {
  const EquipmentInspectionsTab({super.key});

  IconData _categoryIcon(String? cat) {
    switch (cat) {
      case 'Heavy Plant':
        return Icons.agriculture;
      case 'Light Vehicle':
        return Icons.directions_car;
      case 'Power Tools':
        return Icons.handyman;
      case 'Lifting Equipment':
        return Icons.forklift;
      case 'Electrical':
        return Icons.electrical_services;
      case 'Pressure Vessel':
        return Icons.science;
      default:
        return Icons.precision_manufacturing;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);
    return StreamBuilder<QuerySnapshot>(
      stream:
          siteId == null
              ? null
              : fs
                  .tenantCollection(
                    ref.watch(currentTenantIdProvider) ?? "",
                    'equipment',
                  )
                  .where('siteId', isEqualTo: siteId)
                  .where('daysUntilInspection', isLessThanOrEqualTo: 30)
                  .orderBy('daysUntilInspection')
                  .limit(50)
                  .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: XMTheme.success.withValues(alpha: 0.5),
                ),
                GSpacing.vLg,
                Text(
                  'All inspections current',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                GSpacing.vSm,
                Text(
                  'No inspections due in the next 30 days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final days = d['daysUntilInspection'] as int? ?? 0;
            return GCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(
                  _categoryIcon(d['category']),
                  color: days < 0 ? XMTheme.error : XMTheme.warning,
                  size: 24,
                ),
                title: Text(
                  d['equipmentName'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${d['location'] ?? ''} • ${d['assetTag'] ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  days < 0 ? 'OVERDUE' : '${days}d',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: days < 0 ? XMTheme.error : XMTheme.warning,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
