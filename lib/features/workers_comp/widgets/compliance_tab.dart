import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class ComplianceTab extends ConsumerWidget {
  const ComplianceTab({super.key});

  static const _defaultItems = [
    'Register with COIDA Fund (RAF)',
    'Annual Return of Earnings submitted',
    'W.CL.2 form filed within 7 days of incident',
    'Medical reports obtained from treating doctor',
    'Employee notified of claim status',
    'Return-to-work plan documented',
    'COIDA claim file retained for 3 years',
    'Compensation Commissioner correspondence filed',
    'Section 56 investigation if applicable',
    'Death benefit notifications processed',
  ];

  Future<void> _seedDefaults(WidgetRef ref, String tenantId) async {
    final fs = ref.read(firestoreProvider);
    final coll = fs.tenantCollection(tenantId, 'coida_compliance_checklist');
    final batch = fs.batch();
    for (var i = 0; i < _defaultItems.length; i++) {
      batch.set(coll.doc('item_$i'), {
        'label': _defaultItems[i],
        'done': false,
        'order': i,
      });
    }
    await batch.commit();
  }

  Future<void> _toggle(WidgetRef ref, String tenantId, String docId, bool value) {
    return ref
        .read(firestoreProvider)
        .tenantCollection(tenantId, 'coida_compliance_checklist')
        .doc(docId)
        .update({'done': value});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tenantId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);

    return StreamBuilder<QuerySnapshot>(
      stream: tenantId == null
          ? null
          : fs
              .tenantCollection(tenantId, 'coida_compliance_checklist')
              .orderBy('order')
              .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No COIDA compliance checklist found for this tenant.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: tenantId == null ? null : () => _seedDefaults(ref, tenantId),
                    child: const Text('Create Default Checklist'),
                  ),
                ],
              ),
            ),
          );
        }

        final done = docs.where((d) => (d.data() as Map<String, dynamic>)['done'] == true).length;
        final progress = done / docs.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GCard(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COIDA Compliance',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          GSpacing.vSm,
                          Text('$done / ${docs.length} requirements met', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          color: XMTheme.success,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GSpacing.vLg,
              Text('Compliance Checklist', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              GSpacing.vMd,
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final isDone = d['done'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      onTap: tenantId == null ? null : () => _toggle(ref, tenantId, doc.id, !isDone),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isDone ? XMTheme.success : theme.colorScheme.outline,
                              size: 22,
                            ),
                            GSpacing.hMd,
                            Expanded(
                              child: Text(
                                d['label']?.toString() ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDone ? null : theme.colorScheme.onSurfaceVariant,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
