import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'contractor_projects_sheet.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class ContractorList extends ConsumerStatefulWidget {
  final String searchQuery;
  final String statusFilter;

  const ContractorList({
    super.key,
    required this.searchQuery,
    required this.statusFilter,
  });

  @override
  ConsumerState<ContractorList> createState() => _ContractorListState();
}



class _ContractorListState extends ConsumerState<ContractorList> {


  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);

    return StreamBuilder<QuerySnapshot>(
      stream: siteId == null
          ? null
          : fs
              .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'contractors')
              .where('siteId', isEqualTo: siteId)
              .orderBy('createdAt', descending: true)
              .limit(100)
              .snapshots(),
      builder: (ctx, snap) {
        var docs = snap.data?.docs ?? [];
        if (widget.searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['companyName'] ?? '').toString().toLowerCase().contains(widget.searchQuery);
          }).toList();
        }
        if (widget.statusFilter != 'All') {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['status'] == widget.statusFilter;
          }).toList();
        }
        if (docs.isEmpty) {
          return const Center(child: Text('No contractors found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final riskRating = d['riskRating'] ?? 'Medium';
            final status = d['status'] ?? 'Active';
            final contractorId = docs[i].id;

            return GestureDetector(
              onTap: () {
                ContractorProjectsSheet.show(context, contractorId, d['companyName'] ?? 'Contractor');
              },
              child: GCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['companyName'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${d['contactPerson'] ?? ''} • ${d['scopeOfWork'] ?? ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GStatusTag(
                          label: riskRating,
                          color: riskRating == 'Critical' || riskRating == 'High'
                              ? XMTheme.error
                              : riskRating == 'Medium'
                                  ? XMTheme.warning
                                  : XMTheme.success,
                        ),
                        GSpacing.vSm,
                        GStatusTag(
                          label: status,
                          color: status == 'Active' ? XMTheme.success : XMTheme.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
