import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';

/// Occupational Health — medical exams, hygiene surveys, first aid log, wellbeing.
class OccupationalHealthScreen extends ConsumerStatefulWidget {
  const OccupationalHealthScreen({super.key});
  @override
  ConsumerState<OccupationalHealthScreen> createState() => _OHState();
}

class _OHState extends ConsumerState<OccupationalHealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _isSub = false;

  // Medical form controllers
  final _medEmpCtrl = TextEditingController();
  final _medIdCtrl = TextEditingController();
  final _medRestCtrl = TextEditingController();
  String _medType = 'Pre-employment';
  String _medStatus = 'Fit';
  DateTime _medDate = DateTime.now();
  DateTime _medNextDue = DateTime.now().add(const Duration(days: 365));

  // Hygiene survey form controllers
  final _zoneCtrl = TextEditingController();
  final _readingCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  String _hazardType = 'Noise';
  bool _requiresSurveillance = false;

  // First aid form controllers
  final _faEmpCtrl = TextEditingController();
  final _faDescCtrl = TextEditingController();
  final _faTreatCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _medEmpCtrl.dispose();
    _medIdCtrl.dispose();
    _medRestCtrl.dispose();
    _zoneCtrl.dispose();
    _readingCtrl.dispose();
    _limitCtrl.dispose();
    _faEmpCtrl.dispose();
    _faDescCtrl.dispose();
    _faTreatCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitMedical() async {
    if (_medEmpCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Employee name is required', type: ToastType.error);
      return;
    }
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(
        collection: 'medical_records',
        data: {
          'employeeName': _medEmpCtrl.text.trim(),
          'idNumber': _medIdCtrl.text.trim(),
          'medicalType': _medType,
          'status': _medStatus,
          'restrictions': _medRestCtrl.text.trim(),
          'dateConducted': _medDate.toIso8601String(),
          'nextDueDate': _medNextDue.toIso8601String(),
          'authorId': p.uid,
          'siteId': p.siteId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        Navigator.pop(context); // Close SideSheet
        UIUtils.showToast(context, 'Medical record saved successfully');
        setState(() {
          _medEmpCtrl.clear();
          _medIdCtrl.clear();
          _medRestCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSub = false);
    }
  }

  Future<void> _submitHygiene() async {
    if (_zoneCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Zone name is required', type: ToastType.error);
      return;
    }
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(
        collection: 'hygiene_surveys',
        data: {
          'zoneName': _zoneCtrl.text.trim(),
          'hazardType': _hazardType,
          'readingValue': _readingCtrl.text.trim(),
          'legalLimit': _limitCtrl.text.trim(),
          'requiresMedicalSurveillance': _requiresSurveillance,
          'dateConducted': DateTime.now().toIso8601String(),
          'authorId': p.uid,
          'siteId': p.siteId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        Navigator.pop(context); // Close SideSheet
        UIUtils.showToast(context, 'Hygiene survey saved successfully');
        setState(() {
          _zoneCtrl.clear();
          _readingCtrl.clear();
          _limitCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSub = false);
    }
  }

  Future<void> _submitFirstAid() async {
    if (_faEmpCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Employee name is required', type: ToastType.error);
      return;
    }
    setState(() => _isSub = true);
    try {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(
        collection: 'first_aid_log',
        data: {
          'employeeName': _faEmpCtrl.text.trim(),
          'description': _faDescCtrl.text.trim(),
          'treatment': _faTreatCtrl.text.trim(),
          'date': DateTime.now().toIso8601String(),
          'authorId': p.uid,
          'siteId': p.siteId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        Navigator.pop(context); // Close SideSheet
        UIUtils.showToast(context, 'First aid entry saved successfully');
        setState(() {
          _faEmpCtrl.clear();
          _faDescCtrl.clear();
          _faTreatCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, '$e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const GHeader(
          title: 'Occupational Health',
          subtitle: 'Medical surveillance, hygiene surveys, and wellbeing',
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
            controller: _tab,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Medicals'),
              Tab(text: 'Hygiene'),
              Tab(text: 'First Aid'),
              Tab(text: 'Wellbeing'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _medicalsTab(),
              _hygieneTab(),
              _firstAidTab(),
              _wellbeingTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _medicalsTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);

    return Column(
      children: [
        // Action Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _OHStatChip(label: 'Fit', count: '85%', color: XMTheme.success),
                      GSpacing.hMd,
                      _OHStatChip(label: 'Restricted', count: '12%', color: XMTheme.warning),
                      GSpacing.hMd,
                      _OHStatChip(label: 'Unfit', count: '3%', color: XMTheme.error),
                    ],
                  ),
                ),
              ),
              GSpacing.hMd,
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'New Medical Record',
                  builder: (ctx) => _buildMedicalForm(),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Record'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: siteId == null
                ? null
                : fs
                    .collection('medical_records')
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .limit(100)
                    .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monitor_heart_outlined, size: 48, color: Theme.of(context).disabledColor),
                      GSpacing.vMd,
                      Text('No medical records found', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _MedicalListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _hygieneTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hygiene Surveys', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Environmental monitoring logs', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'New Hygiene Assessment',
                  builder: (ctx) => _buildHygieneForm(),
                ),
                icon: const Icon(Icons.science_rounded, size: 20),
                label: const Text('New Survey'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: siteId == null
                ? null
                : fs
                    .collection('hygiene_surveys')
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No hygiene surveys logged'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _HygieneListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _firstAidTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final fs = ref.watch(firestoreProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('First Aid Log', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Incident treatment records', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'New First Aid Incident',
                  builder: (ctx) => _buildFirstAidForm(),
                ),
                icon: const Icon(Icons.medical_services_rounded, size: 20),
                label: const Text('Log Entry'),
                style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: siteId == null
                ? null
                : fs
                    .collection('first_aid_log')
                    .where('siteId', isEqualTo: siteId)
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No first aid entries logged'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _FirstAidListItem(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _wellbeingTab() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wellbeing Hub', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text('Mental resilience and health initiatives', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          GSpacing.vLg,
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.8,
            children: const [
              _WellbeingCard(
                title: 'Mental Health Support',
                subtitle: 'EAP available 24/7 for counseling',
                icon: Icons.psychology_rounded,
                color: XMTheme.primary,
              ),
              _WellbeingCard(
                title: 'Fatigue Management',
                subtitle: 'Monitoring rest period compliance',
                icon: Icons.bedtime_rounded,
                color: XMTheme.secondary,
              ),
              _WellbeingCard(
                title: 'Substance Awareness',
                subtitle: 'Training schedule and support',
                icon: Icons.local_bar_rounded,
                color: XMTheme.warning,
              ),
              _WellbeingCard(
                title: 'Wellness Campaigns',
                subtitle: 'Monthly screening drives',
                icon: Icons.favorite_rounded,
                color: XMTheme.error,
              ),
            ],
          ),
          GSpacing.vLg,
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  XMTheme.success.withValues(alpha: 0.1),
                  XMTheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: XMTheme.success.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: XMTheme.success.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.tips_and_updates, color: XMTheme.success, size: 20),
                    ),
                    GSpacing.hMd,
                    const Text(
                      'EAP Helpline',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ],
                ),
                GSpacing.vSm,
                const Text(
                  '0800 611 655 — Confidential, free, 24/7 counselling and support services available to all employees.',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalForm() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Employee Details', style: Theme.of(context).textTheme.titleSmall),
              GSpacing.vSm,
              TextFormField(
                controller: _medEmpCtrl,
                decoration: const InputDecoration(labelText: 'Employee Name *', prefixIcon: Icon(Icons.person_outline)),
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _medIdCtrl,
                decoration: const InputDecoration(labelText: 'ID / Employee Number', prefixIcon: Icon(Icons.badge_outlined)),
              ),
              GSpacing.vLg,
              Text('Examination Info', style: Theme.of(context).textTheme.titleSmall),
              GSpacing.vSm,
              DropdownButtonFormField<String>(
                value: _medType,
                decoration: const InputDecoration(labelText: 'Exam Type'),
                items: ['Pre-employment', 'Annual', 'Exit', 'Baseline', 'Other']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setLocalState(() => _medType = v!),
              ),
              GSpacing.vMd,
              DropdownButtonFormField<String>(
                value: _medStatus,
                decoration: const InputDecoration(labelText: 'Fitness Status'),
                items: ['Fit', 'Fit with Restrictions', 'Unfit']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setLocalState(() => _medStatus = v!),
              ),
              GSpacing.vMd,
              TextFormField(
                controller: _medRestCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Restrictions / Comments'),
              ),
              GSpacing.vLg,
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Conducted On', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        GSpacing.vSm,
                        InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _medDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setLocalState(() => _medDate = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).dividerColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                GSpacing.hSm,
                                Text(UIUtils.formatDate(_medDate)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GSpacing.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Next Due', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        GSpacing.vSm,
                        InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _medNextDue,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 1825)),
                            );
                            if (d != null) setLocalState(() => _medNextDue = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).dividerColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_repeat, size: 16),
                                GSpacing.hSm,
                                Text(UIUtils.formatDate(_medNextDue)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              GSpacing.vLg,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSub ? null : _submitMedical,
                  child: Text(_isSub ? 'Saving…' : 'Save Record'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHygieneForm() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _zoneCtrl,
                decoration: const InputDecoration(labelText: 'Zone / Area *', prefixIcon: Icon(Icons.place_outlined)),
              ),
              GSpacing.vMd,
              DropdownButtonFormField<String>(
                value: _hazardType,
                decoration: const InputDecoration(labelText: 'Hazard Type'),
                items: ['Noise', 'Dust', 'Chemical', 'Ergonomic', 'Illumination', 'Thermal', 'Other']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setLocalState(() => _hazardType = v!),
              ),
              GSpacing.vMd,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _readingCtrl,
                      decoration: const InputDecoration(labelText: 'Reading Value'),
                    ),
                  ),
                  GSpacing.hMd,
                  Expanded(
                    child: TextFormField(
                      controller: _limitCtrl,
                      decoration: const InputDecoration(labelText: 'Legal Limit'),
                    ),
                  ),
                ],
              ),
              GSpacing.vMd,
              SwitchListTile(
                value: _requiresSurveillance,
                onChanged: (v) => setLocalState(() => _requiresSurveillance = v),
                title: const Text('Requires Medical Surveillance?', style: TextStyle(fontSize: 14)),
                contentPadding: EdgeInsets.zero,
              ),
              GSpacing.vLg,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSub ? null : _submitHygiene,
                  child: Text(_isSub ? 'Saving…' : 'Save Survey'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFirstAidForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _faEmpCtrl,
            decoration: const InputDecoration(labelText: 'Employee / Person *', prefixIcon: Icon(Icons.person_outline)),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _faDescCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Injury / Complaint Description'),
          ),
          GSpacing.vMd,
          TextFormField(
            controller: _faTreatCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Treatment Provided'),
          ),
          GSpacing.vXl,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSub ? null : _submitFirstAid,
              child: Text(_isSub ? 'Saving…' : 'Save Entry'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MedicalListItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = data['status'] ?? 'Unknown';
    final type = data['medicalType'] ?? 'Exam';
    
    Color color = XMTheme.success;
    IconData icon = Icons.check_circle_outline_rounded;
    
    if (status == 'Unfit') {
      color = XMTheme.error;
      icon = Icons.cancel_outlined;
    } else if (status.contains('Restriction')) {
      color = XMTheme.warning;
      icon = Icons.warning_amber_rounded;
    }

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          GSpacing.hLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['employeeName'] ?? 'Unknown Employee', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                GSpacing.vXs,
                Text('$type • ${data['idNumber'] ?? "No ID"}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          GSpacing.hMd,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GStatusTag(label: status.toUpperCase(), color: color),
              GSpacing.vXs,
              Text(
                'Due: ${UIUtils.formatTimestamp(data['nextDueDate']).split(',').first}',
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HygieneListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HygieneListItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reading = double.tryParse(data['readingValue']?.toString() ?? '0') ?? 0;
    final limit = double.tryParse(data['legalLimit']?.toString() ?? '100') ?? 100;
    final isOver = reading > limit;
    final color = isOver ? XMTheme.error : XMTheme.info;

    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['zoneName'] ?? 'Unknown Zone', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text(data['hazardType'] ?? 'Unknown Hazard', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              GStatusTag(
                label: isOver ? 'THRESHOLD EXCEEDED' : 'WITHIN LIMITS',
                color: isOver ? XMTheme.error : XMTheme.success,
              ),
            ],
          ),
          GSpacing.vMd,
          Row(
            children: [
              _SurveyMetric(label: 'READING', value: '${data['readingValue'] ?? "0"}', color: color),
              GSpacing.hLg,
              _SurveyMetric(label: 'LEGAL LIMIT', value: '${data['legalLimit'] ?? "0"}', color: theme.colorScheme.outline),
              const Spacer(),
              if (data['requiresMedicalSurveillance'] == true)
                _TinyBadge(label: 'SURVEILLANCE REQ', color: XMTheme.warning, icon: Icons.medical_services_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurveyMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SurveyMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 8, letterSpacing: 1, color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _FirstAidListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FirstAidListItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: theme.colorScheme.errorContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.medical_services_rounded, color: theme.colorScheme.error, size: 24),
          ),
          GSpacing.hLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['employeeName'] ?? 'Unknown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      UIUtils.formatTimestamp(data['date']).split(',').first,
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                GSpacing.vSm,
                Text(data['description'] ?? 'No description', style: theme.textTheme.bodySmall),
                GSpacing.vMd,
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.healing_rounded, size: 14, color: theme.colorScheme.primary),
                      GSpacing.hMd,
                      Expanded(
                        child: Text(
                          'Treatment: ${data['treatment'] ?? "None recorded"}',
                          style: theme.textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OHStatChip extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _OHStatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          GSpacing.hMd,
          Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
          GSpacing.hSm,
          Text(count, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _WellbeingCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  const _WellbeingCard({required this.title, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          GSpacing.hLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                GSpacing.vXs,
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _TinyBadge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          GSpacing.hXs,
          Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
