import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/tenant_firestore_extension.dart';
import '../models/property_models.dart';
import '../../people/widgets/employee_selector.dart';

class PropertyFormSheet extends ConsumerStatefulWidget {
  final Property? property;

  const PropertyFormSheet({super.key, this.property});

  @override
  ConsumerState<PropertyFormSheet> createState() => _PropertyFormSheetState();
}

class _PropertyFormSheetState extends ConsumerState<PropertyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _addressController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _totalAreaController;
  late TextEditingController _floorsController;
  late TextEditingController _occupancyController;
  late TextEditingController _capacityController;
  late TextEditingController _statusController;
  late TextEditingController _complianceScoreController;
  late TextEditingController _totalAssetsController;
  
  DateTime? _constructionDate;
  String? _managerId;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _nameController = TextEditingController(text: p?.name ?? '');
    _typeController = TextEditingController(text: p?.type ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _latController = TextEditingController(text: p?.lat.toString() ?? '');
    _lngController = TextEditingController(text: p?.lng.toString() ?? '');
    _totalAreaController = TextEditingController(text: p?.totalArea ?? '');
    _floorsController = TextEditingController(text: p?.floors.toString() ?? '');
    _occupancyController = TextEditingController(text: p?.occupancy.toString() ?? '');
    _capacityController = TextEditingController(text: p?.capacity.toString() ?? '');
    _statusController = TextEditingController(text: p?.status ?? '');
    _complianceScoreController = TextEditingController(text: p?.complianceScore.toString() ?? '');
    _totalAssetsController = TextEditingController(text: p?.totalAssets.toString() ?? '');
    
    _constructionDate = p?.constructionDate ?? DateTime.now();
    _managerId = p?.managerId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _totalAreaController.dispose();
    _floorsController.dispose();
    _occupancyController.dispose();
    _capacityController.dispose();
    _statusController.dispose();
    _complianceScoreController.dispose();
    _totalAssetsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final firestore = ref.read(firestoreProvider);
    final tenantId = ref.read(currentTenantIdProvider) ?? '';
    
    final data = {
      'siteId': tenantId,
      'name': _nameController.text.trim(),
      'type': _typeController.text.trim(),
      'address': _addressController.text.trim(),
      'lat': double.tryParse(_latController.text.trim()) ?? 0.0,
      'lng': double.tryParse(_lngController.text.trim()) ?? 0.0,
      'totalArea': _totalAreaController.text.trim(),
      'floors': int.tryParse(_floorsController.text.trim()) ?? 0,
      'occupancy': int.tryParse(_occupancyController.text.trim()) ?? 0,
      'capacity': int.tryParse(_capacityController.text.trim()) ?? 0,
      'status': _statusController.text.trim(),
      'constructionDate': _constructionDate?.toIso8601String(),
      'manager': _managerId ?? '',
      'complianceScore': double.tryParse(_complianceScoreController.text.trim()) ?? 0.0,
      'totalAssets': int.tryParse(_totalAssetsController.text.trim()) ?? 0,
    };

    if (widget.property == null) {
      await firestore.tenantCollection(tenantId, 'properties').add(data);
    } else {
      await firestore.tenantCollection(tenantId, 'properties').doc(widget.property!.id).update(data);
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.property == null ? 'Add Property' : 'Edit Property',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalAreaController,
                decoration: const InputDecoration(labelText: 'Total Area'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _floorsController,
                      decoration: const InputDecoration(labelText: 'Floors'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _occupancyController,
                      decoration: const InputDecoration(labelText: 'Occupancy'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(labelText: 'Capacity'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _complianceScoreController,
                      decoration: const InputDecoration(labelText: 'Compliance Score'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _totalAssetsController,
                      decoration: const InputDecoration(labelText: 'Total Assets'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              EmployeeSelector(
                label: 'Property Manager',
                value: _managerId,
                onChanged: (val) {
                  setState(() {
                    _managerId = val;
                  });
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
