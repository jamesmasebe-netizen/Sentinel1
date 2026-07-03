import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../config/theme.dart';
import '../../../../../core/providers/app_providers.dart';
import '../../../../../core/utils/ui_utils.dart';
import '../../../../../core/widgets/ds_widgets.dart';
import '../../models/project_models.dart';
import '../../../contractors/screens/contractor_management_screen.dart';
import 'contractor_card_ohs_row.dart';

class ContractorCard extends ConsumerWidget {
  final String contractorId;
  final Project project;
  final VoidCallback onRemove;
  final void Function(BuildContext, String, String, String, String?) onShowOHS;

  const ContractorCard({
    super.key,
    required this.contractorId,
    required this.project,
    required this.onRemove,
    required this.onShowOHS,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreProvider);
    final tenantId = ref.watch(currentTenantIdProvider) ?? "";

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchContractorWithOHS(fs, tenantId, contractorId, project.id),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }

        final data = snap.data!;
        final contractor = data['contractor'] as Map<String, dynamic>? ?? {};
        final submission = data['submission'] as Map<String, dynamic>?;
        final submissionId = data['submissionId'] as String?;

        final companyName = contractor['companyName'] ?? 'Unknown Contractor';
        final scopeOfWork = contractor['scopeOfWork'] ?? '';
        final riskRating = contractor['riskRating'] ?? 'Medium';
        final subcontractors =
            contractor['subcontractors'] as List<dynamic>? ?? [];

        String ohsStatus = 'Not Submitted';
        Color ohsColor = Colors.grey;
        double ohsScore = 0.0;

        if (submission != null) {
          final rawStatus = submission['status'] ?? 'pending';
          ohsScore = (submission['score'] as num?)?.toDouble() ?? 0.0;
          switch (rawStatus) {
            case 'finalized':
              ohsStatus = 'Approved';
              ohsColor = XMTheme.success;
              break;
            case 'underReview':
              ohsStatus = 'Under Review';
              ohsColor = XMTheme.warning;
              break;
            case 'requiresRevision':
              ohsStatus = 'Needs Revision';
              ohsColor = XMTheme.error;
              break;
            default:
              ohsStatus = 'Pending';
              ohsColor = XMTheme.info;
          }
        }

        return GCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: XMTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.engineering_rounded,
                      color: XMTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (scopeOfWork.isNotEmpty)
                          Text(
                            scopeOfWork,
                            style: TextStyle(
                              fontSize: 12,
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
                  GStatusTag(
                    label: riskRating,
                    color:
                        riskRating == 'High' || riskRating == 'Critical'
                            ? XMTheme.error
                            : riskRating == 'Medium'
                            ? XMTheme.warning
                            : XMTheme.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // OHS Status Row
              ContractorCardOhsRow(
                ohsStatus: ohsStatus,
                ohsColor: ohsColor,
                submission: submission,
                ohsScore: ohsScore,
                onViewFile:
                    () => onShowOHS(
                      context,
                      contractorId,
                      project.id,
                      companyName,
                      submissionId,
                    ),
              ),
              // Subcontractors
              if (subcontractors.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Subcontractors (${subcontractors.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children:
                      subcontractors
                          .map(
                            (sub) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sub.toString(),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      UIUtils.showSideSheet(
                        context: context,
                        title: 'Contractor Management',
                        builder: (ctx) => const ContractorManagementScreen(),
                      );
                    },
                    icon: const Icon(Icons.edit_document, size: 16),
                    label: const Text('Scope', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      UIUtils.showSideSheet(
                        context: context,
                        title: 'Contractor Management',
                        builder: (ctx) => const ContractorManagementScreen(),
                      );
                    },
                    icon: const Icon(Icons.group_add_rounded, size: 16),
                    label: const Text('Subs', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.person_remove_rounded, size: 16),
                    label: const Text('Remove', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: XMTheme.error),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchContractorWithOHS(
    dynamic fs,
    String tenantId,
    String contractorId,
    String projectId,
  ) async {
    final contractorDoc =
        await fs
            .tenantCollection(tenantId, 'contractors')
            .doc(contractorId)
            .get();
    final contractor =
        contractorDoc.exists
            ? (contractorDoc.data() as Map<String, dynamic>)
            : <String, dynamic>{};

    final submissionQuery =
        await fs
            .tenantCollection(tenantId, 'safetyFileSubmissions')
            .where('contractorId', isEqualTo: contractorId)
            .where('projectId', isEqualTo: projectId)
            .limit(1)
            .get();

    Map<String, dynamic>? submission;
    String? submissionId;
    if (submissionQuery.docs.isNotEmpty) {
      submission = submissionQuery.docs.first.data() as Map<String, dynamic>;
      submissionId = submissionQuery.docs.first.id;
    }

    return {
      'contractor': contractor,
      'submission': submission,
      'submissionId': submissionId,
    };
  }
}
