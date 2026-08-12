import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/crm_models.dart';
import '../providers/crm_providers.dart';
import 'pipeline_kanban_screen.dart';
import 'account_list_screen.dart';

/// Re-pointed onto Opportunity 2026-08-12 — previously ran entirely on the separate Deal/DealStage
/// pipeline. See pipeline_kanban_screen.dart's header comment for the full merge rationale.
/// The "Generate Quote" quick-action tile (QuoteGenerationScreen) was removed rather than
/// re-pointed — investigation found its "Generate PDF Quote" button never wrote anything real
/// (just a success toast + pop), fully superseded by the real, working Quote flow already built
/// this session on Opportunity's own BPF chain (opportunity_detail_screen.dart's "Generate Quote").
class CrmHubScreen extends ConsumerWidget {
  const CrmHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunitiesAsync = ref.watch(opportunitiesStreamProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Sales & CRM Hub'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: opportunitiesAsync.when(
        data: (opportunities) {
          final accountNames = <String, String>{
            for (final a in accountsAsync.valueOrNull ?? <Account>[]) a.id: a.name,
          };
          return _buildDashboard(context, opportunities, accountNames, theme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading opportunities: $err')),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    List<Opportunity> opportunities,
    Map<String, String> accountNames,
    ThemeData theme,
  ) {
    final formatCurrency = NumberFormat.simpleCurrency();

    // Calculate metrics
    final totalPipelineValue = opportunities
        .where((o) => o.stage != 'Closed Lost')
        .fold(0.0, (sum, item) => sum + item.amount);

    final wonValue = opportunities
        .where((o) => o.stage == 'Closed Won')
        .fold(0.0, (sum, item) => sum + item.amount);

    final activeOpportunitiesCount =
        opportunities
            .where(
              (o) => o.stage != 'Closed Lost' && o.stage != 'Closed Won',
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
                  title: 'Active Opportunities',
                  value: activeOpportunitiesCount.toString(),
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
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Recent Active Opportunities',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentOpportunitiesList(
              context, opportunities, accountNames, theme, formatCurrency),
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

  Widget _buildRecentOpportunitiesList(
    BuildContext context,
    List<Opportunity> opportunities,
    Map<String, String> accountNames,
    ThemeData theme,
    NumberFormat formatCurrency,
  ) {
    final activeOpportunities =
        opportunities
            .where(
              (o) => o.stage != 'Closed Lost' && o.stage != 'Closed Won',
            )
            .toList();
    activeOpportunities.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    final recentOpportunities = activeOpportunities.take(5).toList();

    if (recentOpportunities.isEmpty) {
      return const Text('No active opportunities found.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentOpportunities.length,
      itemBuilder: (context, index) {
        final opp = recentOpportunities[index];
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
              opp.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
                '${accountNames[opp.accountId] ?? 'Unknown Account'} • ${opp.stage}'),
            trailing: Text(
              formatCurrency.format(opp.amount),
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
