import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/crm_models.dart';
import '../services/crm_service.dart';

class SalesPipelineScreen extends ConsumerWidget {
  const SalesPipelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsyncValue = ref.watch(dealsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Sales CRM Pipeline'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('New Deal'),
              onPressed: () => _showAddDealDialog(context, ref),
            ),
          ),
        ],
      ),
      body: dealsAsyncValue.when(
        data: (deals) {
          return _buildPipeline(context, ref, deals);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading deals: $err')),
      ),
    );
  }

  Widget _buildPipeline(BuildContext context, WidgetRef ref, List<Deal> deals) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: DealStage.values.length,
        itemBuilder: (context, index) {
          final stage = DealStage.values[index];
          final stageDeals = deals.where((d) => d.stage == stage).toList();
          return _buildStageColumn(context, ref, stage, stageDeals, theme);
        },
      ),
    );
  }

  Widget _buildStageColumn(
    BuildContext context,
    WidgetRef ref,
    DealStage stage,
    List<Deal> deals,
    ThemeData theme,
  ) {
    final formatCurrency = NumberFormat.simpleCurrency();
    final totalStageValue = deals.fold<double>(
      0.0,
      (prev, deal) => prev + deal.value,
    );

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                return _buildDealCard(
                  context,
                  ref,
                  deal,
                  theme,
                  formatCurrency,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(
    BuildContext context,
    WidgetRef ref,
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Open deal details or edit
          _showEditStageDialog(context, ref, deal);
        },
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

  void _showAddDealDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final customerController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Deal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Deal Title (e.g. Acme Q3 Upgrade)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: customerController,
                decoration: const InputDecoration(labelText: 'Customer Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(labelText: 'Value (\$)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final crmService = ref.read(crmServiceProvider);
                final deal = Deal(
                  id: '', // Will be assigned by Firestore
                  title: titleController.text,
                  customerName: customerController.text,
                  value: double.tryParse(valueController.text) ?? 0.0,
                  stage: DealStage.lead,
                  createdAt: DateTime.now(),
                );
                crmService.createDeal(deal);
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showEditStageDialog(BuildContext context, WidgetRef ref, Deal deal) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Move Deal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                DealStage.values.map((stage) {
                  return RadioListTile<DealStage>(
                    title: Text(_getStageName(stage)),
                    value: stage,
                    groupValue: deal.stage,
                    onChanged: (selectedStage) {
                      if (selectedStage != null &&
                          selectedStage != deal.stage) {
                        final crmService = ref.read(crmServiceProvider);
                        crmService.updateDeal(
                          deal.copyWith(stage: selectedStage),
                        );
                      }
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Confirm delete
                _confirmDelete(context, ref, deal);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Deal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Deal deal) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Deal?'),
          content: Text('Are you sure you want to delete ${deal.title}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(crmServiceProvider).deleteDeal(deal.id);
                Navigator.pop(ctx); // Close confirm
                Navigator.pop(context); // Close edit dialog
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
