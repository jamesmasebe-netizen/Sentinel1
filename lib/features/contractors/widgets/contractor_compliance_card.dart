import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../models/safety_file_models.dart';

/// Real cross-contractor compliance overview — aggregates every contractor's
/// latest safety_file_submissions status instead of requiring a manager to
/// drill into each contractor individually. See F-223 in docs/fixes/FIX_LIST.md.
class ContractorComplianceCard extends ConsumerWidget {
  const ContractorComplianceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);
    if (tenantId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: fs.tenantCollection(tenantId, 'contractors').snapshots(),
      builder: (context, contractorSnap) {
        if (!contractorSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final contractors = contractorSnap.data!.docs;

        return StreamBuilder<QuerySnapshot>(
          stream: fs.tenantCollection(tenantId, 'safety_file_submissions').snapshots(),
          builder: (context, subSnap) {
            if (!subSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final submissions = subSnap.data!.docs
                .map((d) => SafetyFileSubmission.fromFirestore(d))
                .toList();

            // Latest submission per contractor
            final latestByContractor = <String, SafetyFileSubmission>{};
            for (final s in submissions) {
              final existing = latestByContractor[s.contractorId];
              if (existing == null || s.createdAt.isAfter(existing.createdAt)) {
                latestByContractor[s.contractorId] = s;
              }
            }

            final finalized = <QueryDocumentSnapshot>[];
            final needsAttention = <QueryDocumentSnapshot>[];
            final noSubmission = <QueryDocumentSnapshot>[];

            for (final c in contractors) {
              final latest = latestByContractor[c.id];
              if (latest == null) {
                noSubmission.add(c);
              } else if (latest.status == SubmissionStatus.finalized) {
                finalized.add(c);
              } else {
                needsAttention.add(c);
              }
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    _statCard('Compliant', finalized.length, XMTheme.success),
                    GSpacing.hMd,
                    _statCard('Needs Attention', needsAttention.length, XMTheme.warning),
                    GSpacing.hMd,
                    _statCard('No Safety File', noSubmission.length, XMTheme.error),
                  ],
                ),
                GSpacing.vLg,
                if (needsAttention.isNotEmpty) ...[
                  Text('Outstanding Safety Files', style: Theme.of(context).textTheme.titleMedium),
                  GSpacing.vSm,
                  ...needsAttention.map((c) {
                    final data = c.data() as Map<String, dynamic>;
                    final latest = latestByContractor[c.id]!;
                    return GCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.warning_amber, color: XMTheme.warning),
                        title: Text(data['companyName'] ?? 'Unknown Contractor'),
                        subtitle: Text('Status: ${latest.status.name}'),
                      ),
                    );
                  }),
                ],
                if (noSubmission.isNotEmpty) ...[
                  GSpacing.vMd,
                  Text('No Safety File Submitted', style: Theme.of(context).textTheme.titleMedium),
                  GSpacing.vSm,
                  ...noSubmission.map((c) {
                    final data = c.data() as Map<String, dynamic>;
                    return GCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.error_outline, color: XMTheme.error),
                        title: Text(data['companyName'] ?? 'Unknown Contractor'),
                        subtitle: const Text('No safety file submission on record'),
                      ),
                    );
                  }),
                ],
                if (needsAttention.isEmpty && noSubmission.isEmpty && contractors.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('All contractors are fully compliant.')),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Expanded(
      child: GCard(
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
            GSpacing.vXs,
            Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
