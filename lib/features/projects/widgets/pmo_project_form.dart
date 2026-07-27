import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/searchable_multi_select.dart';
import '../models/pmo_models.dart';
import '../../people/providers/employee_providers.dart';
import '../../equipment/widgets/equipment_multi_selector.dart';

class PmoProjectForm extends ConsumerStatefulWidget {
  final Project? initialProject;
  final void Function(Project project) onSave;

  const PmoProjectForm({super.key, this.initialProject, required this.onSave});

  @override
  ConsumerState<PmoProjectForm> createState() => _PmoProjectFormState();
}

class _PmoProjectFormState extends ConsumerState<PmoProjectForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _clientIdCtrl = TextEditingController();
  final _contractIdCtrl = TextEditingController();
  final _pmIdCtrl = TextEditingController();
  final _budgetAmountCtrl = TextEditingController();
  final _budgetConsumedCtrl = TextEditingController();
  final _revRecogMethodCtrl = TextEditingController();

  List<String> _allocatedEmployeeIds = [];
  List<String> _allocatedContractorIds = [];
  List<String> _allocatedAssetIds = [];

  String _status = 'Draft';
  String _currency = 'USD';
  DateTime? _startDate;
  DateTime? _endDate;

  static const _statuses = [
    'Draft',
    'Active',
    'On Hold',
    'Completed',
    'Cancelled',
  ];
  static const _currencies = ['USD', 'EUR', 'GBP', 'ZAR'];

  @override
  void initState() {
    super.initState();
    if (widget.initialProject != null) {
      final p = widget.initialProject!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description;
      _clientIdCtrl.text = p.clientId;
      _contractIdCtrl.text = p.contractId;
      _pmIdCtrl.text = p.projectManagerId;
      if (p.budget != null) {
        _budgetAmountCtrl.text = p.budget!.totalBudgetAmount.toString();
        _budgetConsumedCtrl.text = p.budget!.consumedBudget.toString();
        _currency =
            _currencies.contains(p.budget!.currency)
                ? p.budget!.currency
                : 'USD';
      }
      _revRecogMethodCtrl.text = p.revenueRecognitionMethod;
      _allocatedEmployeeIds = List.from(p.allocatedEmployeeIds);
      _allocatedContractorIds = List.from(p.allocatedContractorIds);
      _allocatedAssetIds = List.from(p.allocatedAssetIds);
      _status = _statuses.contains(p.status) ? p.status : 'Draft';
      _startDate = p.startDate;
      _endDate = p.endDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _clientIdCtrl.dispose();
    _contractIdCtrl.dispose();
    _pmIdCtrl.dispose();
    _budgetAmountCtrl.dispose();
    _budgetConsumedCtrl.dispose();
    _revRecogMethodCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isStart
              ? (_startDate ?? DateTime.now())
              : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final project = Project(
      projectId:
          widget.initialProject?.projectId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      clientId: _clientIdCtrl.text.trim(),
      contractId: _contractIdCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      status: _status,
      projectManagerId: _pmIdCtrl.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      budget: BudgetModel(
        totalBudgetAmount: double.tryParse(_budgetAmountCtrl.text) ?? 0.0,
        currency: _currency,
        consumedBudget: double.tryParse(_budgetConsumedCtrl.text) ?? 0.0,
      ),
      revenueRecognitionMethod: _revRecogMethodCtrl.text.trim(),
      allocatedEmployeeIds: _allocatedEmployeeIds,
      allocatedContractorIds: _allocatedContractorIds,
      allocatedAssetIds: _allocatedAssetIds,
      createdAt: widget.initialProject?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    widget.onSave(project);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('yyyy-MM-dd');
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Project Name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _clientIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Client ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _contractIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contract ID',
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
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _statuses
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _pmIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Project Manager ID',
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
                    onTap: () => _pickDate(true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _startDate != null
                            ? dateFmt.format(_startDate!)
                            : 'Select Date',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _endDate != null
                            ? dateFmt.format(_endDate!)
                            : 'Select Date',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _budgetAmountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Budget Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _currencies
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _budgetConsumedCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Consumed Budget',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _revRecogMethodCtrl,
              decoration: const InputDecoration(
                labelText: 'Revenue Recognition Method',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Comprehensive Resource Allocation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ref.watch(employeesProvider).when(
                  data: (employees) {
                    final Map<String, String> empLabels = {};
                    final List<String> availableEmpIds = [];
                    for (var e in employees) {
                      empLabels[e.id] = '\${e.firstName} \${e.lastName} (\${e.department})';
                      availableEmpIds.add(e.id);
                    }
                    return SearchableStringMultiSelect(
                      label: 'Allocated Employee IDs',
                      hintText: 'Search or type Employee Name/ID...',
                      availableItems: availableEmpIds,
                      itemLabels: empLabels,
                      selectedItems: _allocatedEmployeeIds,
                      onChanged: (val) => setState(() => _allocatedEmployeeIds = val),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('Error loading employees: $e'),
                ),
            const SizedBox(height: 12),
            SearchableStringMultiSelect(
              label: 'Allocated Contractor IDs',
              hintText: 'Search or type Contractor ID...',
              selectedItems: _allocatedContractorIds,
              onChanged: (val) => setState(() => _allocatedContractorIds = val),
            ),
            const SizedBox(height: 12),
            EquipmentMultiSelector(
              selectedItems: _allocatedAssetIds,
              onChanged: (val) => setState(() => _allocatedAssetIds = val),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Project'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
