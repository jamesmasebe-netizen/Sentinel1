import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/project_models.dart';
import 'contractors_tab.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../../../core/widgets/searchable_multi_select.dart';
import '../../providers/project_providers.dart';
import '../../../people/providers/employee_providers.dart';
import '../../../equipment/providers/equipment_providers.dart';

class ResourcesTab extends ConsumerWidget {
  final Project project;
  const ResourcesTab({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Contractors'),
              Tab(text: 'Personnel'),
              Tab(text: 'Equipment & Tools'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ContractorsTab(project: project),
                _PersonnelList(project: project),
                _EquipmentList(project: project),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonnelList extends ConsumerWidget {
  final Project project;
  const _PersonnelList({required this.project});

  void _showAllocationDialog(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.read(employeesProvider);
    final employees = employeesAsync.valueOrNull ?? [];
    final availableIds = employees.map((e) => e.id).toList();
    final labels = {for (var e in employees) e.id: '${e.fullName} (${e.department})'};

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Allocate Personnel'),
          content: SizedBox(
            width: 400,
            child: SearchableStringMultiSelect(
              label: 'Select Personnel',
              hintText: 'Search employees by name...',
              availableItems: availableIds,
              itemLabels: labels,
              selectedItems: project.allocatedEmployeeIds,
              onChanged: (newSelection) async {
                final updated = project.copyWith(allocatedEmployeeIds: newSelection);
                await ref.read(projectServiceProvider).updateProject(updated);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = project.allocatedEmployeeIds;
    final employeesAsync = ref.watch(employeesProvider);
    final employeeMap = employeesAsync.valueOrNull != null
        ? {for (var e in employeesAsync.valueOrNull!) e.id: e}
        : {};

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Allocated Personnel (\${employees.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            FilledButton.icon(
              onPressed: () => _showAllocationDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Allocate Personnel'),
            ),
          ],
        ),
        GSpacing.vMd,
        if (employees.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No personnel allocated.')))
        else
          ...employees.map((id) {
            final emp = employeeMap[id];
            final displayName = emp != null ? emp.fullName : id;
            final subtitle = emp != null ? '${emp.jobTitle} • ${emp.department}' : null;
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(displayName),
              subtitle: subtitle != null ? Text(subtitle) : null,
            );
          }),
      ],
    );
  }
}

class _EquipmentList extends ConsumerWidget {
  final Project project;
  const _EquipmentList({required this.project});

  void _showAllocationDialog(BuildContext context, WidgetRef ref) {
    final equipmentAsync = ref.read(equipmentListProvider);
    final equipmentItems = (equipmentAsync.valueOrNull ?? [])
        .where((e) => e.status != 'Locked Out')
        .toList();
    final availableIds = equipmentItems.map((e) => e.id ?? '').where((id) => id.isNotEmpty).toList();
    final labels = {for (var e in equipmentItems) if (e.id != null) e.id!: '${e.equipmentName} (${e.id})'};

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Allocate Equipment'),
          content: SizedBox(
            width: 400,
            child: SearchableStringMultiSelect(
              label: 'Select Equipment',
              hintText: 'Search equipment by name or tag...',
              availableItems: availableIds,
              itemLabels: labels,
              selectedItems: project.allocatedAssetIds,
              onChanged: (newSelection) async {
                final updated = project.copyWith(allocatedAssetIds: newSelection);
                await ref.read(projectServiceProvider).updateProject(updated);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = project.allocatedAssetIds;
    final equipmentAsync = ref.watch(equipmentListProvider);
    final equipmentMap = equipmentAsync.valueOrNull != null
        ? {for (var e in equipmentAsync.valueOrNull!) if (e.id != null) e.id!: e}
        : <String, dynamic>{};

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Allocated Equipment (\${assets.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            FilledButton.icon(
              onPressed: () => _showAllocationDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Allocate Equipment'),
            ),
          ],
        ),
        GSpacing.vMd,
        if (assets.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No equipment allocated.')))
        else
          ...assets.map((id) {
            final equip = equipmentMap[id];
            final displayName = equip != null ? equip.equipmentName : id;
            final subtitle = equip != null ? '${equip.assetTag} • ${equip.category} • ${equip.status}' : null;
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.precision_manufacturing)),
              title: Text(displayName),
              subtitle: subtitle != null ? Text(subtitle) : null,
            );
          }),
      ],
    );
  }
}
