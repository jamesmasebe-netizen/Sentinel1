import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/searchable_multi_select.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../people/providers/employee_providers.dart';
import '../../../people/widgets/employee_selector.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';
import 'new_project_header.dart';
import 'project_stages_preview.dart';
import 'new_project_footer.dart';
import '../../../equipment/widgets/equipment_multi_selector.dart';

class NewProjectDialogContent extends ConsumerStatefulWidget {
  const NewProjectDialogContent({super.key});

  @override
  ConsumerState<NewProjectDialogContent> createState() =>
      _NewProjectDialogContentState();
}

class _NewProjectDialogContentState
    extends ConsumerState<NewProjectDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _leadContactCtrl = TextEditingController();
  final _fallbackContactCtrl = TextEditingController();

  List<String> _allocatedEmployeeIds = [];
  List<String> _allocatedContractorIds = [];
  List<String> _allocatedAssetIds = [];

  String? _selectedLeadId;
  String? _selectedFallbackId;

  String _category = 'Maintenance';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 90));
  bool _saving = false;

  static const _categories = [
    'Maintenance',
    'Opex',
    'Renovation',
    'Emergency',
    'New Build',
    'Compliance',
  ];

  List<ProjectStage> get _defaultStages => [
    ProjectStage(
      id: 'stage_0',
      stageName: 'Starting Up a Project (SU)',
      order: 0,
    ),
    ProjectStage(
      id: 'stage_1',
      stageName: 'Initiating a Project (IP)',
      order: 1,
      requiresSafetyClearance: true,
    ),
    ProjectStage(
      id: 'stage_2',
      stageName: 'Controlling a Stage (CS)',
      order: 2,
    ),
    ProjectStage(
      id: 'stage_3',
      stageName: 'Managing Stage Boundaries (SB)',
      order: 3,
    ),
    ProjectStage(
      id: 'stage_4',
      stageName: 'Managing Product Delivery (MP)',
      order: 4,
      requiresSafetyClearance: true,
    ),
    ProjectStage(id: 'stage_5', stageName: 'Closing a Project (CP)', order: 5),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    _leadContactCtrl.dispose();
    _fallbackContactCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final siteId = ref.read(currentTenantIdProvider) ?? 'Site A';
      final project = Project(
        id: '',
        tenantId: siteId,
        propertyId: 'default-property',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        startDate: _startDate,
        targetEndDate: _endDate,
        budget: double.tryParse(_budgetCtrl.text.replaceAll(',', '')) ?? 0.0,
        projectLead: _selectedLeadId ?? '',
        projectLeadContact: _leadContactCtrl.text.trim(),
        fallbackContact: _selectedFallbackId ?? '',
        fallbackContactContact: _fallbackContactCtrl.text.trim(),
        allocatedEmployeeIds: _allocatedEmployeeIds,
        allocatedContractorIds: _allocatedContractorIds,
        allocatedAssetIds: _allocatedAssetIds,
        status: 'Draft',
        stages: _defaultStages,
        createdAt: DateTime.now(),
      );

      await ref.read(projectServiceProvider).createProject(project);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        UIUtils.showToast(
          context,
          'Failed to create project: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 90));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NewProjectHeader(),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Project Name *',
                      prefixIcon: Icon(Icons.label_rounded),
                      hintText: 'e.g. Building Renovation Phase 1',
                    ),
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Project name is required'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description_rounded),
                      hintText: 'Scope and objectives of this project...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            prefixIcon: Icon(Icons.category_rounded),
                            isDense: true,
                          ),
                          items:
                              _categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _budgetCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Budget (R)',
                            prefixIcon: Icon(Icons.attach_money),
                            hintText: '0.00',
                          ),
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              if (double.tryParse(v.replaceAll(',', '')) ==
                                  null) {
                                return 'Enter a valid number';
                              }
                            }
                            return null;
                          },
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
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Date *',
                              prefixIcon: Icon(Icons.calendar_today_rounded),
                              isDense: true,
                            ),
                            child: Text(
                              dateFmt.format(_startDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(false),
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Target End Date *',
                              prefixIcon: Icon(Icons.event_rounded),
                              isDense: true,
                            ),
                            child: Text(
                              dateFmt.format(_endDate),
                              style: const TextStyle(fontSize: 14),
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
                        child: EmployeeSelector(
                          label: 'Project Lead Name',
                          value: _selectedLeadId,
                          onChanged: (val) {
                            setState(() {
                              _selectedLeadId = val;
                              if (val != null) {
                                final emps =
                                    ref.read(employeesProvider).valueOrNull;
                                if (emps != null) {
                                  try {
                                    final emp = emps.firstWhere(
                                      (e) => e.id == val,
                                    );
                                    _leadContactCtrl.text = emp.email;
                                  } catch (_) {}
                                }
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _leadContactCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Project Lead Contact',
                            prefixIcon: Icon(Icons.contact_phone_rounded),
                            hintText: 'e.g. john@company.com',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: EmployeeSelector(
                          label: 'Fallback Contact Name',
                          value: _selectedFallbackId,
                          onChanged: (val) {
                            setState(() {
                              _selectedFallbackId = val;
                              if (val != null) {
                                final emps =
                                    ref.read(employeesProvider).valueOrNull;
                                if (emps != null) {
                                  try {
                                    final emp = emps.firstWhere(
                                      (e) => e.id == val,
                                    );
                                    _fallbackContactCtrl.text = emp.email;
                                  } catch (_) {}
                                }
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _fallbackContactCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Fallback Contact Details',
                            prefixIcon: Icon(Icons.contact_phone_outlined),
                            hintText: 'e.g. +27 82 123 4567',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 20),
                  ProjectStagesPreview(stages: _defaultStages),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        NewProjectFooter(
          saving: _saving,
          onCancel: () => Navigator.of(context).pop(),
          onSave: _save,
        ),
      ],
    );
  }
}
