import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../providers/hr_providers.dart';
import '../models/hr_models.dart';
import '../services/hr_service.dart';
import '../widgets/department_form.dart';
import '../widgets/job_role_form.dart';

class OrgConfigScreen extends ConsumerWidget {
  const OrgConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Organization Config'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Departments'),
              Tab(text: 'Job Roles'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DepartmentsTab(),
            _JobRolesTab(),
          ],
        ),
      ),
    );
  }
}

class _DepartmentsTab extends ConsumerWidget {
  const _DepartmentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          UIUtils.showSideSheet(
            context: context,
            title: 'New Department',
            builder: (ctx) => const DepartmentForm(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: deptsAsync.when(
        data: (depts) {
          if (depts.isEmpty) return const Center(child: Text('No departments found.'));
          return ListView.builder(
            itemCount: depts.length,
            itemBuilder: (context, index) {
              final dept = depts[index];
              return ListTile(
                title: Text(dept.name),
                subtitle: Text(dept.description ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    UIUtils.showSideSheet(
                      context: context,
                      title: 'Edit Department',
                      builder: (ctx) => DepartmentForm(department: dept),
                    );
                  },
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

class _JobRolesTab extends ConsumerWidget {
  const _JobRolesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(jobRolesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          UIUtils.showSideSheet(
            context: context,
            title: 'New Job Role',
            builder: (ctx) => const JobRoleForm(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: rolesAsync.when(
        data: (roles) {
          if (roles.isEmpty) return const Center(child: Text('No job roles found.'));
          return ListView.builder(
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final role = roles[index];
              return ListTile(
                title: Text(role.title),
                subtitle: Text('Legal Appointment: ${role.isLegalAppointment}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    UIUtils.showSideSheet(
                      context: context,
                      title: 'Edit Job Role',
                      builder: (ctx) => JobRoleForm(jobRole: role),
                    );
                  },
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
