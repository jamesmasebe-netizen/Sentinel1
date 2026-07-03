import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../widgets/permit_card.dart';
import '../widgets/permit_form_sheet.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

/// Permit to Work module — create, approve, and manage permits.
/// Mirrors React PermitToWork: types, LOTO, contractor compliance gate, status workflow.
class PermitToWorkScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? highlightId;

  const PermitToWorkScreen({
    super.key,
    this.initialSearch,
    this.highlightId,
  });

  @override
  ConsumerState<PermitToWorkScreen> createState() => _PermitToWorkScreenState();
}

class _PermitToWorkScreenState extends ConsumerState<PermitToWorkScreen> {

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      // _search = widget.initialSearch!;
    }
    if (widget.highlightId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
                UIUtils.showSideSheet(
          context: context,
          title: 'Item Details',
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Viewing item: ${widget.highlightId}\n(Detail view not yet implemented)'),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);

    final isExecutive = ref.watch(isExecutiveProvider);

    if (siteId == null) {
      return const Center(child: Text('No site assigned'));
    }

    return Column(
      children: [
        GHeader(
          title: 'Permit to Work',
          subtitle: 'Manage and approve site access permits',
          trailing: FilledButton.icon(
            onPressed: () => showPermitForm(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Request Permit'),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'permits')
                .where('siteId', isEqualTo: siteId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                      GSpacing.vMd,
                      const Text('No permits found'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return PermitCard(
                    docId: doc.id,
                    data: data,
                    canApprove: isExecutive,
                    onStatusUpdate: (newStatus) async {
                      await firestore.tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'permits').doc(doc.id).update({
                        'status': newStatus,
                        'updatedAt': DateTime.now().toIso8601String(),
                      });
                      if (context.mounted) {
                        UIUtils.showToast(context, 'Status updated to $newStatus', type: ToastType.success);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
