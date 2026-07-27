import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/scm_models.dart';
import '../services/scm_service.dart';

class InventoryItemForm extends ConsumerStatefulWidget {
  final InventoryItem? initialData;
  final VoidCallback? onSuccess;

  const InventoryItemForm({super.key, this.initialData, this.onSuccess});

  @override
  ConsumerState<InventoryItemForm> createState() => _InventoryItemFormState();
}

class _InventoryItemFormState extends ConsumerState<InventoryItemForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _skuController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _itemTypeController;
  late TextEditingController _unitOfMeasureController;
  late TextEditingController _valuationMethodController;
  late TextEditingController _leadTimeDaysController;
  late TextEditingController _safetyStockController;
  late TextEditingController _reorderPointController;
  late TextEditingController _weightValueController;
  late TextEditingController _weightUnitController;
  late TextEditingController _dimLengthController;
  late TextEditingController _dimWidthController;
  late TextEditingController _dimHeightController;
  late TextEditingController _dimUnitController;
  late TextEditingController _costAmountController;
  late TextEditingController _costCurrencyController;
  late TextEditingController _stockLevelController;

  bool _isConfigurable = false;
  bool _isActive = true;
  String _lifecycleStatus = 'Active';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialData;
    _skuController = TextEditingController(text: item?.sku ?? '');
    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _itemTypeController = TextEditingController(text: item?.itemType ?? '');
    _unitOfMeasureController = TextEditingController(
      text: item?.unitOfMeasure ?? 'pcs',
    );
    _valuationMethodController = TextEditingController(
      text: item?.valuationMethod ?? 'FIFO',
    );
    _leadTimeDaysController = TextEditingController(
      text: item?.leadTimeDays.toString() ?? '0',
    );
    _safetyStockController = TextEditingController(
      text: item?.safetyStock.toString() ?? '0.0',
    );
    _reorderPointController = TextEditingController(
      text: item?.reorderPoint.toString() ?? '0.0',
    );
    _weightValueController = TextEditingController(
      text: item?.weight?['value']?.toString() ?? '',
    );
    _weightUnitController = TextEditingController(
      text: item?.weight?['unit']?.toString() ?? '',
    );
    _dimLengthController = TextEditingController(
      text: item?.dimensions?['length']?.toString() ?? '',
    );
    _dimWidthController = TextEditingController(
      text: item?.dimensions?['width']?.toString() ?? '',
    );
    _dimHeightController = TextEditingController(
      text: item?.dimensions?['height']?.toString() ?? '',
    );
    _dimUnitController = TextEditingController(
      text: item?.dimensions?['unit']?.toString() ?? '',
    );
    _costAmountController = TextEditingController(
      text: item?.standardCost?['amount']?.toString() ?? '',
    );
    _costCurrencyController = TextEditingController(
      text: item?.standardCost?['currency']?.toString() ?? 'USD',
    );
    _stockLevelController = TextEditingController(
      text: item?.stockLevel.toString() ?? '0.0',
    );

    if (item != null) {
      _isConfigurable = item.isConfigurable;
      _isActive = item.isActive;
      _lifecycleStatus = item.lifecycleStatus;
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _itemTypeController.dispose();
    _unitOfMeasureController.dispose();
    _valuationMethodController.dispose();
    _leadTimeDaysController.dispose();
    _safetyStockController.dispose();
    _reorderPointController.dispose();
    _weightValueController.dispose();
    _weightUnitController.dispose();
    _dimLengthController.dispose();
    _dimWidthController.dispose();
    _dimHeightController.dispose();
    _dimUnitController.dispose();
    _costAmountController.dispose();
    _costCurrencyController.dispose();
    _stockLevelController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final item = InventoryItem(
        id: widget.initialData?.id ?? const Uuid().v4(),
        sku: _skuController.text,
        name: _nameController.text,
        description: _descriptionController.text,
        itemType: _itemTypeController.text,
        unitOfMeasure: _unitOfMeasureController.text,
        valuationMethod: _valuationMethodController.text,
        leadTimeDays: int.tryParse(_leadTimeDaysController.text) ?? 0,
        safetyStock: double.tryParse(_safetyStockController.text) ?? 0.0,
        reorderPoint: double.tryParse(_reorderPointController.text) ?? 0.0,
        weight: {
          'value': double.tryParse(_weightValueController.text),
          'unit': _weightUnitController.text,
        },
        dimensions: {
          'length': double.tryParse(_dimLengthController.text),
          'width': double.tryParse(_dimWidthController.text),
          'height': double.tryParse(_dimHeightController.text),
          'unit': _dimUnitController.text,
        },
        standardCost: {
          'amount': double.tryParse(_costAmountController.text),
          'currency': _costCurrencyController.text,
        },
        stockLevel: double.tryParse(_stockLevelController.text) ?? 0.0,
        isConfigurable: _isConfigurable,
        isActive: _isActive,
        lifecycleStatus: _lifecycleStatus,
        createdAt: widget.initialData?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final service = ref.read(scmServiceProvider);
      if (widget.initialData == null) {
        await service.createInventoryItem(item);
      } else {
        await service.updateInventoryItem(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventory Item saved successfully')),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving Inventory Item: $e')),
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
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _itemTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Item Type',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _unitOfMeasureController,
                  decoration: const InputDecoration(
                    labelText: 'Unit Of Measure',
                    border: OutlineInputBorder(),
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
                  controller: _stockLevelController,
                  decoration: const InputDecoration(
                    labelText: 'Current Stock Level',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _valuationMethodController,
                  decoration: const InputDecoration(
                    labelText: 'Valuation Method',
                    border: OutlineInputBorder(),
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
                  controller: _leadTimeDaysController,
                  decoration: const InputDecoration(
                    labelText: 'Lead Time (Days)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _safetyStockController,
                  decoration: const InputDecoration(
                    labelText: 'Safety Stock',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _reorderPointController,
                  decoration: const InputDecoration(
                    labelText: 'Reorder Point',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
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
                  controller: _weightValueController,
                  decoration: const InputDecoration(
                    labelText: 'Weight Value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _weightUnitController,
                  decoration: const InputDecoration(
                    labelText: 'Weight Unit',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Dimensions', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dimLengthController,
                  decoration: const InputDecoration(
                    labelText: 'Length',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _dimWidthController,
                  decoration: const InputDecoration(
                    labelText: 'Width',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _dimHeightController,
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _dimUnitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
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
                  controller: _costAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Standard Cost Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _costCurrencyController,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _lifecycleStatus,
            decoration: const InputDecoration(
              labelText: 'Lifecycle Status',
              border: OutlineInputBorder(),
            ),
            items:
                ['Active', 'Discontinued', 'In Development']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
            onChanged:
                (val) => setState(() => _lifecycleStatus = val ?? 'Active'),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Is Active'),
            value: _isActive,
            onChanged: (val) => setState(() => _isActive = val),
          ),
          SwitchListTile(
            title: const Text('Is Configurable'),
            value: _isConfigurable,
            onChanged: (val) => setState(() => _isConfigurable = val),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Save Inventory Item'),
            ),
          ),
        ],
      ),
    );
  }
}
