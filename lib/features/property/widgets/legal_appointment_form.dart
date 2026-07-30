import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import 'package:sentinel1/features/people/widgets/employee_selector.dart';
import 'package:sentinel1/features/people/providers/hr_providers.dart';
import 'package:sentinel1/features/people/services/hr_service.dart';

class LegalAppointmentForm extends ConsumerStatefulWidget {
  final String propertyId;
  const LegalAppointmentForm({super.key, required this.propertyId});

  @override
  ConsumerState<LegalAppointmentForm> createState() => _LegalAppointmentFormState();
}

class _LegalAppointmentFormState extends ConsumerState<LegalAppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _roleId;
  String? _roleTitle;
  String? _personId;
  String? _personName; // Optional optimization to store name
  String _status = 'Appointed';
  DateTime? _expiry = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
    // Ensure basic roles exist on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hrServiceProvider).seedOhsRolesIfEmpty();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roleTitle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }
    if (_personId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a person')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tenantId = ref.read(currentTenantIdProvider);
      final firestore = ref.read(firestoreProvider);

      await firestore.tenantCollection(tenantId ?? '', 'legal_appointments').add({
        'propertyId': widget.propertyId,
        'role': _roleTitle, // Store title since the UI depends on 'role' as a string
        'personName': _personId, // Follows property_facility_tab.dart display logic
        'status': _status,
        'expiry': _expiry?.toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment created successfully')),
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
    final rolesAsync = ref.watch(ohsRolesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Legal Appointment'),
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
            rolesAsync.when(
              data: (roles) {
                if (roles.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Loading roles...'),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: _roleId,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: roles.map((r) => DropdownMenuItem(
                        value: r.id,
                        child: Text(r.title),
                      )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _roleId = val;
                        _roleTitle = roles.firstWhere((r) => r.id == val).title;
                      });
                    }
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => Text('Error loading roles: $e'),
            ),
            const SizedBox(height: 16),
            EmployeeSelector(
              label: 'Appointed Person',
              value: _personId,
              onChanged: (id) => setState(() => _personId = id),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'Appointed', child: Text('Appointed')),
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Expired', child: Text('Expired')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Expiry Date'),
              subtitle: Text(_expiry != null ? '${_expiry!.year}-${_expiry!.month.toString().padLeft(2, '0')}-${_expiry!.day.toString().padLeft(2, '0')}' : 'None'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expiry ?? DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                );
                if (date != null) {
                  setState(() => _expiry = date);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
