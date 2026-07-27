import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_models.dart';
import '../services/finance_service.dart';

class InvoiceForm extends ConsumerStatefulWidget {
  final Invoice? initialInvoice;
  final VoidCallback? onSaved;

  const InvoiceForm({super.key, this.initialInvoice, this.onSaved});

  @override
  ConsumerState<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends ConsumerState<InvoiceForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _vendorIdController;
  late TextEditingController _customerIdController;
  late TextEditingController _invoiceNumberController;
  late TextEditingController _currencyCodeController;
  late TextEditingController _grossAmountController;
  late TextEditingController _taxAmountController;
  late TextEditingController _netAmountController;
  late TextEditingController _amountPaidOrReceivedController;
  late TextEditingController _journalEntryIdController;

  String _invoiceType = 'AP';
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _status = 'DRAFT';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _vendorIdController = TextEditingController(
      text: widget.initialInvoice?.vendorId ?? '',
    );
    _customerIdController = TextEditingController(
      text: widget.initialInvoice?.customerId ?? '',
    );
    _invoiceNumberController = TextEditingController(
      text: widget.initialInvoice?.invoiceNumber ?? '',
    );
    _currencyCodeController = TextEditingController(
      text: widget.initialInvoice?.currencyCode ?? 'USD',
    );
    _grossAmountController = TextEditingController(
      text: widget.initialInvoice?.grossAmount.toString() ?? '0.0',
    );
    _taxAmountController = TextEditingController(
      text: widget.initialInvoice?.taxAmount.toString() ?? '0.0',
    );
    _netAmountController = TextEditingController(
      text: widget.initialInvoice?.netAmount.toString() ?? '0.0',
    );
    _amountPaidOrReceivedController = TextEditingController(
      text: widget.initialInvoice?.amountPaidOrReceived?.toString() ?? '0.0',
    );
    _journalEntryIdController = TextEditingController(
      text: widget.initialInvoice?.journalEntryId ?? '',
    );

    if (widget.initialInvoice != null) {
      _invoiceType = widget.initialInvoice!.invoiceType;
      _invoiceDate = widget.initialInvoice!.invoiceDate;
      _dueDate = widget.initialInvoice!.dueDate;
      _status = widget.initialInvoice!.status;
    }
  }

  @override
  void dispose() {
    _vendorIdController.dispose();
    _customerIdController.dispose();
    _invoiceNumberController.dispose();
    _currencyCodeController.dispose();
    _grossAmountController.dispose();
    _taxAmountController.dispose();
    _netAmountController.dispose();
    _amountPaidOrReceivedController.dispose();
    _journalEntryIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isInvoiceDate) async {
    final initial = isInvoiceDate ? _invoiceDate : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isInvoiceDate) {
          _invoiceDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  void _calculateNetAmount() {
    final gross = double.tryParse(_grossAmountController.text) ?? 0.0;
    final tax = double.tryParse(_taxAmountController.text) ?? 0.0;
    final net = gross + tax;
    _netAmountController.text = net.toStringAsFixed(2);
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final service = ref.read(financeServiceProvider);
      final invoiceId =
          widget.initialInvoice?.id ??
          'INV-${DateTime.now().millisecondsSinceEpoch}';

      final invoice = Invoice(
        id: invoiceId,
        invoiceType: _invoiceType,
        vendorId:
            _vendorIdController.text.isEmpty ? null : _vendorIdController.text,
        customerId:
            _customerIdController.text.isEmpty
                ? null
                : _customerIdController.text,
        invoiceNumber:
            _invoiceNumberController.text.isEmpty
                ? null
                : _invoiceNumberController.text,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        status: _status,
        currencyCode: _currencyCodeController.text,
        grossAmount: double.tryParse(_grossAmountController.text) ?? 0.0,
        taxAmount: double.tryParse(_taxAmountController.text) ?? 0.0,
        netAmount: double.tryParse(_netAmountController.text) ?? 0.0,
        amountPaidOrReceived: double.tryParse(
          _amountPaidOrReceivedController.text,
        ),
        journalEntryId:
            _journalEntryIdController.text.isEmpty
                ? null
                : _journalEntryIdController.text,
      );

      if (widget.initialInvoice == null) {
        await service.createInvoice(invoice);
      } else {
        await service.updateInvoice(invoice);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invoice Saved!')));

      widget.onSaved?.call();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Invoice Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _invoiceType,
                  decoration: const InputDecoration(
                    labelText: 'Invoice Type',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      ['AP', 'AR']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _invoiceType = val!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      ['DRAFT', 'POSTED', 'PAID', 'VOID']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _status = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller:
                      _invoiceType == 'AP'
                          ? _vendorIdController
                          : _customerIdController,
                  decoration: InputDecoration(
                    labelText:
                        _invoiceType == 'AP' ? 'Vendor ID' : 'Customer ID',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _invoiceNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Invoice Number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Invoice Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text('${_invoiceDate.toLocal()}'.split(' ')[0]),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text('${_dueDate.toLocal()}'.split(' ')[0]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _currencyCodeController,
            decoration: const InputDecoration(
              labelText: 'Currency Code',
              border: OutlineInputBorder(),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _grossAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Gross Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateNetAmount(),
                  validator:
                      (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _taxAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Tax Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateNetAmount(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _netAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Net Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amountPaidOrReceivedController,
                  decoration: InputDecoration(
                    labelText:
                        _invoiceType == 'AP'
                            ? 'Amount Paid'
                            : 'Amount Received',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _journalEntryIdController,
                  decoration: const InputDecoration(
                    labelText: 'Journal Entry ID (Ref)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveForm,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Invoice'),
            ),
          ),
        ],
      ),
    );
  }
}
