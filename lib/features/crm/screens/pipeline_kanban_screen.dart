import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/crm_models.dart';
import '../services/crm_service.dart';

class PipelineKanbanScreen extends ConsumerStatefulWidget {
  const PipelineKanbanScreen({super.key});

  @override
  ConsumerState<PipelineKanbanScreen> createState() =>
      _PipelineKanbanScreenState();
}

class _PipelineKanbanScreenState extends ConsumerState<PipelineKanbanScreen> {
  @override
  Widget build(BuildContext context) {
    final dealsAsyncValue = ref.watch(dealsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Sales Pipeline'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: dealsAsyncValue.when(
        data: (deals) {
          return _buildKanbanBoard(context, deals, theme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading deals: $err')),
      ),
    );
  }

  Widget _buildKanbanBoard(
    BuildContext context,
    List<Deal> deals,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: DealStage.values.length,
        itemBuilder: (context, index) {
          final stage = DealStage.values[index];
          final stageDeals = deals.where((d) => d.stage == stage).toList();
          return _buildStageColumn(context, stage, stageDeals, theme);
        },
      ),
    );
  }

  Widget _buildStageColumn(
    BuildContext context,
    DealStage stage,
    List<Deal> deals,
    ThemeData theme,
  ) {
    final formatCurrency = NumberFormat.simpleCurrency();
    final totalStageValue = deals.fold<double>(
      0.0,
      (prev, deal) => prev + deal.value,
    );

    return DragTarget<Deal>(
      onAcceptWithDetails: (details) {
        final deal = details.data;
        if (deal.stage != stage) {
          final crmService = ref.read(crmServiceProvider);
          crmService.updateDeal(deal.copyWith(stage: stage));
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
                            _getStageName(stage),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${deals.length} deals • ${formatCurrency.format(totalStageValue)}',
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
                  itemCount: deals.length,
                  itemBuilder: (context, index) {
                    final deal = deals[index];
                    return Draggable<Deal>(
                      data: deal,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Opacity(
                          opacity: 0.8,
                          child: SizedBox(
                            width: 296,
                            child: _buildDealCard(deal, theme, formatCurrency),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildDealCard(deal, theme, formatCurrency),
                      ),
                      child: _buildDealCard(deal, theme, formatCurrency),
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

  Widget _buildDealCard(
    Deal deal,
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
              deal.title,
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
                    deal.customerName,
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
                    currencyFormat.format(deal.value),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  DateFormat.MMMd().format(deal.createdAt),
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

  String _getStageName(DealStage stage) {
    switch (stage) {
      case DealStage.lead:
        return 'Leads';
      case DealStage.qualified:
        return 'Qualified';
      case DealStage.proposal:
        return 'Proposal Made';
      case DealStage.negotiation:
        return 'Negotiation';
      case DealStage.closedWon:
        return 'Closed Won';
      case DealStage.closedLost:
        return 'Closed Lost';
    }
  }

  IconData _getStageIcon(DealStage stage) {
    switch (stage) {
      case DealStage.lead:
        return Icons.person_add_alt_1;
      case DealStage.qualified:
        return Icons.fact_check_outlined;
      case DealStage.proposal:
        return Icons.description_outlined;
      case DealStage.negotiation:
        return Icons.handshake_outlined;
      case DealStage.closedWon:
        return Icons.emoji_events_outlined;
      case DealStage.closedLost:
        return Icons.cancel_outlined;
    }
  }
}
