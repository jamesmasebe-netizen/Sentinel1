import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../config/theme.dart';
import '../../../../../core/providers/app_providers.dart';
import '../../../../../core/utils/ui_utils.dart';
import '../../models/project_models.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

void showAssignContractorDialog(
  BuildContext context,
  Project project,
  WidgetRef ref,
  List<String> contractorIds,
) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Quick Assign Contractor'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: FutureBuilder<QuerySnapshot>(
            future:
                ref
                    .read(firestoreProvider)
                    .tenantCollection(
                      ref.watch(currentTenantIdProvider) ?? "",
                      'contractors',
                    )
                    .where('siteId', isEqualTo: project.tenantId)
                    .get(),
            builder: (c, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final contractors = snap.data!.docs;
              final available =
                  contractors
                      .where((doc) => !contractorIds.contains(doc.id))
                      .toList();

              if (available.isEmpty) {
                return const Center(
                  child: Text('No available contractors found.'),
                );
              }

              return ListView.builder(
                itemCount: available.length,
                itemBuilder: (cc, i) {
                  final cData = available[i].data() as Map<String, dynamic>;
                  final expiry =
                      (cData['safetyFileExpiry'] as Timestamp?)?.toDate();
                  final isExpired =
                      expiry != null && expiry.isBefore(DateTime.now());

                  return ListTile(
                    leading: Icon(
                      isExpired
                          ? Icons.warning_rounded
                          : Icons.engineering_rounded,
                      color: isExpired ? XMTheme.error : XMTheme.primary,
                    ),
                    title: Text(cData['companyName'] ?? 'Unknown'),
                    subtitle: Text(
                      isExpired ? 'Safety File Expired!' : 'Valid',
                      style: TextStyle(
                        color: isExpired ? XMTheme.error : XMTheme.success,
                        fontSize: 12,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () async {
                        try {
                          await ref
                              .read(firestoreProvider)
                              .tenantCollection(
                                ref.watch(currentTenantIdProvider) ?? "",
                                'projects',
                              )
                              .doc(project.id)
                              .collection('contractors')
                              .doc(available[i].id)
                              .set({});
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            UIUtils.showToast(
                              context,
                              'Contractor assigned.',
                              type: ToastType.success,
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            UIUtils.showToast(
                              context,
                              'Error: $e',
                              type: ToastType.error,
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
