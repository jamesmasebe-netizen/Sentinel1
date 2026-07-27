import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import 'first_aid_form.dart';
import 'first_aid_list_item.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class FirstAidTab extends ConsumerStatefulWidget {
  const FirstAidTab({super.key});

  @override
  ConsumerState<FirstAidTab> createState() => _FirstAidTabState();
}

class _FirstAidTabState extends ConsumerState<FirstAidTab> {
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
                  Text(
                    'First Aid Log',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Incident treatment records',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed:
                    () => UIUtils.showSideSheet(
                      context: context,
                      title: 'New First Aid Incident',
                      builder: (ctx) => const FirstAidForm(),
                    ),
                icon: const Icon(Icons.medical_services_rounded, size: 20),
                label: const Text('Log Entry'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                siteId == null
                    ? null
                    : fs
                        .tenantCollection(
                          ref.watch(currentTenantIdProvider) ?? "",
                          'first_aid_log',
                        )
                        .where('siteId', isEqualTo: siteId)
                        .orderBy('createdAt', descending: true)
                        .limit(50)
                        .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No first aid entries logged'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return FirstAidListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
