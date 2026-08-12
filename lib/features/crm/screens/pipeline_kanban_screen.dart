import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/crm_models.dart';
import '../providers/crm_providers.dart';
import '../services/crm_service.dart';

/// Re-pointed onto Opportunity 2026-08-12 — previously ran on the separate Deal/DealStage
/// pipeline (CRM's own, independently-routed one), which is now retired (see crm_service.dart's
/// header comment). Opportunity's stage vocabulary is its own real 10-stage pipeline (matching
/// opportunity_form.dart's dropdown exactly), richer than Deal's 6 simplified stages — this is
/// the one genuinely live, BPF-integrated pipeline the app has, so the Kanban board (Deal's one
/// real advantage over Opportunity — a drag-and-drop view Opportunity's own screens never had)
/// now visualizes it instead.
const _stages = [
  'Prospecting',
  'Qualification',
  'Needs Analysis',
  'Value Proposition',
  'Id. Decision Makers',
  'Perception Analysis',
  'Proposal/Price Quote',
  'Negotiation/Review',
  'Closed Won',
  'Closed Lost',
];

class PipelineKanbanScreen extends ConsumerStatefulWidget {
  const PipelineKanbanScreen({super.key});

  @override
  ConsumerState<PipelineKanbanScreen> createState() =>
      _PipelineKanbanScreenState();
}

class _PipelineKanbanScreenState extends ConsumerState<PipelineKanbanScreen> {
  @override
  Widget build(BuildContext context) {
    final opportunitiesAsync = ref.watch(opportunitiesStreamProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Sales Pipeline'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: opportunitiesAsync.when(
        data: (opportunities) {
          final accountNames = <String, String>{
            for (final a in accountsAsync.valueOrNull ?? <Account>[]) a.id: a.name,
          };
          return _buildKanbanBoard(context, opportunities, accountNames, theme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading opportunities: $err')),
      ),
    );
  }

  Widget _buildKanbanBoard(
    BuildContext context,
    List<Opportunity> opportunities,
    Map<String, String> accountNames,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _stages.length,
        itemBuilder: (context, index) {
          final stage = _stages[index];
          final stageOpps = opportunities.where((o) => o.stage == stage).toList();
          return _buildStageColumn(context, stage, stageOpps, accountNames, theme);
        },
      ),
    );
  }

  Widget _buildStageColumn(
    BuildContext context,
    String stage,
    List<Opportunity> opportunities,
    Map<String, String> accountNames,
    ThemeData theme,
  ) {
    final formatCurrency = NumberFormat.simpleCurrency();
    final totalStageValue = opportunities.fold<double>(
      0.0,
      (prev, opp) => prev + opp.amount,
    );

    return DragTarget<Opportunity>(
      onAcceptWithDetails: (details) {
        final opp = details.data;
        if (opp.stage != stage) {
          final crmService = ref.read(crmServiceProvider);
          crmService.updateOpportunity(_withStage(opp, stage));
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 320,
          margin: const EdgeInsets.only(right: 16.0),
          decoration: BoxDecoration(
            color:
                candidateData.isNotEmpty
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  candidateData.isNotEmpty
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: candidateData.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Column Header
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${opportunities.length} opportunities • ${formatCurrency.format(totalStageValue)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _getStageIcon(stage),
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),

              // Cards List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: opportunities.length,
                  itemBuilder: (context, index) {
                    final opp = opportunities[index];
                    return Draggable<Opportunity>(
                      data: opp,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Opacity(
                          opacity: 0.8,
                          child: SizedBox(
                            width: 296,
                            child: _buildOpportunityCard(
                                opp, accountNames, theme, formatCurrency),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildOpportunityCard(
                            opp, accountNames, theme, formatCurrency),
                      ),
                      child: _buildOpportunityCard(
                          opp, accountNames, theme, formatCurrency),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpportunityCard(
    Opportunity opp,
    Map<String, String> accountNames,
    ThemeData theme,
    NumberFormat currencyFormat,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              opp.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.business,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    accountNames[opp.accountId] ?? 'Unknown Account',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    currencyFormat.format(opp.amount),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${opp.probability.toInt()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Opportunity _withStage(Opportunity opp, String stage) => Opportunity(
        id: opp.id,
        name: opp.name,
        accountId: opp.accountId,
        primaryContactId: opp.primaryContactId,
        stage: stage,
        amount: opp.amount,
        probability: opp.probability,
        expectedCloseDate: opp.expectedCloseDate,
        forecastCategory: opp.forecastCategory,
        leadSource: opp.leadSource,
        nextStep: opp.nextStep,
        ownerId: opp.ownerId,
        lossReason: opp.lossReason,
        createdAt: opp.createdAt,
        updatedAt: opp.updatedAt,
      );

  IconData _getStageIcon(String stage) {
    switch (stage) {
      case 'Prospecting':
        return Icons.person_add_alt_1;
      case 'Qualification':
        return Icons.fact_check_outlined;
      case 'Needs Analysis':
        return Icons.search;
      case 'Value Proposition':
        return Icons.lightbulb_outline;
      case 'Id. Decision Makers':
        return Icons.groups_outlined;
      case 'Perception Analysis':
        return Icons.psychology_outlined;
      case 'Proposal/Price Quote':
        return Icons.description_outlined;
      case 'Negotiation/Review':
        return Icons.handshake_outlined;
      case 'Closed Won':
        return Icons.emoji_events_outlined;
      case 'Closed Lost':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}
