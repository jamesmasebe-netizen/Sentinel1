import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../widgets/observation_card.dart';
import '../widgets/bbs_observation_form.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

/// Behavioral Based Safety — observations, suggestion box, and gamification leaderboard.
class BBSObservationsScreen extends ConsumerWidget {
  const BBSObservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);
    final theme = Theme.of(context);

    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Column(
      children: [
        GHeader(
          title: 'BBS Observations',
          subtitle: 'Behavioral safety and interventions',
          trailing: FilledButton.icon(
            onPressed: () => UIUtils.showSideSheet(
              context: context,
              title: 'New Observation',
              builder: (ctx) => const BBSObservationForm(),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Observation'),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'bbs_observations')
                .where('siteId', isEqualTo: siteId)
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility_outlined, size: 48, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                      GSpacing.vMd,
                      Text('No observations found', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return ObservationCard(data: data);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
