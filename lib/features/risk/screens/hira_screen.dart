import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/safety_models.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../services/hira_service.dart';
import '../widgets/hira_card.dart';
import '../widgets/hira_form.dart';

/// Baseline HIRA (Hazard Identification & Risk Assessment) — full CRUD register.
class HiraScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? highlightId;

  const HiraScreen({super.key, this.initialSearch, this.highlightId});

  @override
  ConsumerState<HiraScreen> createState() => _HiraScreenState();
}

class _HiraScreenState extends ConsumerState<HiraScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      // _search = widget.initialSearch!;
    }
    if (widget.highlightId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UIUtils.showSideSheet(
          context: context,
          title: 'Item Details',
          builder:
              (ctx) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Viewing item: ${widget.highlightId}\n(Detail view not yet implemented)',
                ),
              ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final siteId = ref.watch(currentTenantIdProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));
    final assessmentsAsync = ref.watch(hiraAssessmentsProvider);

    return Column(
      children: [
        // ─── Actions Bar ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Text(
                'Assessment History',
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
                      title: 'New HIRA Assessment',
                      builder: (ctx) => const HiraForm(),
                    ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Assessment'),
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
                        Icons.assessment_outlined,
                        size: 64,
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      GSpacing.vMd,
                      Text(
                        'No HIRA records found',
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
                  final assessment = docs[i];
                  return HiraCard(
                    assessment: assessment,
                    onTap: () => _showDetails(context, assessment),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDetails(BuildContext context, RiskAssessment assessment) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              assessment.title.isEmpty ? 'Details' : assessment.title,
            ),
            content: Text(
              // Fixed 2026-08-06 (same class of bug as FIX_LIST.md F-306): previously read
              // data['preparedBy']/data['riskScore'], neither of which hira_form.dart ever
              // writes — this always showed "Unknown"/0. assessorId maps to the real
              // 'assessedBy' key; inherentRiskScore is the real, always-populated score field.
              'Prepared by: ${assessment.assessorId ?? 'Unknown'}\nRisk Score: ${assessment.inherentRiskScore ?? 0}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
