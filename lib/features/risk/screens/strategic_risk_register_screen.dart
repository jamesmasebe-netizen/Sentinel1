import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../services/strategic_risk_service.dart';
import '../widgets/strategic_risk_card.dart';
import '../widgets/strategic_risk_form.dart';

/// Strategic Risk Register — corporate-level risks with likelihood × impact scoring.
class StrategicRiskRegisterScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? highlightId;

  const StrategicRiskRegisterScreen({
    super.key,
    this.initialSearch,
    this.highlightId,
  });

  @override
  ConsumerState<StrategicRiskRegisterScreen> createState() =>
      _StrategicRiskRegisterScreenState();
}

class _StrategicRiskRegisterScreenState
    extends ConsumerState<StrategicRiskRegisterScreen> {
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
    final risksAsync = ref.watch(strategicRisksProvider);

    return Column(
      children: [
        // ─── Actions Bar ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Text(
                'Corporate Risks',
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
                      title: 'New Strategic Risk',
                      builder:
                          (ctx) => const StrategicRiskForm(),
                    ),
                icon: const Icon(Icons.shield_rounded, size: 18),
                label: const Text('Add Risk'),
              ),
            ],
          ),
        ),

        // ─── List ───
        Expanded(
          child: risksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (docs) {
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 64,
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      GSpacing.vMd,
                      Text(
                        'No strategic risks registered',
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
                  return StrategicRiskCard(risk: docs[i]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
