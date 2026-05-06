import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

/// Emergency Response — drills, equipment inventory, contacts, broadcast.
class EmergencyResponseScreen extends ConsumerStatefulWidget {
  const EmergencyResponseScreen({super.key});
  @override
  ConsumerState<EmergencyResponseScreen> createState() => _EmergencyState();
}

class _EmergencyState extends ConsumerState<EmergencyResponseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _showDrillForm = false, _showEquipForm = false, _isSubmitting = false;
  // Drill form
  String _drillType = 'Fire';
  final _dateCtrl = TextEditingController(),
      _durationCtrl = TextEditingController();
  final _evalCtrl = TextEditingController(),
      _scenarioCtrl = TextEditingController(),
      _improvementsCtrl = TextEditingController();
  // Equipment form
  String _equipType = 'Extinguisher', _equipStatus = 'Operational';
  final _equipLocCtrl = TextEditingController(),
      _inspDateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _dateCtrl.dispose();
    _durationCtrl.dispose();
    _evalCtrl.dispose();
    _scenarioCtrl.dispose();
    _improvementsCtrl.dispose();
    _equipLocCtrl.dispose();
    _inspDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitDrill() async {
    if (_scenarioCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            collection: 'emergency_drills',
            data: {
              'drillType': _drillType,
              'dateConducted': _dateCtrl.text.trim(),
              'durationMinutes': int.tryParse(_durationCtrl.text) ?? 0,
              'evaluatorName': _evalCtrl.text.trim(),
              'scenarioDescription': _scenarioCtrl.text.trim(),
              'areasForImprovement': _improvementsCtrl.text.trim(),
              'authorId': p.uid,
              'siteId': p.siteId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drill logged'),
            backgroundColor: XMTheme.success,
          ),
        );
        setState(() {
          _showDrillForm = false;
          _scenarioCtrl.clear();
          _evalCtrl.clear();
          _durationCtrl.clear();
          _improvementsCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: XMTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitEquipment() async {
    if (_equipLocCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            collection: 'emergency_equipment',
            data: {
              'equipmentType': _equipType,
              'location': _equipLocCtrl.text.trim(),
              'nextInspectionDate': _inspDateCtrl.text.trim(),
              'status': _equipStatus,
              'authorId': p.uid,
              'siteId': p.siteId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment added'),
            backgroundColor: XMTheme.success,
          ),
        );
        setState(() {
          _showEquipForm = false;
          _equipLocCtrl.clear();
          _inspDateCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: XMTheme.error),
        );
      }
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
          title: 'Emergency Response',
          subtitle: 'Drills, equipment, and protocols',
        ),
        // Premium Sub-Header for Tabs
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabCtrl,
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
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(text: 'Drills'),
              Tab(text: 'Equipment'),
              Tab(text: 'Contacts'),
              Tab(text: 'Broadcast'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _drillsTab(),
              _equipmentTab(),
              _contactsTab(),
              _broadcastTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _drillsTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Recent Drills',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => setState(() => _showDrillForm = !_showDrillForm),
                icon: Icon(_showDrillForm ? Icons.close : Icons.add, size: 18),
                label: Text(_showDrillForm ? 'Cancel' : 'Log Drill'),
              ),
            ],
          ),
        ),
        if (_showDrillForm)
          GCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Log Emergency Drill',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  GSpacing.vMd,
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _drillType,
                          decoration: const InputDecoration(
                            labelText: 'Drill Type',
                          ),
                          items: [
                            'Fire',
                            'Medical',
                            'Spill',
                            'Security',
                            'Evacuation',
                            'Other',
                          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() => _drillType = v!),
                        ),
                      ),
                      GSpacing.hMd,
                      Expanded(
                        child: TextFormField(
                          controller: _durationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Duration (mins)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  GSpacing.vMd,
                  TextFormField(
                    controller: _scenarioCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Scenario Description *',
                    ),
                  ),
                  GSpacing.vMd,
                  TextFormField(
                    controller: _evalCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Evaluator Name',
                    ),
                  ),
                  GSpacing.vMd,
                  TextFormField(
                    controller: _improvementsCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Areas for Improvement',
                    ),
                  ),
                  GSpacing.vLg,
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitDrill,
                      child: Text(_isSubmitting ? 'Saving...' : 'Save Drill'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                siteId == null
                    ? null
                    : fs
                        .collection('emergency_drills')
                        .where('siteId', isEqualTo: siteId)
                        .orderBy('createdAt', descending: true)
                        .limit(50)
                        .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emergency_outlined, size: 64, color: Theme.of(context).disabledColor),
                      GSpacing.vLg,
                      Text('No drills logged', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return GCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _drillIcon(d['drillType']),
                          color: XMTheme.error,
                        ),
                      ),
                      title: Text(
                        '${d['drillType']} Drill',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GSpacing.vSm,
                          Text(
                            '${d['durationMinutes'] ?? 0} min • ${d['evaluatorName'] ?? 'No evaluator'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          GSpacing.vSm,
                          Text(
                            d['scenarioDescription'] ?? '',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: Icon(Icons.chevron_right, color: Theme.of(context).disabledColor),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _equipmentTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Safety Equipment',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => setState(() => _showEquipForm = !_showEquipForm),
                icon: Icon(_showEquipForm ? Icons.close : Icons.add, size: 18),
                label: Text(_showEquipForm ? 'Cancel' : 'Add Item'),
              ),
            ],
          ),
        ),
        if (_showEquipForm)
          GCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Equipment',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  GSpacing.vMd,
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _equipType,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: [
                            'Extinguisher',
                            'First Aid Kit',
                            'Spill Kit',
                            'AED',
                            'Other',
                          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() => _equipType = v!),
                        ),
                      ),
                      GSpacing.hMd,
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _equipStatus,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: [
                            'Operational',
                            'Needs Inspection',
                            'Out of Service',
                          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() => _equipStatus = v!),
                        ),
                      ),
                    ],
                  ),
                  GSpacing.vMd,
                  TextFormField(
                    controller: _equipLocCtrl,
                    decoration: const InputDecoration(labelText: 'Location *'),
                  ),
                  GSpacing.vMd,
                  TextFormField(
                    controller: _inspDateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Next Inspection Date',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  GSpacing.vLg,
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitEquipment,
                      child: Text(_isSubmitting ? 'Saving...' : 'Save Equipment'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: siteId == null
                ? null
                : fs
                    .collection('emergency_equipment')
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .limit(100)
                    .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.build_outlined, size: 64, color: Theme.of(context).disabledColor),
                      GSpacing.vLg,
                      Text('No equipment found', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final statusColor = d['status'] == 'Operational'
                      ? XMTheme.success
                      : d['status'] == 'Out of Service'
                          ? XMTheme.error
                          : XMTheme.warning;
                  return GCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _equipIcon(d['equipmentType']),
                              size: 20,
                              color: statusColor,
                            ),
                          ),
                          GSpacing.hMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['equipmentType'] ?? 'Unknown Item',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                GSpacing.vSm,
                                Text(
                                  d['location'] ?? 'No location',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GStatusTag(
                            label: d['status'] ?? 'Unknown',
                            color: statusColor,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _contactsTab() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Emergency Contacts',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      GSpacing.vLg,
      const _ContactCard(
        name: 'Fire Department',
        number: '10111',
        icon: Icons.local_fire_department,
        color: XMTheme.error,
      ),
      const _ContactCard(
        name: 'Ambulance / EMS',
        number: '10177',
        icon: Icons.local_hospital,
        color: XMTheme.info,
      ),
      const _ContactCard(
        name: 'Police / SAPS',
        number: '10111',
        icon: Icons.local_police,
        color: XMTheme.primary,
      ),
      const _ContactCard(
        name: 'Poison Information',
        number: '0800 111 990',
        icon: Icons.warning,
        color: XMTheme.warning,
      ),
      const _ContactCard(
        name: 'SHE Manager',
        number: 'On-site ext. 201',
        icon: Icons.person,
        color: XMTheme.success,
      ),
      const _ContactCard(
        name: 'Environmental Officer',
        number: 'On-site ext. 205',
        icon: Icons.eco,
        color: XMTheme.success,
      ),
    ],
  );

  Widget _broadcastTab() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: XMTheme.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.campaign, size: 80, color: XMTheme.error),
        ),
        GSpacing.vLg,
        Text(
          'Emergency Broadcast',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        GSpacing.vSm,
        Text(
          'Send push notifications and SMS alerts to all personnel on site immediately.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        GSpacing.vLg,
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              UIUtils.showToast(context, 'Broadcast system initialized. Configure in FCM.');
            },
            icon: const Icon(Icons.send),
            label: const Text('Initialize Test Broadcast'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: XMTheme.error,
            ),
          ),
        ),
      ],
    ),
  );

  IconData _drillIcon(String? type) {
    switch (type) {
      case 'Fire':
        return Icons.local_fire_department;
      case 'Medical':
        return Icons.local_hospital;
      case 'Spill':
        return Icons.water_drop;
      case 'Security':
        return Icons.security;
      default:
        return Icons.emergency;
    }
  }

  IconData _equipIcon(String? type) {
    switch (type) {
      case 'Extinguisher':
        return Icons.fire_extinguisher;
      case 'First Aid Kit':
        return Icons.medical_services;
      case 'AED':
        return Icons.monitor_heart;
      case 'Spill Kit':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final String number;
  final IconData icon;
  final Color color;

  const _ContactCard({
    required this.name,
    required this.number,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      color: color.withValues(alpha: 0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          number,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: IconButton.filledTonal(
          onPressed: () {},
          icon: const Icon(Icons.phone),
          color: color,
        ),
      ),
    );
  }
}
