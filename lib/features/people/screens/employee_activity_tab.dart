import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class EmployeeActivityTab extends ConsumerWidget {
  final String employeeId;
  const EmployeeActivityTab({super.key, required this.employeeId});

  DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  Widget _section(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required Color color,
    required String collection,
    required String linkField,
    required String dateField,
  }) {
    final tenantId = ref.watch(currentTenantIdProvider);
    final fs = ref.watch(firestoreProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream:
                tenantId == null
                    ? null
                    : fs
                        .tenantCollection(tenantId, collection)
                        .where(linkField, isEqualTo: employeeId)
                        .orderBy(dateField, descending: true)
                        .limit(5)
                        .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return GCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No records found',
                    style: TextStyle(color: Theme.of(context).disabledColor),
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
                    final date = _parseDate(d[dateField]);
                    final status = d['status']?.toString();
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.1),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(
                        (d['title'] ?? d['type'] ?? 'Untitled').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        date != null
                            ? DateFormat('MMM d, yyyy - HH:mm').format(date)
                            : 'Unknown date',
                      ),
                      trailing:
                          status == null
                              ? null
                              : GStatusTag(label: status.toUpperCase(), color: color),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section(
            context,
            ref,
            title: 'Incidents Reported',
            icon: Icons.warning,
            color: XMTheme.error,
            collection: 'incidents',
            linkField: 'reportedBy',
            dateField: 'dateOfIncident',
          ),
          _section(
            context,
            ref,
            title: 'Permits Requested',
            icon: Icons.assignment_turned_in,
            color: XMTheme.success,
            collection: 'permits',
            linkField: 'requestedBy',
            dateField: 'createdAt',
          ),
          _section(
            context,
            ref,
            title: 'Risk Assessments (HIRA)',
            icon: Icons.analytics,
            color: XMTheme.info,
            collection: 'risk_assessments',
            linkField: 'assessedBy',
            dateField: 'createdAt',
          ),
        ],
      ),
    );
  }
}
