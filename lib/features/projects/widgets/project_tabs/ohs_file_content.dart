import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../config/theme.dart';
import '../../../../../core/providers/app_providers.dart';

class OHSFileContent extends ConsumerWidget {
  final String contractorId;
  final String projectId;

  const OHSFileContent({
    super.key,
    required this.contractorId,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreProvider);
    final tenantId = ref.watch(currentTenantIdProvider) ?? "";

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadOHSData(fs, tenantId),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final submission = snap.data!['submission'] as Map<String, dynamic>?;
        final findings = snap.data!['findings'] as List<Map<String, dynamic>>;

        if (submission == null) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.folder_off_rounded,
                  size: 56,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No safety file submitted yet for this project.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final rawStatus = submission['status'] ?? 'pending';
        final score = (submission['score'] as num?)?.toDouble() ?? 0.0;
        Color statusColor;
        String statusLabel;
        switch (rawStatus) {
          case 'finalized':
            statusColor = XMTheme.success;
            statusLabel = 'Approved';
            break;
          case 'underReview':
            statusColor = XMTheme.warning;
            statusLabel = 'Under Review';
            break;
          case 'requiresRevision':
            statusColor = XMTheme.error;
            statusLabel = 'Needs Revision';
            break;
          default:
            statusColor = XMTheme.info;
            statusLabel = 'Pending';
        }

        final open = findings.where((f) => f['status'] == 'open').length;
        final major = findings.where((f) => f['type'] == 'majorNc').length;
        final minor = findings.where((f) => f['type'] == 'minorNc').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(
                    rawStatus == 'finalized'
                        ? Icons.verified_rounded
                        : Icons.pending_actions_rounded,
                    color: statusColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Submitted for this project',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${score.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Score bar
            Row(
              children: [
                const Text(
                  'Compliance Score',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  '${score.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 8,
                backgroundColor: statusColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 20),
            // Findings summary
            Text(
              'Findings Summary',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _findingChip(context, 'Open', open.toString(), XMTheme.error),
                const SizedBox(width: 10),
                _findingChip(
                  context,
                  'Major NC',
                  major.toString(),
                  XMTheme.error,
                ),
                const SizedBox(width: 10),
                _findingChip(
                  context,
                  'Minor NC',
                  minor.toString(),
                  XMTheme.warning,
                ),
                const SizedBox(width: 10),
                _findingChip(
                  context,
                  'Total',
                  findings.length.toString(),
                  XMTheme.info,
                ),
              ],
            ),
            if (findings.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Findings Detail',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...findings.map((f) {
                final fType = f['type'] ?? 'observation';
                final fStatus = f['status'] ?? 'open';
                final color =
                    fType == 'majorNc'
                        ? XMTheme.error
                        : fType == 'minorNc'
                        ? XMTheme.warning
                        : XMTheme.info;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        color: color,
                        margin: const EdgeInsets.only(right: 10),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              f['description'] ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),
                            if ((f['contractorAction'] ?? '').isNotEmpty)
                              Text(
                                'Action: ${f['contractorAction']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (fStatus == 'open'
                                  ? XMTheme.error
                                  : XMTheme.success)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          fStatus,
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                fStatus == 'open'
                                    ? XMTheme.error
                                    : XMTheme.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _findingChip(
    BuildContext context,
    String label,
    String count,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 18,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadOHSData(dynamic fs, String tenantId) async {
    final subQ =
        await fs
            .tenantCollection(tenantId, 'safetyFileSubmissions')
            .where('contractorId', isEqualTo: contractorId)
            .where('projectId', isEqualTo: projectId)
            .limit(1)
            .get();

    if (subQ.docs.isEmpty) {
      return {'submission': null, 'findings': <Map<String, dynamic>>[]};
    }

    final subDoc = subQ.docs.first;
    final submission = subDoc.data() as Map<String, dynamic>;
    final submissionId = subDoc.id;

    final findingsQ =
        await fs
            .tenantCollection(tenantId, 'findings')
            .where('submissionId', isEqualTo: submissionId)
            .get();

    final findings =
        findingsQ.docs.map((d) => d.data() as Map<String, dynamic>).toList();

    return {'submission': submission, 'findings': findings};
  }
}
