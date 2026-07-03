import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class EmployeePPEProfileSheet extends ConsumerWidget {
  final String employeeName;
  final Function(String) onLogNewCheck;

  const EmployeePPEProfileSheet({
    super.key,
    required this.employeeName,
    required this.onLogNewCheck,
  });

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'ppe_compliance')
          .where('siteId', isEqualTo: siteId)
          .where('employeeName', isEqualTo: employeeName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Active Equipment Logs', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                const Text('No logged equipment for this employee.')
              else
                ...docs.map((doc) {
                  final r = doc.data() as Map<String, dynamic>;
                  final status = r['status'] ?? 'Unknown';
                  Color statusColor;
                  switch (status) {
                    case 'Compliant': statusColor = XMTheme.success;
                    case 'Non-Compliant': statusColor = XMTheme.error;
                    case 'Expired': statusColor = XMTheme.warning;
                    default: statusColor = XMTheme.statusDraft;
                  }
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(r['ppeType'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Expires: ${_fmtDate(r['expiryDate'])}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GStatusTag(label: status, color: statusColor),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: XMTheme.error),
                            onPressed: () async {
                              final confirm = await UIUtils.showConfirmDialog(
                                context: context,
                                title: 'Delete Record',
                                content: 'Are you sure you want to delete this PPE record?',
                                isDestructive: true,
                              );
                              if (confirm) {
                                await firestore.tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'ppe_compliance').doc(doc.id).delete();
                                if (context.mounted) {
                                  UIUtils.showToast(context, 'Record deleted', type: ToastType.success);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onLogNewCheck(employeeName);
                },
                icon: const Icon(Icons.add),
                label: const Text('Log New Check'),
              ),
            ],
          ),
        );
      },
    );
  }
}
