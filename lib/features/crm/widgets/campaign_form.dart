import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_models.dart';
import '../services/crm_service.dart';
import '../../people/widgets/employee_selector.dart';
import '../../../core/utils/ui_utils.dart';

class CampaignForm extends ConsumerStatefulWidget {
  final Campaign? campaign;

  const CampaignForm({super.key, this.campaign});

  @override
  ConsumerState<CampaignForm> createState() => _CampaignFormState();
}

class _CampaignFormState extends ConsumerState<CampaignForm> {
  final _formKey = GlobalKey<FormState>();

  static const _types = [
    'Email',
    'Social Media',
    'Webinar',
    'Trade Show',
    'Direct Mail',
    'Other',
  ];
  static const _statuses = ['Planning', 'Active', 'Completed', 'Cancelled'];

  late String name;
  late String type;
  late String status;
  DateTime? startDate;
  DateTime? endDate;
  late double budget;
  late double actualSpend;
  late String targetAudience;
  late double expectedRevenue;
  late double actualRevenue;
  late String ownerId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.campaign;
    name = c?.name ?? '';
    type = c?.type ?? _types.first;
    status = c?.status ?? _statuses.first;
    startDate = c?.startDate;
    endDate = c?.endDate;
    budget = c?.budget ?? 0.0;
    actualSpend = c?.actualSpend ?? 0.0;
    targetAudience = c?.targetAudience ?? '';
    expectedRevenue = c?.expectedRevenue ?? 0.0;
    actualRevenue = c?.actualRevenue ?? 0.0;
    ownerId = c?.ownerId ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final service = ref.read(crmServiceProvider);
      final campaign = Campaign(
        id: widget.campaign?.id ?? '',
        name: name,
        type: type,
        status: status,
        startDate: startDate,
        endDate: endDate,
        budget: budget,
        actualSpend: actualSpend,
        targetAudience: targetAudience,
        expectedRevenue: expectedRevenue,
        actualRevenue: actualRevenue,
        ownerId: ownerId,
        createdAt: widget.campaign?.createdAt,
      );

      if (widget.campaign == null) {
        await service.createCampaign(campaign);
      } else {
        await service.updateCampaign(campaign);
      }

      if (mounted) {
        UIUtils.showToast(context, 'Campaign saved successfully', type: ToastType.success);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error saving campaign: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: (isStart ? startDate : endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          startDate = date;
        } else {
          endDate = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.campaign == null ? 'New Campaign' : 'Edit Campaign'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: name,
              decoration: const InputDecoration(
                labelText: 'Campaign Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.campaign),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              onSaved: (v) => name = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => type = v ?? type),
                    onSaved: (v) => type = v ?? type,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => status = v ?? status),
                    onSaved: (v) => status = v ?? status,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    title: const Text('Start Date'),
                    subtitle: Text(
                      startDate?.toLocal().toString().split(' ')[0] ?? 'Select Date',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    title: const Text('End Date'),
                    subtitle: Text(
                      endDate?.toLocal().toString().split(' ')[0] ?? 'Select Date',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: budget.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Budget',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onSaved: (v) => budget = double.tryParse(v ?? '') ?? 0.0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: actualSpend.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Actual Spend',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money_off),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onSaved: (v) => actualSpend = double.tryParse(v ?? '') ?? 0.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: expectedRevenue.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Expected Revenue',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.trending_up),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onSaved: (v) => expectedRevenue = double.tryParse(v ?? '') ?? 0.0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: actualRevenue.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Actual Revenue',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.paid),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onSaved: (v) => actualRevenue = double.tryParse(v ?? '') ?? 0.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: targetAudience,
              decoration: const InputDecoration(
                labelText: 'Target Audience',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.groups),
              ),
              onSaved: (v) => targetAudience = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            EmployeeSelector(
              value: ownerId.isEmpty ? null : ownerId,
              label: 'Owner',
              onChanged: (v) => setState(() => ownerId = v ?? ''),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }
}
