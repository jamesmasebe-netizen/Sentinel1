import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import 'rtw_badge.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class ClaimsTab extends ConsumerStatefulWidget {
  const ClaimsTab({super.key});

  @override
  ConsumerState<ClaimsTab> createState() => _ClaimsTabState();
}

class _ClaimsTabState extends ConsumerState<ClaimsTab> {
  bool _showClaimForm = false;
  bool _isSub = false;

  final _empCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _claimNoCtrl = TextEditingController();
  final _lostDaysCtrl = TextEditingController();
  DateTime _incidentDate = DateTime.now();

  @override
  void dispose() {
    _empCtrl.dispose();
    _idCtrl.dispose();
    _claimNoCtrl.dispose();
    _lostDaysCtrl.dispose();
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
            tenantId: ref.read(currentTenantIdProvider) ?? '',
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
              'siteId': p.tenantId,
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

  Future<void> _updateStatus(String id, String field, String value) async {
    try {
      await ref
          .read(firestoreProvider)
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'coida_claims',
          )
          .doc(id)
          .update({field: value});
      if (mounted) UIUtils.showToast(context, 'Status updated to $value');
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final siteId = ref.watch(currentTenantIdProvider);
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
                Text(
                  'Log New COIDA Claim',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GSpacing.vMd,
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _empCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Employee Name *',
                        ),
                      ),
                    ),
                    GSpacing.hMd,
                    Expanded(
                      child: TextFormField(
                        controller: _idCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ID Number',
                        ),
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
                        decoration: const InputDecoration(
                          labelText: 'Claim Number',
                        ),
                      ),
                    ),
                    GSpacing.hMd,
                    Expanded(
                      child: TextFormField(
                        controller: _lostDaysCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Lost Work Days',
                        ),
                      ),
                    ),
                  ],
                ),
                GSpacing.vMd,
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Incident Date',
                    style: theme.textTheme.labelSmall,
                  ),
                  subtitle: Text(
                    '${_incidentDate.day}/${_incidentDate.month}/${_incidentDate.year}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(
                    Icons.calendar_month_rounded,
                    color: theme.colorScheme.primary,
                  ),
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
          stream:
              siteId == null
                  ? null
                  : fs
                      .tenantCollection(
                        ref.watch(currentTenantIdProvider) ?? "",
                        'coida_claims',
                      )
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
              children:
                  docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final status = d['status'] ?? 'Submitted';
                    final statusColor =
                        status == 'Accepted'
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
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                GStatusTag(
                                  label: status.toUpperCase(),
                                  color: statusColor,
                                ),
                              ],
                            ),
                            GSpacing.vSm,
                            Text(
                              'Claim: ${d['claimNumber'] ?? 'N/A'} • Lost Days: ${d['lostDays'] ?? 0}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            GSpacing.vMd,
                            Row(
                              children: [
                                RtwBadge(label: d['rtwStatus'] ?? 'Off Sick'),
                                const Spacer(),
                                if (status != 'Closed')
                                  PopupMenuButton<String>(
                                    initialValue: status,
                                    onSelected:
                                        (val) => _updateStatus(
                                          doc.id,
                                          'status',
                                          val,
                                        ),
                                    itemBuilder:
                                        (ctx) =>
                                            ['Accepted', 'Rejected', 'Closed']
                                                .map(
                                                  (s) => PopupMenuItem(
                                                    value: s,
                                                    child: Text(s),
                                                  ),
                                                )
                                                .toList(),
                                    child: Text(
                                      'Update Status',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
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
}
