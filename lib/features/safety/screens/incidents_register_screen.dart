import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/utils/ui_utils.dart';
import '../widgets/incident_card.dart';
import '../widgets/mini_summary_card.dart';
import 'incident_report_form.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class IncidentsRegisterScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? highlightId;
  const IncidentsRegisterScreen({super.key, this.initialSearch, this.highlightId});
  @override
  ConsumerState<IncidentsRegisterScreen> createState() => _IncidentsRegisterScreenState();
}

class _IncidentsRegisterScreenState extends ConsumerState<IncidentsRegisterScreen> {
  String _filterStatus = 'All';
  String _filterSeverity = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      // _search = widget.initialSearch!;
    }
    if (widget.highlightId != null) WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'incidents').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(100).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const HubSkeleton();
        final docs = snapshot.data?.docs ?? [];
        final totalInc = docs.length;
        final openInc = docs.where((d) => d.get('status') != 'Closed').length;
        final injuryCount = docs.where((d) => d.get('type') == 'Injury').length;
        final nearMissCount = docs.where((d) => d.get('type') == 'Near Miss').length;
        final otherCount = totalInc - injuryCount - nearMissCount;

        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (_filterStatus != 'All' && data['status'] != _filterStatus) return false;
          if (_filterSeverity != 'All' && data['severity'] != _filterSeverity) return false;
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  MiniSummaryCard(label: 'Total Incidents', count: '$totalInc', color: XMTheme.info), GSpacing.hSm,
                  MiniSummaryCard(label: 'Open', count: '$openInc', color: XMTheme.error), GSpacing.hSm,
                  MiniSummaryCard(label: 'Injuries', count: '$injuryCount', color: Colors.orange), GSpacing.hSm,
                  MiniSummaryCard(label: 'Near Misses', count: '$nearMissCount', color: XMTheme.warning), GSpacing.hSm,
                  MiniSummaryCard(label: 'Other', count: '$otherCount', color: XMTheme.success),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, value: _filterStatus,
                      decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.filter_list_rounded, size: 18), isDense: true),
                      items: ['All', 'Open', 'Investigating', 'Resolved', 'Closed'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) => setState(() => _filterStatus = v!),
                    ),
                  ),
                  GSpacing.hMd,
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, value: _filterSeverity,
                      decoration: const InputDecoration(labelText: 'Severity', prefixIcon: Icon(Icons.warning_amber_rounded, size: 18), isDense: true),
                      items: ['All', 'Minor', 'Moderate', 'Major', 'Critical'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) => setState(() => _filterSeverity = v!),
                    ),
                  ),
                  GSpacing.hMd,
                  FilledButton.icon(
                    onPressed: () => UIUtils.showSideSheet(context: context, title: 'Report Incident', builder: (ctx) => IncidentReportForm(tenantId: ref.read(currentTenantIdProvider) ?? '')),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    icon: const Icon(Icons.add, size: 18), label: const Text('Log Incident', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_outline, size: 48, color: XMTheme.success.withValues(alpha: 0.3)), GSpacing.vMd, Text('No incidents found', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))]))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        return IncidentCard(docId: doc.id, data: doc.data() as Map<String, dynamic>, onStatusUpdate: (s) => _updateStatus(doc.id, s));
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    try {
      await ref.read(firestoreProvider).tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'incidents').doc(docId).update({'status': newStatus, 'updatedAt': DateTime.now().toIso8601String()});
      if (mounted) UIUtils.showToast(context, 'Status updated to $newStatus', type: ToastType.success);
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Error updating status: $e', type: ToastType.error);
    }
  }
}
