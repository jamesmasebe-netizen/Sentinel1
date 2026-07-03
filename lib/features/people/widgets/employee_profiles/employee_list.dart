import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/widgets/ds_widgets.dart';
import 'employee_card.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

class EmployeeList extends StatelessWidget {
  final FirebaseFirestore firestore;
  final String siteId;
  final String search;
  final String filterStatus;
  final String filterDept;

  const EmployeeList({
    super.key,
    required this.firestore,
    required this.siteId,
    required this.search,
    required this.filterStatus,
    required this.filterDept,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .tenantCollection(siteId, 'employees')
          .where('siteId', isEqualTo: siteId)
          .orderBy('fullName')
          .snapshots(),
      builder: (ctx, snap) {
        final docs = (snap.data?.docs ?? []).where((d) {
          final data = d.data() as Map<String, dynamic>;
          final matchSearch =
              (data['fullName'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(search.toLowerCase()) ||
              (data['employeeCode'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(search.toLowerCase());
          final matchStatus = filterStatus == 'All' || data['status'] == filterStatus;
          final matchDept = filterDept == 'All' || data['department'] == filterDept;
          return matchSearch && matchStatus && matchDept;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
                GSpacing.vMd,
                const Text('No employees found'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return EmployeeCard(
              data: d,
              onTap: () => context.push('/employee-360/${docs[i].id}'),
            );
          },
        );
      },
    );
  }
}
