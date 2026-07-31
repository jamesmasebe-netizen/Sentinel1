import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../field_service/providers/field_service_providers.dart';
import '../../field_service/screens/work_order_details_screen.dart';

/// Real maintenance log — streams work_orders linked to equipment (assetId
/// set), the same field LotoAutomation.lockoutFailedEquipment() writes when
/// it auto-generates a work order. See F-217 in docs/fixes/FIX_LIST.md.
class MaintenanceLogDialog extends ConsumerWidget {
  const MaintenanceLogDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workOrdersAsync = ref.watch(workOrdersStreamProvider);

    return workOrdersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (allOrders) {
        final equipmentOrders = allOrders
            .where((wo) => wo.assetId != null && wo.assetId!.isNotEmpty)
            .where((wo) => wo.status != 'COMPLETED' && wo.status != 'CANCELED')
            .toList();

        if (equipmentOrders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: XMTheme.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.engineering_outlined,
                    size: 80,
                    color: XMTheme.success,
                  ),
                ),
                GSpacing.vLg,
                Text(
                  'No Open Maintenance Work Orders',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                GSpacing.vSm,
                Text(
                  'Equipment-linked work orders (from LOTO events or manual scheduling) will appear here.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: equipmentOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final wo = equipmentOrders[i];
            return GCard(
              onTap: () => UIUtils.showSideSheet(
                context: context,
                title: wo.workOrderNumber,
                builder: (_) => WorkOrderDetailsScreen(workOrderId: wo.id),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.build_circle_outlined,
                    color: wo.priority == 'HIGH' || wo.priority == 'CRITICAL'
                        ? XMTheme.error
                        : XMTheme.warning,
                  ),
                  GSpacing.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wo.workOrderNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          wo.description ?? 'No description',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  GStatusTag(label: wo.status, color: XMTheme.warning),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
