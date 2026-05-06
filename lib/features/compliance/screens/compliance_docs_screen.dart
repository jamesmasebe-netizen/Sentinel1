import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

/// Compliance & Documents — register, upload, review, expiry alerts.
class ComplianceDocsScreen extends ConsumerStatefulWidget {
  const ComplianceDocsScreen({super.key});
  @override
  ConsumerState<ComplianceDocsScreen> createState() => _CompDocsState();
}

class _CompDocsState extends ConsumerState<ComplianceDocsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _isSub = false;
  String _docType = 'Licence', _docStatus = 'Current', _searchQuery = '';
  final _titleCtrl = TextEditingController(),
      _refCtrl = TextEditingController(),
      _ownerCtrl = TextEditingController();
  DateTime _expiry = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _titleCtrl.dispose();
    _refCtrl.dispose();
    _ownerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (_titleCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Document title is required', type: ToastType.error);
      return;
    }
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            collection: 'compliance_docs',
            data: {
              'title': _titleCtrl.text.trim(),
              'referenceNumber': _refCtrl.text.trim(),
              'documentType': _docType,
              'status': _docStatus,
              'owner': _ownerCtrl.text.trim(),
              'expiryDate': _expiry.toIso8601String(),
              'daysUntilExpiry': _expiry.difference(DateTime.now()).inDays,
              'authorId': p.uid,
              'siteId': p.siteId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'Document successfully registered');
        _titleCtrl.clear();
        _refCtrl.clear();
        _ownerCtrl.clear();
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // ─── Actions Bar ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Text('Regulatory Compliance', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'Register Document',
                  builder: (ctx) => _buildForm(context),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Document'),
              ),
            ],
          ),
        ),

        // ─── Modern TabBar ───
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tab,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Register'),
              Tab(text: 'Expiring'),
              Tab(text: 'Framework'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [_registerTab(), _expiringTab(), _legalTab()],
          ),
        ),
      ],
    );
  }

  Widget _registerTab() {
    final theme = Theme.of(context);
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              hintText: 'Search by document title or reference...',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                siteId == null
                    ? null
                    : fs
                        .collection('compliance_docs')
                        .where('siteId', isEqualTo: siteId)
                        .orderBy('createdAt', descending: true)
                        .limit(100)
                        .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var docs = snap.data?.docs ?? [];
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final ref = (data['referenceNumber'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery) || ref.contains(_searchQuery);
                }).toList();
              }
              
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_off_outlined, size: 64, color: theme.colorScheme.outline),
                      GSpacing.vMd,
                      Text(
                        'No matching documents found',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _DocListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _expiringTab() {
    final theme = Theme.of(context);
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    
    return StreamBuilder<QuerySnapshot>(
      stream:
          siteId == null
              ? null
              : fs
                  .collection('compliance_docs')
                  .where('siteId', isEqualTo: siteId)
                  .where('daysUntilExpiry', isLessThanOrEqualTo: 90)
                  .orderBy('daysUntilExpiry')
                  .limit(50)
                  .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: XMTheme.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded, size: 48, color: XMTheme.success),
                ),
                GSpacing.vLg,
                Text(
                  'All Documents Up to Date',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                GSpacing.vSm,
                Text(
                  'No critical expiries in the next 90 days',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return _DocListItem(data: d, showExpiryContext: true);
          },
        );
      },
    );
  }

  Widget _legalTab() {
    final theme = Theme.of(context);
    final reqs = [
      ('Occupational Health and Safety Act 85 of 1993', 'Primary OHS legislation', Icons.gavel_rounded, XMTheme.riskExtreme),
      ('COIDA — Compensation for Injuries', 'Workplace injury framework', Icons.health_and_safety_rounded, XMTheme.riskHigh),
      ('General Safety Regulations (GSR)', 'Workplace safety standards', Icons.rule_folder_rounded, XMTheme.riskMedium),
      ('Hazardous Chemical Substances Regulations', 'Chemical safety management', Icons.science_rounded, XMTheme.error),
      ('Construction Regulations 2014', 'Construction management', Icons.construction_rounded, XMTheme.warning),
      ('National Environmental Management Act (NEMA)', 'Environmental compliance', Icons.eco_rounded, XMTheme.success),
      ('ISO 45001:2018', 'Occupational Health & Safety', Icons.verified_rounded, theme.colorScheme.primary),
      ('ISO 14001:2015', 'Environmental Management', Icons.nature_people_rounded, XMTheme.success),
      ('ISO 9001:2015', 'Quality Management', Icons.stars_rounded, theme.colorScheme.tertiary),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reqs.length,
      itemBuilder: (ctx, i) {
        final r = reqs[i];
        return GCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: r.$4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(r.$3, color: r.$4, size: 24),
              ),
              GSpacing.hLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.$1, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, height: 1.2)),
                    GSpacing.vSm,
                    Text(r.$2, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, color: theme.colorScheme.outlineVariant, size: 18),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Document Title *',
                  hintText: 'e.g., Forklift Operator License',
                  prefixIcon: Icon(Icons.description_rounded),
                ),
              ),
              GSpacing.vMd,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _refCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reference #',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                    ),
                  ),
                  GSpacing.hMd,
                  Expanded(
                    child: TextFormField(
                      controller: _ownerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Owner / Dept',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              GSpacing.vMd,
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _docType,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: ['Licence', 'Certificate', 'Permit', 'Policy', 'Procedure', 'Audit', 'Other']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => setLocalState(() => _docType = v!),
                    ),
                  ),
                  GSpacing.hMd,
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _docStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: ['Current', 'Under Review', 'Expired', 'Superseded']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => setLocalState(() => _docStatus = v!),
                    ),
                  ),
                ],
              ),
              GSpacing.vMd,
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _expiry,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime(2040),
                  );
                  if (d != null) setLocalState(() => _expiry = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 20, color: theme.colorScheme.primary),
                      GSpacing.hMd,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EXPIRY DATE', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1)),
                          Text(
                            '${_expiry.day} ${UIUtils.getMonthName(_expiry.month)} ${_expiry.year}',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              GSpacing.vXl,
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isSub ? null : () => _submit(context),
                  icon: _isSub
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.app_registration_rounded),
                  label: Text(_isSub ? 'REGISTERING...' : 'REGISTER DOCUMENT'),
                ),
              ),
              GSpacing.vXl,
            ],
          ),
        );
      },
    );
  }
}

class _DocListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool showExpiryContext;

  const _DocListItem({required this.data, this.showExpiryContext = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = data['daysUntilExpiry'] as int? ?? 999;

    Color statusColor = XMTheme.success;
    IconData statusIcon = Icons.check_circle_outline_rounded;

    if (days < 0) {
      statusColor = XMTheme.error;
      statusIcon = Icons.error_outline_rounded;
    } else if (days < 30) {
      statusColor = XMTheme.riskHigh;
      statusIcon = Icons.warning_amber_rounded;
    } else if (days < 90) {
      statusColor = XMTheme.warning;
      statusIcon = Icons.timer_outlined;
    }

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          GSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? 'Untitled Doc', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                GSpacing.vSm,
                Text('${data['documentType']} • ${data['referenceNumber'] ?? "No Ref"}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          GSpacing.hMd,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GStatusTag(label: days < 0 ? 'EXPIRED' : '${days}d', color: statusColor),
              if (showExpiryContext)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    UIUtils.formatTimestamp(data['expiryDate']).split(',').first,
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

