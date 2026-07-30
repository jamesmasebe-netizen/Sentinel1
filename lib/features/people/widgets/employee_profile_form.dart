import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hr_models.dart';
import '../services/hr_service.dart';
import '../providers/hr_providers.dart';
import 'employee_selector.dart';
import '../../../core/widgets/entity_selector.dart';
class EmployeeProfileForm extends ConsumerStatefulWidget {
  final EmployeeProfile? initialData;
  final VoidCallback? onSaved;

  const EmployeeProfileForm({super.key, this.initialData, this.onSaved});

  @override
  ConsumerState<EmployeeProfileForm> createState() =>
      _EmployeeProfileFormState();
}

class _EmployeeProfileFormState extends ConsumerState<EmployeeProfileForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _preferredNameController;
  late TextEditingController _workEmailController;
  late TextEditingController _personalEmailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _employmentStatusController;
  String? _departmentId;
  String? _positionId;
  String? _managerId;
  List<String> _ohsRoleIds = [];

  DateTime? _hireDate;
  DateTime? _terminationDate;
  bool _missingMandatorySafetyTraining = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _firstNameController = TextEditingController(text: data?.firstName ?? '');
    _lastNameController = TextEditingController(text: data?.lastName ?? '');
    _preferredNameController = TextEditingController(
      text: data?.preferredName ?? '',
    );
    _workEmailController = TextEditingController(text: data?.workEmail ?? '');
    _personalEmailController = TextEditingController(
      text: data?.personalEmail ?? '',
    );
    _phoneNumberController = TextEditingController(
      text: data?.phoneNumber ?? '',
    );
    _employmentStatusController = TextEditingController(
      text: data?.employmentStatus ?? 'Active',
    );
    _positionId = data?.positionId;
    _departmentId = data?.departmentId;
    _managerId = data?.managerEmployeeId;

    _hireDate = data?.hireDate ?? DateTime.now();
    _terminationDate = data?.terminationDate;
    _missingMandatorySafetyTraining = data?.missingMandatorySafetyTraining ?? false;
    _ohsRoleIds = List.from(data?.ohsRoleIds ?? []);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _preferredNameController.dispose();
    _workEmailController.dispose();
    _personalEmailController.dispose();
    _phoneNumberController.dispose();
    _employmentStatusController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isHireDate) async {
    final initialDate =
        isHireDate
            ? (_hireDate ?? DateTime.now())
            : (_terminationDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isHireDate) {
          _hireDate = picked;
        } else {
          _terminationDate = picked;
        }
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final employee = EmployeeProfile(
        id:
            widget.initialData?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        preferredName:
            _preferredNameController.text.trim().isEmpty
                ? null
                : _preferredNameController.text.trim(),
        workEmail: _workEmailController.text.trim(),
        personalEmail: _personalEmailController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        hireDate: _hireDate,
        terminationDate: _terminationDate,
        employmentStatus: _employmentStatusController.text.trim(),
        positionId: _positionId ?? '',
        ohsRoleIds: _ohsRoleIds,
        departmentId: _departmentId ?? '',
        managerEmployeeId: _managerId ?? '',
        missingMandatorySafetyTraining: _missingMandatorySafetyTraining,
      );

      final hrService = ref.read(hrServiceProvider);
      if (widget.initialData == null) {
        await hrService.createEmployee(employee);
      } else {
        await hrService.updateEmployee(employee.id, employee.toJson());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee profile saved successfully.')),
        );
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving employee: $e')));
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
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _preferredNameController,
            decoration: const InputDecoration(
              labelText: 'Preferred Name (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _workEmailController,
            decoration: const InputDecoration(
              labelText: 'Work Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator:
                (value) =>
                    value == null || !value.contains('@')
                        ? 'Enter a valid email'
                        : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _personalEmailController,
            decoration: const InputDecoration(
              labelText: 'Personal Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneNumberController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator:
                (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Hire Date'),
            subtitle: Text(
              _hireDate != null
                  ? '${_hireDate!.toLocal()}'.split(' ')[0]
                  : 'Not set',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context, true),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Termination Date (Optional)'),
            subtitle: Text(
              _terminationDate != null
                  ? '${_terminationDate!.toLocal()}'.split(' ')[0]
                  : 'Not set',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context, false),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _employmentStatusController,
            decoration: const InputDecoration(
              labelText: 'Employment Status',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          EntitySelector<Department>(
            label: 'Department',
            value: _departmentId,
            asyncEntities: ref.watch(departmentsProvider),
            idMapper: (d) => d.id,
            displayMapper: (d) => d.name,
            onChanged: (val) => setState(() => _departmentId = val),
          ),
          const SizedBox(height: 16),
          EntitySelector<JobRole>(
            label: 'HR Role (Position)',
            asyncEntities: ref.watch(jobRolesProvider),
            value: _positionId,
            idMapper: (r) => r.id,
            displayMapper: (r) => r.title,
            onChanged: (v) => setState(() => _positionId = v),
          ),
          const SizedBox(height: 16),
          const Text('OHS Roles (Appointments)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, child) {
              final ohsRolesAsync = ref.watch(ohsRolesProvider);
              return ohsRolesAsync.when(
                data: (roles) {
                  if (roles.isEmpty) return const Text('No OHS roles available.');
                  return Wrap(
                    spacing: 8.0,
                    children: roles.map((role) {
                      final isSelected = _ohsRoleIds.contains(role.id);
                      return FilterChip(
                        label: Text(role.title),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _ohsRoleIds.add(role.id);
                            } else {
                              _ohsRoleIds.remove(role.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => Text('Error loading OHS roles: $e'),
              );
            },
          ),
          const SizedBox(height: 16),
          EmployeeSelector(
            label: 'Manager / Supervisor',
            value: _managerId,
            onChanged: (val) => setState(() => _managerId = val),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Missing Mandatory Safety Training'),
            value: _missingMandatorySafetyTraining,
            onChanged: (val) {
              setState(() {
                _missingMandatorySafetyTraining = val;
              });
            },
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveForm,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Employee Profile'),
            ),
          ),
        ],
      ),
    );
  }
}
