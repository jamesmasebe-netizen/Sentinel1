import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../utils/ui_utils.dart';
import '../services/offline_sync_service.dart';
import '../../config/theme.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class SyncIndicator extends StatelessWidget {
  final SyncStatus status;
  final int pendingCount;

  const SyncIndicator({
    super.key,
    required this.status,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String tooltip;

    switch (status) {
      case SyncStatus.synced:
        icon = Icons.cloud_done;
        color = XMTheme.success;
        tooltip = 'All changes saved to cloud';
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = XMTheme.info;
        tooltip = 'Saving...';
        break;
      case SyncStatus.pending:
        icon = Icons.cloud_upload;
        color = XMTheme.warning;
        tooltip = '$pendingCount items waiting to sync';
        break;
      case SyncStatus.error:
        icon = Icons.cloud_off;
        color = XMTheme.error;
        tooltip = 'Sync failed. Working offline.';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            if (pendingCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$pendingCount',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GlobalSearchDelegate extends SearchDelegate<String> {
  final String tenantId;
  GlobalSearchDelegate(this.tenantId);
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('Enter a search term'));
    }

    return FutureBuilder<List<DocumentSnapshot>>(
      future: _performGlobalSearch(query.trim()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const Center(child: Text('No results found.'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final doc = results[index];
            final data = doc.data() as Map<String, dynamic>;
            final collection = doc.reference.parent.id;

            String title = 'Unknown';
            String subtitle = 'Collection: $collection';

            if (collection == 'incidents') {
              title = data['title'] ?? 'Incident';
            } else if (collection == 'projects') {
              title = data['name'] ?? 'Project';
            } else if (collection == 'employees') {
              title = '${data['firstName']} ${data['lastName']}';
            }

            return ListTile(
              leading: const Icon(Icons.search),
              title: Text(title),
              subtitle: Text(subtitle),
              onTap: () {
                close(context, '');
                if (collection == 'incidents') {
                  UIUtils.showSideSheet(
                    context: context,
                    title: 'Incident Detail',
                    builder:
                        (ctx) => Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Viewing item: ${doc.id}\n(Detail view not yet implemented)',
                          ),
                        ),
                  );
                } else if (collection == 'projects') {
                  context.push('/projects/${doc.id}');
                } else if (collection == 'employees') {
                  context.push('/employee-360/${doc.id}');
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text(
        'Type to search across projects, employees, and incidents...',
      ),
    );
  }

  Future<List<DocumentSnapshot>> _performGlobalSearch(String q) async {
    final fs = FirebaseFirestore.instance;
    final futures = <Future<QuerySnapshot>>[
      fs
          .tenantCollection(tenantId, 'incidents')
          .where('title', isGreaterThanOrEqualTo: q)
          .where('title', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(5)
          .get(),
      fs
          .tenantCollection(tenantId, 'projects')
          .where('name', isGreaterThanOrEqualTo: q)
          .where('name', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(5)
          .get(),
      fs
          .tenantCollection(tenantId, 'employees')
          .where('firstName', isGreaterThanOrEqualTo: q)
          .where('firstName', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(5)
          .get(),
    ];
    final results = await Future.wait(futures);
    return results.expand((snap) => snap.docs).toList();
  }
}
