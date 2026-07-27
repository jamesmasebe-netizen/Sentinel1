import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class ExpiryAlertsTab extends ConsumerWidget {
  const ExpiryAlertsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);

    return StreamBuilder<QuerySnapshot>(
      stream:
          siteId == null
              ? null
              : firestore
                  .tenantCollection(
                    ref.watch(currentTenantIdProvider) ?? "",
                    'training_records',
                  )
                  .where('siteId', isEqualTo: siteId)
                  .where('status', isEqualTo: 'Active')
                  .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        final now = DateTime.now();

        final expiring =
            docs.where((d) {
              try {
                final data = d.data() as Map<String, dynamic>;
                final exp = DateTime.parse(data['expiryDate']);
                return exp.difference(now).inDays <= 60 && exp.isAfter(now);
              } catch (_) {
                return false;
              }
            }).toList();

        if (expiring.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: XMTheme.success.withValues(alpha: 0.5),
                ),
                GSpacing.vLg,
                Text(
                  'All certifications current',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                GSpacing.vSm,
                Text(
                  'No upcoming expirations within 60 days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expiring.length,
          itemBuilder: (ctx, i) {
            final d = expiring[i].data() as Map<String, dynamic>;
            final expDate = DateTime.parse(d['expiryDate']);
            final daysLeft = expDate.difference(now).inDays;
            final isUrgent = daysLeft <= 14;

            return GCard(
              margin: const EdgeInsets.only(bottom: 12),
              color:
                  isUrgent
                      ? Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.3)
                      : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isUrgent
                          ? Icons.priority_high
                          : Icons.warning_amber_rounded,
                      color: isUrgent ? XMTheme.error : XMTheme.warning,
                    ),
                    GSpacing.hLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['employeeName'] ?? '',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            d['courseName'] ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$daysLeft days',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isUrgent ? XMTheme.error : XMTheme.warning,
                          ),
                        ),
                        Text(
                          'Remaining',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
