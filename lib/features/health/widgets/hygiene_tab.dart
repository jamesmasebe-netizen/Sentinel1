import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import 'hygiene_form.dart';
import 'hygiene_list_item.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class HygieneTab extends ConsumerStatefulWidget {
  const HygieneTab({super.key});

  @override
  ConsumerState<HygieneTab> createState() => _HygieneTabState();
}

class _HygieneTabState extends ConsumerState<HygieneTab> {


  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hygiene Surveys', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Environmental monitoring logs', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'New Hygiene Assessment',
                  builder: (ctx) => const HygieneForm(),
                ),
                icon: const Icon(Icons.science_rounded, size: 20),
                label: const Text('New Survey'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: siteId == null
                ? null
                : fs
                    .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'hygiene_surveys')
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No hygiene surveys logged'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return HygieneListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


