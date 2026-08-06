import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../services/health_service.dart';
import 'hygiene_form.dart';
import 'hygiene_list_item.dart';

class HygieneTab extends ConsumerWidget {
  const HygieneTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final surveysAsync = ref.watch(hygieneSurveysProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hygiene Surveys',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Environmental monitoring logs',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed:
                    () => UIUtils.showSideSheet(
                      context: context,
                      title: 'New Hygiene Assessment',
                      builder: (ctx) => const HygieneForm(),
                    ),
                icon: const Icon(Icons.science_rounded, size: 20),
                label: const Text('New Survey'),
              ),
            ],
          ),
        ),
        Expanded(
          child: surveysAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (surveys) {
              if (surveys.isEmpty) {
                return const Center(child: Text('No hygiene surveys logged'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: surveys.length,
                itemBuilder: (ctx, i) => HygieneListItem(survey: surveys[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}
