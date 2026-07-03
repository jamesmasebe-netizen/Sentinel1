import 'package:flutter/material.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../screens/approvals_inbox_screen.dart';

class DashboardHeader extends StatelessWidget {
  final bool isSeeding;
  final VoidCallback onSeedData;

  const DashboardHeader({
    super.key,
    required this.isSeeding,
    required this.onSeedData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Hub',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GSpacing.vXs,
                  Text(
                    'Integrated SHEQ & Property Performance',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              GSpacing.vMd,
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _buildHeaderButtons(theme, context),
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Hub',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GSpacing.vXs,
                  Text(
                    'Integrated SHEQ & Property Performance',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(spacing: 12, children: _buildHeaderButtons(theme, context)),
          ],
        );
      },
    );
  }

  List<Widget> _buildHeaderButtons(ThemeData theme, BuildContext context) {
    return [
      FilledButton.icon(
        onPressed: () {
          UIUtils.showSideSheet(
            context: context,
            title: 'My Approvals Inbox',
            builder: (ctx) => const ApprovalsInboxScreen(),
          );
        },
        icon: const Icon(Icons.inbox_rounded, size: 18),
        label: const Text('My Approvals'),
      ),
      OutlinedButton.icon(
        onPressed: isSeeding ? null : onSeedData,
        icon:
            isSeeding
                ? SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
                : const Icon(Icons.cloud_upload_outlined, size: 18),
        label: Text(isSeeding ? 'Seeding...' : 'Seed Data'),
      ),
      FilledButton.icon(
        onPressed: () {
          UIUtils.showToast(
            context,
            'Exporting CSV data...',
            type: ToastType.info,
          );
        },
        icon: const Icon(Icons.description_outlined, size: 18),
        label: const Text('Export CSV'),
      ),
    ];
  }
}
