import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

/// Environmental & ESG Management — waste manifests, spill response, emissions tracking, water/energy.
class EnvironmentalScreen extends ConsumerStatefulWidget {
  const EnvironmentalScreen({super.key});
  @override
  ConsumerState<EnvironmentalScreen> createState() => _EnvState();
}

class _EnvState extends ConsumerState<EnvironmentalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isSubmitting = false;

  // Waste form
  String _wasteType = 'General';
  String _wasteUnit = 'kg';
  final String _wasteStatus = 'Pending Pickup';
  final _qtyCtrl = TextEditingController();
  final _transporterCtrl = TextEditingController();
  final _facilityCtrl = TextEditingController();

  // Spill form
  final _substanceCtrl = TextEditingController();
  final _volCtrl = TextEditingController();
  final _spillLocCtrl = TextEditingController();
  bool _contained = false;
  bool _reported = false;

  // ESG metric form
  String _esgCategory = 'Scope 1';
  String _esgUnit = 'tCO2e';
  final String _esgPeriod = '2026';
  final _esgValueCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _qtyCtrl.dispose();
    _transporterCtrl.dispose();
    _facilityCtrl.dispose();
    _substanceCtrl.dispose();
    _volCtrl.dispose();
    _spillLocCtrl.dispose();
    _esgValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitWaste() async {
    if (_qtyCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Quantity is required', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(
        collection: 'waste_manifests',
        data: {
          'wasteType': _wasteType,
          'quantity': double.tryParse(_qtyCtrl.text) ?? 0,
          'unit': _wasteUnit,
          'transporterName': _transporterCtrl.text.trim(),
          'disposalFacility': _facilityCtrl.text.trim(),
          'status': _wasteStatus,
          'authorId': p.uid,
          'siteId': p.siteId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'Waste manifest added successfully');
        setState(() {
          _qtyCtrl.clear();
          _transporterCtrl.clear();
          _facilityCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitSpill() async {
    if (_substanceCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Substance is required', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(
        collection: 'environmental_spills',
        data: {
          'substance': _substanceCtrl.text.trim(),
          'volume': _volCtrl.text.trim(),
          'location': _spillLocCtrl.text.trim(),
          'contained': _contained,
          'reportedToAuthorities': _reported,
          'authorId': p.uid,
          'siteId': p.siteId,
          'dateOfSpill': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'Environmental spill logged successfully');
        setState(() {
          _substanceCtrl.clear();
          _volCtrl.clear();
          _spillLocCtrl.clear();
          _contained = false;
          _reported = false;
        });
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitMetric() async {
    if (_esgValueCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Value is required', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(
        collection: 'esg_metrics',
        data: {
          'category': _esgCategory,
          'value': double.tryParse(_esgValueCtrl.text) ?? 0,
          'unit': _esgUnit,
          'period': _esgPeriod,
          'authorId': p.uid,
          'siteId': p.siteId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        Navigator.pop(context);
        UIUtils.showToast(context, 'ESG metric added successfully');
        setState(() {
          _esgValueCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const GHeader(
          title: 'Environmental & ESG',
          subtitle: 'Waste manifests, spill response, and emissions',
        ),
        // Standardized Sub-Header for Tabs
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Waste'),
              Tab(text: 'Spills'),
              Tab(text: 'ESG Metrics'),
              Tab(text: 'Analytics'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _wasteTab(),
              _spillsTab(),
              _metricsTab(),
              _analyticsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _wasteTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Waste Manifests', style: Theme.of(context).textTheme.titleMedium),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'New Waste Manifest',
                  builder: (ctx) => _buildWasteForm(),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Manifest'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: siteId == null
                ? null
                : fs
                    .collection('waste_manifests')
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('No waste manifests logged'));
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _WasteListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _spillsTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spill Logs', style: Theme.of(context).textTheme.titleMedium),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'Log Spill Incident',
                  builder: (ctx) => _buildSpillForm(),
                ),
                icon: const Icon(Icons.water_drop_outlined, size: 18),
                label: const Text('Log Spill'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: siteId == null
                ? null
                : fs
                    .collection('environmental_spills')
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('No spill records logged'));
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _SpillListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _metricsTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ESG Performance', style: Theme.of(context).textTheme.titleMedium),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'Resource Usage',
                  builder: (ctx) => _buildResourceForm(),
                ),
                icon: const Icon(Icons.eco_outlined, size: 18),
                label: const Text('Add Metric'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: siteId == null
                ? null
                : fs
                    .collection('esg_metrics')
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .limit(100)
                    .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('No ESG metrics recorded'));
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _MetricListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _analyticsTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Environmental Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          GSpacing.vSm,
          Text(
            'Performance overview for $siteId',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          GSpacing.vLg,

          // ─── Spill KPIs ───
          Text('Spill Response', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          GSpacing.vMd,
          StreamBuilder<QuerySnapshot>(
            stream: fs.collection('environmental_spills').where('siteId', isEqualTo: siteId).snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              int total = docs.length, contained = 0, uncontained = 0;
              for (final doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                if (d['contained'] == true) {
                  contained++;
                } else {
                  uncontained++;
                }
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _AnalyticsKpiCard(label: 'Total Spills', value: '$total', icon: Icons.water_drop, color: XMTheme.info),
                    GSpacing.hMd,
                    _AnalyticsKpiCard(label: 'Contained', value: '$contained', icon: Icons.check_circle, color: XMTheme.success),
                    GSpacing.hMd,
                    _AnalyticsKpiCard(label: 'Uncontained', value: '$uncontained', icon: Icons.cancel, color: XMTheme.error),
                    GSpacing.hMd,
                    _AnalyticsKpiCard(
                      label: 'Containment %',
                      value: total > 0 ? '${(contained / total * 100).toStringAsFixed(0)}%' : '—',
                      icon: Icons.percent,
                      color: XMTheme.primary,
                    ),
                  ],
                ),
              );
            },
          ),
          GSpacing.vLg,

          // ─── Waste Distribution ───
          Text('Waste Distribution', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          GSpacing.vMd,
          StreamBuilder<QuerySnapshot>(
            stream: fs.collection('waste_manifests').where('siteId', isEqualTo: siteId).snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              final byType = <String, int>{};
              for (final doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                final t = (d['wasteType'] ?? 'Other').toString();
                byType[t] = (byType[t] ?? 0) + 1;
              }
              if (byType.isEmpty) return const GCard(child: Center(child: Text('No waste data available')));
              final total = byType.values.reduce((a, b) => a + b);
              return GCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: byType.entries.map((e) {
                    final pct = e.value / total;
                    final color = e.key == 'Hazardous'
                        ? XMTheme.error
                        : (e.key == 'Recyclable' ? XMTheme.success : (e.key == 'General' ? XMTheme.info : XMTheme.warning));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text('${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                                  style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                          GSpacing.vSm,
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 10,
                              backgroundColor: color.withValues(alpha: 0.1),
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          GSpacing.vLg,

          // ─── ESG Scorecard ───
          Text('ESG Scorecard', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          GSpacing.vMd,
          StreamBuilder<QuerySnapshot>(
            stream: fs.collection('esg_metrics').where('siteId', isEqualTo: siteId).snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const GCard(child: Center(child: Text('No ESG metrics available')));
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return GCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(d['category'] ?? 'Metric', style: Theme.of(context).textTheme.labelSmall),
                        GSpacing.vSm,
                        Text('${d['value']} ${d['unit']}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWasteForm() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _wasteType,
                decoration: const InputDecoration(labelText: 'Waste Type'),
                items: ['Hazardous', 'General', 'Recyclable', 'Medical', 'E-Waste']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setLocalState(() => _wasteType = v!),
              ),
              GSpacing.vMd,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Quantity *'),
                    ),
                  ),
                  GSpacing.hMd,
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<String>(
                      value: _wasteUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: ['kg', 'tons', 'liters', 'm3']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setLocalState(() => _wasteUnit = v!),
                    ),
                  ),
                ],
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _transporterCtrl,
                decoration: const InputDecoration(labelText: 'Transporter Name', prefixIcon: Icon(Icons.local_shipping_outlined)),
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _facilityCtrl,
                decoration: const InputDecoration(labelText: 'Disposal Facility', prefixIcon: Icon(Icons.factory_outlined)),
              ),
              GSpacing.vLg,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitWaste,
                  child: Text(_isSubmitting ? 'Saving...' : 'Save Manifest'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpillForm() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _substanceCtrl,
                decoration: const InputDecoration(labelText: 'Substance Spilled *', prefixIcon: Icon(Icons.opacity)),
              ),
              GSpacing.vMd,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _volCtrl,
                      decoration: const InputDecoration(labelText: 'Volume / Qty'),
                    ),
                  ),
                  GSpacing.hMd,
                  Expanded(
                    child: TextFormField(
                      controller: _spillLocCtrl,
                      decoration: const InputDecoration(labelText: 'Specific Location', prefixIcon: Icon(Icons.place_outlined)),
                    ),
                  ),
                ],
              ),
              GSpacing.vMd,
              SwitchListTile(
                value: _contained,
                onChanged: (v) => setLocalState(() => _contained = v),
                title: const Text('Was the spill contained?', style: TextStyle(fontSize: 14)),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: _reported,
                onChanged: (v) => setLocalState(() => _reported = v),
                title: const Text('Reported to Authorities?', style: TextStyle(fontSize: 14)),
                contentPadding: EdgeInsets.zero,
              ),
              GSpacing.vLg,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitSpill,
                  child: Text(_isSubmitting ? 'Logging Spill...' : 'Log Spill'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResourceForm() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _esgCategory,
                decoration: const InputDecoration(labelText: 'ESG Category'),
                items: ['Scope 1', 'Scope 2', 'Scope 3', 'Water', 'Waste', 'Diversity', 'Training', 'Ethics']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setLocalState(() => _esgCategory = v!),
              ),
              GSpacing.vMd,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _esgValueCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Metric Value *'),
                    ),
                  ),
                  GSpacing.hMd,
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: _esgUnit,
                      onChanged: (v) => _esgUnit = v,
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                  ),
                ],
              ),
              GSpacing.vLg,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitMetric,
                  child: Text(_isSubmitting ? 'Adding Metric...' : 'Add Metric'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WasteListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _WasteListItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final type = data['wasteType'] ?? 'General';
    final color = type == 'Hazardous' ? XMTheme.error : (type == 'Recyclable' ? XMTheme.success : XMTheme.info);

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          GSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data['wasteType']} • ${data['quantity']} ${data['unit']}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text('${data['transporterName'] ?? ""} → ${data['disposalFacility'] ?? ""}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          GStatusTag(label: data['status'] ?? 'Log', color: color),
        ],
      ),
    );
  }
}

class _SpillListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SpillListItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final contained = data['contained'] == true;
    final color = contained ? XMTheme.success : XMTheme.error;

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.water_drop, color: color, size: 20),
          ),
          GSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['substance'] ?? 'Unknown Substance', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${data['volume'] ?? ""} @ ${data['location'] ?? ""}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          GStatusTag(label: contained ? 'Contained' : 'Active', color: color),
        ],
      ),
    );
  }
}

class _MetricListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MetricListItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          GStatusTag(label: data['category'] ?? 'ESG', color: XMTheme.primary),
          GSpacing.hLg,
          Text('${data['value']} ${data['unit']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const Spacer(),
          Text(data['period'] ?? '2026', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _AnalyticsKpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _AnalyticsKpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => GCard(
        width: 150,
        color: color.withValues(alpha: 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            GSpacing.vMd,
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            GSpacing.vSm,
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
}
