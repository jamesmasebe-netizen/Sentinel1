import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../services/workers_comp_service.dart';

class ComplianceTab extends ConsumerWidget {
  const ComplianceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tenantId = ref.watch(currentTenantIdProvider);
    final checklistAsync = ref.watch(complianceChecklistProvider);

    return checklistAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No COIDA compliance checklist found for this tenant.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: tenantId == null
                        ? null
                        : () => ref.read(workersCompServiceProvider).seedComplianceChecklist(),
                    child: const Text('Create Default Checklist'),
                  ),
                ],
              ),
            ),
          );
        }

        final done = items.where((i) => i.done).length;
        final progress = done / items.length;

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
                          Text('$done / ${items.length} requirements met', style: theme.textTheme.bodySmall),
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
              ...items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () =>
                          ref.read(workersCompServiceProvider).toggleComplianceItem(item.id, !item.done),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              item.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: item.done ? XMTheme.success : theme.colorScheme.outline,
                              size: 22,
                            ),
                            GSpacing.hMd,
                            Expanded(
                              child: Text(
                                item.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: item.done ? null : theme.colorScheme.onSurfaceVariant,
                                  decoration: item.done ? TextDecoration.lineThrough : null,
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
