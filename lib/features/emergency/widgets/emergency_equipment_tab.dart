import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../services/emergency_service.dart';
import 'equipment_form_card.dart';
import 'equipment_list_item.dart';

class EmergencyEquipmentTab extends ConsumerStatefulWidget {
  const EmergencyEquipmentTab({super.key});

  @override
  ConsumerState<EmergencyEquipmentTab> createState() =>
      _EmergencyEquipmentTabState();
}

class _EmergencyEquipmentTabState extends ConsumerState<EmergencyEquipmentTab> {
  bool _showEquipForm = false;

  @override
  Widget build(BuildContext context) {
    final equipmentAsync = ref.watch(emergencyEquipmentProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Safety Equipment',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed:
                    () => setState(() => _showEquipForm = !_showEquipForm),
                icon: Icon(_showEquipForm ? Icons.close : Icons.add, size: 18),
                label: Text(_showEquipForm ? 'Cancel' : 'Add Item'),
              ),
            ],
          ),
        ),
        if (_showEquipForm)
          EquipmentFormCard(
            onCancel: () => setState(() => _showEquipForm = false),
          ),

        Expanded(
          child: equipmentAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (equipment) {
              if (equipment.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.build_outlined,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      GSpacing.vLg,
                      Text(
                        'No equipment found',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: equipment.length,
                itemBuilder: (ctx, i) => EquipmentListItem(equipment: equipment[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}
