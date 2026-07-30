import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/loto_providers.dart';
import 'package:sentinel1/core/widgets/ds_widgets.dart';
import '../../../core/providers/app_providers.dart';
import '../widgets/loto_return_dialog.dart';

class LotoManagementScreen extends ConsumerWidget {
  const LotoManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockedOutAsync = ref.watch(lockedOutEquipmentProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final canRelease = isLotoReleaseAuthorized(profile?.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LOTO Management'),
      ),
      body: lockedOutAsync.when(
        data: (equipmentList) {
          if (equipmentList.isEmpty) {
            return const Center(child: Text('No locked out equipment.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: equipmentList.length,
            separatorBuilder: (_, __) => GSpacing.vSm,
            itemBuilder: (context, index) {
              final eq = equipmentList[index];
              return GCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GHeader(title: eq['name'] ?? 'Unknown Equipment'),
                    GSpacing.vSm,
                    GStatusTag(label: 'Locked Out', color: Colors.red),
                    GSpacing.vSm,
                    Text('Reason: ${eq['lockoutReason'] ?? 'Unknown'}'),
                    Text('Locked out by: ${eq['lockoutBy'] ?? 'Unknown'}'),
                    Text('Date: ${eq['lockoutDate'] ?? 'Unknown'}'),
                    GSpacing.vLg,
                    ElevatedButton(
                      onPressed: canRelease
                          ? () => showLotoReturnDialog(
                                context,
                                ref,
                                equipmentId: eq['id'],
                                equipmentName: eq['name'] ?? 'Unknown Equipment',
                                workOrderId: eq['lockoutWorkOrderId'],
                              )
                          : null,
                      child: Text(
                        canRelease ? 'Inspect & Release' : 'Inspect & Release (Manager/SHEQ only)',
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
