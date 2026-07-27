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

final pendingApprovalsProvider = StreamProvider<List<ApprovalItem>>((
  ref,
) async* {
  final userProfile = ref.watch(userProfileProvider).valueOrNull;
  if (userProfile == null) {
    yield [];
    return;
  }

  // We use RxDart or just listen to multiple streams and combine them.
  // For simplicity, we'll yield a combined list.
  // Wait, StreamProvider can handle a single stream well. We can yield* a Stream.multi or just a combined stream.

  // Actually, since Firestore SDK in Flutter doesn't easily combine disparate collections,
  // we can use a custom Stream that combines them using combineLatest or asyncMap.
  // Let's use a simpler approach: listening to collections sequentially in a periodic timer? No,
  // we can just return a Stream created from StreamGroup or manually updating a list.

  // We'll create a manual stream controller to combine them.
  // Dart's StreamZip or similar isn't available by default without async package.
  // Alternatively, we can use an async generator with a loop if we don't need real-time streams for all 3 instantly.
  // But let's just make it a FutureProvider if it's easier, or we can just fetch Futures and yield them?
  // Let's use a FutureProvider for simplicity of combined results, or StreamProvider that maps.
  // Let's just yield the result from Futures for now since it's an inbox.
});

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
