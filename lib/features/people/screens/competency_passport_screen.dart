import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

/// Competency Passport — per-employee competency tracking with certifications and expiry.
class CompetencyPassportScreen extends ConsumerStatefulWidget {
  const CompetencyPassportScreen({super.key});
  @override
  ConsumerState<CompetencyPassportScreen> createState() => _CompetencyPassportScreenState();
}

class _CompetencyPassportScreenState extends ConsumerState<CompetencyPassportScreen> {
  bool _showForm = false;
  final _employeeCtrl = TextEditingController();
  final _certCtrl = TextEditingController();
  final _issuerCtrl = TextEditingController();
  String _status = 'Valid';
  DateTime? _expiryDate;
  bool _isSubmitting = false;

  static const _statuses = ['Valid', 'Expiring Soon', 'Expired', 'Revoked'];

  @override
  void dispose() { _employeeCtrl.dispose(); _certCtrl.dispose(); _issuerCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_employeeCtrl.text.isEmpty || _certCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill employee and certification'), backgroundColor: XMTheme.error));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      await ref.read(firestoreServiceProvider).createDocument(collection: 'competency_passports', data: {
        'employeeName': _employeeCtrl.text.trim(),
        'certification': _certCtrl.text.trim(),
        'issuer': _issuerCtrl.text.trim(),
        'status': _status,
        'expiryDate': _expiryDate?.toIso8601String(),
        'siteId': profile.siteId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Competency added'), backgroundColor: XMTheme.success));
        setState(() { _showForm = false; _employeeCtrl.clear(); _certCtrl.clear(); _issuerCtrl.clear(); _expiryDate = null; });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: XMTheme.error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentSiteIdProvider);
    final firestore = ref.watch(firestoreProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text('Competency Passport', style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
          FilledButton.icon(
            onPressed: () => setState(() => _showForm = !_showForm),
            icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
            label: Text(_showForm ? 'Cancel' : 'Add Cert'),
          ),
        ]),
      ),
      if (_showForm) _buildForm(context),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('competency_passports').where('siteId', isEqualTo: siteId).orderBy('createdAt', descending: true).limit(100).snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.card_membership, size: 48, color: XMTheme.secondary.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              const Text('No competency records yet'),
            ]));

            // Group by employee
            final byEmployee = <String, List<Map<String, dynamic>>>{};
            for (final doc in docs) {
              final d = doc.data() as Map<String, dynamic>;
              byEmployee.putIfAbsent(d['employeeName'] ?? 'Unknown', () => []).add(d);
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: byEmployee.entries.map((entry) {
                final allValid = entry.value.every((c) => c['status'] == 'Valid');
                final hasExpired = entry.value.any((c) => c['status'] == 'Expired');
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(XMTheme.radiusLg),
                    side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (allValid ? XMTheme.success : hasExpired ? XMTheme.error : XMTheme.warning).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            allValid ? Icons.verified : hasExpired ? Icons.cancel : Icons.warning,
                            size: 20,
                            color: allValid ? XMTheme.success : hasExpired ? XMTheme.error : XMTheme.warning,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('${entry.value.length} certifications', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (allValid ? XMTheme.success : hasExpired ? XMTheme.error : XMTheme.warning).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(XMTheme.radiusXl),
                          ),
                          child: Text(allValid ? 'COMPLIANT' : hasExpired ? 'NON-COMPLIANT' : 'ACTION NEEDED',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: allValid ? XMTheme.success : hasExpired ? XMTheme.error : XMTheme.warning)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      ...entry.value.map((cert) {
                        final status = cert['status'] ?? 'Valid';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            Container(
                              width: 4,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _statusColor(status),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(cert['certification'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                              Row(children: [
                                if (cert['issuer'] != null && cert['issuer'].toString().isNotEmpty)
                                  Text('${cert['issuer']}', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                if (cert['expiryDate'] != null) ...[
                                  Text(' • Exp: ${_formatDate(cert['expiryDate'])}', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                ],
                              ]),
                            ])),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(XMTheme.radiusXl)),
                              child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status))),
                            ),
                          ]),
                        );
                      }),
                    ]),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildForm(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add Certification', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          TextFormField(controller: _employeeCtrl, decoration: const InputDecoration(labelText: 'Employee Name *', prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 12),
          TextFormField(controller: _certCtrl, decoration: const InputDecoration(labelText: 'Certification / Competency *', prefixIcon: Icon(Icons.card_membership))),
          const SizedBox(height: 12),
          TextFormField(controller: _issuerCtrl, decoration: const InputDecoration(labelText: 'Issuing Body', prefixIcon: Icon(Icons.business))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _status = v!),
            )),
            const SizedBox(width: 12),
            Expanded(child: InkWell(
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 1825)));
                if (date != null) setState(() => _expiryDate = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Expiry Date', prefixIcon: Icon(Icons.calendar_today)),
                child: Text(_expiryDate != null ? _formatDate(_expiryDate!.toIso8601String()) : 'Select date', style: TextStyle(fontSize: 13, color: _expiryDate != null ? null : Theme.of(context).hintColor)),
              ),
            )),
          ]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            label: Text(_isSubmitting ? 'Saving...' : 'Add Certification'),
          )),
        ]),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Valid': return XMTheme.success;
      case 'Expiring Soon': return XMTheme.warning;
      case 'Expired': return XMTheme.error;
      case 'Revoked': return XMTheme.riskExtreme;
      default: return XMTheme.primary;
    }
  }
}
