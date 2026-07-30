import 'package:flutter/material.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_service_models.dart';
import '../services/customer_service_service.dart';
import '../../../core/widgets/entity_selector.dart';
import '../../people/models/employee.dart';
import '../../people/providers/employee_providers.dart';

class TicketForm extends ConsumerStatefulWidget {
  final Ticket? initialTicket;
  final VoidCallback? onSaved;

  const TicketForm({super.key, this.initialTicket, this.onSaved});

  @override
  ConsumerState<TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends ConsumerState<TicketForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _customerIdController;
  late TextEditingController _contactIdController;
  late TextEditingController _workstreamIdController;
  late TextEditingController _queueIdController;
  late TextEditingController _entitlementIdController;

  String _status = 'New';
  String _priority = 'Medium';
  String _severity = '3';
  String _channel = 'Email';
  bool _isEscalated = false;
  bool _isLoading = false;

  String? _assignedTo;
  String? _assetId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialTicket?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialTicket?.description ?? '',
    );
    _customerIdController = TextEditingController(text: widget.initialTicket?.customerId ?? '');
    _contactIdController = TextEditingController(text: widget.initialTicket?.contactId ?? '');
    _workstreamIdController = TextEditingController(text: widget.initialTicket?.workstreamId ?? '');
    _queueIdController = TextEditingController(text: widget.initialTicket?.queueId ?? '');
    _entitlementIdController = TextEditingController(text: widget.initialTicket?.entitlementId ?? '');

    _status = widget.initialTicket?.status ?? 'New';
    _priority = widget.initialTicket?.priority ?? 'Medium';
    _severity = widget.initialTicket?.severity ?? '3';
    _channel = widget.initialTicket?.channel ?? 'Email';
    _isEscalated = widget.initialTicket?.isEscalated ?? false;
    _assignedTo = widget.initialTicket?.assignedTo;
    _assetId = widget.initialTicket?.assetId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customerIdController.dispose();
    _contactIdController.dispose();
    _workstreamIdController.dispose();
    _queueIdController.dispose();
    _entitlementIdController.dispose();
    super.dispose();
  }

  Future<void> _saveTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final service = ref.read(customerServiceServiceProvider);

      final ticket = Ticket(
        id: widget.initialTicket?.id ?? '',
        ticketId:
            widget.initialTicket?.ticketId ??
            'TKT-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text,
        description: _descriptionController.text,
        status: _status,
        priority: _priority,
        severity: _severity,
        channel: _channel,
        isEscalated: _isEscalated,
        assignedTo: _assignedTo,
        assetId: _assetId,
        customerId: _customerIdController.text.trim().isEmpty ? null : _customerIdController.text.trim(),
        contactId: _contactIdController.text.trim().isEmpty ? null : _contactIdController.text.trim(),
        workstreamId: _workstreamIdController.text.trim().isEmpty ? null : _workstreamIdController.text.trim(),
        queueId: _queueIdController.text.trim().isEmpty ? null : _queueIdController.text.trim(),
        entitlementId: _entitlementIdController.text.trim().isEmpty ? null : _entitlementIdController.text.trim(),
        createdAt: widget.initialTicket?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.initialTicket == null) {
        await service.createTicket(ticket);
      } else {
        await service.updateTicket(ticket);
      }

      if (mounted) {
        UIUtils.showToast(context, 'Ticket saved successfully');
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error saving ticket: $e', type: ToastType.error);
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
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) =>
                    value == null || value.isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items:
                [
                      'New',
                      'In Progress',
                      'Waiting on Customer',
                      'Resolved',
                      'Closed',
                    ]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
            onChanged: (value) => setState(() => _status = value!),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      ['Low', 'Medium', 'High', 'Critical']
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _priority = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _severity,
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      ['1', '2', '3', '4']
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text('Severity $s'),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _severity = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _channel,
            decoration: const InputDecoration(
              labelText: 'Channel',
              border: OutlineInputBorder(),
            ),
            items:
                ['Email', 'Phone', 'Chat', 'Web', 'Social']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
            onChanged: (value) => setState(() => _channel = value!),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Is Escalated'),
            value: _isEscalated,
            onChanged: (value) => setState(() => _isEscalated = value),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          EntitySelector<Employee>(
            asyncEntities: ref.watch(employeesProvider),
            value: _assignedTo,
            onChanged: (val) => setState(() => _assignedTo = val),
            label: 'Assigned To',
            idMapper: (employee) => employee.id,
            displayMapper: (employee) => employee.fullName,
          ),
          const SizedBox(height: 16),
          EntitySelector<CsAsset>(
            asyncEntities: ref.watch(csAssetsProvider),
            value: _assetId,
            onChanged: (val) => setState(() => _assetId = val),
            label: 'Asset',
            idMapper: (asset) => asset.id,
            displayMapper: (asset) => asset.name,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _customerIdController,
            decoration: const InputDecoration(
              labelText: 'Customer ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactIdController,
            decoration: const InputDecoration(
              labelText: 'Contact ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _workstreamIdController,
            decoration: const InputDecoration(
              labelText: 'Workstream ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _queueIdController,
            decoration: const InputDecoration(
              labelText: 'Queue ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _entitlementIdController,
            decoration: const InputDecoration(
              labelText: 'Entitlement ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveTicket,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Save Ticket'),
          ),
        ],
      ),
    );
  }
}
