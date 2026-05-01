import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// PPE Compliance Tracker — Stats cards, compliance log, smart expiry reminders.
/// Mirrors React PPEComplianceTracker: employee tracking, status, expiry alerts.
class PPEComplianceScreen extends ConsumerStatefulWidget {
  const PPEComplianceScreen({super.key});

  @override
  ConsumerState<PPEComplianceScreen> createState() => _PPEComplianceScreenState();
}

class _PPEComplianceScreenState extends ConsumerState<PPEComplianceScreen> {
  bool _showForm = false;
  bool _isSubmitting = false;

  final _employeeController = TextEditingController();
  String _ppeType = 'Hard Hat';
  String _status = 'Compliant';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  static const _ppeTypes = ['Hard Hat', 'Safety Boots', 'Hi-Vis Vest', 'Safety Glasses', 'Gloves', 'Ear Protection', 'Harness', 'Respirator'];
  static const _statuses = ['Compliant', 'Non-Compliant', 'Expired'];

  @override
  void dispose() {
    _employeeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_employeeController.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');

      await ref.read(firestoreServiceProvider).createDocument(
        collection: 'ppe_compliance',
        data: {
          'employeeName': _employeeController.text.trim(),
          'ppeType': _ppeType,
          'status': _status,
          'expiryDate': _expiryDate.toIso8601String(),
          'authorId': profile.uid,
          'siteId': profile.siteId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PPE record logged'), backgroundColor: XMTheme.success),
        );
        setState(() {
          _showForm = false;
          _employeeController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: XMTheme.error));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);

    if (siteId == null) return const Center(child: Text('No site assigned'));

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('ppe_compliance')
          .where('siteId', isEqualTo: siteId)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final records = docs.map((d) => d.data() as Map<String, dynamic>).toList();

        // Stats
        final compliant = records.where((r) => r['status'] == 'Compliant').length;
        final nonCompliant = records.where((r) => r['status'] == 'Non-Compliant').length;
        final expired = records.where((r) => r['status'] == 'Expired').length;

        // Upcoming expirations (within 30 days)
        final upcoming = records.where((r) {
          if (r['status'] != 'Compliant') return false;
          try {
            final expiry = DateTime.parse(r['expiryDate']);
            final diff = expiry.difference(DateTime.now()).inDays;
            return diff > 0 && diff <= 30;
          } catch (_) {
            return false;
          }
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PPE Compliance', style: Theme.of(context).textTheme.titleMedium),
                  FilledButton.icon(
                    onPressed: () => setState(() => _showForm = !_showForm),
                    icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                    label: Text(_showForm ? 'Cancel' : 'Log'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats cards
              Row(
                children: [
                  _StatCard(icon: Icons.engineering, label: 'Total', value: '${records.length}', color: XMTheme.info),
                  _StatCard(icon: Icons.check_circle, label: 'Compliant', value: '$compliant', color: XMTheme.success),
                  _StatCard(icon: Icons.cancel, label: 'Non-Compliant', value: '$nonCompliant', color: XMTheme.error),
                  _StatCard(icon: Icons.calendar_today, label: 'Expired', value: '$expired', color: XMTheme.warning),
                ],
              ),
              const SizedBox(height: 16),

              // Form
              if (_showForm) _buildForm(),

              // Smart Reminders
              if (upcoming.isNotEmpty) ...[
                Card(
                  color: XMTheme.info.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notifications_active, color: XMTheme.info, size: 18),
                            const SizedBox(width: 8),
                            Text('Smart Reminders', style: TextStyle(fontWeight: FontWeight.w600, color: XMTheme.info, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...upcoming.map((r) {
                          final daysLeft = DateTime.parse(r['expiryDate']).difference(DateTime.now()).inDays;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r['employeeName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text(r['ppeType'] ?? '', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: XMTheme.warning.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('$daysLeft days left', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: XMTheme.warning)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Compliance log
              Text('Compliance Log', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (records.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No PPE records found')))
              else
                ...records.map((r) => _PPERow(data: r)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForm() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log PPE Compliance', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: _employeeController,
              decoration: const InputDecoration(labelText: 'Employee Name *', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _ppeType,
                    decoration: const InputDecoration(labelText: 'PPE Type', isDense: true),
                    items: _ppeTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _ppeType = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status', isDense: true),
                    items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Expiry Date'),
              subtitle: Text('${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}'),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _expiryDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 1825)));
                if (d != null) setState(() => _expiryDate = d);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                label: Text(_isSubmitting ? 'Saving...' : 'Save Record'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
              Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PPERow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PPERow({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Unknown';
    Color statusColor;
    switch (status) {
      case 'Compliant': statusColor = XMTheme.success;
      case 'Non-Compliant': statusColor = XMTheme.error;
      case 'Expired': statusColor = XMTheme.warning;
      default: statusColor = XMTheme.statusDraft;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(data['employeeName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          Expanded(flex: 2, child: Text(data['ppeType'] ?? '', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(status, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: Text(_fmtDate(data['expiryDate']), style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant))),
        ],
      ),
    );
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
