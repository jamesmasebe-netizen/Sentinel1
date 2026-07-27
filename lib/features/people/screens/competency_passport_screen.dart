import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../core/utils/ui_utils.dart';
import '../widgets/competency_passport/competency_form_card.dart';
import '../widgets/competency_passport/competency_employee_card.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

/// Competency Passport — per-employee competency tracking with certifications and expiry.
class CompetencyPassportScreen extends ConsumerStatefulWidget {
  const CompetencyPassportScreen({super.key});
  @override
  ConsumerState<CompetencyPassportScreen> createState() =>
      _CompetencyPassportScreenState();
}

class _CompetencyPassportScreenState
    extends ConsumerState<CompetencyPassportScreen> {
  bool _showForm = false;
  final _employeeCtrl = TextEditingController();
  final _certCtrl = TextEditingController();
  final _issuerCtrl = TextEditingController();
  String _status = 'Valid';
  DateTime? _expiryDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _employeeCtrl.dispose();
    _certCtrl.dispose();
    _issuerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_employeeCtrl.text.isEmpty || _certCtrl.text.isEmpty) {
      UIUtils.showToast(
        context,
        'Please fill employee and certification',
        type: ToastType.error,
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');
      await ref
          .read(firestoreServiceProvider)
          .createDocument(
            tenantId: ref.read(currentTenantIdProvider) ?? '',
            collection: 'competency_passports',
            data: {
              'employeeName': _employeeCtrl.text.trim(),
              'certification': _certCtrl.text.trim(),
              'issuer': _issuerCtrl.text.trim(),
              'status': _status,
              'expiryDate': _expiryDate?.toIso8601String(),
              'siteId': profile.tenantId,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
      if (mounted) {
        UIUtils.showToast(context, 'Competency added', type: ToastType.success);
        setState(() {
          _showForm = false;
          _employeeCtrl.clear();
          _certCtrl.clear();
          _issuerCtrl.clear();
          _expiryDate = null;
        });
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);
    if (siteId == null) return const Center(child: Text('No site assigned'));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Column(
        children: [
          const GHeader(
            title: 'Competency Passport',
            subtitle: 'Digital worker verification and certificate tracking',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Employee Certifications',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                FilledButton.icon(
                  onPressed: () => setState(() => _showForm = !_showForm),
                  icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                  label: Text(_showForm ? 'Cancel' : 'Add Cert'),
                ),
              ],
            ),
          ),
          GSpacing.vMd,
          if (_showForm)
            CompetencyFormCard(
              employeeCtrl: _employeeCtrl,
              certCtrl: _certCtrl,
              issuerCtrl: _issuerCtrl,
              status: _status,
              onStatusChanged: (v) => setState(() => _status = v),
              expiryDate: _expiryDate,
              onExpiryDateChanged: (d) => setState(() => _expiryDate = d),
              isSubmitting: _isSubmitting,
              onSubmit: _submit,
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  firestore
                      .tenantCollection(
                        ref.watch(currentTenantIdProvider) ?? "",
                        'competency_passports',
                      )
                      .where('siteId', isEqualTo: siteId)
                      .orderBy('createdAt', descending: true)
                      .limit(100)
                      .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_membership,
                          size: 48,
                          color: XMTheme.secondary.withValues(alpha: 0.3),
                        ),
                        GSpacing.vMd,
                        const Text('No competency records yet'),
                      ],
                    ),
                  );
                }

                // Group by employee
                final byEmployee = <String, List<Map<String, dynamic>>>{};
                for (final doc in docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  byEmployee
                      .putIfAbsent(d['employeeName'] ?? 'Unknown', () => [])
                      .add(d);
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children:
                      byEmployee.entries.map<Widget>((entry) {
                        return CompetencyEmployeeCard(entry: entry);
                      }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
