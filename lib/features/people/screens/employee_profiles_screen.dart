import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Employee Profiles — search, filter, add, detail view, induction tracking.
class EmployeeProfilesScreen extends ConsumerStatefulWidget {
  const EmployeeProfilesScreen({super.key});
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
  void dispose() { for (final c in [_nameCtrl, _codeCtrl, _idCtrl, _titleCtrl, _deptCtrl, _emailCtrl, _phoneCtrl]) { c.dispose(); } super.dispose(); }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _codeCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'employees', data: {
        'fullName': _nameCtrl.text.trim(), 'employeeCode': _codeCtrl.text.trim(),
        'idNumber': _idCtrl.text.trim(), 'jobTitle': _titleCtrl.text.trim(),
        'department': _deptCtrl.text.trim(), 'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(), 'status': 'Active',
        'authorId': profile.uid, 'siteId': profile.siteId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee added'), backgroundColor: XMTheme.success));
        setState(() { _showForm = false; for (final c in [_nameCtrl, _codeCtrl, _idCtrl, _titleCtrl, _deptCtrl, _emailCtrl, _phoneCtrl]) { c.clear(); } }); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: XMTheme.error)); }
    finally { if (mounted) setState(() => _isSubmitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Scaffold(
      appBar: AppBar(title: const Text('Employee Profiles'), actions: [
        FilledButton.icon(onPressed: () => setState(() => _showForm = !_showForm),
          icon: Icon(_showForm ? Icons.close : Icons.person_add, size: 18), label: Text(_showForm ? 'Cancel' : 'Add')),
      ]),
      body: Column(children: [
        // Search + Filters
        Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          TextFormField(onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(hintText: 'Search name or code...', prefixIcon: Icon(Icons.search), isDense: true)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(value: _filterStatus, decoration: const InputDecoration(labelText: 'Status', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              items: ['All', 'Active', 'On Leave', 'Inactive', 'Terminated'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _filterStatus = v!))),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(value: _filterDept, decoration: const InputDecoration(labelText: 'Department', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              items: ['All', 'Operations', 'Safety', 'Engineering', 'Admin', 'HR'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _filterDept = v!))),
          ]),
        ])),
        if (_showForm) _buildForm(),
        // Employee List
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('employees').where('siteId', isEqualTo: siteId).orderBy('fullName').snapshots(),
          builder: (ctx, snap) {
            final docs = (snap.data?.docs ?? []).where((d) {
              final data = d.data() as Map<String, dynamic>;
              final matchSearch = (data['fullName'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
                  (data['employeeCode'] ?? '').toString().toLowerCase().contains(_search.toLowerCase());
              final matchStatus = _filterStatus == 'All' || data['status'] == _filterStatus;
              final matchDept = _filterDept == 'All' || data['department'] == _filterDept;
              return matchSearch && matchStatus && matchDept;
            }).toList();

            if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.people_outline, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 12), const Text('No employees found'),
            ]));

            return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: docs.length, itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return _EmployeeCard(data: d, onTap: () => _showDetail(context, d));
            });
          },
        )),
      ]),
    );
  }

  Widget _buildForm() => Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Add Employee', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 12),
    Row(children: [Expanded(child: TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *'))),
      const SizedBox(width: 12), Expanded(child: TextFormField(controller: _codeCtrl, decoration: const InputDecoration(labelText: 'Employee Code *')))]),
    const SizedBox(height: 10),
    Row(children: [Expanded(child: TextFormField(controller: _idCtrl, decoration: const InputDecoration(labelText: 'ID Number'))),
      const SizedBox(width: 12), Expanded(child: TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Job Title')))]),
    const SizedBox(height: 10),
    Row(children: [Expanded(child: TextFormField(controller: _deptCtrl, decoration: const InputDecoration(labelText: 'Department'))),
      const SizedBox(width: 12), Expanded(child: TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')))]),
    const SizedBox(height: 10),
    TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
    const SizedBox(height: 12),
    SizedBox(width: double.infinity, child: FilledButton(onPressed: _isSubmitting ? null : _submit, child: Text(_isSubmitting ? 'Saving...' : 'Save Employee'))),
  ])));

  void _showDetail(BuildContext context, Map<String, dynamic> emp) {
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
      builder: (ctx, scroll) => SingleChildScrollView(controller: scroll, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Row(children: [
          CircleAvatar(radius: 30, backgroundColor: XMTheme.primary.withValues(alpha: 0.1),
            child: Text((emp['fullName'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: XMTheme.primary))),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emp['fullName'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(emp['jobTitle'] ?? '', style: TextStyle(fontSize: 14, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            _StatusBadge(status: emp['status'] ?? 'Active'),
          ]),
        ]),
        const SizedBox(height: 20), const Divider(), const SizedBox(height: 12),
        _DetailRow(icon: Icons.badge, label: 'Employee Code', value: emp['employeeCode'] ?? ''),
        _DetailRow(icon: Icons.credit_card, label: 'ID Number', value: emp['idNumber'] ?? ''),
        _DetailRow(icon: Icons.business, label: 'Department', value: emp['department'] ?? ''),
        _DetailRow(icon: Icons.email, label: 'Email', value: emp['email'] ?? ''),
        _DetailRow(icon: Icons.phone, label: 'Phone', value: emp['phone'] ?? ''),
      ])),
    ));
  }
}

class _EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> data; final VoidCallback onTap;
  const _EmployeeCard({required this.data, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 6), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10),
      child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          CircleAvatar(radius: 20, backgroundColor: XMTheme.primary.withValues(alpha: 0.1),
            child: Text((data['fullName'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, color: XMTheme.primary))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('${data['jobTitle'] ?? ''} • ${data['department'] ?? ''}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ])),
          _StatusBadge(status: data['status'] ?? 'Active'),
          const SizedBox(width: 8), const Icon(Icons.chevron_right, size: 18),
        ])),
    ));
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  Color get _color { switch (status) { case 'Active': return XMTheme.success; case 'On Leave': return XMTheme.info; case 'Terminated': return XMTheme.error; default: return XMTheme.statusDraft; } }
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _color)));
}

class _DetailRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
    Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 12),
    SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))),
    Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
  ]));
}
