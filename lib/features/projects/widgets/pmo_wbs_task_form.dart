import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pmo_models.dart';
import '../../../../core/widgets/searchable_multi_select.dart';
import '../../people/providers/employee_providers.dart';

class PmoWbsTaskForm extends ConsumerStatefulWidget {
  final WbsTask? initialTask;
  final void Function(WbsTask task) onSave;

  const PmoWbsTaskForm({super.key, this.initialTask, required this.onSave});

  @override
  ConsumerState<PmoWbsTaskForm> createState() => _PmoWbsTaskFormState();
}

class _PmoWbsTaskFormState extends ConsumerState<PmoWbsTaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _parentTaskIdCtrl = TextEditingController();
  final _estHoursCtrl = TextEditingController();
  final _actHoursCtrl = TextEditingController();
  final _remHoursCtrl = TextEditingController();
  
  List<String> _assignedResourceIds = [];
  List<String> _dependencies = [];

  double _percentComplete = 0;
  String _taskType = 'Task';
  String _status = 'NotStarted';
  bool _isBillable = true;
  DateTime? _startDate;
  DateTime? _endDate;

  static const _taskTypes = ['Task', 'Milestone', 'Phase', 'Deliverable'];
  static const _statuses = ['NotStarted', 'InProgress', 'Completed', 'OnHold'];

  @override
  void initState() {
    super.initState();
    if (widget.initialTask != null) {
      final t = widget.initialTask!;
      _nameCtrl.text = t.name;
      _descCtrl.text = t.description;
      _parentTaskIdCtrl.text = t.parentTaskId ?? '';
      _assignedResourceIds = List.from(t.assignedResourceIds);
      _dependencies = List.from(t.dependencies);
      if (t.effort != null) {
        _estHoursCtrl.text = t.effort!.estimatedHours.toString();
        _actHoursCtrl.text = t.effort!.actualHours.toString();
        _remHoursCtrl.text = t.effort!.remainingHours.toString();
      }
      _percentComplete = t.percentComplete;
      _taskType = _taskTypes.contains(t.taskType) ? t.taskType : 'Task';
      _status = _statuses.contains(t.status) ? t.status : 'NotStarted';
      _isBillable = t.isBillable;
      _startDate = t.startDate;
      _endDate = t.endDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _parentTaskIdCtrl.dispose();
    _estHoursCtrl.dispose();
    _actHoursCtrl.dispose();
    _remHoursCtrl.dispose();
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
    final task = WbsTask(
      taskId:
          widget.initialTask?.taskId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      parentTaskId:
          _parentTaskIdCtrl.text.trim().isEmpty
              ? null
              : _parentTaskIdCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      taskType: _taskType,
      status: _status,
      startDate: _startDate,
      endDate: _endDate,
      effort: EffortModel(
        estimatedHours: double.tryParse(_estHoursCtrl.text) ?? 0.0,
        actualHours: double.tryParse(_actHoursCtrl.text) ?? 0.0,
        remainingHours: double.tryParse(_remHoursCtrl.text) ?? 0.0,
      ),
      percentComplete: _percentComplete,
      assignedResourceIds: _assignedResourceIds,
      dependencies: _dependencies,
      isBillable: _isBillable,
    );
    widget.onSave(task);
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
                labelText: 'Task Name *',
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
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _parentTaskIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Parent Task ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _taskType,
                    decoration: const InputDecoration(
                      labelText: 'Task Type',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _taskTypes
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _taskType = v!),
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
                  child: SwitchListTile(
                    title: const Text('Is Billable'),
                    value: _isBillable,
                    onChanged: (v) => setState(() => _isBillable = v),
                    contentPadding: EdgeInsets.zero,
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
                  child: TextFormField(
                    controller: _estHoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Est. Hours',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _actHoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Actual Hours',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _remHoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Rem. Hours',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Percent Complete: ${_percentComplete.toInt()}%'),
            Slider(
              value: _percentComplete,
              min: 0,
              max: 100,
              divisions: 100,
              label: _percentComplete.toInt().toString(),
              onChanged: (v) => setState(() => _percentComplete = v),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final employeesAsync = ref.watch(employeesProvider);
                final availableEmployees = employeesAsync.valueOrNull?.map((e) => e.id).toList() ?? [];
                final employeeLabels = employeesAsync.valueOrNull != null
                    ? <String, String>{for (var e in employeesAsync.valueOrNull!) e.id: e.fullName}
                    : <String, String>{};
                return SearchableStringMultiSelect(
                  label: 'Assigned Resource IDs',
                  hintText: 'Search employees...',
                  availableItems: availableEmployees,
                  itemLabels: employeeLabels,
                  selectedItems: _assignedResourceIds,
                  onChanged: (val) {
                    setState(() {
                      _assignedResourceIds = val;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            SearchableStringMultiSelect(
              label: 'Dependencies (Task IDs)',
              hintText: 'Search or type task ID...',
              availableItems: const [], // We don't have a task list provider here yet, but typing works
              selectedItems: _dependencies,
              onChanged: (val) {
                setState(() {
                  _dependencies = val;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Save WBS Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
