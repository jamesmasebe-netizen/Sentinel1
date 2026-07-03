import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';
import 'assign_contractor_dialog.dart';
import 'ohs_file_content.dart';
import 'contractor_card.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class ContractorsTab extends ConsumerWidget {
  final Project project;
  const ContractorsTab({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(firestoreProvider);
    final contractorIdsAsync = ref.watch(
      projectContractorsProvider(project.id),
    );

    return contractorIdsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data:
          (contractorIds) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Assigned Contractors',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Quick Assign'),
                      onPressed:
                          () => showAssignContractorDialog(
                            context,
                            project,
                            ref,
                            contractorIds,
                          ),
                    ),
                  ],
                ),
              ),
              if (contractorIds.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.engineering_rounded,
                          size: 56,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        const Text('No contractors linked to this project.'),
                        const SizedBox(height: 8),
                        Text(
                          'Click Quick Assign to add a contractor.',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: contractorIds.length,
                    itemBuilder: (context, index) {
                      final contractorId = contractorIds[index];

                      return ContractorCard(
                        contractorId: contractorId,
                        project: project,
                        onRemove: () {
                          showDialog(
                            context: context,
                            builder:
                                (ctx) => AlertDialog(
                                  title: const Text('Remove Contractor'),
                                  content: const Text(
                                    'Are you sure you want to remove this contractor from this project?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        try {
                                          await fs
                                              .tenantCollection(
                                                ref.watch(
                                                      currentTenantIdProvider,
                                                    ) ??
                                                    "",
                                                'projects',
                                              )
                                              .doc(project.id)
                                              .collection('contractors')
                                              .doc(contractorId)
                                              .delete();
                                          if (context.mounted) {
                                            UIUtils.showToast(
                                              context,
                                              'Contractor removed from project.',
                                              type: ToastType.success,
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            UIUtils.showToast(
                                              context,
                                              'Failed to remove contractor: $e',
                                              type: ToastType.error,
                                            );
                                          }
                                        }
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: XMTheme.error,
                                      ),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                          );
                        },
                        onShowOHS: _showOHSPanel,
                      );
                    },
                  ),
                ),
            ],
          ),
    );
  }

  void _showOHSPanel(
    BuildContext context,
    String contractorId,
    String projectId,
    String contractorName,
    String? submissionId,
  ) {
    _openSafetyFileSheet(context, contractorId, projectId, contractorName);
  }

  void _openSafetyFileSheet(
    BuildContext context,
    String contractorId,
    String projectId,
    String contractorName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            minChildSize: 0.4,
            builder:
                (ctx, scrollCtrl) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.health_and_safety_rounded,
                              color: XMTheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'OHS Safety File',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    contractorName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.all(20),
                          child: OHSFileContent(
                            contractorId: contractorId,
                            projectId: projectId,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
