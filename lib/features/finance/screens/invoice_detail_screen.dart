import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/finance_providers.dart';
import '../models/finance_models.dart';
import '../../../core/bpf/bpf_ribbon_widget.dart';
import '../../../core/bpf/lead_to_cash_bpf.dart';
import '../../../core/bpf/procure_to_pay_bpf.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;
  final String invoiceType; // 'AP' or 'AR'

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
    required this.invoiceType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (id: invoiceId, type: invoiceType);
    final invoiceAsync = ref.watch(invoiceStreamProvider(args));
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${invoiceType == 'AP' ? 'Payable' : 'Receivable'} Invoice',
        ),
        elevation: 0,
      ),
      body: invoiceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (invoice) {
          if (invoice == null) {
            return const Center(child: Text('Invoice not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (invoice.invoiceType == 'AR')
                  BpfRibbonWidget(
                    bpfTypeId: 'lead_to_cash',
                    recordType: 'invoiceId',
                    recordId: invoice.id,
                    definition: leadToCashDefinition,
                  )
                else if (invoice.invoiceType == 'AP')
                  BpfRibbonWidget(
                    bpfTypeId: 'procure_to_pay',
                    recordType: 'apInvoiceId',
                    recordId: invoice.id,
                    definition: procureToPayDefinition,
                  ),
                _buildMainCard(context, invoice),
                const SizedBox(height: 16),
                _buildAmountSummary(context, invoice, currencyFormat),
                const SizedBox(height: 16),
                _buildLinkedEntities(context, invoice),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainCard(
    BuildContext context,
    Invoice invoice,
  ) {
    final df = DateFormat('MMM dd, yyyy');
    return Card(
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
                  'Invoice ${invoice.invoiceNumber ?? "#${invoice.id.substring(0, 8)}"}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                _buildStatusChip(invoice.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Type',
              invoice.invoiceType == 'AP'
                  ? 'Account Payable'
                  : 'Account Receivable',
            ),
            if (invoice.vendorId != null)
              _buildDetailRow('Vendor ID', invoice.vendorId!),
            if (invoice.customerId != null)
              _buildDetailRow('Customer ID', invoice.customerId!),
            const Divider(height: 32),
            _buildDetailRow('Invoice Date', df.format(invoice.invoiceDate)),
            _buildDetailRow('Due Date', df.format(invoice.dueDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSummary(
    BuildContext context,
    Invoice invoice,
    NumberFormat format,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Amount Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildAmountRow(
              'Gross Amount',
              invoice.grossAmount,
              invoice.currencyCode,
              format,
            ),
            _buildAmountRow(
              'Tax Amount',
              invoice.taxAmount,
              invoice.currencyCode,
              format,
            ),
            const Divider(),
            _buildAmountRow(
              'Net Amount',
              invoice.netAmount,
              invoice.currencyCode,
              format,
              isTotal: true,
            ),
            const SizedBox(height: 16),
            _buildAmountRow(
              invoice.invoiceType == 'AP' ? 'Amount Paid' : 'Amount Received',
              invoice.amountPaidOrReceived ?? 0.0,
              invoice.currencyCode,
              format,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedEntities(BuildContext context, Invoice invoice) {
    if (invoice.journalEntryId == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: Colors.blue),
        title: const Text('Linked Journal Entry'),
        subtitle: Text('ID: ${invoice.journalEntryId}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Typically navigation to Journal Entry Detail Screen
        },
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount,
    String currency,
    NumberFormat format, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.black87 : Colors.grey[700],
            ),
          ),
          Text(
            '$currency ${format.format(amount).replaceAll('\$', '')}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.blue : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'PAID':
        color = Colors.green;
        break;
      case 'OPEN':
      case 'UNPAID':
        color = Colors.orange;
        break;
      case 'OVERDUE':
        color = Colors.red;
        break;
      case 'DRAFT':
        color = Colors.grey;
        break;
      default:
        color = Colors.blue;
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
}
