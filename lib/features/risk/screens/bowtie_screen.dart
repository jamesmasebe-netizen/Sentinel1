import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../widgets/bowtie_card.dart';
import '../widgets/bowtie_form.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

/// Bow-Tie Analysis — register for threat/barrier/consequence chains.
class BowtieScreen extends ConsumerStatefulWidget {
  const BowtieScreen({super.key});
  @override
  ConsumerState<BowtieScreen> createState() => _BowtieScreenState();
}

class _BowtieScreenState extends ConsumerState<BowtieScreen> {
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
              Text(
                'Threat Analysis',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed:
                    () => UIUtils.showSideSheet(
                      context: context,
                      title: 'New Bow-Tie Analysis',
                      builder: (ctx) => const BowTieForm(),
                    ),
                icon: const Icon(Icons.account_tree_rounded, size: 18),
                label: const Text('New Analysis'),
              ),
            ],
          ),
        ),

        // ─── List ───
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                firestore
                    .tenantCollection(
                      ref.watch(currentTenantIdProvider) ?? "",
                      'bowtie_analyses',
                    )
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .limit(30)
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
                      Icon(
                        Icons.account_tree_outlined,
                        size: 64,
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bow-tie analyses found',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return BowTieCard(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
