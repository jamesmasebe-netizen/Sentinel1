import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import 'waste_form.dart';
import 'waste_list_item.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class WasteManifestsTab extends ConsumerStatefulWidget {
  const WasteManifestsTab({super.key});

  @override
  ConsumerState<WasteManifestsTab> createState() => _WasteManifestsTabState();
}

class _WasteManifestsTabState extends ConsumerState<WasteManifestsTab> {


  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Waste Manifests', style: Theme.of(context).textTheme.titleMedium),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
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
          child: StreamBuilder<QuerySnapshot>(
            stream: siteId == null
                ? null
                : fs
                    .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'waste_manifests')
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('No waste manifests logged'));
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return WasteListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
