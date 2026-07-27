import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_models.dart';
import '../services/crm_service.dart';
import '../../people/widgets/employee_selector.dart';

class LeadForm extends ConsumerStatefulWidget {
  final Lead? lead;

  const LeadForm({super.key, this.lead});

  @override
  ConsumerState<LeadForm> createState() => _LeadFormState();
}

class _LeadFormState extends ConsumerState<LeadForm> {
  final _formKey = GlobalKey<FormState>();

  late String firstName;
  late String lastName;
  late String company;
  late String email;
  late String phone;
  late String leadSource;
  late String status;
  late String rating;
  late double aiLeadScore;
  String? sequenceId;
  late String ownerId;
  late bool isConverted;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    firstName = l?.firstName ?? '';
    lastName = l?.lastName ?? '';
    company = l?.company ?? '';
    email = l?.email ?? '';
    phone = l?.phone ?? '';
    leadSource = l?.leadSource ?? '';
    status = l?.status ?? 'New';
    rating = l?.rating ?? 'Cold';
    aiLeadScore = l?.aiLeadScore ?? 0.0;
    sequenceId = l?.sequenceId ?? '';
    ownerId = l?.ownerId ?? '';
    isConverted = l?.isConverted ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(crmServiceProvider);
      final newLead = Lead(
        id: widget.lead?.id ?? '',
        firstName: firstName,
        lastName: lastName,
        company: company,
        email: email,
        phone: phone,
        leadSource: leadSource,
        status: status,
        rating: rating,
        aiLeadScore: aiLeadScore,
        sequenceId: sequenceId,
        ownerId: ownerId,
        isConverted: isConverted,
        convertedAccountId: widget.lead?.convertedAccountId,
        convertedContactId: widget.lead?.convertedContactId,
        convertedOpportunityId: widget.lead?.convertedOpportunityId,
        createdAt: widget.lead?.createdAt,
      );

      if (widget.lead == null) {
        await service.createLead(newLead);
      } else {
        await service.updateLead(newLead);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead saved successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving lead: $e')));
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
        title: Text(widget.lead == null ? 'New Lead' : 'Edit Lead'),
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: firstName,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => firstName = v?.trim() ?? '',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: lastName,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => lastName = v?.trim() ?? '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: company,
              decoration: const InputDecoration(
                labelText: 'Company',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              onSaved: (v) => company = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              onSaved: (v) => email = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              onSaved: (v) => phone = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              items:
                  const ['New', 'Contacted', 'Qualified', 'Unqualified']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
              onChanged: (v) => setState(() => status = v!),
              onSaved: (v) => status = v ?? 'New',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: rating,
              decoration: const InputDecoration(
                labelText: 'Rating',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star),
              ),
              items:
                  const ['Hot', 'Warm', 'Cold']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
              onChanged: (v) => setState(() => rating = v!),
              onSaved: (v) => rating = v ?? 'Cold',
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
              initialValue: aiLeadScore.toString(),
              decoration: const InputDecoration(
                labelText: 'AI Lead Score',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.analytics),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onSaved: (v) => aiLeadScore = double.tryParse(v ?? '') ?? 0.0,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: sequenceId,
              decoration: const InputDecoration(
                labelText: 'Sequence ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
              onSaved: (v) => sequenceId = v?.trim(),
            ),
            const SizedBox(height: 16),
            EmployeeSelector(
              value: ownerId.isEmpty ? null : ownerId,
              label: 'Owner',
              onChanged: (v) => setState(() => ownerId = v ?? ''),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Is Converted?'),
              value: isConverted,
              onChanged: (val) => setState(() => isConverted = val),
              secondary: const Icon(Icons.transform),
            ),
          ],
        ),
      ),
    );
  }
}
