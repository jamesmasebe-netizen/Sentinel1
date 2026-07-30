import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/scm_models.dart';
import '../services/scm_service.dart';
import '../../../core/bpf/bpf_orchestrator.dart';
import '../../crm/providers/crm_providers.dart';
import '../../crm/models/crm_models.dart';
import '../../../core/widgets/entity_selector.dart';

class PurchaseOrderForm extends ConsumerStatefulWidget {
  final PurchaseOrder? initialData;
  final VoidCallback? onSuccess;

  const PurchaseOrderForm({super.key, this.initialData, this.onSuccess});

  @override
  ConsumerState<PurchaseOrderForm> createState() => _PurchaseOrderFormState();
}

class _PurchaseOrderFormState extends ConsumerState<PurchaseOrderForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _poNumberController;
  late TextEditingController _vendorIdController;
  late TextEditingController _warehouseIdController;
  late TextEditingController _currencyController;
  late TextEditingController _totalAmountController;

  String _status = 'Draft';
  DateTime? _orderDate;
  DateTime? _expectedDeliveryDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _poNumberController = TextEditingController(
      text: widget.initialData?.poNumber ?? '',
    );
    _vendorIdController = TextEditingController(
      text: widget.initialData?.vendorId ?? '',
    );
    _warehouseIdController = TextEditingController(
      text: widget.initialData?.warehouseId ?? '',
    );
    _currencyController = TextEditingController(
      text: widget.initialData?.currency ?? 'USD',
    );
    _totalAmountController = TextEditingController(
      text: widget.initialData?.totalAmount.toString() ?? '0.0',
    );
    _status = widget.initialData?.status ?? 'Draft';
    _orderDate = widget.initialData?.orderDate ?? DateTime.now();
    _expectedDeliveryDate = widget.initialData?.expectedDeliveryDate;
  }

  @override
  void dispose() {
    _poNumberController.dispose();
    _vendorIdController.dispose();
    _warehouseIdController.dispose();
    _currencyController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final po = PurchaseOrder(
        id: widget.initialData?.id ?? const Uuid().v4(),
        poNumber: _poNumberController.text,
        vendorId:
            _vendorIdController.text.isNotEmpty
                ? _vendorIdController.text
                : null,
        warehouseId:
            _warehouseIdController.text.isNotEmpty
                ? _warehouseIdController.text
                : null,
        status: _status,
        orderDate: _orderDate,
        expectedDeliveryDate: _expectedDeliveryDate,
        currency: _currencyController.text,
        totalAmount: double.tryParse(_totalAmountController.text) ?? 0.0,
      );

      final service = ref.read(scmServiceProvider);
      final orchestrator = ref.read(bpfOrchestratorProvider);
      
      if (widget.initialData == null) {
        await orchestrator.createPurchaseOrder(po);
      } else {
        if (po.status == 'Received' && widget.initialData!.status != 'Received') {
          await orchestrator.receivePurchaseOrderGoods(po);
        } else {
          await service.updatePurchaseOrder(po);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase Order saved successfully')),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving Purchase Order: $e')),
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
          TextFormField(
            controller: _poNumberController,
            decoration: const InputDecoration(
              labelText: 'PO Number',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          EntitySelector<Account>(
            value: _vendorIdController.text.isEmpty ? null : _vendorIdController.text,
            onChanged: (val) => setState(() => _vendorIdController.text = val ?? ''),
            label: 'Vendor',
            asyncEntities: ref.watch(accountsStreamProvider),
            idMapper: (a) => a.id,
            displayMapper: (a) => a.name,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _warehouseIdController,
            decoration: const InputDecoration(
              labelText: 'Warehouse ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items:
                ['Draft', 'Sent', 'Received', 'Cancelled']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
            onChanged: (val) => setState(() => _status = val ?? 'Draft'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _currencyController,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _totalAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Total Amount',
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
          ListTile(
            title: const Text('Order Date'),
            subtitle: Text(_orderDate?.toLocal().toString().split(' ')[0] ?? 'Select Date'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _orderDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                setState(() => _orderDate = date);
              }
            },
          ),
          ListTile(
            title: const Text('Expected Delivery Date'),
            subtitle: Text(_expectedDeliveryDate?.toLocal().toString().split(' ')[0] ?? 'Select Date'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _expectedDeliveryDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                setState(() => _expectedDeliveryDate = date);
              }
            },
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
                      : const Text('Save Purchase Order'),
            ),
          ),
        ],
      ),
    );
  }
}
