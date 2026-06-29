import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/offline_sync_service.dart';
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

/// Firestore service with offline-first writes
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final offlineSync = ref.watch(offlineSyncServiceProvider);
  return FirestoreService(firestore, offlineSync);
});

/// Auth service
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ─── Auth State Providers ───

/// Stream of Firebase auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Current user profile from Firestore
final userProfileProvider = StreamProvider<UserProfile?>((ref) async* {
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

/// Current site ID (used for all Firestore queries)
final currentSiteIdProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.whenOrNull(data: (p) => p?.siteId);
});

/// Whether the user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull != null;
});

/// User role for access control
final userRoleProvider = Provider<String>((ref) {
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
