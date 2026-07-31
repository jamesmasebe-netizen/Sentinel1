import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class ApprovalItem {
  final String id;
  final String type; // 'Leave', 'Job Requisition', 'Incident'
  final String title;
  final String subtitle;
  final DateTime date;
  final String collectionPath; // e.g., 'leave_requests'
  final Map<String, dynamic> rawData;

  ApprovalItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.collectionPath,
    required this.rawData,
  });
}

final pendingApprovalsFutureProvider =
    FutureProvider.autoDispose<List<ApprovalItem>>((ref) async {
      final userProfile = ref.watch(userProfileProvider).valueOrNull;
      if (userProfile == null) return [];

      final siteId = ref.watch(currentTenantIdProvider);

      List<ApprovalItem> items = [];

      // 1. Leave Requests
      final leaves =
          await FirebaseFirestore.instance
              .tenantCollection(
                ref.watch(currentTenantIdProvider) ?? "",
                'leave_requests',
              )
              .where('siteId', isEqualTo: siteId)
              .where('managerId', isEqualTo: userProfile.uid)
              .where('status', isEqualTo: 'Pending')
              .get();

      for (var doc in leaves.docs) {
        final data = doc.data();
        items.add(
          ApprovalItem(
            id: doc.id,
            type: 'Leave',
            title: '${data['employeeName']} - ${data['leaveType']}',
            subtitle: data['reason'] ?? 'No reason provided',
            date: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            collectionPath: 'leave_requests',
            rawData: data,
          ),
        );
      }

      // 2. Job Requisitions (if user is HR manager / approver)
      final reqs =
          await ref
              .watch(firestoreProvider)
              .tenantCollection(
                ref.watch(currentTenantIdProvider) ?? "",
                'job_requisitions',
              )
              .where('siteId', isEqualTo: siteId)
              .where('hiringManagerId', isEqualTo: userProfile.uid)
              .where(
                'status',
                isEqualTo: 'Draft',
              ) // Using Draft as pending approval
              .get();

      for (var doc in reqs.docs) {
        final data = doc.data();
        items.add(
          ApprovalItem(
            id: doc.id,
            type: 'Job Requisition',
            title: data['jobTitle'] ?? 'Unknown Role',
            subtitle: data['department'] ?? 'Unknown Dept',
            date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            collectionPath: 'job_requisitions',
            rawData: data,
          ),
        );
      }

      // Sort by date descending
      items.sort((a, b) => b.date.compareTo(a.date));

      return items;
    });
