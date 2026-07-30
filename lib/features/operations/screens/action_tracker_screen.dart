import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/utils/ui_utils.dart';
import '../models/action_tracker_models.dart';
import '../widgets/action_tracker_stats_row.dart';
import '../widgets/action_tracker_list_item.dart';
import '../widgets/action_tracker_search_bar.dart';
import '../widgets/action_form.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

/// Unified Action Item Tracker — aggregates items from incidents, CAPA, permits, DRA, observations.
class ActionTrackerScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? highlightId;

  const ActionTrackerScreen({super.key, this.initialSearch, this.highlightId});

  @override
  ConsumerState<ActionTrackerScreen> createState() => _ActionTrackerState();
}

class _ActionTrackerState extends ConsumerState<ActionTrackerScreen> {
  String _filter = 'All';
  String _search = '';
  bool _loading = true;
  List<ActionItem> _items = [];

  static const _collections = [
    CollSource('incidents', 'Incident'),
    CollSource('capas', 'CAPA'),
    CollSource('permits', 'Permit'),
    CollSource('bbs_observations', 'Observation'),
    CollSource('dynamic_risk_assessments', 'DRA'),
    CollSource('hazards', 'Hazard'),
    CollSource('actionItems', 'General'),
  ];

  final List<StreamSubscription> _subs = [];
  final Map<String, List<ActionItem>> _itemsMap = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      _search = widget.initialSearch!;
    }
    if (widget.highlightId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UIUtils.showSideSheet(
          context: context,
          title: 'Item Details',
          builder:
              (ctx) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Viewing item: ${widget.highlightId}\n(Detail view not yet implemented)',
                ),
              ),
        );
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupStreams());
  }

  @override
  void dispose() {
    for (var sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  void _setupStreams() {
    final siteId = ref.read(currentTenantIdProvider);
    final firestore = ref.read(firestoreProvider);
    if (siteId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    for (final coll in _collections) {
      final sub = firestore
          .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", coll.name)
          .where('siteId', isEqualTo: siteId)
          .limit(20)
          .snapshots()
          .listen((snap) {
            final List<ActionItem> collectionItems = [];
            for (final doc in snap.docs) {
              final d = doc.data();
              collectionItems.add(
                ActionItem(
                  id: doc.id,
                  collectionName: coll.name,
                  type: coll.type,
                  title:
                      d['title'] ??
                      d['description'] ??
                      d['taskDescription'] ??
                      d['type'] ??
                      d['hazard'] ??
                      'Untitled',
                  status: d['status'] ?? 'Pending',
                  dueDate: d['dueDate'] ?? d['createdAt'] ?? '',
                  assignee:
                      d['assigneeName'] ??
                      d['observerName'] ??
                      d['authorName'] ??
                      'Unassigned',
                ),
              );
            }
            if (mounted) {
              setState(() {
                _itemsMap[coll.name] = collectionItems;
                _items = _itemsMap.values.expand((e) => e).toList();
                _items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                _loading = false;
              });
            }
          });
      _subs.add(sub);
    }
  }

  Future<void> _updateStatus(ActionItem item, String newStatus) async {
    try {
      await ref
          .read(firestoreProvider)
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            item.collectionName,
          )
          .doc(item.id)
          .update({'status': newStatus});
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        _items
            .where(
              (item) =>
                  (_filter == 'All' || item.status == _filter) &&
                  item.title.toLowerCase().contains(_search.toLowerCase()),
            )
            .toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => UIUtils.showSideSheet(
              context: context,
              title: 'New Action Item',
              builder: (ctx) => const ActionForm(),
            ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const GHeader(
            title: 'Unified Action Tracker',
            subtitle: 'Aggregate actions from across all safety modules',
          ),
          ActionTrackerSearchBar(
            searchValue: _search,
            onSearchChanged: (v) => setState(() => _search = v),
            filterValue: _filter,
            onFilterChanged: (v) => setState(() => _filter = v),
          ),
          GSpacing.vMd,
          ActionTrackerStatsRow(items: _items),
          GSpacing.vMd,
          Expanded(
            child:
                _loading
                    ? const HubSkeleton()
                    : filtered.isEmpty
                    ? const Center(child: Text('No action items found'))
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder:
                          (ctx, i) => ActionTrackerListItem(
                            item: filtered[i],
                            onUpdateStatus: _updateStatus,
                          ),
                    ),
          ),
        ],
      ),
    );
  }
}
