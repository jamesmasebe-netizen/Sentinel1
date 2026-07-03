import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'doc_list_item.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class RegisterTab extends ConsumerStatefulWidget {
  const RegisterTab({super.key});

  @override
  ConsumerState<RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends ConsumerState<RegisterTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final siteId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              hintText: 'Search by document title or reference...',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                siteId == null
                    ? null
                    : fs
                        .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'compliance_docs')
                        .where('siteId', isEqualTo: siteId)
                        .orderBy('createdAt', descending: true)
                        .limit(100)
                        .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var docs = snap.data?.docs ?? [];
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final ref = (data['referenceNumber'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery) || ref.contains(_searchQuery);
                }).toList();
              }
              
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_off_outlined, size: 64, color: theme.colorScheme.outline),
                      GSpacing.vMd,
                      Text(
                        'No matching documents found',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return DocListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
