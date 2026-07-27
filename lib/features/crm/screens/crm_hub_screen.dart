import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/crm_models.dart';
import '../services/crm_service.dart';
import 'pipeline_kanban_screen.dart';
import 'quote_generation_screen.dart';
import 'account_list_screen.dart';

class CrmHubScreen extends ConsumerWidget {
  const CrmHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsyncValue = ref.watch(dealsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Sales & CRM Hub'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: dealsAsyncValue.when(
        data: (deals) => _buildDashboard(context, deals, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading deals: $err')),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    List<Deal> deals,
    ThemeData theme,
  ) {
    final formatCurrency = NumberFormat.simpleCurrency();

    // Calculate metrics
    final totalPipelineValue = deals
        .where((d) => d.stage != DealStage.closedLost)
        .fold(0.0, (sum, item) => sum + item.value);

    final wonValue = deals
        .where((d) => d.stage == DealStage.closedWon)
        .fold(0.0, (sum, item) => sum + item.value);

    final activeDealsCount =
        deals
            .where(
              (d) =>
                  d.stage != DealStage.closedLost &&
                  d.stage != DealStage.closedWon,
            )
            .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context: context,
                  title: 'Total Pipeline',
                  value: formatCurrency.format(totalPipelineValue),
                  icon: Icons.monetization_on,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context: context,
                  title: 'Closed Won',
                  value: formatCurrency.format(wonValue),
                  icon: Icons.emoji_events,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context: context,
                  title: 'Active Deals',
                  value: activeDealsCount.toString(),
                  icon: Icons.assignment,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionCard(
                context: context,
                title: 'Pipeline Kanban',
                icon: Icons.view_kanban,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PipelineKanbanScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                context: context,
                title: 'Accounts',
                icon: Icons.business,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                context: context,
                title: 'Generate Quote',
                icon: Icons.request_quote,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QuoteGenerationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Recent Active Deals',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentDealsList(context, deals, theme, formatCurrency),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDealsList(
    BuildContext context,
    List<Deal> deals,
    ThemeData theme,
    NumberFormat formatCurrency,
  ) {
    final activeDeals =
        deals
            .where(
              (d) =>
                  d.stage != DealStage.closedLost &&
                  d.stage != DealStage.closedWon,
            )
            .toList();
    activeDeals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentDeals = activeDeals.take(5).toList();

    if (recentDeals.isEmpty) {
      return const Text('No active deals found.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentDeals.length,
      itemBuilder: (context, index) {
        final deal = recentDeals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.business,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              deal.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${deal.customerName} • ${deal.stage.name}'),
            trailing: Text(
              formatCurrency.format(deal.value),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
