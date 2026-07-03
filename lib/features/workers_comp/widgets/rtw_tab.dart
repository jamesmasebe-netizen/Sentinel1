import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class RtwTab extends ConsumerWidget {
  const RtwTab({super.key});

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String id,
    String field,
    String value,
  ) async {
    try {
      await ref
          .read(firestoreProvider)
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'coida_claims',
          )
          .doc(id)
          .update({field: value});
      if (context.mounted) {
        UIUtils.showToast(context, 'Status updated to $value');
      }
    } catch (e) {
      if (context.mounted) {
        UIUtils.showToast(context, '$e', type: ToastType.error);
      }
    }
  }

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
                    'coida_claims',
                  )
                  .where('siteId', isEqualTo: siteId)
                  .where('status', isNotEqualTo: 'Closed')
                  .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No active RTW cases'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['employeeName'] ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GSpacing.vSm,
                    Text(
                      'Lost days to date: ${d['lostDays'] ?? 0}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    GSpacing.vMd,
                    const Divider(),
                    GSpacing.vMd,
                    Text(
                      'Current Return to Work Status',
                      style: theme.textTheme.labelSmall,
                    ),
                    GSpacing.vSm,
                    Wrap(
                      spacing: 8,
                      children:
                          ['Off Sick', 'Light Duty', 'Full Duty'].map((s) {
                            final isSelected = d['rtwStatus'] == s;
                            return ChoiceChip(
                              label: Text(s),
                              selected: isSelected,
                              onSelected:
                                  (_) => _updateStatus(
                                    context,
                                    ref,
                                    docs[i].id,
                                    'rtwStatus',
                                    s,
                                  ),
                              selectedColor: XMTheme.success.withValues(
                                alpha: 0.15,
                              ),
                              checkmarkColor: XMTheme.success,
                              labelStyle: TextStyle(
                                color: isSelected ? XMTheme.success : null,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                            );
                          }).toList(),
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
