import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../services/bowtie_service.dart';
import '../widgets/bowtie_card.dart';
import '../widgets/bowtie_form.dart';

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
    if (siteId == null) return const Center(child: Text('No site assigned'));
    final analysesAsync = ref.watch(bowtieAnalysesProvider);

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
          child: analysesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (docs) {
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
                  return BowTieCard(analysis: docs[i]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
