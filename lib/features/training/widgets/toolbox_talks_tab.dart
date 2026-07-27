import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'talk_form_sheet.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class ToolboxTalksTab extends ConsumerWidget {
  const ToolboxTalksTab({super.key});

  void _openTalkForm(BuildContext context) {
    UIUtils.showSideSheet(
      context: context,
      title: 'Log Toolbox Talk',
      builder: (ctx) => const TalkFormSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Recent Talks',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _openTalkForm(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Talk'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                siteId == null
                    ? null
                    : firestore
                        .tenantCollection(
                          ref.watch(currentTenantIdProvider) ?? "",
                          'toolbox_talks',
                        )
                        .where('siteId', isEqualTo: siteId)
                        .orderBy('createdAt', descending: true)
                        .limit(50)
                        .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.record_voice_over_outlined,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      GSpacing.vLg,
                      Text(
                        'No toolbox talks logged',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final attendees =
                      (d['attendees'] as List?)?.cast<String>() ?? [];

                  return GCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                d['topic'] ?? 'Untitled Talk',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                d['date']?.toString().split('T').first ?? '',
                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          GSpacing.vMd,
                          Row(
                            children: [
                              if (d['location'] != null &&
                                  d['location'].toString().isNotEmpty) ...[
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                                GSpacing.hSm,
                                Text(
                                  d['location'],
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                GSpacing.hMd,
                              ],
                              Icon(
                                Icons.people_outline,
                                size: 14,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                              GSpacing.hSm,
                              Text(
                                '${attendees.length} attendees',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          if (attendees.isNotEmpty) ...[
                            GSpacing.vLg,
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children:
                                  attendees
                                      .take(5)
                                      .map(
                                        (a) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            a,
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.labelSmall,
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
