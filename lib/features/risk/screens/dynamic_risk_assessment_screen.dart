import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../widgets/dra_card.dart';
import '../widgets/dra_form.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

/// Dynamic Risk Assessment — on-the-spot task risk evaluation with hazard/control chip lists.
class DynamicRiskAssessmentScreen extends ConsumerStatefulWidget {
  const DynamicRiskAssessmentScreen({super.key});
  @override
  ConsumerState<DynamicRiskAssessmentScreen> createState() => _DRAState();
}

class _DRAState extends ConsumerState<DynamicRiskAssessmentScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Column(
      children: [
        // ─── Actions Bar ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Text('Live Assessments', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'New Dynamic Assessment',
                  builder: (ctx) => DRAForm(tenantId: ref.read(currentTenantIdProvider) ?? ''),
                ),
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text('New Assessment'),
              ),
            ],
          ),
        ),

        // ─── Assessment List ───
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'dynamic_risk_assessments')
                .where('siteId', isEqualTo: siteId)
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                      GSpacing.vMd,
                      Text('No dynamic assessments yet', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return DRACard(data: data);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

