import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/ppe_dashboard.dart';
import '../widgets/ppe_issuance_form.dart';
import '../widgets/ppe_inspections_list.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class PPEComplianceScreen extends ConsumerStatefulWidget {
  const PPEComplianceScreen({super.key});

  @override
  ConsumerState<PPEComplianceScreen> createState() => _PPEComplianceScreenState();
}

class _PPEComplianceScreenState extends ConsumerState<PPEComplianceScreen> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentTenantIdProvider);
    final firestore = ref.watch(firestoreProvider);
    final role = ref.watch(userRoleProvider);
    final canIssue = role == 'admin' || role == 'executive' || role == 'sheq';

    if (siteId == null) return const Center(child: Text('No site assigned'));

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'ppe_compliance')
          .where('siteId', isEqualTo: siteId)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final records = docs.map((d) => d.data() as Map<String, dynamic>).toList();

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
              GHeader(
                title: 'PPE Compliance',
                subtitle: 'Track equipment assignments and expiry alerts',
                trailing: canIssue ? FilledButton.icon(
                  onPressed: () => setState(() => _showForm = !_showForm),
                  icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                  label: Text(_showForm ? 'Cancel' : 'Log'),
                ) : null,
              ),
              GSpacing.vMd,

              PPEDashboard(records: records, upcoming: upcoming),

              if (_showForm) PPEIssuanceForm(tenantId: ref.read(currentTenantIdProvider)!, 
                onCancel: () => setState(() => _showForm = false),
              ),

              Text('Compliance Log', style: Theme.of(context).textTheme.titleSmall),
              GSpacing.vSm,
              PPEInspectionsList(
                records: records,
                onLogNewCheck: (employeeName) {
                  setState(() => _showForm = true);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
