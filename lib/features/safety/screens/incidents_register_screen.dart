import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Status filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['All', 'Open', 'Investigating', 'Resolved', 'Closed']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setState(() => _filterStatus = v!),
                ),
              ),
              const SizedBox(width: 12),
              // Severity filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterSeverity,
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      Icon(Icons.check_circle_outline, size: 48, color: XMTheme.success.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text('No incidents found'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: XMTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: XMTheme.error),
        );
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showIncidentDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
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
                  const SizedBox(width: 10),
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
                  _StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 10),

              // Info chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _InfoChip(icon: Icons.warning, label: severity, color: _sevColor(severity)),
                  if (data['location'] != null && data['location'].toString().isNotEmpty)
                    _InfoChip(icon: Icons.location_on, label: data['location'], color: XMTheme.info),
                  if (dateStr.isNotEmpty)
                    _InfoChip(icon: Icons.access_time, label: _formatDate(dateStr), color: XMTheme.primary),
                  if (data['totalCost'] != null && (data['totalCost'] as num) > 0)
                    _InfoChip(icon: Icons.attach_money, label: 'R${data['totalCost']}', color: XMTheme.warning),
                ],
              ),

              // Quick status actions
              const SizedBox(height: 8),
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
          ),
        ),
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
                _StatusChip(status: data['status'] ?? 'Open'),
                Chip(
                  label: Text(data['severity'] ?? 'Minor'),
                  backgroundColor: _sevColor(data['severity'] ?? 'Minor').withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: _sevColor(data['severity'] ?? 'Minor'), fontSize: 12, fontWeight: FontWeight.bold),
                  side: BorderSide.none,
                ),
                Chip(
                  label: Text(data['type'] ?? 'Unknown'),
                  side: BorderSide.none,
                ),
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

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Color _sevColor(String severity) {
    switch (severity) {
      case 'Critical': return XMTheme.severityCritical;
      case 'Major': return XMTheme.severityMajor;
      case 'Moderate': return XMTheme.severityModerate;
      case 'Minor': return XMTheme.severityMinor;
      default: return XMTheme.severityNegligible;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Open': color = XMTheme.statusOpen;
      case 'Investigating': color = XMTheme.statusInProgress;
      case 'Resolved': color = XMTheme.statusResolved;
      case 'Closed': color = XMTheme.statusClosed;
      default: color = XMTheme.statusDraft;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(XMTheme.radiusXl), // Fully rounded pill
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(XMTheme.radiusXl), // Fully rounded pill
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
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
