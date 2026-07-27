import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/equipment_providers.dart';
import '../../../core/widgets/searchable_multi_select.dart';

class EquipmentMultiSelector extends ConsumerWidget {
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
  final String label;
  final String hintText;

  const EquipmentMultiSelector({
    super.key,
    required this.selectedItems,
    required this.onChanged,
    this.label = 'Allocated Asset IDs',
    this.hintText = 'Search or select assets...',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentAsync = ref.watch(equipmentListProvider);

    return equipmentAsync.when(
      data: (equipmentList) {
        // Filter out locked out assets for allocation
        final availableEquipment = equipmentList.where((e) => e.status != 'Locked Out').toList();
        
        final availableItems = availableEquipment.map((e) => e.id ?? '').where((id) => id.isNotEmpty).toList();
        final itemLabels = {
          for (var e in availableEquipment) if (e.id != null) e.id!: '${e.equipmentName} (${e.id})'
        };

        return SearchableStringMultiSelect(
          label: label,
          hintText: hintText,
          availableItems: availableItems,
          itemLabels: itemLabels,
          selectedItems: selectedItems,
          onChanged: onChanged,
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Text('Error loading equipment: $e'),
    );
  }
}
