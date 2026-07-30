import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'record_form_sheet.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../providers/training_providers.dart';

class TrainingRecordsTab extends ConsumerWidget {
  const TrainingRecordsTab({super.key});

  void _openRecordForm(BuildContext context) {
    UIUtils.showSideSheet(
      context: context,
      title: 'Add Training Record',
      builder: (ctx) => const RecordFormSheet(),
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
                'Training Records',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _openRecordForm(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Record'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer(
            builder: (ctx, ref, child) {
              final comprehensiveAsync = ref.watch(comprehensiveTrainingProvider);
              return comprehensiveAsync.when(
                data: (comprehensive) {
                  final docs = comprehensive?.trainingRecords ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Theme.of(context).disabledColor,
                          ),
                          GSpacing.vLg,
                          Text(
                            'No training records found',
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
                      final d = docs[i];
                  final isExpired = d['status'] == 'Expired';

                  return GCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.badge_outlined,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          GSpacing.hLg,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['employeeName'] ?? 'Unknown Employee',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                GSpacing.vSm,
                                Text(
                                  d['courseName'] ?? 'No course specified',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                GSpacing.vSm,
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 12,
                                      color: Theme.of(context).disabledColor,
                                    ),
                                    GSpacing.hSm,
                                    Text(
                                      'Expires: ${d['expiryDate']?.toString().split('T').first ?? 'N/A'}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).disabledColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GStatusTag(
                            label: d['status'] ?? 'Unknown',
                            color: isExpired ? XMTheme.error : XMTheme.success,
                          ),
                        ],
                      ),
                    ),
                  );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              );
            },
          ),
        ),
      ],
    );
  }
}
