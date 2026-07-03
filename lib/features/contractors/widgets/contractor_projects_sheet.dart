import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'safety_file_submission_view.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class ContractorProjectsSheet extends ConsumerStatefulWidget {
  final String contractorId;
  final String contractorName;

  const ContractorProjectsSheet({
    super.key,
    required this.contractorId,
    required this.contractorName,
  });

  static void show(BuildContext context, String contractorId, String contractorName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ContractorProjectsSheet(
        contractorId: contractorId,
        contractorName: contractorName,
      ),
    );
  }

  @override
  ConsumerState<ContractorProjectsSheet> createState() => _ContractorProjectsSheetState();
}

class _ContractorProjectsSheetState extends ConsumerState<ContractorProjectsSheet> {
  Future<List<Map<String, dynamic>>> _fetchProjectsForContractor(String contractorId) async {
    final fs = FirebaseFirestore.instance;
    final siteId = ref.read(currentTenantIdProvider);

    final projectsQ = await fs.tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'projects')
        .where('siteId', isEqualTo: siteId)
        .get();

    final results = <Map<String, dynamic>>[];
    for (final doc in projectsQ.docs) {
      final projectId = doc.id;
      final contractorLink = await fs.tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'projects').doc(projectId).collection('contractors').doc(contractorId).get();
      if (!contractorLink.exists) continue;

      final project = doc.data();

      final subQ = await fs.tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'safetyFileSubmissions')
          .where('contractorId', isEqualTo: contractorId)
          .where('projectId', isEqualTo: projectId)
          .limit(1).get();

      Map<String, dynamic>? submission;
      if (subQ.docs.isNotEmpty) {
        submission = subQ.docs.first.data();
      }

      results.add({'project': project, 'projectId': projectId, 'submission': submission});
    }
    return results;
  }

  void _showSafetyFile(BuildContext context, String contractorId, String projectId, String projectName) {
    UIUtils.showSideSheet(
      context: context,
      title: 'Safety File: $projectName',
      builder: (ctx) => SafetyFileSubmissionView(
        contractorId: contractorId,
        projectId: projectId,
      ),
    );
  }

  Widget _summaryPill(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: XMTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.engineering_rounded, color: XMTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.contractorName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Active project assignments', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchProjectsForContractor(widget.contractorId),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                  final entries = snap.data!;

                  if (entries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_off_rounded, size: 56, color: Theme.of(context).colorScheme.outlineVariant),
                          const SizedBox(height: 16),
                          const Text('No active projects assigned.'),
                        ],
                      ),
                    );
                  }

                  final approvedCount = entries.where((e) => (e['submission'] as Map<String, dynamic>?)?['status'] == 'finalized').length;
                  final pendingCount = entries.length - approvedCount;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          children: [
                            _summaryPill(context, '${entries.length} Projects', XMTheme.primary),
                            const SizedBox(width: 8),
                            _summaryPill(context, '$approvedCount OHS Approved', XMTheme.success),
                            const SizedBox(width: 8),
                            _summaryPill(context, '$pendingCount Pending', XMTheme.warning),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final project = entry['project'] as Map<String, dynamic>;
                            final projectId = entry['projectId'] as String;
                            final submission = entry['submission'] as Map<String, dynamic>?;

                            final projectName = project['name'] ?? 'Unnamed Project';
                            final category = project['category'] ?? '';
                            final status = project['status'] ?? 'Active';
                            final progress = (project['overallProgress'] as num?)?.toDouble() ?? 0.0;

                            String ohsStatus = 'Not Submitted';
                            Color ohsColor = Colors.grey;
                            double ohsScore = 0.0;

                            if (submission != null) {
                              final rawStatus = submission['status'] ?? 'pending';
                              ohsScore = (submission['score'] as num?)?.toDouble() ?? 0.0;
                              switch (rawStatus) {
                                case 'finalized': ohsStatus = 'OHS Approved'; ohsColor = XMTheme.success; break;
                                case 'underReview': ohsStatus = 'Under Review'; ohsColor = XMTheme.warning; break;
                                case 'requiresRevision': ohsStatus = 'Needs Revision'; ohsColor = XMTheme.error; break;
                                default: ohsStatus = 'Pending'; ohsColor = XMTheme.info;
                              }
                            }

                            return GCard(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              onTap: () => _showSafetyFile(context, widget.contractorId, projectId, projectName),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(projectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            Text('$category • $status', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: ohsColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                        child: Text(ohsStatus, style: TextStyle(fontSize: 10, color: ohsColor, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Text('Progress', style: TextStyle(fontSize: 11)),
                                      const Spacer(),
                                      Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: XMTheme.primary.withValues(alpha: 0.1),
                                    valueColor: const AlwaysStoppedAnimation<Color>(XMTheme.primary),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  if (submission != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.shield_rounded, size: 12, color: ohsColor),
                                        const SizedBox(width: 4),
                                        Text('OHS Score: ${ohsScore.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: ohsColor, fontWeight: FontWeight.w600)),
                                        const Spacer(),
                                        Text('Tap to view file →', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
