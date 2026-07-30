import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/crm_models.dart';
import '../providers/crm_providers.dart';
import 'quote_detail_screen.dart';
import '../../../core/bpf/bpf_ribbon_widget.dart';
import '../../../core/bpf/lead_to_cash_bpf.dart';
import '../../../core/bpf/bpf_orchestrator.dart';
import '../../../core/bpf/bpf_service.dart';
import '../../../core/utils/ui_utils.dart';

class OpportunityDetailScreen extends ConsumerWidget {
  final String opportunityId;

  const OpportunityDetailScreen({super.key, required this.opportunityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oppAsyncValue = ref.watch(opportunityStreamProvider(opportunityId));

    return Scaffold(
      body: oppAsyncValue.when(
        data: (opportunity) {
          if (opportunity == null) {
            return const Center(child: Text('Opportunity not found'));
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: Text(opportunity.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // TODO: Implement edit
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BpfRibbonWidget(
                        bpfTypeId: 'lead_to_cash',
                        recordType: 'opportunityId',
                        recordId: opportunity.id,
                        definition: leadToCashDefinition,
                      ),
                      _buildOverviewCard(context, opportunity),
                      const SizedBox(height: 16),
                      _buildDetailsCard(context, opportunity),
                      const SizedBox(height: 24),
                      Text(
                        'Quotes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildQuotesSection(ref),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: () async {
                              try {
                                final orchestrator = ref.read(bpfOrchestratorProvider);
                                final bpfService = ref.read(bpfServiceProvider);
                                String? bpfId;
                                final bpfs = await bpfService.streamBpfInstancesByRecord('opportunityId', opportunity.id).first;
                                if (bpfs.isNotEmpty) {
                                  bpfId = bpfs.first.id;
                                } else {
                                  bpfId = await bpfService.startBpf('lead_to_cash', 'opportunity', 'opportunityId', opportunity.id);
                                }
                                final quoteId = await orchestrator.createQuoteFromOpportunity(opportunity, bpfId);
                                if (context.mounted) {
                                  UIUtils.showToast(context, 'Quote generated successfully');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => QuoteDetailScreen(quoteId: quoteId)),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  UIUtils.showToast(context, 'Error generating quote: $e');
                                }
                              }
                          },
                          icon: const Icon(Icons.request_quote),
                          label: const Text('Generate Quote'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Activity History',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildActivityHistory(context, opportunity),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, Opportunity opportunity) {
    final formatCurrency = NumberFormat.simpleCurrency();

    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Amount',
                    formatCurrency.format(opportunity.amount),
                    Icons.attach_money,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Stage',
                    opportunity.stage,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Probability',
                    '${opportunity.probability.toInt()}%',
                    Icons.pie_chart_outline,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Close Date',
                    opportunity.expectedCloseDate != null
                        ? DateFormat.yMMMd().format(
                          opportunity.expectedCloseDate!,
                        )
                        : 'Not set',
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, Opportunity opportunity) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow(
              context,
              'Account',
              opportunity.accountId.isNotEmpty ? opportunity.accountId : 'N/A',
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Primary Contact',
              opportunity.primaryContactId.isNotEmpty
                  ? opportunity.primaryContactId
                  : 'N/A',
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Forecast Category',
              opportunity.forecastCategory,
            ),
            const Divider(),
            _buildDetailRow(context, 'Lead Source', opportunity.leadSource),
            const Divider(),
            _buildDetailRow(
              context,
              'Next Step',
              opportunity.nextStep.isNotEmpty ? opportunity.nextStep : 'None',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotesSection(WidgetRef ref) {
    final quotesAsyncValue = ref.watch(
      opportunityQuotesStreamProvider(opportunityId),
    );

    return quotesAsyncValue.when(
      data: (quotes) {
        if (quotes.isEmpty) {
          return const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('No quotes associated with this opportunity.'),
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            final quote = quotes[index];
            final formatCurrency = NumberFormat.simpleCurrency();
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  child: const Icon(Icons.description),
                ),
                title: Text(
                  quote.quoteNumber.isNotEmpty
                      ? quote.quoteNumber
                      : 'Quote #${quote.id.substring(0, 5)}',
                ),
                subtitle: Text(
                  '${quote.status} • ${formatCurrency.format(quote.grandTotal)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => QuoteDetailScreen(quoteId: quote.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error loading quotes: $error'),
    );
  }

  Widget _buildActivityHistory(BuildContext context, Opportunity opportunity) {
    // This is a placeholder for activity history.
    // In a real application, you would fetch the activities related to the opportunity.
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTimelineItem(
              context,
              'Opportunity Created',
              opportunity.createdAt != null
                  ? DateFormat.yMMMd().add_jm().format(opportunity.createdAt!)
                  : 'Unknown',
              Icons.add_circle_outline,
              isFirst: true,
            ),
            if (opportunity.updatedAt != null)
              _buildTimelineItem(
                context,
                'Opportunity Updated',
                DateFormat.yMMMd().add_jm().format(opportunity.updatedAt!),
                Icons.update,
                isLast: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    String time,
    IconData icon, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 2,
              height: 16,
              color:
                  isFirst
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.outlineVariant,
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            Container(
              width: 2,
              height: 24,
              color:
                  isLast
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.outlineVariant,
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(time, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
