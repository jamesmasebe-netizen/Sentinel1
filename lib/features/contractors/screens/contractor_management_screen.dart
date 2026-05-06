import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';

/// Contractor Management — contractor register, compliance status, permit linkage.
class ContractorManagementScreen extends ConsumerStatefulWidget {
  const ContractorManagementScreen({super.key});
  @override
  ConsumerState<ContractorManagementScreen> createState() => _ContractorState();
}

class _ContractorState extends ConsumerState<ContractorManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _showForm = false, _isSub = false;
  String _searchQuery = '', _statusFilter = 'All';
  final _nameCtrl = TextEditingController(),
      _contactCtrl = TextEditingController();
  final _regCtrl = TextEditingController(),
      _scopeCtrl = TextEditingController();
  String _riskRating = 'Medium', _status = 'Active';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _regCtrl.dispose();
    _scopeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            collection: 'contractors',
            data: {
              'companyName': _nameCtrl.text.trim(),
              'contactPerson': _contactCtrl.text.trim(),
              'registrationNumber': _regCtrl.text.trim(),
              'scopeOfWork': _scopeCtrl.text.trim(),
              'riskRating': _riskRating,
              'status': _status,
              'authorId': p.uid,
              'siteId': p.siteId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contractor added'),
            backgroundColor: XMTheme.success,
          ),
        );
        setState(() {
          _showForm = false;
          _nameCtrl.clear();
          _contactCtrl.clear();
          _regCtrl.clear();
          _scopeCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: XMTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Management'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.business, size: 16), text: 'Register'),
            Tab(icon: Icon(Icons.verified_user, size: 16), text: 'Compliance'),
            Tab(icon: Icon(Icons.assignment_ind, size: 16), text: 'Inductions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_registerTab(), _complianceTab(), _inductionsTab()],
      ),
    );
  }

  Widget _registerTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged:
                      (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: 'Search contractors…',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              GSpacing.hMd,
              DropdownButton<String>(
                value: _statusFilter,
                isDense: true,
                underline: const SizedBox(),
                items:
                    ['All', 'Active', 'Inactive', 'Suspended']
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _statusFilter = v!),
              ),
              GSpacing.hSm,
              FilledButton(
                onPressed: () => setState(() => _showForm = !_showForm),
                child: Icon(_showForm ? Icons.close : Icons.add, size: 18),
              ),
            ],
          ),
        ),
        if (_showForm)
          GCard(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Contractor',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                GSpacing.vMd,
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Company Name *',
                  ),
                ),
                GSpacing.vMd,
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _contactCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Contact Person',
                        ),
                      ),
                    ),
                    GSpacing.hMd,
                    Expanded(
                      child: TextFormField(
                        controller: _regCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Registration No.',
                        ),
                      ),
                    ),
                  ],
                ),
                GSpacing.vMd,
                TextFormField(
                  controller: _scopeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Scope of Work',
                  ),
                ),
                GSpacing.vMd,
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _riskRating,
                        decoration: const InputDecoration(
                          labelText: 'Risk Rating',
                          isDense: true,
                        ),
                        items:
                            ['Low', 'Medium', 'High', 'Critical']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _riskRating = v!),
                      ),
                    ),
                    GSpacing.hMd,
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          isDense: true,
                        ),
                        items:
                            ['Active', 'Inactive', 'Suspended']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ),
                  ],
                ),
                GSpacing.vLg,
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSub ? null : _submit,
                    child: Text(_isSub ? 'Saving…' : 'Add Contractor'),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                siteId == null
                    ? null
                    : fs
                        .collection('contractors')
                        .where('siteId', isEqualTo: siteId)
                        .orderBy('createdAt', descending: true)
                        .limit(100)
                        .snapshots(),
            builder: (ctx, snap) {
              var docs = snap.data?.docs ?? [];
              if (_searchQuery.isNotEmpty) {
                docs =
                    docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return (data['companyName'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(_searchQuery);
                    }).toList();
              }
              if (_statusFilter != 'All') {
                docs =
                    docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return data['status'] == _statusFilter;
                    }).toList();
              }
              if (docs.isEmpty) {
                return const Center(child: Text('No contractors found'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final riskRating = d['riskRating'] ?? 'Medium';
                  final status = d['status'] ?? 'Active';

                  return GCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d['companyName'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${d['contactPerson'] ?? ''} • ${d['scopeOfWork'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            GStatusTag(
                              label: riskRating,
                              color:
                                  riskRating == 'Critical' ||
                                          riskRating == 'High'
                                      ? XMTheme.error
                                      : riskRating == 'Medium'
                                      ? XMTheme.warning
                                      : XMTheme.success,
                            ),
                            GSpacing.vSm,
                            GStatusTag(
                              label: status,
                              color: status == 'Active' ? XMTheme.success : XMTheme.error,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _complianceTab() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user,
          size: 48,
          color: XMTheme.success.withValues(alpha: 0.4),
        ),
        GSpacing.vMd,
        const Text('Contractor Compliance Tracking'),
        GSpacing.vSm,
        Text(
          'Insurance certificates, tax clearance, safety files',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _inductionsTab() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.assignment_ind,
          size: 48,
          color: XMTheme.primary.withValues(alpha: 0.4),
        ),
        GSpacing.vMd,
        const Text('Contractor Induction Records'),
        GSpacing.vSm,
        Text(
          'Site induction completion tracking per contractor',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
