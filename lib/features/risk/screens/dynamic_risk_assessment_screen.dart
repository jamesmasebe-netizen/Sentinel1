import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../services/dra_service.dart';
import '../widgets/dra_card.dart';
import '../widgets/dra_form.dart';

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
    if (siteId == null) return const Center(child: Text('No site assigned'));
    final assessmentsAsync = ref.watch(draAssessmentsProvider);

    return Column(
      children: [
        // ─── Actions Bar ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Text(
                'Live Assessments',
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
                      title: 'New Dynamic Assessment',
                      builder:
                          (ctx) => const DRAForm(),
                    ),
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text('New Assessment'),
              ),
            ],
          ),
        ),

        // ─── Assessment List ───
        Expanded(
          child: assessmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (docs) {
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 64,
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      GSpacing.vMd,
                      Text(
                        'No dynamic assessments yet',
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
                itemBuilder: (ctx, i) {
                  return DRACard(assessment: docs[i]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
