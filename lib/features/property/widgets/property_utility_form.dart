import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class PropertyUtilityForm extends ConsumerStatefulWidget {
  final String propertyId;
  const PropertyUtilityForm({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyUtilityForm> createState() => _PropertyUtilityFormState();
}

class _PropertyUtilityFormState extends ConsumerState<PropertyUtilityForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _monthController = TextEditingController();
  final _electricityController = TextEditingController();
  final _waterController = TextEditingController();
  final _wasteController = TextEditingController();
  final _carbonController = TextEditingController();

  @override
  void dispose() {
    _monthController.dispose();
    _electricityController.dispose();
    _waterController.dispose();
    _wasteController.dispose();
    _carbonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tenantId = ref.read(currentTenantIdProvider);
      final firestore = ref.read(firestoreProvider);

      await firestore.tenantCollection(tenantId ?? '', 'property_utilities').add({
        'propertyId': widget.propertyId,
        'month': _monthController.text,
        'electricity': double.tryParse(_electricityController.text) ?? 0.0,
        'water': double.tryParse(_waterController.text) ?? 0.0,
        'waste': double.tryParse(_wasteController.text) ?? 0.0,
        'carbon': double.tryParse(_carbonController.text) ?? 0.0,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utility usage added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Utility Usage'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _monthController,
              decoration: const InputDecoration(labelText: 'Month (e.g., Oct 2023)'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _electricityController,
              decoration: const InputDecoration(labelText: 'Electricity (kWh)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _waterController,
              decoration: const InputDecoration(labelText: 'Water (L)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _wasteController,
              decoration: const InputDecoration(labelText: 'Waste (kg)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _carbonController,
              decoration: const InputDecoration(labelText: 'Carbon (tons CO2)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }
}
