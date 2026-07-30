import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scm_models.dart';
import '../services/scm_service.dart';
import '../../../core/utils/ui_utils.dart';

class PurchaseOrderLineForm extends ConsumerStatefulWidget {
  final String poId;
  const PurchaseOrderLineForm({Key? key, required this.poId}) : super(key: key);

  @override
  ConsumerState<PurchaseOrderLineForm> createState() =>
      _PurchaseOrderLineFormState();
}

class _PurchaseOrderLineFormState extends ConsumerState<PurchaseOrderLineForm> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  
  List<InventoryItem> _inventoryItems = [];
  String? _selectedItemId;
  
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }
  
  Future<void> _fetchInventory() async {
    try {
      final items = await ref.read(scmServiceProvider).getInventoryItems();
      if (mounted) {
        setState(() {
          _inventoryItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIUtils.showToast(context, 'Failed to load items: $e', type: ToastType.error);
      }
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedItemId == null) {
      UIUtils.showToast(context, 'Please select an item', type: ToastType.warning);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final qty = double.tryParse(_qtyCtrl.text) ?? 0.0;
      final price = double.tryParse(_priceCtrl.text) ?? 0.0;
      
      final line = PurchaseOrderLine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemId: _selectedItemId,
        quantityOrdered: qty,
        quantityReceived: 0,
        unitPrice: price,
      );

      await ref.read(scmServiceProvider).createPurchaseOrderLine(widget.poId, line);
      
      if (mounted) {
        UIUtils.showToast(context, 'PO Line added successfully', type: ToastType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add PO Line'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Item',
                border: OutlineInputBorder(),
              ),
              value: _selectedItemId,
              items: _inventoryItems.map((item) {
                return DropdownMenuItem(
                  value: item.id,
                  child: Text('${item.name} (${item.sku})'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedItemId = val);
              },
              validator: (val) => val == null ? 'Item is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _qtyCtrl,
              decoration: const InputDecoration(
                labelText: 'Quantity Ordered',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                if (double.tryParse(val) == null) return 'Must be a number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Unit Price',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                if (double.tryParse(val) == null) return 'Must be a number';
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Line Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
