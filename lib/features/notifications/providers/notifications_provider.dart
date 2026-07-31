import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'leave', 'training', 'action', etc.
  final bool isRead;
  final DateTime createdAt;
  final String? collectionPath;
  final String? recordId;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.collectionPath,
    this.recordId,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      collectionPath: data['collectionPath'],
      recordId: data['recordId'],
    );
  }
}

/// Real notifications stream for the signed-in user, scoped to their tenant
/// (tenants/{tenantId}/notifications, filtered by recipientUid) — matching
/// this app's tenant-scoping convention rather than a top-level per-user
/// path. See F-520 in docs/fixes/FIX_LIST.md.
final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final tenantId = ref.watch(currentTenantIdProvider);
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (tenantId == null || profile == null) return const Stream.empty();

  return ref
      .watch(firestoreProvider)
      .tenantCollection(tenantId, 'notifications')
      .where('recipientUid', isEqualTo: profile.uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map((d) => AppNotification.fromFirestore(d)).toList());
});
