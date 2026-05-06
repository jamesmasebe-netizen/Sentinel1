import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';

/// Training & Competency — training records, toolbox talks, expiry alerts.
class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});
  @override
  ConsumerState<TrainingScreen> createState() => _TrainingState();
}

class _TrainingState extends ConsumerState<TrainingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isSubmitting = false;

  // Training record form controllers
  final _empNameCtrl = TextEditingController();
  final _idNumCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  DateTime _completed = DateTime.now();
  DateTime _expiry = DateTime.now().add(const Duration(days: 365));

  // Toolbox talk form controllers
  final _topicCtrl = TextEditingController();
  final _talkLocCtrl = TextEditingController();
  final _attendeesCtrl = TextEditingController();
  final DateTime _talkDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _empNameCtrl.dispose();
    _idNumCtrl.dispose();
    _courseCtrl.dispose();
    _topicCtrl.dispose();
    _talkLocCtrl.dispose();
    _attendeesCtrl.dispose();
    super.dispose();
  }

  void _openRecordForm() {
    UIUtils.showSideSheet(
      context: context,
      title: 'Add Training Record',
      builder: (ctx) => _buildRecordForm(),
    );
  }

  void _openTalkForm() {
    UIUtils.showSideSheet(
      context: context,
      title: 'Log Toolbox Talk',
      builder: (ctx) => _buildTalkForm(),
    );
  }

  Future<void> _submitRecord() async {
    if (_empNameCtrl.text.isEmpty || _courseCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Please fill in required fields', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      final status = _expiry.isAfter(DateTime.now()) ? 'Active' : 'Expired';
      
      await ref.read(firestoreServiceProvider).createDocument(
        collection: 'training_records',
        data: {
          'employeeName': _empNameCtrl.text.trim(),
          'idNumber': _idNumCtrl.text.trim(),
          'courseName': _courseCtrl.text.trim(),
          'dateCompleted': _completed.toIso8601String(),
          'expiryDate': _expiry.toIso8601String(),
          'status': status,
          'authorId': profile.uid,
          'siteId': profile.siteId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      
      if (mounted) {
        Navigator.pop(context); // Close side sheet
        UIUtils.showToast(context, 'Training record added successfully');
        _empNameCtrl.clear();
        _idNumCtrl.clear();
        _courseCtrl.clear();
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitTalk() async {
    if (_topicCtrl.text.isEmpty) {
      UIUtils.showToast(context, 'Please enter a topic', type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      
      final attendees = _attendeesCtrl.text
          .split(',')
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .toList();

      await ref.read(firestoreServiceProvider).createDocument(
        collection: 'toolbox_talks',
        data: {
          'topic': _topicCtrl.text.trim(),
          'date': _talkDate.toIso8601String(),
          'conductorName': profile.displayName,
          'location': _talkLocCtrl.text.trim(),
          'attendees': attendees,
          'authorId': profile.uid,
          'siteId': profile.siteId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      
      if (mounted) {
        Navigator.pop(context); // Close side sheet
        UIUtils.showToast(context, 'Toolbox talk logged successfully');
        _topicCtrl.clear();
        _talkLocCtrl.clear();
        _attendeesCtrl.clear();
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
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
          title: 'Training & Development',
          subtitle: 'Records and toolbox talks',
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
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Records'),
              Tab(text: 'Toolbox Talks'),
              Tab(text: 'Expiry Alerts'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildRecordsTab(),
              _buildToolboxTab(),
              _buildExpiryTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Training Records',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _openRecordForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Record'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: siteId == null
                ? null
                : firestore
                    .collection('training_records')
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
                      Icon(Icons.school_outlined, size: 64, color: Theme.of(context).disabledColor),
                      GSpacing.vLg,
                      Text('No training records found', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final isExpired = d['status'] == 'Expired';
                  
                  return GCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.badge_outlined,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          GSpacing.hLg,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['employeeName'] ?? 'Unknown Employee',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GSpacing.vSm,
                                Text(
                                  d['courseName'] ?? 'No course specified',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                GSpacing.vSm,
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 12, color: Theme.of(context).disabledColor),
                                    GSpacing.hSm,
                                    Text(
                                      'Expires: ${d['expiryDate']?.toString().split('T').first ?? 'N/A'}',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).disabledColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GStatusTag(
                            label: d['status'] ?? 'Unknown',
                            color: isExpired ? XMTheme.error : XMTheme.success,
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

  Widget _buildToolboxTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Recent Talks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _openTalkForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Talk'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: siteId == null
                ? null
                : firestore
                    .collection('toolbox_talks')
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
                      Icon(Icons.record_voice_over_outlined, size: 64, color: Theme.of(context).disabledColor),
                      GSpacing.vLg,
                      Text('No toolbox talks logged', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final attendees = (d['attendees'] as List?)?.cast<String>() ?? [];
                  
                  return GCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                d['topic'] ?? 'Untitled Talk',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                d['date']?.toString().split('T').first ?? '',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          GSpacing.vMd,
                          Row(
                            children: [
                              if (d['location'] != null && d['location'].toString().isNotEmpty) ...[
                                Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                GSpacing.hSm,
                                Text(
                                  d['location'],
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                GSpacing.hMd,
                              ],
                              Icon(Icons.people_outline, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              GSpacing.hSm,
                              Text(
                                '${attendees.length} attendees',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          if (attendees.isNotEmpty) ...[
                            GSpacing.vLg,
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: attendees.take(5).map((a) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  a,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              )).toList(),
                            ),
                          ],
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

  Widget _buildExpiryTab() {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    
    return StreamBuilder<QuerySnapshot>(
      stream: siteId == null
          ? null
          : firestore
              .collection('training_records')
              .where('siteId', isEqualTo: siteId)
              .where('status', isEqualTo: 'Active')
              .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        final now = DateTime.now();
        
        final expiring = docs.where((d) {
          try {
            final data = d.data() as Map<String, dynamic>;
            final exp = DateTime.parse(data['expiryDate']);
            return exp.difference(now).inDays <= 60 && exp.isAfter(now);
          } catch (_) {
            return false;
          }
        }).toList();

        if (expiring.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: XMTheme.success.withValues(alpha: 0.5),
                ),
                GSpacing.vLg,
                Text(
                  'All certifications current',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                GSpacing.vSm,
                Text(
                  'No upcoming expirations within 60 days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expiring.length,
          itemBuilder: (ctx, i) {
            final d = expiring[i].data() as Map<String, dynamic>;
            final expDate = DateTime.parse(d['expiryDate']);
            final daysLeft = expDate.difference(now).inDays;
            final isUrgent = daysLeft <= 14;
            
            return GCard(
              margin: const EdgeInsets.only(bottom: 12),
              color: isUrgent 
                  ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3) 
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isUrgent ? Icons.priority_high : Icons.warning_amber_rounded,
                      color: isUrgent ? XMTheme.error : XMTheme.warning,
                    ),
                    GSpacing.hLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['employeeName'] ?? '',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            d['courseName'] ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$daysLeft days',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isUrgent ? XMTheme.error : XMTheme.warning,
                          ),
                        ),
                        Text(
                          'Remaining',
                          style: Theme.of(context).textTheme.labelSmall,
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

  Widget _buildRecordForm() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _empNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Employee Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    GSpacing.vLg,
                    TextFormField(
                      controller: _idNumCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ID / Payroll Number',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    GSpacing.vLg,
                    TextFormField(
                      controller: _courseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Course / Qualification *',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                    ),
                    GSpacing.vLg,
                    const Text('Certification Dates', style: TextStyle(fontWeight: FontWeight.bold)),
                    GSpacing.vMd,
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _completed,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (d != null) {
                                setSheetState(() => _completed = d);
                                setState(() => _completed = d);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Completed'),
                              child: Text('${_completed.day}/${_completed.month}/${_completed.year}'),
                            ),
                          ),
                        ),
                        GSpacing.hLg,
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _expiry,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                              );
                              if (d != null) {
                                setSheetState(() => _expiry = d);
                                setState(() => _expiry = d);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Expiry'),
                              child: Text('${_expiry.day}/${_expiry.month}/${_expiry.year}'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            UIUtils.buildFormButtons(
              context: context,
              onSave: _submitRecord,
              isSubmitting: _isSubmitting,
            ),
          ],
        );
      }
    );
  }

  Widget _buildTalkForm() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _topicCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Talk Topic *',
                        prefixIcon: Icon(Icons.topic_outlined),
                      ),
                    ),
                    GSpacing.vLg,
                    TextFormField(
                      controller: _talkLocCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Location / Venue',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    GSpacing.vLg,
                    TextFormField(
                      controller: _attendeesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Attendees',
                        hintText: 'Enter names separated by commas',
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                    ),
                    GSpacing.vMd,
                    Text(
                      'Conducted on: ${_talkDate.day}/${_talkDate.month}/${_talkDate.year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            UIUtils.buildFormButtons(
              context: context,
              onSave: _submitTalk,
              isSubmitting: _isSubmitting,
            ),
          ],
        );
      }
    );
  }
}
