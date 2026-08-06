import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../services/emergency_service.dart';
import 'drill_form_card.dart';
import 'drill_list_item.dart';

class EmergencyDrillsTab extends ConsumerStatefulWidget {
  const EmergencyDrillsTab({super.key});

  @override
  ConsumerState<EmergencyDrillsTab> createState() => _EmergencyDrillsTabState();
}

class _EmergencyDrillsTabState extends ConsumerState<EmergencyDrillsTab> {
  bool _showDrillForm = false;

  @override
  Widget build(BuildContext context) {
    final drillsAsync = ref.watch(emergencyDrillsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Recent Drills',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed:
                    () => setState(() => _showDrillForm = !_showDrillForm),
                icon: Icon(_showDrillForm ? Icons.close : Icons.add, size: 18),
                label: Text(_showDrillForm ? 'Cancel' : 'Log Drill'),
              ),
            ],
          ),
        ),
        if (_showDrillForm)
          DrillFormCard(onCancel: () => setState(() => _showDrillForm = false)),
        Expanded(
          child: drillsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (drills) {
              if (drills.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emergency_outlined,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      GSpacing.vLg,
                      Text(
                        'No drills logged',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: drills.length,
                itemBuilder: (ctx, i) => DrillListItem(drill: drills[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}
