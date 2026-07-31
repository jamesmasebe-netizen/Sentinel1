import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/ds_widgets.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class PayslipsSection extends ConsumerWidget {
  final String employeeId;
  const PayslipsSection({super.key, required this.employeeId});

  void _showDetail(BuildContext context, Map<String, dynamic> d) {
    final base = (d['baseSalary'] ?? 0).toDouble();
    final bonuses = (d['bonuses'] ?? 0).toDouble();
    final deductions = (d['deductions'] ?? 0).toDouble();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payslip Breakdown'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Base Salary: R${base.toStringAsFixed(2)}'),
            Text('Bonuses: R${bonuses.toStringAsFixed(2)}'),
            Text('Deductions: R${deductions.toStringAsFixed(2)}'),
            const Divider(),
            Text(
              'Net Pay: R${(base + bonuses - deductions).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Payslips', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: tenantId == null
              ? null
              : fs
                  .tenantCollection(tenantId, 'payroll_ledgers')
                  .where('employeeId', isEqualTo: employeeId)
                  .orderBy('periodEnd', descending: true)
                  .limit(3)
                  .snapshots(),
          builder: (ctx, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return GCard(padding: const EdgeInsets.all(16), child: Text('No payslips found', style: TextStyle(color: Theme.of(context).disabledColor)));
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
                  final period = (d['periodEnd'] as Timestamp?)?.toDate();
                  return ListTile(
                    leading: const Icon(Icons.request_quote, color: XMTheme.primary),
                    title: Text(
                      'Payslip - ${period != null ? DateFormat('MMMM yyyy').format(period) : 'Unknown period'}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(d['status']?.toString() ?? 'Processed'),
                    trailing: IconButton(
                      icon: const Icon(Icons.receipt_long),
                      onPressed: () => _showDetail(context, d),
                    ),
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
