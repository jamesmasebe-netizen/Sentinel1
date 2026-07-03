import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'doc_list_item.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class ExpiringTab extends ConsumerWidget {
  const ExpiringTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final siteId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);

    return StreamBuilder<QuerySnapshot>(
      stream:
          siteId == null
              ? null
              : fs
                  .tenantCollection(
                    ref.watch(currentTenantIdProvider) ?? "",
                    'compliance_docs',
                  )
                  .where('siteId', isEqualTo: siteId)
                  .where('daysUntilExpiry', isLessThanOrEqualTo: 90)
                  .orderBy('daysUntilExpiry')
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
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: XMTheme.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    size: 48,
                    color: XMTheme.success,
                  ),
                ),
                GSpacing.vLg,
                Text(
                  'All Documents Up to Date',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GSpacing.vSm,
                Text(
                  'No critical expiries in the next 90 days',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
            return DocListItem(data: d, showExpiryContext: true);
          },
        );
      },
    );
  }
}
