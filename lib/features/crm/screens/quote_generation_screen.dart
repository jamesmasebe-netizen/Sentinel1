import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/crm_models.dart';
import '../services/crm_service.dart';

class QuoteGenerationScreen extends ConsumerStatefulWidget {
  const QuoteGenerationScreen({super.key});

  @override
  ConsumerState<QuoteGenerationScreen> createState() =>
      _QuoteGenerationScreenState();
}

class _QuoteGenerationScreenState extends ConsumerState<QuoteGenerationScreen> {
  Deal? _selectedDeal;
  final _taxController = TextEditingController(text: '0.0');
  final _notesController = TextEditingController();
  final _currencyFormat = NumberFormat.simpleCurrency();

  @override
  Widget build(BuildContext context) {
    final dealsAsync = ref.watch(dealsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Generate Quote'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: dealsAsync.when(
        data: (deals) {
          final activeDeals =
              deals.where((d) => d.stage != DealStage.closedLost).toList();
          return _buildQuoteForm(activeDeals, theme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading deals: $err')),
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildQuoteForm(List<Deal> activeDeals, ThemeData theme) {
    final subtotal = _selectedDeal?.value ?? 0.0;
    final taxRate = double.tryParse(_taxController.text) ?? 0.0;
    final total = subtotal + (subtotal * (taxRate / 100));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quote Details',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Deal>(
            decoration: const InputDecoration(
              labelText: 'Select Deal / Customer',
              border: OutlineInputBorder(),
            ),
            value: _selectedDeal,
            items:
                activeDeals.map((deal) {
                  return DropdownMenuItem(
                    value: deal,
                    child: Text('${deal.title} (${deal.customerName})'),
                  );
                }).toList(),
            onChanged: (deal) {
              setState(() {
                _selectedDeal = deal;
              });
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Line Items',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedDeal == null)
            const Text('Please select a deal to view line items.')
          else
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: ListTile(
                title: Text(_selectedDeal!.title),
                subtitle: const Text('Main Service/Product'),
                trailing: Text(
                  _currencyFormat.format(_selectedDeal!.value),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Additional Settings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _taxController,
            decoration: const InputDecoration(
              labelText: 'Tax Rate (%)',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.percent),
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes to Customer',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Subtotal',
                  _currencyFormat.format(subtotal),
                  theme,
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Tax (${taxRate.toStringAsFixed(1)}%)',
                  _currencyFormat.format(subtotal * (taxRate / 100)),
                  theme,
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  'Total',
                  _currencyFormat.format(total),
                  theme,
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              isTotal
                  ? theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                  : theme.textTheme.bodyLarge,
        ),
        Text(
          value,
          style:
              isTotal
                  ? theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )
                  : theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed:
                  _selectedDeal == null
                      ? null
                      : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Quote Generated Successfully!'),
                          ),
                        );
                        Navigator.pop(context);
                      },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generate PDF Quote'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _taxController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
