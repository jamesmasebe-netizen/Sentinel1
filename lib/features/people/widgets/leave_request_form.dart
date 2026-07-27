import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hr_models.dart';
import '../services/hr_service.dart';

class LeaveRequestForm extends ConsumerStatefulWidget {
  final String employeeId;
  final LeaveRequest? initialData;
  final VoidCallback? onSaved;

  const LeaveRequestForm({
    super.key,
    required this.employeeId,
    this.initialData,
    this.onSaved,
  });

  @override
  ConsumerState<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends ConsumerState<LeaveRequestForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _leaveTypeIdController;
  late TextEditingController _leaveTypeController;
  late TextEditingController _totalHoursRequestedController;
  late TextEditingController _statusController;
  late TextEditingController _approverIdController;
  late TextEditingController _reasonController;
  late TextEditingController _medicalCertificateUrlController;
  late TextEditingController _employeeNameController;
  late TextEditingController _managerIdController;
  late TextEditingController _siteIdController;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _leaveTypeIdController = TextEditingController(
      text: data?.leaveTypeId ?? '',
    );
    _leaveTypeController = TextEditingController(text: data?.leaveType ?? '');
    _totalHoursRequestedController = TextEditingController(
      text: data?.totalHoursRequested.toString() ?? '0.0',
    );
    _statusController = TextEditingController(text: data?.status ?? 'Pending');
    _approverIdController = TextEditingController(text: data?.approverId ?? '');
    _reasonController = TextEditingController(text: data?.reason ?? '');
    _medicalCertificateUrlController = TextEditingController(
      text: data?.medicalCertificateUrl ?? '',
    );
    _employeeNameController = TextEditingController(
      text: data?.employeeName ?? '',
    );
    _managerIdController = TextEditingController(text: data?.managerId ?? '');
    _siteIdController = TextEditingController(text: data?.siteId ?? '');

    _startDate = data?.startDate ?? DateTime.now();
    _endDate = data?.endDate ?? DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _leaveTypeIdController.dispose();
    _leaveTypeController.dispose();
    _totalHoursRequestedController.dispose();
    _statusController.dispose();
    _approverIdController.dispose();
    _reasonController.dispose();
    _medicalCertificateUrlController.dispose();
    _employeeNameController.dispose();
    _managerIdController.dispose();
    _siteIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate =
        isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = LeaveRequest(
        id:
            widget.initialData?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        leaveTypeId: _leaveTypeIdController.text.trim(),
        leaveType: _leaveTypeController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        totalHoursRequested:
            double.tryParse(_totalHoursRequestedController.text.trim()) ?? 0.0,
        status: _statusController.text.trim(),
        approverId: _approverIdController.text.trim(),
        reason: _reasonController.text.trim(),
        medicalCertificateUrl:
            _medicalCertificateUrlController.text.trim().isEmpty
                ? null
                : _medicalCertificateUrlController.text.trim(),
        employeeId: widget.employeeId,
        employeeName: _employeeNameController.text.trim(),
        managerId: _managerIdController.text.trim(),
        siteId: _siteIdController.text.trim(),
      );

      final hrService = ref.read(hrServiceProvider);
      if (widget.initialData == null) {
        await hrService.createLeaveRequest(widget.employeeId, request);
      } else {
        await hrService.updateLeaveRequest(
          widget.employeeId,
          request.id,
          request.toJson(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request saved successfully.')),
        );
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving leave request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _leaveTypeIdController,
            decoration: const InputDecoration(
              labelText: 'Leave Type ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _leaveTypeController,
            decoration: const InputDecoration(
              labelText: 'Leave Type (e.g. Sick, Vacation)',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(
                    _startDate != null
                        ? '${_startDate!.toLocal()}'.split(' ')[0]
                        : 'Not set',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, true),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(
                    _endDate != null
                        ? '${_endDate!.toLocal()}'.split(' ')[0]
                        : 'Not set',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, false),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _totalHoursRequestedController,
            decoration: const InputDecoration(
              labelText: 'Total Hours Requested',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (double.tryParse(value) == null) return 'Enter a valid number';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _statusController,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _medicalCertificateUrlController,
            decoration: const InputDecoration(
              labelText: 'Medical Certificate URL (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const Text(
            'Additional Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _employeeNameController,
            decoration: const InputDecoration(
              labelText: 'Employee Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _approverIdController,
            decoration: const InputDecoration(
              labelText: 'Approver ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _managerIdController,
            decoration: const InputDecoration(
              labelText: 'Manager ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _siteIdController,
            decoration: const InputDecoration(
              labelText: 'Site ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveForm,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Leave Request'),
            ),
          ),
        ],
      ),
    );
  }
}
