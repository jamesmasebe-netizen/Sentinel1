import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'action_tracker_screen.dart';
import '../widgets/operations_hub_metrics.dart';
import '../widgets/operations_hub_modules.dart';

/// Operations & Assets Hub Dashboard — Material 3 Expressive
class OperationsHubScreen extends ConsumerWidget {
  const OperationsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          UIUtils.showSideSheet(context: context, title: 'Action Tracker', builder: (ctx) => const ActionTrackerScreen());
        },
        backgroundColor: XMTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.assignment_add),
        label: const Text('Add Action'),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: GHeader(
              title: 'Operations & Assets Hub',
              subtitle:
                  'Track organizational assets, environmental compliance, actions, and contractors.',
            ),
          ),
          OperationsHubMetrics(siteId: siteId, fs: fs),
          const OperationsHubModules(),
          const SliverToBoxAdapter(child: GSpacing.vXl),
        ],
      ),
    );
  }
}
