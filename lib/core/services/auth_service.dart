import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user_profile.dart';
import '../../config/firebase_config.dart';

/// Authentication service handling Google Sign-In, biometrics, and user profile management.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  // Stream controller for user profile changes
  final _profileController = StreamController<UserProfile?>.broadcast();
  Stream<UserProfile?> get profileStream => _profileController.stream;

  UserProfile? _currentProfile;
  UserProfile? get currentProfile => _currentProfile;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  /// Sign in with Google
  Future<UserProfile?> signInWithGoogle() async {
    try {
      // Use Firebase Auth's built-in Google provider for cross-platform support
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final userCredential = await _auth.signInWithProvider(googleProvider);
      final user = userCredential.user;
      if (user == null) return null;

      // Store auth state for biometric re-login
      await _secureStorage.write(key: 'auth_uid', value: user.uid);
      await _secureStorage.write(key: 'biometric_enabled', value: 'true');

      // Fetch or create user profile
      final profile = await _getOrCreateProfile(user);
      _currentProfile = profile;
      _profileController.add(profile);
      return profile;
    } catch (e) {
      rethrow;
    }
  }

  /// Authenticate with biometrics (for app unlock)
  Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheck || !isDeviceSupported) return false;

      final biometricEnabled = await _secureStorage.read(key: 'biometric_enabled');
      if (biometricEnabled != 'true') return false;

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access XM System',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric auth is available and enabled
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Check if user was previously logged in (for auto-login with biometrics)
  Future<bool> hasPreviousSession() async {
    final uid = await _secureStorage.read(key: 'auth_uid');
    return uid != null && _auth.currentUser != null;
  }

  /// Get or create user profile in Firestore
  Future<UserProfile> _getOrCreateProfile(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      // Update last login
      await docRef.update({'lastLogin': FieldValue.serverTimestamp()});
      return UserProfile.fromFirestore(doc);
    }

    // Create new profile with default siteId
    final newProfile = UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'New User',
      photoURL: user.photoURL,
      role: 'employee',
      siteId: FirebaseConfig.defaultSiteId,
    );

    await docRef.set(newProfile.toFirestore());

    // Re-fetch to get server timestamps
    final created = await docRef.get();
    return UserProfile.fromFirestore(created);
  }

  /// Refresh the current user profile from Firestore
  Future<UserProfile?> refreshProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    _currentProfile = UserProfile.fromFirestore(doc);
    _profileController.add(_currentProfile);
    return _currentProfile;
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update(updates);
    await refreshProfile();
  }

  /// Sign out
  Future<void> signOut() async {
    await _secureStorage.delete(key: 'auth_uid');
    await _auth.signOut();
    _currentProfile = null;
    _profileController.add(null);
  }

  /// Listen to auth state and keep profile in sync
  void listenToAuthState() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await refreshProfile();
      } else {
        _currentProfile = null;
        _profileController.add(null);
      }
    });
  }

  void dispose() {
    _profileController.close();
  }
}
