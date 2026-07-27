import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/scm_models.dart';
import '../services/scm_service.dart';

class TransferOrderForm extends ConsumerStatefulWidget {
  final TransferOrder? initialData;
  final VoidCallback? onSuccess;

  const TransferOrderForm({super.key, this.initialData, this.onSuccess});

  @override
  ConsumerState<TransferOrderForm> createState() => _TransferOrderFormState();
}

class _TransferOrderFormState extends ConsumerState<TransferOrderForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _orderNumberController;
  late TextEditingController _sourceLocationController;
  late TextEditingController _destinationLocationController;

  String _status = 'Pending';
  DateTime? _orderDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _orderNumberController = TextEditingController(
      text: data?.orderNumber ?? const Uuid().v4().substring(0, 8),
    );
    _sourceLocationController = TextEditingController(
      text: data?.sourceLocation ?? '',
    );
    _destinationLocationController = TextEditingController(
      text: data?.destinationLocation ?? '',
    );
    _status = data?.status ?? 'Pending';
    _orderDate = data?.orderDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _sourceLocationController.dispose();
    _destinationLocationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final to = TransferOrder(
        id: widget.initialData?.id ?? const Uuid().v4(),
        orderNumber: _orderNumberController.text,
        sourceLocation: _sourceLocationController.text,
        destinationLocation: _destinationLocationController.text,
        status: _status,
        orderDate: _orderDate,
      );

      final service = ref.read(scmServiceProvider);
      if (widget.initialData == null) {
        await service.createTransferOrder(to);
      } else {
        await service.updateTransferOrder(to);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer Order saved successfully')),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving Transfer Order: $e')),
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
            controller: _orderNumberController,
            decoration: const InputDecoration(
              labelText: 'Order Number',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sourceLocationController,
            decoration: const InputDecoration(
              labelText: 'Source Location',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _destinationLocationController,
            decoration: const InputDecoration(
              labelText: 'Destination Location',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items:
                ['Pending', 'In Transit', 'Completed', 'Cancelled']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
            onChanged: (val) => setState(() => _status = val ?? 'Pending'),
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
                      : const Text('Save Transfer Order'),
            ),
          ),
        ],
      ),
    );
  }
}

