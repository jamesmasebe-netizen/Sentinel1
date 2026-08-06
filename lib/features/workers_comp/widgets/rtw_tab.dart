import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../services/workers_comp_service.dart';

class RtwTab extends ConsumerWidget {
  const RtwTab({super.key});

  Future<void> _updateRtwStatus(
    BuildContext context,
    WidgetRef ref,
    String id,
    String value,
  ) async {
    try {
      await ref.read(workersCompServiceProvider).updateClaimRtwStatus(id, value);
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
    final activeCasesAsync = ref.watch(activeRtwCasesProvider);

    return activeCasesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (claims) {
        if (claims.isEmpty) {
          return const Center(child: Text('No active RTW cases'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: claims.length,
          itemBuilder: (ctx, i) {
            final claim = claims[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.employeeName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GSpacing.vSm,
                    Text(
                      'Lost days to date: ${claim.lostDays}',
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
                      children: ['Off Sick', 'Light Duty', 'Full Duty'].map((s) {
                        final isSelected = claim.rtwStatus == s;
                        return ChoiceChip(
                          label: Text(s),
                          selected: isSelected,
                          onSelected: (_) => _updateRtwStatus(context, ref, claim.id, s),
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
