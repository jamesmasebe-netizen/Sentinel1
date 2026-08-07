import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../services/environment_service.dart';
import 'spill_form.dart';
import 'spill_list_item.dart';

class SpillLogsTab extends ConsumerWidget {
  const SpillLogsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spillsAsync = ref.watch(environmentalSpillsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spill Logs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FilledButton.icon(
                onPressed:
                    () => UIUtils.showSideSheet(
                      context: context,
                      title: 'Log Spill Incident',
                      builder: (ctx) => const SpillForm(),
                    ),
                icon: const Icon(Icons.water_drop_outlined, size: 18),
                label: const Text('Log Spill'),
              ),
            ],
          ),
        ),
        Expanded(
          child: spillsAsync.when(
            data: (spills) {
              if (spills.isEmpty) {
                return const Center(child: Text('No spill records logged'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: spills.length,
                itemBuilder: (ctx, i) => SpillListItem(spill: spills[i]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}
