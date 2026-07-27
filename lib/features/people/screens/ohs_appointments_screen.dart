import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/providers/app_providers.dart';
import '../providers/hr_providers.dart';
import '../providers/employee_providers.dart';
import '../widgets/employee_selector.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../models/hr_models.dart';

class OHSAppointmentsScreen extends ConsumerWidget {
  const OHSAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(ohsAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('OHS Legal Appointments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          UIUtils.showSideSheet(
            context: context,
            title: 'New OHS Appointment',
            builder: (ctx) => const OHSAppointmentForm(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Appointment'),
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return const Center(child: Text('No active OHS appointments.'));
          }
          return ListView.builder(
            itemCount: appointments.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final appt = appointments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text(appt.appointeeName),
                  subtitle: Text(
                    '${appt.statutoryReference}\nAppointed: ${UIUtils.formatDate(appt.appointedDate)}',
                  ),
                  isThreeLine: true,
                  trailing: Chip(
                    label: Text(appt.status),
                    backgroundColor:
                        appt.status == 'Active'
                            ? Colors.green.shade100
                            : Colors.grey.shade300,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class OHSAppointmentForm extends ConsumerStatefulWidget {
  const OHSAppointmentForm({super.key});

  @override
  ConsumerState<OHSAppointmentForm> createState() => _OHSAppointmentFormState();
}

class _OHSAppointmentFormState extends ConsumerState<OHSAppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  final _referenceCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final siteId = ref.read(currentTenantIdProvider);
      if (siteId == null) throw Exception('No site selected');

      final employees = ref.read(employeesProvider).valueOrNull ?? [];
      final employee = employees.firstWhere((e) => e.id == _selectedEmployeeId);

      final customId =
          'OHS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final appt = OHSAppointment(
        id: customId,
        appointeeId: employee.id,
        appointeeName: employee.fullName,
        statutoryReference: _referenceCtrl.text.trim(),
        appointedDate: DateTime.now(),
        status: 'Active',
        siteId: siteId,
      );

      await ref
          .read(firestoreProvider)
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'ohs_appointments',
          )
          .doc(customId)
          .set(appt.toFirestore());

      if (mounted) {
        UIUtils.showToast(
          context,
          'Appointment saved successfully',
          type: ToastType.success,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(
          context,
          'Failed to save appointment: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            EmployeeSelector(
              value: _selectedEmployeeId,
              label: 'Select Appointee',
              onChanged: (val) => setState(() => _selectedEmployeeId = val),
              validator:
                  (val) => val == null ? 'Please select an employee' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenceCtrl,
              decoration: const InputDecoration(
                labelText: 'Statutory Reference',
                hintText: 'e.g. OHS Act 16.2 Assignee',
                border: OutlineInputBorder(),
              ),
              validator:
                  (val) => val == null || val.isEmpty ? 'Required field' : null,
            ),
            const Spacer(),
            UIUtils.buildFormButtons(
              context: context,
              onSave: _submit,
              isSubmitting: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
