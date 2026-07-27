import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/offline_sync_service.dart';
import '../services/audit_log_service.dart';
import '../models/user_profile.dart';

// ─── Core Service Providers ───

/// Firebase instances
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// Offline sync service (initialized in main.dart)
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return OfflineSyncService(firestore);
});

final auditLogServiceProvider = Provider<AuditLogService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return AuditLogService(firestore);
});

/// Firestore service with offline-first writes
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final offlineSync = ref.watch(offlineSyncServiceProvider);
  final auditLog = ref.watch(auditLogServiceProvider);
  return FirestoreService(firestore, offlineSync, auditLog);
});

/// Auth service
final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  service.onSignOut = () {
    ref.read(isMockLoggedInProvider.notifier).state = false;
  };
  return service;
});

// ─── Auth State Providers ───

final isMockLoggedInProvider = StateProvider<bool>((ref) => false);

/// Stream of Firebase auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Current user profile from Firestore
final userProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final isMocked = ref.watch(isMockLoggedInProvider);
  if (isMocked) {
    yield UserProfile(
      uid: 'dev-admin-123',
      email: 'dev@sentinel.com',
      displayName: 'Developer Admin',
      photoURL: null,
      role: 'admin',
      tenantId: 'sentinel-dev',
    );
    return;
  }

  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    yield null;
    return;
  }

  final firestore = ref.watch(firestoreProvider);
  yield* firestore
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null);
});

/// Extracted custom claims from Firebase ID Token
final authClaimsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return {};

  // Force refresh to get the latest claims if updated recently
  final idTokenResult = await user.getIdTokenResult(true);
  return idTokenResult.claims ?? {};
});

final tenantIdClaimProvider = Provider<AsyncValue<String?>>((ref) {
  return ref
      .watch(authClaimsProvider)
      .whenData((claims) => claims['tenantId'] as String?);
});

final roleClaimProvider = Provider<AsyncValue<String?>>((ref) {
  return ref
      .watch(authClaimsProvider)
      .whenData((claims) => claims['role'] as String?);
});

/// Current tenant ID (used for all Firestore queries)
final currentTenantIdProvider = Provider<String?>((ref) {
  final isMocked = ref.watch(isMockLoggedInProvider);
  if (isMocked) return 'sentinel-dev';

  final claims = ref.watch(authClaimsProvider).valueOrNull ?? {};
  if (claims.containsKey('tenantId')) {
    return claims['tenantId'] as String?;
  }

  // Fallback to profile
  final profile = ref.watch(userProfileProvider);
  return profile.whenOrNull(data: (p) => p?.tenantId);
});

/// Resolves the base document reference for the current tenant.
/// Use this provider in all service classes instead of root collection references.
final tenantDocProvider = Provider<DocumentReference>((ref) {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null || tenantId.isEmpty) {
    throw Exception('No active tenant ID found for the current session.');
  }
  return ref.watch(firestoreProvider).collection('tenants').doc(tenantId);
});

/// Whether the user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final isMocked = ref.watch(isMockLoggedInProvider);
  if (isMocked) return true;
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull != null;
});

/// User role for access control
final userRoleProvider = Provider<String>((ref) {
  final isMocked = ref.watch(isMockLoggedInProvider);
  if (isMocked) return 'admin';

  final claims = ref.watch(authClaimsProvider).valueOrNull ?? {};
  if (claims.containsKey('role')) {
    return claims['role'] as String;
  }

  // Fallback to profile
  final profile = ref.watch(userProfileProvider);
  return profile.valueOrNull?.role ?? 'user';
});

/// Is executive access
final isExecutiveProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'admin' || role == 'executive';
});

// ─── Sync Status Providers ───

/// Offline sync status stream
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final offlineSync = ref.watch(offlineSyncServiceProvider);
  return offlineSync.syncStatus;
});

/// Pending sync operations count
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final offlineSync = ref.watch(offlineSyncServiceProvider);
  return offlineSync.pendingCount;
});

// ─── Theme Providers ───

/// Dark mode toggle
final isDarkModeProvider = StateProvider<bool>((ref) => false);
