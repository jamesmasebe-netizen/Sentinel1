import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../people/widgets/employee_selector.dart';
import '../models/field_service_models.dart';
import '../services/field_service_service.dart';

class DispatcherRouteForm extends ConsumerStatefulWidget {
  final DispatcherRoute? initialRoute;

  const DispatcherRouteForm({super.key, this.initialRoute});

  @override
  ConsumerState<DispatcherRouteForm> createState() =>
      _DispatcherRouteFormState();
}

class _DispatcherRouteFormState extends ConsumerState<DispatcherRouteForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _technicianIdController;
  late TextEditingController _statusController;
  late TextEditingController _generatedByController;
  late TextEditingController _startLocationLatController;
  late TextEditingController _startLocationLngController;
  late TextEditingController _endLocationLatController;
  late TextEditingController _endLocationLngController;
  late TextEditingController _metricsController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _technicianIdController = TextEditingController(
      text: widget.initialRoute?.technicianId ?? '',
    );
    _statusController = TextEditingController(
      text: widget.initialRoute?.status ?? 'DRAFT',
    );
    _generatedByController = TextEditingController(
      text: widget.initialRoute?.generatedBy ?? '',
    );
    _startLocationLatController = TextEditingController(
      text: widget.initialRoute?.startLocation?.latitude.toString() ?? '',
    );
    _startLocationLngController = TextEditingController(
      text: widget.initialRoute?.startLocation?.longitude.toString() ?? '',
    );
    _endLocationLatController = TextEditingController(
      text: widget.initialRoute?.endLocation?.latitude.toString() ?? '',
    );
    _endLocationLngController = TextEditingController(
      text: widget.initialRoute?.endLocation?.longitude.toString() ?? '',
    );
    _metricsController = TextEditingController(
      text: widget.initialRoute?.metrics != null ? jsonEncode(widget.initialRoute!.metrics) : '',
    );
    _selectedDate = widget.initialRoute?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _technicianIdController.dispose();
    _statusController.dispose();
    _generatedByController.dispose();
    _startLocationLatController.dispose();
    _startLocationLngController.dispose();
    _endLocationLatController.dispose();
    _endLocationLngController.dispose();
    _metricsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final service = ref.read(fieldServiceServiceProvider);

      final route = DispatcherRoute(
        id:
            widget.initialRoute?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        technicianId: _technicianIdController.text,
        date: _selectedDate,
        status: _statusController.text,
        startLocation: _startLocationLatController.text.isNotEmpty && _startLocationLngController.text.isNotEmpty
            ? GeoPoint(double.parse(_startLocationLatController.text), double.parse(_startLocationLngController.text))
            : null,
        endLocation: _endLocationLatController.text.isNotEmpty && _endLocationLngController.text.isNotEmpty
            ? GeoPoint(double.parse(_endLocationLatController.text), double.parse(_endLocationLngController.text))
            : null,
        metrics: _metricsController.text.isNotEmpty ? jsonDecode(_metricsController.text) : null,
        generatedBy: _generatedByController.text.isNotEmpty ? _generatedByController.text : null,
        createdAt: widget.initialRoute?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        if (widget.initialRoute == null) {
          await service.createRoutePlan(route);
        } else {
          await service.updateRoutePlan(route);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Route saved successfully')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving route: $e')));
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
          EmployeeSelector(
            value: _technicianIdController.text.isEmpty ? null : _technicianIdController.text,
            onChanged: (val) {
              setState(() {
                _technicianIdController.text = val ?? '';
              });
            },
            label: 'Technician ID',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _statusController,
            decoration: const InputDecoration(labelText: 'Status'),
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          EmployeeSelector(
            value: _generatedByController.text.isEmpty ? null : _generatedByController.text,
            onChanged: (val) {
              setState(() {
                _generatedByController.text = val ?? '';
              });
            },
            label: 'Generated By',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _startLocationLatController,
            decoration: const InputDecoration(labelText: 'Start Location Latitude'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _startLocationLngController,
            decoration: const InputDecoration(labelText: 'Start Location Longitude'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _endLocationLatController,
            decoration: const InputDecoration(labelText: 'End Location Latitude'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _endLocationLngController,
            decoration: const InputDecoration(labelText: 'End Location Longitude'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _metricsController,
            decoration: const InputDecoration(labelText: 'Metrics (JSON)'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(
              'Route Date: ${_selectedDate?.toLocal().toString().split(' ')[0] ?? 'Not set'}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: _submit, child: const Text('Save Route')),
        ],
      ),
    );
  }
}
