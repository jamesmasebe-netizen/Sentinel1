import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/skeleton_loader.dart';

/// Unified Action Item Tracker — aggregates items from incidents, CAPA, permits, DRA, observations.
class ActionTrackerScreen extends ConsumerStatefulWidget {
  const ActionTrackerScreen({super.key});
  @override
  ConsumerState<ActionTrackerScreen> createState() => _ActionTrackerState();
}

class _ActionTrackerState extends ConsumerState<ActionTrackerScreen> {
  String _filter = 'All';
  String _search = '';
  bool _loading = true;
  List<_ActionItem> _items = [];

  static const _collections = [
    _CollSource('incidents', 'Incident'),
    _CollSource('capas', 'CAPA'),
    _CollSource('permits', 'Permit'),
    _CollSource('bbs_observations', 'Observation'),
    _CollSource('dynamic_risk_assessments', 'DRA'),
    _CollSource('hazards', 'Hazard'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchAll() async {
    final siteId = ref.read(currentSiteIdProvider);
    final firestore = ref.read(firestoreProvider);
    if (siteId == null) { setState(() => _loading = false); return; }

    final List<_ActionItem> all = [];
    for (final coll in _collections) {
      try {
        final snap = await firestore.collection(coll.name).where('siteId', isEqualTo: siteId).limit(20).get();
        for (final doc in snap.docs) {
          final d = doc.data();
          all.add(_ActionItem(
            id: doc.id, collectionName: coll.name, type: coll.type,
            title: d['title'] ?? d['description'] ?? d['taskDescription'] ?? d['type'] ?? d['hazard'] ?? 'Untitled',
            status: d['status'] ?? 'Pending',
            dueDate: d['dueDate'] ?? d['createdAt'] ?? '',
            assignee: d['assigneeName'] ?? d['observerName'] ?? d['authorName'] ?? 'Unassigned',
          ));
        }
      } catch (_) {}
    }
    all.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (mounted) setState(() { _items = all; _loading = false; });
  }

  Future<void> _updateStatus(_ActionItem item, String newStatus) async {
    try {
      await ref.read(firestoreProvider).collection(item.collectionName).doc(item.id).update({'status': newStatus});
      setState(() { final idx = _items.indexOf(item); if (idx >= 0) _items[idx] = item.copyWith(status: newStatus); });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: XMTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((item) =>
      (_filter == 'All' || item.status == _filter) &&
      item.title.toLowerCase().contains(_search.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Unified Action Tracker')),
      body: Column(children: [
        // Search & filter bar
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Expanded(child: TextFormField(onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search), isDense: true))),
          const SizedBox(width: 12),
          DropdownButton<String>(value: _filter, underline: const SizedBox(),
            items: ['All', 'Pending', 'In Progress', 'Open', 'Completed', 'Closed'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _filter = v!)),
        ])),
        // Stats row
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          _StatChip(label: 'Total', value: '${_items.length}', color: XMTheme.info),
          _StatChip(label: 'Pending', value: '${_items.where((i) => i.status == 'Pending' || i.status == 'Open').length}', color: XMTheme.warning),
          _StatChip(label: 'In Progress', value: '${_items.where((i) => i.status == 'In Progress').length}', color: XMTheme.primary),
          _StatChip(label: 'Done', value: '${_items.where((i) => i.status == 'Completed' || i.status == 'Closed').length}', color: XMTheme.success),
        ])),
        const SizedBox(height: 8),
        // List
        Expanded(child: _loading
          ? const HubSkeleton()
          : filtered.isEmpty
            ? const Center(child: Text('No action items found'))
            : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: filtered.length, itemBuilder: (ctx, i) {
                final item = filtered[i];
                return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    Container(width: 4, height: 40, decoration: BoxDecoration(color: _typeColor(item.type), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${item.type} • ${item.assignee} • ${_fmtDate(item.dueDate)}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ])),
                    PopupMenuButton<String>(
                      initialValue: item.status,
                      onSelected: (v) => _updateStatus(item, v),
                      itemBuilder: (_) => ['Pending', 'In Progress', 'Completed'].map((s) => PopupMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                      child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: _statusColor(item.status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(item.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(item.status))),
                          Icon(Icons.arrow_drop_down, size: 16, color: _statusColor(item.status)),
                        ])),
                    ),
                  ]),
                );
              }),
        ),
      ]),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Incident': return XMTheme.error;
      case 'CAPA': return XMTheme.warning;
      case 'Permit': return XMTheme.primary;
      case 'Observation': return XMTheme.info;
      case 'DRA': return XMTheme.secondary;
      case 'Hazard': return XMTheme.severityMajor;
      default: return XMTheme.statusDraft;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending': case 'Open': return XMTheme.warning;
      case 'In Progress': return XMTheme.primary;
      case 'Completed': case 'Closed': return XMTheme.success;
      default: return XMTheme.statusDraft;
    }
  }

  String _fmtDate(String? iso) { if (iso == null || iso.isEmpty) return ''; try { final dt = DateTime.parse(iso); return '${dt.day}/${dt.month}/${dt.year}'; } catch (_) { return ''; } }
}

class _CollSource {
  final String name, type;
  const _CollSource(this.name, this.type);
}

class _ActionItem {
  final String id, collectionName, type, title, status, dueDate, assignee;
  const _ActionItem({required this.id, required this.collectionName, required this.type, required this.title, required this.status, required this.dueDate, required this.assignee});
  _ActionItem copyWith({String? status}) => _ActionItem(id: id, collectionName: collectionName, type: type, title: title, status: status ?? this.status, dueDate: dueDate, assignee: assignee);
}

class _StatChip extends StatelessWidget {
  final String label, value; final Color color;
  const _StatChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: color)),
    ]),
  ));
}
