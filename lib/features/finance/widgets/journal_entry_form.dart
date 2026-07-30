import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_models.dart';
import '../services/finance_service.dart';
import '../../people/widgets/employee_selector.dart';
import '../providers/finance_providers.dart';
import '../../projects/providers/project_providers.dart';
import '../../projects/models/project_models.dart';
import '../../../core/widgets/entity_selector.dart';
class JournalEntryForm extends ConsumerStatefulWidget {
  final JournalEntry? initialEntry;
  final List<JournalLine>? initialLines;
  final VoidCallback? onSaved;

  const JournalEntryForm({
    super.key,
    this.initialEntry,
    this.initialLines,
    this.onSaved,
  });

  @override
  ConsumerState<JournalEntryForm> createState() => _JournalEntryFormState();
}

class _JournalEntryFormState extends ConsumerState<JournalEntryForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _descriptionController;
  late TextEditingController _currencyCodeController;
  late TextEditingController _sourceReferenceIdController;
  late TextEditingController _exchangeRateController;
  
  late TextEditingController _fiscalYearController;
  late TextEditingController _fiscalPeriodController;
  late TextEditingController _baseCurrencyCodeController;
  late TextEditingController _baseTotalDebitController;
  late TextEditingController _baseTotalCreditController;
  late TextEditingController _reversesJournalIdController;

  DateTime _transactionDate = DateTime.now();
  DateTime? _systemDate;
  DateTime? _postedAt;
  String _sourceModule = 'GL';
  String _type = 'STANDARD';
  String _status = 'DRAFT';
  String? _createdBy;
  String? _approvedBy;

  List<JournalLineInput> _lines = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.initialEntry?.description ?? '');
    _currencyCodeController = TextEditingController(text: widget.initialEntry?.currencyCode ?? 'USD');
    _sourceReferenceIdController = TextEditingController(text: widget.initialEntry?.sourceReferenceId ?? '');
    _exchangeRateController = TextEditingController(text: widget.initialEntry?.exchangeRate?.toString() ?? '1.0');

    _fiscalYearController = TextEditingController(text: widget.initialEntry?.fiscalYear ?? '');
    _fiscalPeriodController = TextEditingController(text: widget.initialEntry?.fiscalPeriod ?? '');
    _baseCurrencyCodeController = TextEditingController(text: widget.initialEntry?.baseCurrencyCode ?? '');
    _baseTotalDebitController = TextEditingController(text: widget.initialEntry?.baseTotalDebit?.toString() ?? '');
    _baseTotalCreditController = TextEditingController(text: widget.initialEntry?.baseTotalCredit?.toString() ?? '');
    _createdBy = widget.initialEntry?.createdBy;
    _approvedBy = widget.initialEntry?.approvedBy;
    _reversesJournalIdController = TextEditingController(text: widget.initialEntry?.reversesJournalId ?? '');

    if (widget.initialEntry != null) {
      _transactionDate = widget.initialEntry!.transactionDate;
      _systemDate = widget.initialEntry!.systemDate;
      _postedAt = widget.initialEntry!.postedAt;
      _sourceModule = widget.initialEntry!.sourceModule;
      _type = widget.initialEntry!.type;
      _status = widget.initialEntry!.status;
    }

    if (widget.initialLines != null && widget.initialLines!.isNotEmpty) {
      _lines = widget.initialLines!.map((l) => JournalLineInput.fromModel(l)).toList();
    } else {
      _lines.add(JournalLineInput());
      _lines.add(JournalLineInput());
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _currencyCodeController.dispose();
    _sourceReferenceIdController.dispose();
    _exchangeRateController.dispose();
    
    _fiscalYearController.dispose();
    _fiscalPeriodController.dispose();
    _baseCurrencyCodeController.dispose();
    _baseTotalDebitController.dispose();
    _baseTotalCreditController.dispose();
    _reversesJournalIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required bool isTransactionDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isTransactionDate ? _transactionDate : (_systemDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isTransactionDate) {
          _transactionDate = picked;
        } else {
          _systemDate = picked;
        }
      });
    }
  }

  Future<void> _selectPostedAt(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _postedAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _postedAt = picked;
      });
    }
  }

  void _addLine() {
    setState(() {
      _lines.add(JournalLineInput());
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines.removeAt(index);
    });
  }

  double get _totalDebit => _lines.fold(0.0, (sum, line) => sum + line.debit);
  double get _totalCredit => _lines.fold(0.0, (sum, line) => sum + line.credit);

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_totalDebit != _totalCredit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total Debit must equal Total Credit.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(financeServiceProvider);
      final entryId = widget.initialEntry?.id ?? 'JE-${DateTime.now().millisecondsSinceEpoch}';

      final entry = JournalEntry(
        id: entryId,
        transactionDate: _transactionDate,
        systemDate: _systemDate,
        fiscalYear: _fiscalYearController.text.isEmpty ? null : _fiscalYearController.text,
        fiscalPeriod: _fiscalPeriodController.text.isEmpty ? null : _fiscalPeriodController.text,
        sourceModule: _sourceModule,
        sourceReferenceId: _sourceReferenceIdController.text.isEmpty ? null : _sourceReferenceIdController.text,
        type: _type,
        description: _descriptionController.text,
        status: _status,
        currencyCode: _currencyCodeController.text,
        baseCurrencyCode: _baseCurrencyCodeController.text.isEmpty ? null : _baseCurrencyCodeController.text,
        exchangeRate: double.tryParse(_exchangeRateController.text) ?? 1.0,
        totalDebit: _totalDebit,
        totalCredit: _totalCredit,
        baseTotalDebit: double.tryParse(_baseTotalDebitController.text),
        baseTotalCredit: double.tryParse(_baseTotalCreditController.text),
        createdBy: _createdBy,
        approvedBy: _approvedBy,
        postedAt: _postedAt,
        reversesJournalId: _reversesJournalIdController.text.isEmpty ? null : _reversesJournalIdController.text,
      );

      final lineModels = _lines.asMap().entries.map((e) {
        final index = e.key;
        final lineInput = e.value;
        return JournalLine(
          id: lineInput.id ?? 'LINE-$index-${DateTime.now().millisecondsSinceEpoch}',
          accountId: lineInput.accountId,
          costCenterId: lineInput.costCenterId?.isEmpty ?? true ? null : lineInput.costCenterId,
          projectId: lineInput.projectId?.isEmpty ?? true ? null : lineInput.projectId,
          debitAmount: lineInput.debit,
          creditAmount: lineInput.credit,
          baseDebitAmount: lineInput.baseDebitAmount,
          baseCreditAmount: lineInput.baseCreditAmount,
          description: lineInput.description?.isEmpty ?? true ? null : lineInput.description,
          taxCodeId: lineInput.taxCodeId?.isEmpty ?? true ? null : lineInput.taxCodeId,
        );
      }).toList();

      if (widget.initialEntry == null) {
        await service.createJournalEntry(entry, lineModels);
      } else {
        await service.updateJournalEntry(entry);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Journal Entry Saved!')));

      widget.onSaved?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          const Text('Journal Entry Header', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, isTransactionDate: true),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Transaction Date', border: OutlineInputBorder()),
                    child: Text('${_transactionDate.toLocal()}'.split(' ')[0]),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, isTransactionDate: false),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'System Date', border: OutlineInputBorder()),
                    child: Text(_systemDate != null ? '${_systemDate!.toLocal()}'.split(' ')[0] : 'None'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _currencyCodeController,
                  decoration: const InputDecoration(labelText: 'Currency Code', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _exchangeRateController,
                  decoration: const InputDecoration(labelText: 'Exchange Rate', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _baseCurrencyCodeController,
                  decoration: const InputDecoration(labelText: 'Base Currency Code', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _sourceReferenceIdController,
                  decoration: const InputDecoration(labelText: 'Source Reference ID', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sourceModule,
                  decoration: const InputDecoration(labelText: 'Source Module', border: OutlineInputBorder()),
                  items: ['GL', 'AP', 'AR', 'FA'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _sourceModule = val!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: ['STANDARD', 'ACCRUAL', 'REVERSAL', 'ADJUSTMENT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _type = val!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: ['DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'POSTED', 'REVERSED', 'REJECTED'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
                  controller: _fiscalYearController,
                  decoration: const InputDecoration(labelText: 'Fiscal Year', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _fiscalPeriodController,
                  decoration: const InputDecoration(labelText: 'Fiscal Period', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _baseTotalDebitController,
                  decoration: const InputDecoration(labelText: 'Base Total Debit', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _baseTotalCreditController,
                  decoration: const InputDecoration(labelText: 'Base Total Credit', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: EmployeeSelector(
                  label: 'Created By',
                  value: _createdBy,
                  onChanged: (val) => setState(() => _createdBy = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: EmployeeSelector(
                  label: 'Approved By',
                  value: _approvedBy,
                  onChanged: (val) => setState(() => _approvedBy = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectPostedAt(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Posted At', border: OutlineInputBorder()),
                    child: Text(_postedAt != null ? '${_postedAt!.toLocal()}'.split(' ')[0] : 'None'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _reversesJournalIdController,
                  decoration: const InputDecoration(labelText: 'Reverses Journal ID', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Journal Lines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add),
                label: const Text('Add Line'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._lines.asMap().entries.map((e) {
            final index = e.key;
            final line = e.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: EntitySelector<GeneralLedgerAccount>(
                            label: 'Account',
                            value: line.accountId.isEmpty ? null : line.accountId,
                            asyncEntities: ref.watch(glAccountsStreamProvider),
                            idMapper: (a) => a.id,
                            displayMapper: (a) => '${a.accountNumber} - ${a.name}',
                            onChanged: (val) => setState(() => line.accountId = val ?? ''),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: line.description,
                            decoration: const InputDecoration(labelText: 'Description'),
                            onChanged: (val) => line.description = val,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: line.debit.toString(),
                            decoration: const InputDecoration(labelText: 'Debit'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              setState(() {
                                line.debit = double.tryParse(val) ?? 0.0;
                                if (line.debit > 0) line.credit = 0.0;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: line.credit.toString(),
                            decoration: const InputDecoration(labelText: 'Credit'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              setState(() {
                                line.credit = double.tryParse(val) ?? 0.0;
                                if (line.credit > 0) line.debit = 0.0;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeLine(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: EntitySelector<CostCenter>(
                            label: 'Cost Center',
                            value: (line.costCenterId?.isEmpty ?? true) ? null : line.costCenterId,
                            asyncEntities: ref.watch(costCentersStreamProvider),
                            idMapper: (c) => c.id,
                            displayMapper: (c) => c.name,
                            onChanged: (val) => setState(() => line.costCenterId = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: EntitySelector<Project>(
                            label: 'Project',
                            value: (line.projectId?.isEmpty ?? true) ? null : line.projectId,
                            asyncEntities: ref.watch(projectsProvider),
                            idMapper: (p) => p.id,
                            displayMapper: (p) => p.name,
                            onChanged: (val) => setState(() => line.projectId = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: EntitySelector<TaxCode>(
                            label: 'Tax Code',
                            value: (line.taxCodeId?.isEmpty ?? true) ? null : line.taxCodeId,
                            asyncEntities: ref.watch(taxCodesStreamProvider),
                            idMapper: (t) => t.id,
                            displayMapper: (t) => t.code,
                            onChanged: (val) => setState(() => line.taxCodeId = val),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            initialValue: line.baseDebitAmount?.toString(),
                            decoration: const InputDecoration(labelText: 'Base Debit'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => line.baseDebitAmount = double.tryParse(val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: line.baseCreditAmount?.toString(),
                            decoration: const InputDecoration(labelText: 'Base Credit'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => line.baseCreditAmount = double.tryParse(val),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Total Debit: ${_totalDebit.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Text('Total Credit: ${_totalCredit.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveForm,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Save Journal Entry'),
            ),
          ),
        ],
      ),
    );
  }
}

class JournalLineInput {
  String? id;
  String accountId = '';
  String? costCenterId;
  String? projectId;
  double debit = 0.0;
  double credit = 0.0;
  double? baseDebitAmount;
  double? baseCreditAmount;
  String? description;
  String? taxCodeId;

  JournalLineInput();

  factory JournalLineInput.fromModel(JournalLine model) {
    final input = JournalLineInput();
    input.id = model.id;
    input.accountId = model.accountId;
    input.costCenterId = model.costCenterId;
    input.projectId = model.projectId;
    input.description = model.description;
    input.debit = model.debitAmount;
    input.credit = model.creditAmount;
    input.baseDebitAmount = model.baseDebitAmount;
    input.baseCreditAmount = model.baseCreditAmount;
    input.taxCodeId = model.taxCodeId;
    return input;
  }
}
