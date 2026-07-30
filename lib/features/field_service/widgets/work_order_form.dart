import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../people/widgets/employee_selector.dart';
import '../models/field_service_models.dart';
import '../services/field_service_service.dart';
import '../providers/field_service_providers.dart';
import '../../crm/providers/crm_providers.dart';
import '../../crm/models/crm_models.dart';
import '../../../core/widgets/entity_selector.dart';

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
  late TextEditingController _addrStreetController;
  late TextEditingController _addrCityController;
  late TextEditingController _schedStartController;
  late TextEditingController _schedEndController;
  late TextEditingController _safetyPpeController;
  late TextEditingController _iotDeviceIdController;
  late TextEditingController _finEstCostController;
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
    _addrStreetController = TextEditingController(
      text: widget.initialWorkOrder?.address?['street'] ?? '',
    );
    _addrCityController = TextEditingController(
      text: widget.initialWorkOrder?.address?['city'] ?? '',
    );
    _schedStartController = TextEditingController(
      text: widget.initialWorkOrder?.scheduling?['scheduled_start'] ?? '',
    );
    _schedEndController = TextEditingController(
      text: widget.initialWorkOrder?.scheduling?['scheduled_end'] ?? '',
    );
    _safetyPpeController = TextEditingController(
      text: widget.initialWorkOrder?.safetyRequirements?['ppe_required'] ?? '',
    );
    _iotDeviceIdController = TextEditingController(
      text: widget.initialWorkOrder?.iotContext?['device_id'] ?? '',
    );
    _finEstCostController = TextEditingController(
      text: widget.initialWorkOrder?.financials?['estimated_cost']?.toString() ?? '',
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
    _addrStreetController.dispose();
    _addrCityController.dispose();
    _schedStartController.dispose();
    _schedEndController.dispose();
    _safetyPpeController.dispose();
    _iotDeviceIdController.dispose();
    _finEstCostController.dispose();
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
        address: (_addrStreetController.text.isNotEmpty || _addrCityController.text.isNotEmpty)
            ? {
                'street': _addrStreetController.text,
                'city': _addrCityController.text,
              }
            : null,
        scheduling: (_schedStartController.text.isNotEmpty || _schedEndController.text.isNotEmpty)
            ? {
                'scheduled_start': _schedStartController.text,
                'scheduled_end': _schedEndController.text,
              }
            : null,
        safetyRequirements: _safetyPpeController.text.isNotEmpty
            ? {'ppe_required': _safetyPpeController.text}
            : null,
        iotContext: _iotDeviceIdController.text.isNotEmpty
            ? {'device_id': _iotDeviceIdController.text}
            : null,
        financials: _finEstCostController.text.isNotEmpty
            ? {'estimated_cost': double.tryParse(_finEstCostController.text) ?? 0.0}
            : null,
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
          DropdownButtonFormField<String>(
            value: kWorkOrderStatuses.contains(_statusController.text) ? _statusController.text : 'DRAFT',
            decoration: const InputDecoration(labelText: 'Status'),
            items: kWorkOrderStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) {
              if (val != null) _statusController.text = val;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: kWorkOrderPriorities.contains(_priorityController.text) ? _priorityController.text : 'LOW',
            decoration: const InputDecoration(labelText: 'Priority'),
            items: kWorkOrderPriorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) {
              if (val != null) _priorityController.text = val;
            },
          ),
          const SizedBox(height: 16),
          EntitySelector<Account>(
            value: _customerIdController.text.isEmpty ? null : _customerIdController.text,
            onChanged: (val) => setState(() => _customerIdController.text = val ?? ''),
            label: 'Customer',
            asyncEntities: ref.watch(accountsStreamProvider),
            idMapper: (a) => a.id,
            displayMapper: (a) => a.name,
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
          EntitySelector<WorkOrderSubstatus>(
            value: _substatusIdController.text.isEmpty ? null : _substatusIdController.text,
            onChanged: (val) => setState(() => _substatusIdController.text = val ?? ''),
            label: 'Substatus',
            asyncEntities: ref.watch(woSubstatusesStreamProvider),
            idMapper: (s) => s.id,
            displayMapper: (s) => s.name,
          ),
          const SizedBox(height: 16),
          EntitySelector<IncidentType>(
            value: _incidentTypeIdController.text.isEmpty ? null : _incidentTypeIdController.text,
            onChanged: (val) => setState(() => _incidentTypeIdController.text = val ?? ''),
            label: 'Incident Type',
            asyncEntities: ref.watch(incidentTypesStreamProvider),
            idMapper: (t) => t.id,
            displayMapper: (t) => t.name,
          ),
          const SizedBox(height: 16),
          EntitySelector<ServiceType>(
            value: _serviceTypeIdController.text.isEmpty ? null : _serviceTypeIdController.text,
            onChanged: (val) => setState(() => _serviceTypeIdController.text = val ?? ''),
            label: 'Service Type',
            asyncEntities: ref.watch(serviceTypesStreamProvider),
            idMapper: (t) => t.id,
            displayMapper: (t) => t.name,
          ),
          const SizedBox(height: 16),
          EntitySelector<Account>(
            value: _billingAccountIdController.text.isEmpty ? null : _billingAccountIdController.text,
            onChanged: (val) => setState(() => _billingAccountIdController.text = val ?? ''),
            label: 'Billing Account',
            asyncEntities: ref.watch(accountsStreamProvider),
            idMapper: (a) => a.id,
            displayMapper: (a) => a.name,
          ),
          const SizedBox(height: 16),
          EntitySelector<Agreement>(
            value: _agreementIdController.text.isEmpty ? null : _agreementIdController.text,
            onChanged: (val) => setState(() => _agreementIdController.text = val ?? ''),
            label: 'Agreement',
            asyncEntities: ref.watch(agreementsStreamProvider),
            idMapper: (a) => a.id,
            displayMapper: (a) => a.title,
          ),
          const SizedBox(height: 16),
          EntitySelector<CustomerAsset>(
            value: _assetIdController.text.isEmpty ? null : _assetIdController.text,
            onChanged: (val) => setState(() => _assetIdController.text = val ?? ''),
            label: 'Asset',
            asyncEntities: ref.watch(allCustomerAssetsStreamProvider),
            idMapper: (a) => a.id,
            displayMapper: (a) => a.assetName,
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
          EntitySelector<Territory>(
            value: _territoryIdController.text.isEmpty ? null : _territoryIdController.text,
            onChanged: (val) => setState(() => _territoryIdController.text = val ?? ''),
            label: 'Territory',
            asyncEntities: ref.watch(territoriesStreamProvider),
            idMapper: (t) => t.id,
            displayMapper: (t) => t.name,
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
          const Divider(),
          const Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
          TextFormField(
            controller: _addrStreetController,
            decoration: const InputDecoration(labelText: 'Street'),
          ),
          TextFormField(
            controller: _addrCityController,
            decoration: const InputDecoration(labelText: 'City'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const Text('Scheduling', style: TextStyle(fontWeight: FontWeight.bold)),
          TextFormField(
            controller: _schedStartController,
            decoration: const InputDecoration(
              labelText: 'Scheduled Start',
              suffixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null && mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  _schedStartController.text = dt.toIso8601String();
                }
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _schedEndController,
            decoration: const InputDecoration(
              labelText: 'Scheduled End',
              suffixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null && mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  _schedEndController.text = dt.toIso8601String();
                }
              }
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const Text('Safety Requirements', style: TextStyle(fontWeight: FontWeight.bold)),
          TextFormField(
            controller: _safetyPpeController,
            decoration: const InputDecoration(labelText: 'PPE Required'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const Text('IoT Context', style: TextStyle(fontWeight: FontWeight.bold)),
          TextFormField(
            controller: _iotDeviceIdController,
            decoration: const InputDecoration(labelText: 'IoT Device ID'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const Text('Financials', style: TextStyle(fontWeight: FontWeight.bold)),
          TextFormField(
            controller: _finEstCostController,
            decoration: const InputDecoration(labelText: 'Estimated Cost'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
