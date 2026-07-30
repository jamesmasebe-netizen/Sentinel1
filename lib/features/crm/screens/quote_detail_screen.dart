import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/crm_models.dart';
import '../providers/crm_providers.dart';
import 'opportunity_detail_screen.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../../core/bpf/bpf_ribbon_widget.dart';
import '../../../core/bpf/lead_to_cash_bpf.dart';
import '../../../core/bpf/bpf_orchestrator.dart';
import '../../../core/bpf/bpf_service.dart';
import '../../../core/utils/ui_utils.dart';

class QuoteDetailScreen extends ConsumerWidget {
  final String quoteId;

  const QuoteDetailScreen({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsyncValue = ref.watch(quoteStreamProvider(quoteId));

    return Scaffold(
      body: quoteAsyncValue.when(
        data: (quote) {
          if (quote == null) {
            return const Center(child: Text('Quote not found'));
          }
          final formatCurrency = NumberFormat.simpleCurrency();

          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: Text(
                  quote.quoteNumber.isNotEmpty
                      ? quote.quoteNumber
                      : 'Quote Details',
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    onPressed: () {
                      // TODO: Generate PDF
                    },
                  ),
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
                        recordType: 'quoteId',
                        recordId: quote.id,
                        definition: leadToCashDefinition,
                      ),
                      _buildStatusCard(context, quote, formatCurrency),
                      const SizedBox(height: 16),
                      _buildFinancialSummary(context, quote, formatCurrency),
                      const SizedBox(height: 16),
                      _buildDetailsCard(context, quote),
                      const SizedBox(height: 24),
                      Text(
                        'Terms & Conditions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTermsCard(context, quote),
                      const SizedBox(height: 24),
                      Text(
                        'Related Entities',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRelatedEntities(context, quote),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: quote.status == 'Accepted' ? null : () async {
                              try {
                                final orchestrator = ref.read(bpfOrchestratorProvider);
                                final bpfService = ref.read(bpfServiceProvider);
                                String? bpfId;
                                final bpfs = await bpfService.streamBpfInstancesByRecord('quoteId', quote.id).first;
                                if (bpfs.isNotEmpty) {
                                  bpfId = bpfs.first.id;
                                } else {
                                  bpfId = await bpfService.startBpf('lead_to_cash', 'quote', 'quoteId', quote.id);
                                }
                                final projectId = await orchestrator.createProjectFromQuote(quote, bpfId);
                                if (context.mounted) {
                                  UIUtils.showToast(context, 'Project created successfully (ID: $projectId)');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProjectDetailScreen(projectId: projectId),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  UIUtils.showToast(context, 'Error accepting quote: $e');
                                }
                              }
                          },
                          icon: const Icon(Icons.check_circle),
                          label: Text(quote.status == 'Accepted' ? 'Quote Accepted' : 'Accept Quote & Create Project'),
                        ),
                      ),
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

  Widget _buildStatusCard(
    BuildContext context,
    Quote quote,
    NumberFormat format,
  ) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                context,
                'Grand Total',
                format.format(quote.grandTotal),
                Icons.monetization_on,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                context,
                'Status',
                quote.status,
                Icons.assignment_turned_in,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(
    BuildContext context,
    Quote quote,
    NumberFormat format,
  ) {
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
            _buildDetailRow(context, 'Subtotal', format.format(quote.subtotal)),
            const Divider(),
            _buildDetailRow(context, 'Discount', format.format(quote.discount)),
            const Divider(),
            _buildDetailRow(context, 'Tax', format.format(quote.tax)),
            const Divider(),
            _buildDetailRow(
              context,
              'Grand Total',
              format.format(quote.grandTotal),
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, Quote quote) {
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
              'Expiration Date',
              quote.expirationDate != null
                  ? DateFormat.yMMMd().format(quote.expirationDate!)
                  : 'Not set',
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Owner ID',
              quote.ownerId.isNotEmpty ? quote.ownerId : 'N/A',
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Is Syncing',
              quote.isSyncing ? 'Yes' : 'No',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCard(BuildContext context, Quote quote) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            quote.termsAndConditions.isNotEmpty
                ? quote.termsAndConditions
                : 'No terms specified.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedEntities(BuildContext context, Quote quote) {
    return Column(
      children: [
        if (quote.opportunityId.isNotEmpty)
          Card(
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
                    Theme.of(context).colorScheme.tertiaryContainer,
                child: Icon(
                  Icons.work_outline,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              title: const Text('View Opportunity'),
              subtitle: Text('ID: ${quote.opportunityId}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => OpportunityDetailScreen(
                          opportunityId: quote.opportunityId,
                        ),
                  ),
                );
              },
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

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }
}
