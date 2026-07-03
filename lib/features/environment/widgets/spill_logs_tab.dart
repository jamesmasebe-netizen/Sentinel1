import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import 'spill_form.dart';
import 'spill_list_item.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class SpillLogsTab extends ConsumerStatefulWidget {
  const SpillLogsTab({super.key});

  @override
  ConsumerState<SpillLogsTab> createState() => _SpillLogsTabState();
}

class _SpillLogsTabState extends ConsumerState<SpillLogsTab> {


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
              Text('Spill Logs', style: Theme.of(context).textTheme.titleMedium),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
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
          child: StreamBuilder<QuerySnapshot>(
            stream: siteId == null
                ? null
                : fs
                    .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'environmental_spills')
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('No spill records logged'));
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return SpillListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
