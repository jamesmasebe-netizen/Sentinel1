import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/widgets/entity_selector.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../models/safety_file_models.dart';
import '../../projects/providers/project_providers.dart';
import '../../projects/models/project_models.dart';

/// Real Inductions tab — site induction completion tracking per contractor.
/// New schema (contractor_inductions), see F-223 in docs/fixes/FIX_LIST.md.
class ContractorInductionsTab extends ConsumerWidget {
  const ContractorInductionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);
    if (tenantId == null) return const SizedBox.shrink();

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: fs
            .tenantCollection(tenantId, 'contractor_inductions')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final inductions = snap.data!.docs
              .map((d) => ContractorInduction.fromFirestore(d))
              .toList();

          if (inductions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_ind, size: 48, color: XMTheme.primary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Text('No induction records yet'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: inductions.length,
            itemBuilder: (context, i) {
              final ind = inductions[i];
              final color = switch (ind.status) {
                InductionStatus.completed => XMTheme.success,
                InductionStatus.expired => XMTheme.error,
                InductionStatus.scheduled => XMTheme.warning,
              };
              return GCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.assignment_ind, color: color),
                  title: Text(ind.attendeeName),
                  subtitle: Text('${ind.date.day}/${ind.date.month}/${ind.date.year}'),
                  trailing: GStatusTag(label: ind.status.name.toUpperCase(), color: color),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => UIUtils.showSideSheet(
          context: context,
          title: 'New Induction Record',
          builder: (_) => const _InductionForm(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _InductionForm extends ConsumerStatefulWidget {
  const _InductionForm();

  @override
  ConsumerState<_InductionForm> createState() => _InductionFormState();
}

class _InductionFormState extends ConsumerState<_InductionForm> {
  final _attendeeCtrl = TextEditingController();
  String? _contractorId;
  String? _projectId;
  DateTime _date = DateTime.now();
  InductionStatus _status = InductionStatus.scheduled;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _attendeeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_contractorId == null || _attendeeCtrl.text.trim().isEmpty) {
      UIUtils.showToast(context, 'Contractor and attendee name are required', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final tenantId = ref.read(currentTenantIdProvider) ?? '';
      final induction = ContractorInduction(
        id: const Uuid().v4(),
        contractorId: _contractorId!,
        attendeeName: _attendeeCtrl.text.trim(),
        projectId: _projectId,
        date: _date,
        status: _status,
        createdAt: DateTime.now(),
      );
      await ref
          .read(firestoreProvider)
          .tenantCollection(tenantId, 'contractor_inductions')
          .doc(induction.id)
          .set(induction.toMap());
      if (mounted) {
        UIUtils.showToast(context, 'Induction record saved', type: ToastType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (tenantId != null)
          StreamBuilder<QuerySnapshot>(
            stream: fs.tenantCollection(tenantId, 'contractors').snapshots(),
            builder: (context, snap) {
              final contractors = snap.data?.docs ?? [];
              return DropdownButtonFormField<String>(
                value: _contractorId,
                decoration: const InputDecoration(labelText: 'Contractor *'),
                items: contractors.map((c) {
                  final data = c.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: c.id,
                    child: Text(data['companyName'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _contractorId = v),
              );
            },
          ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _attendeeCtrl,
          decoration: const InputDecoration(labelText: 'Attendee Name *'),
        ),
        const SizedBox(height: 16),
        EntitySelector<Project>(
          asyncEntities: ref.watch(projectsProvider),
          value: _projectId,
          onChanged: (val) => setState(() => _projectId = val),
          label: 'Site / Project (optional)',
          idMapper: (p) => p.id,
          displayMapper: (p) => p.name,
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Induction Date'),
          subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2040),
            );
            if (d != null) setState(() => _date = d);
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<InductionStatus>(
          value: _status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: InductionStatus.values
              .map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase())))
              .toList(),
          onChanged: (v) => setState(() => _status = v ?? _status),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(_isSubmitting ? 'Saving...' : 'Save Induction Record'),
          ),
        ),
      ],
    );
  }
}
