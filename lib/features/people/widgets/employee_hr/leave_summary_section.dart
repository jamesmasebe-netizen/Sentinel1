import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/ds_widgets.dart';
import '../../../../core/utils/ui_utils.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import '../leave_application_form.dart';

class LeaveSummarySection extends ConsumerWidget {
  final String employeeId;
  const LeaveSummarySection({super.key, required this.employeeId});

  Widget _card(String title, int days, Color color, IconData icon) {
    return GCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 13, color: XMTheme.secondaryLight)),
          const SizedBox(height: 4),
          Text('$days Days', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('used this year', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Leave (This Year)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            FilledButton.tonalIcon(
              onPressed: () => UIUtils.showSideSheet(
                context: context,
                title: 'Apply for Leave',
                builder: (ctx) => const LeaveApplicationForm(),
              ),
              icon: const Icon(Icons.beach_access, size: 18),
              label: const Text('Book Leave'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: tenantId == null
              ? null
              : fs
                  .tenantCollection(tenantId, 'leave_requests')
                  .where('employeeId', isEqualTo: employeeId)
                  .snapshots(),
          builder: (ctx, snap) {
            final docs = snap.data?.docs ?? [];
            final thisYear = DateTime.now().year;
            final used = <String, int>{'Annual': 0, 'Sick': 0, 'Family Responsibility': 0};
            for (final doc in docs) {
              final d = doc.data() as Map<String, dynamic>;
              if (d['status'] != 'Approved') continue;
              final start = DateTime.tryParse(d['startDate'] ?? '');
              final end = DateTime.tryParse(d['endDate'] ?? '');
              if (start == null || end == null || start.year != thisYear) continue;
              final type = d['type'] as String? ?? 'Annual';
              if (used.containsKey(type)) {
                used[type] = used[type]! + end.difference(start).inDays + 1;
              }
            }
            return Row(
              children: [
                Expanded(child: _card('Annual Leave', used['Annual']!, XMTheme.primary, Icons.calendar_month)),
                const SizedBox(width: 16),
                Expanded(child: _card('Sick Leave', used['Sick']!, XMTheme.info, Icons.medical_services)),
                const SizedBox(width: 16),
                Expanded(child: _card('Family Resp.', used['Family Responsibility']!, XMTheme.warning, Icons.family_restroom)),
              ],
            );
          },
        ),
      ],
    );
  }
}
