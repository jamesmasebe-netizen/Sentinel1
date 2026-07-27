import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_models.dart';
import '../services/crm_service.dart';
import '../../people/widgets/employee_selector.dart';

class OpportunityForm extends ConsumerStatefulWidget {
  final Opportunity? opportunity;

  const OpportunityForm({super.key, this.opportunity});

  @override
  ConsumerState<OpportunityForm> createState() => _OpportunityFormState();
}

class _OpportunityFormState extends ConsumerState<OpportunityForm> {
  final _formKey = GlobalKey<FormState>();

  late String name;
  late String accountId;
  late String primaryContactId;
  late String stage;
  late double amount;
  late double probability;
  DateTime? expectedCloseDate;
  late String forecastCategory;
  late String leadSource;
  late String nextStep;
  late String ownerId;
  String? lossReason;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final opp = widget.opportunity;
    name = opp?.name ?? '';
    accountId = opp?.accountId ?? '';
    primaryContactId = opp?.primaryContactId ?? '';
    stage = opp?.stage ?? 'Prospecting';
    amount = opp?.amount ?? 0.0;
    probability = opp?.probability ?? 0.0;
    expectedCloseDate = opp?.expectedCloseDate;
    forecastCategory = opp?.forecastCategory ?? 'Pipeline';
    leadSource = opp?.leadSource ?? '';
    nextStep = opp?.nextStep ?? '';
    ownerId = opp?.ownerId ?? '';
    lossReason = opp?.lossReason;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(crmServiceProvider);
      final opp = Opportunity(
        id: widget.opportunity?.id ?? '',
        name: name,
        accountId: accountId,
        primaryContactId: primaryContactId,
        stage: stage,
        amount: amount,
        probability: probability,
        expectedCloseDate: expectedCloseDate,
        forecastCategory: forecastCategory,
        leadSource: leadSource,
        nextStep: nextStep,
        ownerId: ownerId,
        lossReason: lossReason,
        createdAt: widget.opportunity?.createdAt,
      );

      if (widget.opportunity == null) {
        await service.createOpportunity(opp);
      } else {
        await service.updateOpportunity(opp);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opportunity saved successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving opportunity: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.opportunity == null ? 'New Opportunity' : 'Edit Opportunity',
        ),
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
                labelText: 'Opportunity Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business_center),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              onSaved: (v) => name = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: amount.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onSaved: (v) => amount = double.tryParse(v ?? '') ?? 0.0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: probability.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Probability (%)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.percent),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onSaved:
                        (v) => probability = double.tryParse(v ?? '') ?? 0.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: stage,
              decoration: const InputDecoration(
                labelText: 'Stage',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              items:
                  const [
                        'Prospecting',
                        'Qualification',
                        'Needs Analysis',
                        'Value Proposition',
                        'Id. Decision Makers',
                        'Perception Analysis',
                        'Proposal/Price Quote',
                        'Negotiation/Review',
                        'Closed Won',
                        'Closed Lost',
                      ]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
              onChanged: (v) => setState(() => stage = v!),
              onSaved: (v) => stage = v ?? 'Prospecting',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: accountId,
              decoration: const InputDecoration(
                labelText: 'Account ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
              onSaved: (v) => accountId = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: primaryContactId,
              decoration: const InputDecoration(
                labelText: 'Primary Contact ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              onSaved: (v) => primaryContactId = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: forecastCategory,
              decoration: const InputDecoration(
                labelText: 'Forecast Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.trending_up),
              ),
              items:
                  const ['Pipeline', 'Best Case', 'Commit', 'Omitted', 'Closed']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
              onChanged: (v) => setState(() => forecastCategory = v!),
              onSaved: (v) => forecastCategory = v ?? 'Pipeline',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: leadSource,
              decoration: const InputDecoration(
                labelText: 'Lead Source',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.source),
              ),
              onSaved: (v) => leadSource = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: nextStep,
              decoration: const InputDecoration(
                labelText: 'Next Step',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.next_plan),
              ),
              onSaved: (v) => nextStep = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            EmployeeSelector(
              value: ownerId.isEmpty ? null : ownerId,
              label: 'Owner',
              onChanged: (v) => setState(() => ownerId = v ?? ''),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              title: const Text('Expected Close Date'),
              subtitle: Text(
                expectedCloseDate?.toLocal().toString().split(' ')[0] ??
                    'Select Date',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: expectedCloseDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() => expectedCloseDate = date);
                }
              },
            ),
            const SizedBox(height: 16),
            if (stage == 'Closed Lost')
              TextFormField(
                initialValue: lossReason,
                decoration: const InputDecoration(
                  labelText: 'Loss Reason',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning),
                ),
                onSaved: (v) => lossReason = v?.trim(),
              ),
          ],
        ),
      ),
    );
  }
}
