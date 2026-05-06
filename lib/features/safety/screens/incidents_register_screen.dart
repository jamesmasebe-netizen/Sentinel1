import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/utils/ui_utils.dart';

/// Incidents register — real-time list with filters, severity chips, and status updates.
/// Mirrors the React "register" tab of IncidentsCAPA.
class IncidentsRegisterScreen extends ConsumerStatefulWidget {
  const IncidentsRegisterScreen({super.key});

  @override
  ConsumerState<IncidentsRegisterScreen> createState() => _IncidentsRegisterScreenState();
}

class _IncidentsRegisterScreenState extends ConsumerState<IncidentsRegisterScreen> {
  String _filterStatus = 'All';
  String _filterSeverity = 'All';

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);

    if (siteId == null) {
      return const Center(child: Text('No site assigned'));
    }

    return Column(
      children: [
        // ─── Filter Bar ───
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.filter_list_rounded, size: 18),
                    isDense: true,
                  ),
                  items: ['All', 'Open', 'Investigating', 'Resolved', 'Closed']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setState(() => _filterStatus = v!),
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterSeverity,
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    prefixIcon: Icon(Icons.warning_amber_rounded, size: 18),
                    isDense: true,
                  ),
                  items: ['All', 'Minor', 'Moderate', 'Major', 'Critical']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setState(() => _filterSeverity = v!),
                ),
              ),
            ],
          ),
        ),

        // ─── Incident List ───
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('incidents')
                .where('siteId', isEqualTo: siteId)
                .orderBy('createdAt', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const HubSkeleton();
              }

              final docs = snapshot.data?.docs ?? [];

              // Client-side filtering
              final filtered = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (_filterStatus != 'All' && data['status'] != _filterStatus) return false;
                if (_filterSeverity != 'All' && data['severity'] != _filterSeverity) return false;
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: XMTheme.success.withValues(alpha: 0.3)),
                      GSpacing.vMd,
                      Text('No incidents found', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _IncidentCard(
                    docId: doc.id,
                    data: data,
                    onStatusUpdate: (newStatus) => _updateStatus(doc.id, newStatus),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('incidents').doc(docId).update({
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        UIUtils.showToast(context, 'Status updated to $newStatus', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error updating status: $e', type: ToastType.error);
      }
    }
  }

}

class _IncidentCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final void Function(String) onStatusUpdate;

  const _IncidentCard({
    required this.docId,
    required this.data,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final severity = data['severity'] ?? 'Minor';
    final status = data['status'] ?? 'Open';
    final type = data['type'] ?? 'Unknown';
    final title = data['title'] ?? 'Untitled';
    final reporter = data['reporterName'] ?? 'Unknown';
    final dateStr = data['dateOfIncident'] ?? data['createdAt'] ?? '';
    final isAnonymous = data['isAnonymous'] == true;

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _showIncidentDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _sevColor(severity).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.report_problem, color: _sevColor(severity), size: 18),
              ),
              GSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${type.toString().replaceAll('_', ' ')} • ${isAnonymous ? "Anonymous" : reporter}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              GStatusTag(label: status, color: _statusColor(status)),
            ],
          ),
          GSpacing.vMd,
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MiniInfo(icon: Icons.warning_amber_rounded, label: severity, color: _sevColor(severity)),
              if (data['location'] != null && data['location'].toString().isNotEmpty)
                _MiniInfo(icon: Icons.location_on_outlined, label: data['location']),
              if (dateStr.isNotEmpty)
                _MiniInfo(icon: Icons.access_time_rounded, label: UIUtils.formatTimestamp(dateStr)),
              if (data['totalCost'] != null && (data['totalCost'] as num) > 0)
                _MiniInfo(icon: Icons.attach_money_rounded, label: 'R${data['totalCost']}', color: XMTheme.warning),
            ],
          ),
          if (status != 'Closed') ...[
            GSpacing.vSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'Open')
                  TextButton.icon(
                    onPressed: () => onStatusUpdate('Investigating'),
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Investigate', style: TextStyle(fontSize: 12)),
                  ),
                if (status == 'Investigating')
                  TextButton.icon(
                    onPressed: () => onStatusUpdate('Resolved'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Resolve', style: TextStyle(fontSize: 12)),
                  ),
                if (status == 'Resolved')
                  TextButton.icon(
                    onPressed: () => onStatusUpdate('Closed'),
                    icon: const Icon(Icons.lock, size: 16),
                    label: const Text('Close', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showIncidentDetail(BuildContext context) {
    UIUtils.showSideSheet(
      context: context,
      title: 'Incident Details',
      width: 500, // Slightly narrower for details
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['title'] ?? 'Untitled', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                GStatusTag(label: data['status'] ?? 'Open', color: _statusColor(data['status'] ?? 'Open')),
                GStatusTag(label: data['severity'] ?? 'Minor', color: _sevColor(data['severity'] ?? 'Minor')),
                GStatusTag(label: data['type'] ?? 'Unknown', color: XMTheme.primary),
              ],
            ),
            const Divider(height: 32),
            Text('Description', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(data['description'] ?? 'No description', style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 24),
            if (data['location'] != null) ...[
              _DetailRow(icon: Icons.location_on, label: 'Location', value: data['location']),
            ],
            _DetailRow(icon: Icons.person, label: 'Reporter', value: data['isAnonymous'] == true ? 'Anonymous' : data['reporterName'] ?? 'Unknown'),
            if (data['contractorName'] != null)
              _DetailRow(icon: Icons.engineering, label: 'Contractor', value: data['contractorName']),
            if (data['totalCost'] != null && (data['totalCost'] as num) > 0)
              _DetailRow(icon: Icons.attach_money, label: 'Total Cost', value: 'R${data['totalCost']}'),
            if (data['photoUrl'] != null) ...[
              const SizedBox(height: 24),
              Text('Photo Evidence', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(data['photoUrl'], height: 250, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 40), // Padding at bottom
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Open': return XMTheme.statusOpen;
      case 'Investigating': return XMTheme.statusInProgress;
      case 'Resolved': return XMTheme.statusResolved;
      case 'Closed': return XMTheme.statusClosed;
      default: return XMTheme.statusDraft;
    }
  }

  Color _sevColor(String sev) {
    switch (sev) {
      case 'Critical': return XMTheme.severityCritical;
      case 'Major': return XMTheme.severityMajor;
      case 'Moderate': return XMTheme.severityModerate;
      case 'Minor': return XMTheme.severityMinor;
      default: return XMTheme.severityNegligible;
    }
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MiniInfo({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: c)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
