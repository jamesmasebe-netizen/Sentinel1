import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pmo_models.dart';

class PmoTimeEntryForm extends StatefulWidget {
  final TimeEntry? initialEntry;
  final void Function(TimeEntry entry) onSave;

  const PmoTimeEntryForm({super.key, this.initialEntry, required this.onSave});

  @override
  State<PmoTimeEntryForm> createState() => _PmoTimeEntryFormState();
}

class _PmoTimeEntryFormState extends State<PmoTimeEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _resourceIdCtrl = TextEditingController();
  final _projectIdCtrl = TextEditingController();
  final _taskIdCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _approverIdCtrl = TextEditingController();
  final _rejectionReasonCtrl = TextEditingController();
  final _invoiceIdCtrl = TextEditingController();

  DateTime? _date;
  bool _isBillable = true;
  String _billingStatus = 'Unbilled';
  String _approvalStatus = 'Draft';

  static const _billingStatuses = [
    'Unbilled',
    'ReadyToInvoice',
    'Invoiced',
    'Paid',
  ];
  static const _approvalStatuses = ['Draft', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    if (widget.initialEntry != null) {
      final e = widget.initialEntry!;
      _resourceIdCtrl.text = e.resourceId;
      _projectIdCtrl.text = e.projectId;
      _taskIdCtrl.text = e.taskId;
      _hoursCtrl.text = e.hours.toString();
      _descriptionCtrl.text = e.description;
      _approverIdCtrl.text = e.approverId ?? '';
      _rejectionReasonCtrl.text = e.rejectionReason ?? '';
      _invoiceIdCtrl.text = e.invoiceId ?? '';

      _date = e.date;
      _isBillable = e.isBillable;
      _billingStatus =
          _billingStatuses.contains(e.billingStatus)
              ? e.billingStatus
              : 'Unbilled';
      _approvalStatus =
          _approvalStatuses.contains(e.approvalStatus)
              ? e.approvalStatus
              : 'Draft';
    }
  }

  @override
  void dispose() {
    _resourceIdCtrl.dispose();
    _projectIdCtrl.dispose();
    _taskIdCtrl.dispose();
    _hoursCtrl.dispose();
    _descriptionCtrl.dispose();
    _approverIdCtrl.dispose();
    _rejectionReasonCtrl.dispose();
    _invoiceIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final entry = TimeEntry(
      entryId:
          widget.initialEntry?.entryId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      resourceId: _resourceIdCtrl.text.trim(),
      projectId: _projectIdCtrl.text.trim(),
      taskId: _taskIdCtrl.text.trim(),
      date: _date,
      hours: double.tryParse(_hoursCtrl.text) ?? 0.0,
      description: _descriptionCtrl.text.trim(),
      isBillable: _isBillable,
      billingStatus: _billingStatus,
      approvalStatus: _approvalStatus,
      approverId:
          _approverIdCtrl.text.trim().isEmpty
              ? null
              : _approverIdCtrl.text.trim(),
      rejectionReason:
          _rejectionReasonCtrl.text.trim().isEmpty
              ? null
              : _rejectionReasonCtrl.text.trim(),
      invoiceId:
          _invoiceIdCtrl.text.trim().isEmpty
              ? null
              : _invoiceIdCtrl.text.trim(),
    );
    widget.onSave(entry);
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _resourceIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Resource ID *',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _date != null ? dateFmt.format(_date!) : 'Select Date',
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
                    controller: _projectIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Project ID *',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _taskIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Task ID *',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hours *',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Required' : null,
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
            TextFormField(
              controller: _descriptionCtrl,
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
                  child: DropdownButtonFormField<String>(
                    value: _billingStatus,
                    decoration: const InputDecoration(
                      labelText: 'Billing Status',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _billingStatuses
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _billingStatus = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _approvalStatus,
                    decoration: const InputDecoration(
                      labelText: 'Approval Status',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _approvalStatuses
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _approvalStatus = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_approvalStatus == 'Approved' ||
                _approvalStatus == 'Rejected') ...[
              TextFormField(
                controller: _approverIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Approver ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_approvalStatus == 'Rejected') ...[
              TextFormField(
                controller: _rejectionReasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _invoiceIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Invoice ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Time Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
