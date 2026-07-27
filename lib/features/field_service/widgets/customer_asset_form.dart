import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/field_service_models.dart';
import '../services/field_service_service.dart';

class CustomerAssetForm extends ConsumerStatefulWidget {
  final CustomerAsset? initialAsset;

  const CustomerAssetForm({super.key, this.initialAsset});

  @override
  ConsumerState<CustomerAssetForm> createState() => _CustomerAssetFormState();
}

class _CustomerAssetFormState extends ConsumerState<CustomerAssetForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _assetNameController;
  late TextEditingController _customerIdController;
  late TextEditingController _statusController;
  late TextEditingController _iotDeviceIdController;
  late TextEditingController _categoryIdController;
  late TextEditingController _parentAssetIdController;
  late TextEditingController _locationLatController;
  late TextEditingController _locationLngController;
  DateTime? _installationDate;
  DateTime? _warrantyStartDate;
  DateTime? _warrantyEndDate;

  @override
  void initState() {
    super.initState();
    _assetNameController = TextEditingController(
      text: widget.initialAsset?.assetName ?? '',
    );
    _customerIdController = TextEditingController(
      text: widget.initialAsset?.customerId ?? '',
    );
    _statusController = TextEditingController(
      text: widget.initialAsset?.status ?? 'ACTIVE',
    );
    _iotDeviceIdController = TextEditingController(
      text: widget.initialAsset?.iotDeviceId ?? '',
    );
    _categoryIdController = TextEditingController(
      text: widget.initialAsset?.categoryId ?? '',
    );
    _parentAssetIdController = TextEditingController(
      text: widget.initialAsset?.parentAssetId ?? '',
    );
    _locationLatController = TextEditingController(
      text: widget.initialAsset?.location?.latitude.toString() ?? '',
    );
    _locationLngController = TextEditingController(
      text: widget.initialAsset?.location?.longitude.toString() ?? '',
    );
    _installationDate = widget.initialAsset?.installationDate;
    _warrantyStartDate = widget.initialAsset?.warrantyStartDate;
    _warrantyEndDate = widget.initialAsset?.warrantyEndDate;
  }

  @override
  void dispose() {
    _assetNameController.dispose();
    _customerIdController.dispose();
    _statusController.dispose();
    _iotDeviceIdController.dispose();
    _categoryIdController.dispose();
    _parentAssetIdController.dispose();
    _locationLatController.dispose();
    _locationLngController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, DateTime? initialDate, Function(DateTime) onSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        onSelected(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final service = ref.read(fieldServiceServiceProvider);

      final asset = CustomerAsset(
        id:
            widget.initialAsset?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        assetName: _assetNameController.text,
        customerId: _customerIdController.text,
        status: _statusController.text,
        categoryId: _categoryIdController.text.isNotEmpty ? _categoryIdController.text : null,
        parentAssetId: _parentAssetIdController.text.isNotEmpty ? _parentAssetIdController.text : null,
        location: _locationLatController.text.isNotEmpty && _locationLngController.text.isNotEmpty
            ? GeoPoint(double.parse(_locationLatController.text), double.parse(_locationLngController.text))
            : null,
        installationDate: _installationDate,
        warrantyStartDate: _warrantyStartDate,
        warrantyEndDate: _warrantyEndDate,
        iotDeviceId:
            _iotDeviceIdController.text.isNotEmpty
                ? _iotDeviceIdController.text
                : null,
        createdAt: widget.initialAsset?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        if (widget.initialAsset == null) {
          await service.createCustomerAsset(asset);
        } else {
          await service.updateCustomerAsset(asset);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asset saved successfully')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving asset: $e')));
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
            controller: _assetNameController,
            decoration: const InputDecoration(labelText: 'Asset Name'),
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
            controller: _statusController,
            decoration: const InputDecoration(labelText: 'Status'),
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _iotDeviceIdController,
            decoration: const InputDecoration(
              labelText: 'IoT Device ID (optional)',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _categoryIdController,
            decoration: const InputDecoration(labelText: 'Category ID'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _parentAssetIdController,
            decoration: const InputDecoration(labelText: 'Parent Asset ID'),
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
          ListTile(
            title: Text('Installation Date: ${_installationDate?.toLocal().toString().split(' ')[0] ?? 'Not set'}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context, _installationDate, (date) => _installationDate = date),
          ),
          ListTile(
            title: Text('Warranty Start Date: ${_warrantyStartDate?.toLocal().toString().split(' ')[0] ?? 'Not set'}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context, _warrantyStartDate, (date) => _warrantyStartDate = date),
          ),
          ListTile(
            title: Text('Warranty End Date: ${_warrantyEndDate?.toLocal().toString().split(' ')[0] ?? 'Not set'}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context, _warrantyEndDate, (date) => _warrantyEndDate = date),
          ),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: _submit, child: const Text('Save Asset')),
        ],
      ),
    );
  }
}
