import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

/// Workers Compensation (COIDA) — claims, RTW tracking, COIDA compliance checklist.
class WorkersCompScreen extends ConsumerStatefulWidget {
  const WorkersCompScreen({super.key});
  @override
  ConsumerState<WorkersCompScreen> createState() => _WCState();
}

class _WCState extends ConsumerState<WorkersCompScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _showClaimForm = false, _isSub = false;

  // Claim form
  final _empCtrl = TextEditingController(), _idCtrl = TextEditingController();
  final _claimNoCtrl = TextEditingController(),
      _lostDaysCtrl = TextEditingController();
  DateTime _incidentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [_empCtrl, _idCtrl, _claimNoCtrl, _lostDaysCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitClaim() async {
    if (_empCtrl.text.isEmpty) return;
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            collection: 'coida_claims',
            data: {
              'employeeName': _empCtrl.text.trim(),
              'idNumber': _idCtrl.text.trim(),
              'claimNumber': _claimNoCtrl.text.trim(),
              'incidentDate': _incidentDate.toIso8601String(),
              'lostDays': int.tryParse(_lostDaysCtrl.text) ?? 0,
              'status': 'Submitted',
              'rtwStatus': 'Off Sick',
              'authorId': p.uid,
              'siteId': p.siteId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        UIUtils.showToast(context, 'Claim submitted successfully');
        setState(() {
          _showClaimForm = false;
          _empCtrl.clear();
          _idCtrl.clear();
          _claimNoCtrl.clear();
          _lostDaysCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const GHeader(
          title: 'Workers Compensation',
          subtitle: 'Manage COIDA claims, return-to-work plans, and compliance',
        ),
        // Standardized Sub-Header for Tabs
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tab,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Claims'),
              Tab(text: 'RTW Plans'),
              Tab(text: 'Checklist'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [_claimsTab(), _rtwTab(), _complianceTab()],
          ),
        ),
      ],
    );
  }

  Widget _claimsTab() {
    final theme = Theme.of(context);
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.icon(
              onPressed: () => setState(() => _showClaimForm = !_showClaimForm),
              icon: Icon(_showClaimForm ? Icons.close : Icons.add, size: 18),
              label: Text(_showClaimForm ? 'Cancel' : 'New Claim'),
            ),
          ],
        ),
        if (_showClaimForm) ...[
          GSpacing.vMd,
          GCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Log New COIDA Claim', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                GSpacing.vMd,
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _empCtrl,
                        decoration: const InputDecoration(labelText: 'Employee Name *'),
                      ),
                    ),
                    GSpacing.hMd,
                    Expanded(
                      child: TextFormField(
                        controller: _idCtrl,
                        decoration: const InputDecoration(labelText: 'ID Number'),
                      ),
                    ),
                  ],
                ),
                GSpacing.vMd,
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _claimNoCtrl,
                        decoration: const InputDecoration(labelText: 'Claim Number'),
                      ),
                    ),
                    GSpacing.hMd,
                    Expanded(
                      child: TextFormField(
                        controller: _lostDaysCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Lost Work Days'),
                      ),
                    ),
                  ],
                ),
                GSpacing.vMd,
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Incident Date', style: theme.textTheme.labelSmall),
                  subtitle: Text(
                    '${_incidentDate.day}/${_incidentDate.month}/${_incidentDate.year}',
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),

                  trailing: Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _incidentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _incidentDate = d);
                  },
                ),
                GSpacing.vMd,
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSub ? null : _submitClaim,
                    child: Text(_isSub ? 'Submitting…' : 'Submit Claim'),
                  ),
                ),
              ],
            ),
          ),
        ],
        GSpacing.vMd,
        StreamBuilder<QuerySnapshot>(
          stream: siteId == null
              ? null
              : fs
                  .collection('coida_claims')
                  .where('siteId', isEqualTo: siteId)
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
          builder: (ctx, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Text('No COIDA claims recorded'),
                ),
              );
            }
            return Column(
              children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final status = d['status'] ?? 'Submitted';
                final statusColor = status == 'Accepted'
                    ? XMTheme.success
                    : status == 'Rejected'
                        ? XMTheme.error
                        : status == 'Closed'
                            ? theme.colorScheme.outline
                            : XMTheme.warning;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                d['employeeName'] ?? 'Unknown Employee',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            GStatusTag(label: status.toUpperCase(), color: statusColor),
                          ],
                        ),
                        GSpacing.vSm,
                        Text(
                          'Claim: ${d['claimNumber'] ?? 'N/A'} • Lost Days: ${d['lostDays'] ?? 0}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        GSpacing.vMd,
                        Row(
                          children: [
                            _RtwBadge(label: d['rtwStatus'] ?? 'Off Sick'),
                            const Spacer(),
                            if (status != 'Closed')
                              PopupMenuButton<String>(
                                initialValue: status,
                                onSelected: (val) => _updateStatus(doc.id, 'status', val),
                                itemBuilder: (ctx) => [
                                  'Accepted',
                                  'Rejected',
                                  'Closed',
                                ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                                child: Text(
                                  'Update Status',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _rtwTab() {
    final theme = Theme.of(context);
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    
    return StreamBuilder<QuerySnapshot>(
      stream: siteId == null
          ? null
          : fs
              .collection('coida_claims')
              .where('siteId', isEqualTo: siteId)
              .where('status', isNotEqualTo: 'Closed')
              .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No active RTW cases'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['employeeName'] ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    GSpacing.vSm,
                    Text(
                      'Lost days to date: ${d['lostDays'] ?? 0}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    GSpacing.vMd,
                    const Divider(),
                    GSpacing.vMd,
                    Text('Current Return to Work Status', style: theme.textTheme.labelSmall),
                    GSpacing.vSm,
                    Wrap(
                      spacing: 8,
                      children: ['Off Sick', 'Light Duty', 'Full Duty'].map((s) {
                        final isSelected = d['rtwStatus'] == s;
                        return ChoiceChip(
                          label: Text(s),
                          selected: isSelected,
                          onSelected: (_) => _updateStatus(docs[i].id, 'rtwStatus', s),
                          selectedColor: XMTheme.success.withValues(alpha: 0.15),
                          checkmarkColor: XMTheme.success,
                          labelStyle: TextStyle(
                            color: isSelected ? XMTheme.success : null,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _complianceTab() {
    final theme = Theme.of(context);
    final items = [
      ('Register with COIDA Fund (RAF)', true),
      ('Annual Return of Earnings submitted', true),
      ('W.CL.2 form filed within 7 days of incident', true),
      ('Medical reports obtained from treating doctor', false),
      ('Employee notified of claim status', false),
      ('Return-to-work plan documented', false),
      ('COIDA claim file retained for 3 years', true),
      ('Compensation Commissioner correspondence filed', false),
      ('Section 56 investigation if applicable', false),
      ('Death benefit notifications processed', false),
    ];
    final done = items.where((e) => e.$2).length;
    final progress = done / items.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GCard(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COIDA Compliance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      GSpacing.vSm,
                      Text(
                        '$done / ${items.length} requirements met',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: XMTheme.success,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GSpacing.vLg,
          Text('Compliance Checklist', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          GSpacing.vMd,
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      item.$2 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: item.$2 ? XMTheme.success : theme.colorScheme.outline,
                      size: 22,
                    ),
                    GSpacing.hMd,
                    Expanded(
                      child: Text(
                        item.$1,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: item.$2 ? null : theme.colorScheme.onSurfaceVariant,
                          decoration: item.$2 ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String id, String field, String value) async {
    try {
      await ref
          .read(firestoreProvider)
          .collection('coida_claims')
          .doc(id)
          .update({field: value});
      if (mounted) UIUtils.showToast(context, 'Status updated to $value');
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    }
  }
}

class _RtwBadge extends StatelessWidget {
  final String label;
  const _RtwBadge({required this.label});
  @override
  Widget build(BuildContext context) {
    final color =
        label == 'Full Duty'
            ? XMTheme.success
            : label == 'Light Duty'
            ? XMTheme.warning
            : XMTheme.error;
    return GStatusTag(label: label, color: color);
  }
}
