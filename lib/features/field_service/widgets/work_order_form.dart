import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../people/widgets/employee_selector.dart';
import '../models/field_service_models.dart';
import '../services/field_service_service.dart';

class WorkOrderForm extends ConsumerStatefulWidget {
  final WorkOrder? initialWorkOrder;

  const WorkOrderForm({super.key, this.initialWorkOrder});

  @override
  ConsumerState<WorkOrderForm> createState() => _WorkOrderFormState();
}

class _WorkOrderFormState extends ConsumerState<WorkOrderForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _workOrderNumberController;
  late TextEditingController _statusController;
  late TextEditingController _priorityController;
  late TextEditingController _customerIdController;
  late TextEditingController _descriptionController;
  late TextEditingController _resolutionNotesController;
  late TextEditingController _substatusIdController;
  late TextEditingController _incidentTypeIdController;
  late TextEditingController _serviceTypeIdController;
  late TextEditingController _billingAccountIdController;
  late TextEditingController _agreementIdController;
  late TextEditingController _assetIdController;
  late TextEditingController _assignedTechnicianIdController;
  late TextEditingController _dispatcherIdController;
  late TextEditingController _territoryIdController;
  late TextEditingController _locationLatController;
  late TextEditingController _locationLngController;
  late TextEditingController _addressController;
  late TextEditingController _schedulingController;
  late TextEditingController _safetyRequirementsController;
  late TextEditingController _iotContextController;
  late TextEditingController _financialsController;
  bool _isMobileOfflineSynced = false;

  @override
  void initState() {
    super.initState();
    _workOrderNumberController = TextEditingController(
      text: widget.initialWorkOrder?.workOrderNumber ?? '',
    );
    _statusController = TextEditingController(
      text: widget.initialWorkOrder?.status ?? 'DRAFT',
    );
    _priorityController = TextEditingController(
      text: widget.initialWorkOrder?.priority ?? 'LOW',
    );
    _customerIdController = TextEditingController(
      text: widget.initialWorkOrder?.customerId ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialWorkOrder?.description ?? '',
    );
    _resolutionNotesController = TextEditingController(
      text: widget.initialWorkOrder?.resolutionNotes ?? '',
    );
    _substatusIdController = TextEditingController(
      text: widget.initialWorkOrder?.substatusId ?? '',
    );
    _incidentTypeIdController = TextEditingController(
      text: widget.initialWorkOrder?.incidentTypeId ?? '',
    );
    _serviceTypeIdController = TextEditingController(
      text: widget.initialWorkOrder?.serviceTypeId ?? '',
    );
    _billingAccountIdController = TextEditingController(
      text: widget.initialWorkOrder?.billingAccountId ?? '',
    );
    _agreementIdController = TextEditingController(
      text: widget.initialWorkOrder?.agreementId ?? '',
    );
    _assetIdController = TextEditingController(
      text: widget.initialWorkOrder?.assetId ?? '',
    );
    _assignedTechnicianIdController = TextEditingController(
      text: widget.initialWorkOrder?.assignedTechnicianId ?? '',
    );
    _dispatcherIdController = TextEditingController(
      text: widget.initialWorkOrder?.dispatcherId ?? '',
    );
    _territoryIdController = TextEditingController(
      text: widget.initialWorkOrder?.territoryId ?? '',
    );
    _locationLatController = TextEditingController(
      text: widget.initialWorkOrder?.location?.latitude.toString() ?? '',
    );
    _locationLngController = TextEditingController(
      text: widget.initialWorkOrder?.location?.longitude.toString() ?? '',
    );
    _addressController = TextEditingController(
      text: widget.initialWorkOrder?.address != null ? jsonEncode(widget.initialWorkOrder!.address) : '',
    );
    _schedulingController = TextEditingController(
      text: widget.initialWorkOrder?.scheduling != null ? jsonEncode(widget.initialWorkOrder!.scheduling) : '',
    );
    _safetyRequirementsController = TextEditingController(
      text: widget.initialWorkOrder?.safetyRequirements != null ? jsonEncode(widget.initialWorkOrder!.safetyRequirements) : '',
    );
    _iotContextController = TextEditingController(
      text: widget.initialWorkOrder?.iotContext != null ? jsonEncode(widget.initialWorkOrder!.iotContext) : '',
    );
    _financialsController = TextEditingController(
      text: widget.initialWorkOrder?.financials != null ? jsonEncode(widget.initialWorkOrder!.financials) : '',
    );
    _isMobileOfflineSynced = widget.initialWorkOrder?.isMobileOfflineSynced ?? false;
  }

  @override
  void dispose() {
    _workOrderNumberController.dispose();
    _statusController.dispose();
    _priorityController.dispose();
    _customerIdController.dispose();
    _descriptionController.dispose();
    _resolutionNotesController.dispose();
    _substatusIdController.dispose();
    _incidentTypeIdController.dispose();
    _serviceTypeIdController.dispose();
    _billingAccountIdController.dispose();
    _agreementIdController.dispose();
    _assetIdController.dispose();
    _assignedTechnicianIdController.dispose();
    _dispatcherIdController.dispose();
    _territoryIdController.dispose();
    _locationLatController.dispose();
    _locationLngController.dispose();
    _addressController.dispose();
    _schedulingController.dispose();
    _safetyRequirementsController.dispose();
    _iotContextController.dispose();
    _financialsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final service = ref.read(fieldServiceServiceProvider);

      final workOrder = WorkOrder(
        id:
            widget.initialWorkOrder?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        workOrderNumber: _workOrderNumberController.text,
        status: _statusController.text,
        priority: _priorityController.text,
        customerId: _customerIdController.text,
        description:
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
        resolutionNotes:
            _resolutionNotesController.text.isNotEmpty
                ? _resolutionNotesController.text
                : null,
        substatusId: _substatusIdController.text.isNotEmpty ? _substatusIdController.text : null,
        incidentTypeId: _incidentTypeIdController.text.isNotEmpty ? _incidentTypeIdController.text : null,
        serviceTypeId: _serviceTypeIdController.text.isNotEmpty ? _serviceTypeIdController.text : null,
        billingAccountId: _billingAccountIdController.text.isNotEmpty ? _billingAccountIdController.text : null,
        agreementId: _agreementIdController.text.isNotEmpty ? _agreementIdController.text : null,
        assetId: _assetIdController.text.isNotEmpty ? _assetIdController.text : null,
        assignedTechnicianId: _assignedTechnicianIdController.text.isNotEmpty ? _assignedTechnicianIdController.text : null,
        dispatcherId: _dispatcherIdController.text.isNotEmpty ? _dispatcherIdController.text : null,
        territoryId: _territoryIdController.text.isNotEmpty ? _territoryIdController.text : null,
        location: _locationLatController.text.isNotEmpty && _locationLngController.text.isNotEmpty
            ? GeoPoint(double.parse(_locationLatController.text), double.parse(_locationLngController.text))
            : null,
        address: _addressController.text.isNotEmpty ? jsonDecode(_addressController.text) : null,
        scheduling: _schedulingController.text.isNotEmpty ? jsonDecode(_schedulingController.text) : null,
        safetyRequirements: _safetyRequirementsController.text.isNotEmpty ? jsonDecode(_safetyRequirementsController.text) : null,
        iotContext: _iotContextController.text.isNotEmpty ? jsonDecode(_iotContextController.text) : null,
        financials: _financialsController.text.isNotEmpty ? jsonDecode(_financialsController.text) : null,
        isMobileOfflineSynced: _isMobileOfflineSynced,
        createdAt: widget.initialWorkOrder?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        if (widget.initialWorkOrder == null) {
          await service.createWorkOrder(workOrder);
        } else {
          await service.updateWorkOrder(workOrder);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Work Order saved successfully')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving Work Order: $e')),
          );
        }
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
            controller: _workOrderNumberController,
            decoration: const InputDecoration(labelText: 'Work Order Number'),
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _statusController,
            decoration: const InputDecoration(labelText: 'Status'),
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priorityController,
            decoration: const InputDecoration(labelText: 'Priority'),
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _customerIdController,
            decoration: const InputDecoration(labelText: 'Customer ID'),
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _resolutionNotesController,
            decoration: const InputDecoration(labelText: 'Resolution Notes'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _substatusIdController,
            decoration: const InputDecoration(labelText: 'Substatus ID'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _incidentTypeIdController,
            decoration: const InputDecoration(labelText: 'Incident Type ID'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _serviceTypeIdController,
            decoration: const InputDecoration(labelText: 'Service Type ID'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _billingAccountIdController,
            decoration: const InputDecoration(labelText: 'Billing Account ID'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _agreementIdController,
            decoration: const InputDecoration(labelText: 'Agreement ID'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _assetIdController,
            decoration: const InputDecoration(labelText: 'Asset ID'),
          ),
          const SizedBox(height: 16),
          EmployeeSelector(
            value: _assignedTechnicianIdController.text.isEmpty ? null : _assignedTechnicianIdController.text,
            onChanged: (val) {
              setState(() {
                _assignedTechnicianIdController.text = val ?? '';
              });
            },
            label: 'Assigned Technician ID',
          ),
          const SizedBox(height: 16),
          EmployeeSelector(
            value: _dispatcherIdController.text.isEmpty ? null : _dispatcherIdController.text,
            onChanged: (val) {
              setState(() {
                _dispatcherIdController.text = val ?? '';
              });
            },
            label: 'Dispatcher ID',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _territoryIdController,
            decoration: const InputDecoration(labelText: 'Territory ID'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationLatController,
            decoration: const InputDecoration(labelText: 'Location Latitude'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationLngController,
            decoration: const InputDecoration(labelText: 'Location Longitude'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Address (JSON)'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _schedulingController,
            decoration: const InputDecoration(labelText: 'Scheduling (JSON)'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _safetyRequirementsController,
            decoration: const InputDecoration(labelText: 'Safety Requirements (JSON)'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _iotContextController,
            decoration: const InputDecoration(labelText: 'IoT Context (JSON)'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _financialsController,
            decoration: const InputDecoration(labelText: 'Financials (JSON)'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Is Mobile Offline Synced'),
            value: _isMobileOfflineSynced,
            onChanged: (bool value) {
              setState(() {
                _isMobileOfflineSynced = value;
              });
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Save Work Order'),
          ),
        ],
      ),
    );
  }
}
