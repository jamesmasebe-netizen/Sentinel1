import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../../../core/utils/ui_utils.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../disciplinary_record_form.dart';

class DisciplinarySection extends ConsumerWidget {
  final String employeeId;
  final String employeeName;
  const DisciplinarySection({super.key, required this.employeeId, required this.employeeName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Disciplinary Record', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => UIUtils.showSideSheet(
                context: context,
                title: 'Log Disciplinary Action',
                builder: (ctx) => DisciplinaryRecordForm(employeeId: employeeId, employeeName: employeeName),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Log Action'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: tenantId == null
              ? null
              : fs
                  .tenantCollection(tenantId, 'disciplinary_records')
                  .where('employeeId', isEqualTo: employeeId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
          builder: (ctx, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.gavel, size: 48, color: XMTheme.secondaryLight.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text('No disciplinary records found.'),
                    ],
                  ),
                ),
              );
            }
            return GCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final d = docs[index].data() as Map<String, dynamic>;
                  final date = (d['dateIssued'] as Timestamp?)?.toDate();
                  return ListTile(
                    leading: const Icon(Icons.gavel, color: XMTheme.warning),
                    title: Text(d['actionType']?.toString() ?? 'Action', style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(date != null ? DateFormat('MMM d, yyyy').format(date) : ''),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
