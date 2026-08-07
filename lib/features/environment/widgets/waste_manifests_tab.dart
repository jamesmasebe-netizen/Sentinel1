import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../services/environment_service.dart';
import 'waste_form.dart';
import 'waste_list_item.dart';

class WasteManifestsTab extends ConsumerWidget {
  const WasteManifestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifestsAsync = ref.watch(wasteManifestsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Waste Manifests',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FilledButton.icon(
                onPressed:
                    () => UIUtils.showSideSheet(
                      context: context,
                      title: 'New Waste Manifest',
                      builder: (ctx) => const WasteForm(),
                    ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Manifest'),
              ),
            ],
          ),
        ),
        Expanded(
          child: manifestsAsync.when(
            data: (manifests) {
              if (manifests.isEmpty) {
                return const Center(child: Text('No waste manifests logged'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: manifests.length,
                itemBuilder: (ctx, i) => WasteListItem(manifest: manifests[i]),
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
