// Tests for AuthService (lib/core/services/auth_service.dart) — covers the Firestore-backed
// profile management logic (devBypassLogin/_getOrCreateProfile, refreshProfile, updateProfile,
// signOut, hasPreviousSession) using firebase_auth_mocks' MockFirebaseAuth + fake_cloud_firestore,
// per its fully-injectable constructor. The biometric methods (authenticateWithBiometrics/
// isBiometricAvailable) depend on the local_auth platform plugin, which has no equivalent
// official test double, and aren't covered here.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/services/auth_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFlutterSecureStorage secureStorage;
  late MockFirebaseAuth mockAuth;
  late AuthService authService;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    secureStorage = MockFlutterSecureStorage();
    when(() => secureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((_) async {});
    when(() => secureStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    when(() => secureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'uid-1', isAnonymous: true, email: ''),
    );
    authService = AuthService(auth: mockAuth, firestore: firestore, secureStorage: secureStorage);
  });

  group('devBypassLogin', () {
    test('creates a new profile with default role employee and the default tenant, on first login',
        () async {
      final profile = await authService.devBypassLogin();

      expect(profile, isNotNull);
      expect(profile!.uid, 'uid-1');
      expect(profile.role, 'employee');
      expect(profile.tenantId, isNotEmpty);

      final doc = await firestore.collection('users').doc('uid-1').get();
      expect(doc.exists, isTrue);
    });

    test('updates lastLogin (does not recreate) on a second login for the same user', () async {
      await authService.devBypassLogin();
      final firstDoc = await firestore.collection('users').doc('uid-1').get();
      final firstRole = firstDoc.data()!['role'];

      await authService.devBypassLogin();

      final secondDoc = await firestore.collection('users').doc('uid-1').get();
      expect(secondDoc.data()!['role'], firstRole);
      expect(secondDoc.data()!.containsKey('lastLogin'), isTrue);
    });

    test('exposes the signed-in profile via currentProfile and profileStream', () async {
      final emitted = <String?>[];
      final sub = authService.profileStream.listen((p) => emitted.add(p?.uid));
      addTearDown(sub.cancel);

      await authService.devBypassLogin();

      expect(authService.currentProfile?.uid, 'uid-1');
      await Future<void>.delayed(Duration.zero);
      expect(emitted, contains('uid-1'));
    });
  });

  group('updateProfile / refreshProfile', () {
    test('updateProfile persists the given fields and refreshes currentProfile', () async {
      await authService.devBypassLogin();

      await authService.updateProfile({'displayName': 'Updated Name'});

      expect(authService.currentProfile?.displayName, 'Updated Name');
      final doc = await firestore.collection('users').doc('uid-1').get();
      expect(doc.data()!['displayName'], 'Updated Name');
    });
  });

  group('signOut', () {
    test('clears currentProfile and calls the underlying sign-out', () async {
      await authService.devBypassLogin();
      expect(authService.currentProfile, isNotNull);

      await authService.signOut();

      expect(authService.currentProfile, isNull);
      verify(() => secureStorage.delete(key: 'auth_uid')).called(1);
    });
  });

  group('hasPreviousSession', () {
    test('is false when there is no stored uid, even if a user happens to be signed in', () async {
      final result = await authService.hasPreviousSession();
      expect(result, isFalse);
    });

    test('is true when a uid is stored and a user is currently signed in', () async {
      when(() => secureStorage.read(key: 'auth_uid')).thenAnswer((_) async => 'uid-1');

      final result = await authService.hasPreviousSession();

      expect(result, isTrue);
    });
  });
}
