import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/bpf/asset_lifecycle_bpf.dart';
import '../../../core/bpf/bpf_models.dart';
import '../../../core/bpf/bpf_service.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../models/equipment_models.dart';
import '../providers/equipment_providers.dart';
import 'asset_detail_screen.dart';

/// Fleet-wide view of where every piece of equipment sits in the asset_lifecycle
/// BPF (acquisition -> deployment -> maintenance -> decommissioning). The BPF
/// itself, and the per-asset stage-advance UI, already exist (started at
/// creation time in EquipmentAssetTab, rendered via BpfRibbonWidget in
/// AssetDetailScreen) — this screen is the fleet-level list that was missing,
/// not a new BPF or a new advance mechanism.
class AssetLifecycleScreen extends ConsumerWidget {
  const AssetLifecycleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentAsync = ref.watch(equipmentListProvider);
    final instancesAsync = ref.watch(bpfInstancesByTypeProvider('asset_lifecycle'));

    return equipmentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (equipment) {
        if (equipment.isEmpty) {
          return const Center(child: Text('No equipment registered'));
        }
        return instancesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
          data: (instances) {
            final byEquipmentId = <String, BpfInstance>{
              for (final instance in instances)
                if (instance.linkedRecordIds['equipment'] != null)
                  instance.linkedRecordIds['equipment']!: instance,
            };

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: equipment.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final asset = equipment[i];
                final instance = byEquipmentId[asset.id];
                return _AssetLifecycleTile(asset: asset, instance: instance);
              },
            );
          },
        );
      },
    );
  }
}

class _AssetLifecycleTile extends StatelessWidget {
  final EquipmentModel asset;
  final BpfInstance? instance;

  const _AssetLifecycleTile({required this.asset, this.instance});

  @override
  Widget build(BuildContext context) {
    BpfStageDefinition? stage;
    if (instance != null) {
      for (final s in assetLifecycleDefinition.stages) {
        if (s.id == instance!.currentStageId) {
          stage = s;
          break;
        }
      }
    }

    return GCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AssetDetailScreen(assetId: asset.id ?? ''),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.equipmentName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  asset.assetTag,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          GStatusTag(
            label: stage?.title ?? 'Not tracked',
            color: stage == null ? Colors.grey : Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}
