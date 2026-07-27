import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_models.dart';
import '../services/crm_service.dart';
import '../../people/widgets/employee_selector.dart';

class QuoteForm extends ConsumerStatefulWidget {
  final Quote? quote;

  const QuoteForm({super.key, this.quote});

  @override
  ConsumerState<QuoteForm> createState() => _QuoteFormState();
}

class _QuoteFormState extends ConsumerState<QuoteForm> {
  final _formKey = GlobalKey<FormState>();

  late String opportunityId;
  late String accountId;
  late String quoteNumber;
  late String status;
  DateTime? expirationDate;
  late double subtotal;
  late double discount;
  late double tax;
  late double grandTotal;
  late String termsAndConditions;
  late bool isSyncing;
  late String ownerId;
  late String _billingAddressText;
  late String _shippingAddressText;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final q = widget.quote;
    opportunityId = q?.opportunityId ?? '';
    accountId = q?.accountId ?? '';
    quoteNumber = q?.quoteNumber ?? '';
    status = q?.status ?? 'Draft';
    expirationDate = q?.expirationDate;
    subtotal = q?.subtotal ?? 0.0;
    discount = q?.discount ?? 0.0;
    tax = q?.tax ?? 0.0;
    grandTotal = q?.grandTotal ?? 0.0;
    termsAndConditions = q?.termsAndConditions ?? '';
    isSyncing = q?.isSyncing ?? false;
    ownerId = q?.ownerId ?? '';
    _billingAddressText = q?.billingAddress?['address'] ?? '';
    _shippingAddressText = q?.shippingAddress?['address'] ?? '';
  }

  void _calculateGrandTotal() {
    setState(() {
      grandTotal = subtotal - discount + tax;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(crmServiceProvider);
      final newQuote = Quote(
        id: widget.quote?.id ?? '',
        opportunityId: opportunityId,
        accountId: accountId,
        quoteNumber: quoteNumber,
        status: status,
        expirationDate: expirationDate,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        grandTotal: grandTotal,
        billingAddress: {'address': _billingAddressText},
        shippingAddress: {'address': _shippingAddressText},
        termsAndConditions: termsAndConditions,
        isSyncing: isSyncing,
        ownerId: ownerId,
        createdAt: widget.quote?.createdAt,
      );

      if (widget.quote == null) {
        await service.createQuote(newQuote);
      } else {
        await service.updateQuote(newQuote);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote saved successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving quote: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quote == null ? 'New Quote' : 'Edit Quote'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: quoteNumber,
              decoration: const InputDecoration(
                labelText: 'Quote Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              onSaved: (v) => quoteNumber = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: opportunityId,
              decoration: const InputDecoration(
                labelText: 'Opportunity ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business_center),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              onSaved: (v) => opportunityId = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: accountId,
              decoration: const InputDecoration(
                labelText: 'Account ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
              onSaved: (v) => accountId = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              items:
                  const [
                        'Draft',
                        'Needs Review',
                        'In Review',
                        'Approved',
                        'Rejected',
                        'Presented',
                        'Accepted',
                        'Denied',
                      ]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
              onChanged: (v) => setState(() => status = v!),
              onSaved: (v) => status = v ?? 'Draft',
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              title: const Text('Expiration Date'),
              subtitle: Text(
                expirationDate?.toLocal().toString().split(' ')[0] ??
                    'Select Date',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: expirationDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() => expirationDate = date);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: subtotal.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Subtotal',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) {
                      subtotal = double.tryParse(v) ?? 0.0;
                      _calculateGrandTotal();
                    },
                    onSaved: (v) => subtotal = double.tryParse(v ?? '') ?? 0.0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: discount.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Discount',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money_off),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) {
                      discount = double.tryParse(v) ?? 0.0;
                      _calculateGrandTotal();
                    },
                    onSaved: (v) => discount = double.tryParse(v ?? '') ?? 0.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: tax.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Tax',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) {
                      tax = double.tryParse(v) ?? 0.0;
                      _calculateGrandTotal();
                    },
                    onSaved: (v) => tax = double.tryParse(v ?? '') ?? 0.0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    key: ValueKey(grandTotal), // Update when grandTotal changes
                    initialValue: grandTotal.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Grand Total',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    readOnly:
                        true, // Auto-calculated but can be modified if logic changes
                    onSaved:
                        (v) => grandTotal = double.tryParse(v ?? '') ?? 0.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: termsAndConditions,
              decoration: const InputDecoration(
                labelText: 'Terms and Conditions',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              onSaved: (v) => termsAndConditions = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _billingAddressText,
              decoration: const InputDecoration(
                labelText: 'Billing Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              onSaved: (v) => _billingAddressText = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _shippingAddressText,
              decoration: const InputDecoration(
                labelText: 'Shipping Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_shipping),
              ),
              onSaved: (v) => _shippingAddressText = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            EmployeeSelector(
              value: ownerId.isEmpty ? null : ownerId,
              label: 'Owner',
              onChanged: (v) => setState(() => ownerId = v ?? ''),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Is Syncing?'),
              value: isSyncing,
              onChanged: (val) => setState(() => isSyncing = val),
              secondary: const Icon(Icons.sync),
            ),
          ],
        ),
      ),
    );
  }
}
