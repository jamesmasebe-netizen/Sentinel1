import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/scm_models.dart';
import '../services/scm_service.dart';
import '../providers/scm_streams_provider.dart';
import '../../../core/widgets/entity_selector.dart';
import '../../../core/utils/ui_utils.dart';

class ProductionOrderForm extends ConsumerStatefulWidget {
  final ProductionOrder? initialData;
  final String? initialItemId;
  final double? initialTargetQuantity;
  final VoidCallback? onSuccess;

  const ProductionOrderForm({
    super.key,
    this.initialData,
    this.initialItemId,
    this.initialTargetQuantity,
    this.onSuccess,
  });

  @override
  ConsumerState<ProductionOrderForm> createState() => _ProductionOrderFormState();
}

class _ProductionOrderFormState extends ConsumerState<ProductionOrderForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _orderNumberController;
  late TextEditingController _bomRefController;
  late TextEditingController _targetQuantityController;

  String? _itemId;
  String? _warehouseId;
  String _status = 'PLANNED';
  DateTime? _plannedStartDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final order = widget.initialData;
    _orderNumberController = TextEditingController(text: order?.orderNumber ?? '');
    _bomRefController = TextEditingController(text: order?.bomRef ?? '');
    _targetQuantityController = TextEditingController(
      text: (order?.targetQuantity ?? widget.initialTargetQuantity ?? 0.0).toString(),
    );
    _itemId = order?.itemId ?? widget.initialItemId;
    _warehouseId = order?.warehouseId;
    _status = order?.status ?? 'PLANNED';
    _plannedStartDate = order?.plannedStartDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _bomRefController.dispose();
    _targetQuantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final order = ProductionOrder(
        id: widget.initialData?.id ?? const Uuid().v4(),
        orderNumber: _orderNumberController.text,
        itemId: _itemId,
        bomRef: _bomRefController.text.trim().isEmpty ? null : _bomRefController.text.trim(),
        targetQuantity: double.tryParse(_targetQuantityController.text) ?? 0.0,
        completedQuantity: widget.initialData?.completedQuantity ?? 0.0,
        status: _status,
        warehouseId: _warehouseId,
        plannedStartDate: _plannedStartDate,
        completedAt: widget.initialData?.completedAt,
        createdAt: widget.initialData?.createdAt,
      );

      final service = ref.read(scmServiceProvider);
      if (widget.initialData == null) {
        await service.createProductionOrder(order);
      } else {
        await service.updateProductionOrder(order);
      }

      if (mounted) {
        UIUtils.showToast(context, 'Production Order saved successfully', type: ToastType.success);
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error saving Production Order: $e', type: ToastType.error);
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
          TextFormField(
            controller: _orderNumberController,
            decoration: const InputDecoration(
              labelText: 'Order Number',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          EntitySelector<InventoryItem>(
            label: 'Item to Produce',
            value: _itemId,
            asyncEntities: ref.watch(inventoryItemsListStreamProvider),
            idMapper: (i) => i.id,
            displayMapper: (i) => '${i.sku} - ${i.name}',
            onChanged: (v) => setState(() => _itemId = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bomRefController,
            decoration: const InputDecoration(
              labelText: 'BOM Reference',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _targetQuantityController,
                  decoration: const InputDecoration(
                    labelText: 'Target Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      double.tryParse(v ?? '') == null || double.parse(v!) <= 0 ? 'Required, > 0' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const ['PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v ?? _status),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          EntitySelector<Warehouse>(
            label: 'Warehouse',
            value: _warehouseId,
            asyncEntities: ref.watch(warehousesStreamProvider),
            idMapper: (w) => w.id,
            displayMapper: (w) => w.name,
            onChanged: (v) => setState(() => _warehouseId = v),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            title: const Text('Planned Start Date'),
            subtitle: Text(
              _plannedStartDate?.toLocal().toString().split(' ')[0] ?? 'Select Date',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _plannedStartDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                setState(() => _plannedStartDate = date);
              }
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Production Order'),
            ),
          ),
        ],
      ),
    );
  }
}
