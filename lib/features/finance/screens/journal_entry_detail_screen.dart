import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/finance_providers.dart';
import '../models/finance_models.dart';

class JournalEntryDetailScreen extends ConsumerWidget {
  final String journalEntryId;

  const JournalEntryDetailScreen({super.key, required this.journalEntryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalEntryAsync = ref.watch(
      journalEntryStreamProvider(journalEntryId),
    );
    final journalLinesAsync = ref.watch(
      journalLinesStreamProvider(journalEntryId),
    );

    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
    ); // Can dynamically change if needed

    return Scaffold(
      appBar: AppBar(title: const Text('Journal Entry Details'), elevation: 0),
      body: journalEntryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (entry) {
          if (entry == null) {
            return const Center(child: Text('Journal Entry not found.'));
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeaderCard(context, entry, currencyFormat),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Journal Lines',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              journalLinesAsync.when(
                loading:
                    () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (err, stack) => SliverFillRemaining(
                      child: Center(child: Text('Error: $err')),
                    ),
                data: (lines) {
                  if (lines.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('No lines available.')),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final line = lines[index];
                      return _buildLineItem(
                        context,
                        line,
                        currencyFormat,
                        entry.currencyCode,
                      );
                    }, childCount: lines.length),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    JournalEntry entry,
    NumberFormat format,
  ) {
    final df = DateFormat('MMM dd, yyyy');
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'JE #${entry.id.substring(0, 8).toUpperCase()}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                _buildStatusChip(entry.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Description', entry.description),
            _buildDetailRow(
              'Transaction Date',
              df.format(entry.transactionDate),
            ),
            _buildDetailRow('Source Module', entry.sourceModule),
            _buildDetailRow(
              'Fiscal Period',
              '${entry.fiscalYear ?? "-"} / ${entry.fiscalPeriod ?? "-"}',
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Debit',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '${entry.currencyCode} ${format.format(entry.totalDebit).replaceAll('\$', '')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Credit',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '${entry.currencyCode} ${format.format(entry.totalCredit).replaceAll('\$', '')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'APPROVED':
        color = Colors.green;
        break;
      case 'DRAFT':
        color = Colors.orange;
        break;
      case 'POSTED':
        color = Colors.blue;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(
    BuildContext context,
    JournalLine line,
    NumberFormat format,
    String currency,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Account: ${line.accountId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  'Line #${line.id}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            if (line.description != null && line.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                line.description!,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (line.debitAmount > 0)
                  Text(
                    'DR $currency ${format.format(line.debitAmount).replaceAll('\$', '')}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  const SizedBox.shrink(),

                if (line.creditAmount > 0)
                  Text(
                    'CR $currency ${format.format(line.creditAmount).replaceAll('\$', '')}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
            if (line.costCenterId != null || line.projectId != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (line.costCenterId != null)
                    _buildSmallTag('CC: ${line.costCenterId}'),
                  if (line.projectId != null)
                    _buildSmallTag('Project: ${line.projectId}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSmallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: Colors.grey[800]),
      ),
    );
  }
}
