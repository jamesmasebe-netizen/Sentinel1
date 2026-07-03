import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../widgets/employee_profiles/employee_form_card.dart';
import '../widgets/employee_profiles/employee_filters.dart';
import '../widgets/employee_profiles/employee_list.dart';

/// Employee Profiles — search, filter, add, detail view, induction tracking.
class EmployeeProfilesScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  const EmployeeProfilesScreen({super.key, this.initialSearch});
  @override
  ConsumerState<EmployeeProfilesScreen> createState() => _EmployeeState();
}

class _EmployeeState extends ConsumerState<EmployeeProfilesScreen> {
  bool _showForm = false, _isSubmitting = false;
  String _search = '', _filterStatus = 'All', _filterDept = 'All';
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      _search = widget.initialSearch!;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _codeCtrl,
      _idCtrl,
      _titleCtrl,
      _deptCtrl,
      _emailCtrl,
      _phoneCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _codeCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            tenantId: ref.read(currentTenantIdProvider) ?? '',
            collection: 'employees',
            data: {
              'fullName': _nameCtrl.text.trim(),
              'employeeCode': _codeCtrl.text.trim(),
              'idNumber': _idCtrl.text.trim(),
              'jobTitle': _titleCtrl.text.trim(),
              'department': _deptCtrl.text.trim(),
              'email': _emailCtrl.text.trim(),
              'phone': _phoneCtrl.text.trim(),
              'status': 'Active',
              'authorId': profile.uid,
              'siteId': profile.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        UIUtils.showToast(context, 'Employee added', type: ToastType.success);
        setState(() {
          _showForm = false;
          for (final c in [
            _nameCtrl,
            _codeCtrl,
            _idCtrl,
            _titleCtrl,
            _deptCtrl,
            _emailCtrl,
            _phoneCtrl,
          ]) {
            c.clear();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Column(
        children: [
          const GHeader(
            title: 'Employee Profiles',
            subtitle: 'Directory, roles, and employment history',
          ),
          EmployeeFilters(
            onSearchChanged: (v) => setState(() => _search = v),
            filterStatus: _filterStatus,
            onStatusChanged: (v) => setState(() => _filterStatus = v!),
            filterDept: _filterDept,
            onDeptChanged: (v) => setState(() => _filterDept = v!),
          ),
          GSpacing.vMd,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Personnel Directory',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => setState(() => _showForm = !_showForm),
                  icon: Icon(_showForm ? Icons.close : Icons.person_add, size: 18),
                  label: Text(_showForm ? 'Cancel' : 'Add Employee'),
                ),
              ],
            ),
          ),
          if (_showForm)
            EmployeeFormCard(
              nameCtrl: _nameCtrl,
              codeCtrl: _codeCtrl,
              idCtrl: _idCtrl,
              titleCtrl: _titleCtrl,
              deptCtrl: _deptCtrl,
              emailCtrl: _emailCtrl,
              phoneCtrl: _phoneCtrl,
              isSubmitting: _isSubmitting,
              onSubmit: _submit,
            ),
          GSpacing.vMd,
          Expanded(
            child: EmployeeList(
              firestore: firestore,
              siteId: siteId,
              search: _search,
              filterStatus: _filterStatus,
              filterDept: _filterDept,
            ),
          ),
        ],
      ),
    );
  }
}
