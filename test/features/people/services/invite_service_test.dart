// Tests for InviteService (lib/features/people/services/invite_service.dart).
// Mirrors billing_service_test.dart's approach: streamPendingInvites is
// tested against a real fake_cloud_firestore instance, createInvite (which
// wraps a Cloud Functions callable) is tested with FirebaseFunctions/
// HttpsCallable mocked via mocktail.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/features/people/services/invite_service.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<dynamic> {}

void main() {
  const tenantId = 'tenant-invite-1';

  group('streamPendingInvites', () {
    late FakeFirebaseFirestore firestore;
    late InviteService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = InviteService(firestore, MockFirebaseFunctions(), tenantId);
    });

    test('returns an empty stream when there is no active tenant', () async {
      final noTenantService = InviteService(firestore, MockFirebaseFunctions(), null);
      final result = await noTenantService.streamPendingInvites().first;
      expect(result, isEmpty);
    });

    test('returns only pending invites for this tenant, newest first', () async {
      final invitesRef = firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('invites');
      await invitesRef.doc('inv-1').set({
        'email': 'a@test.com',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      await invitesRef.doc('inv-2').set({
        'email': 'b@test.com',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
      });
      await invitesRef.doc('inv-3').set({
        'email': 'c@test.com',
        'status': 'accepted',
        'createdAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
      });

      final result = await service.streamPendingInvites().first;

      expect(result, hasLength(2));
      expect(result.first.email, 'b@test.com');
      expect(result.last.email, 'a@test.com');
    });
  });

  group('createInvite', () {
    late MockFirebaseFunctions functions;
    late MockHttpsCallable callable;
    late InviteService service;

    setUp(() {
      functions = MockFirebaseFunctions();
      callable = MockHttpsCallable();
      service = InviteService(FakeFirebaseFirestore(), functions, tenantId);
      when(() => functions.httpsCallable('createInvite')).thenReturn(callable);
    });

    test('calls the createInvite callable with email, role, and tenantId', () async {
      final result = MockHttpsCallableResult();
      when(() => callable.call<dynamic>(any())).thenAnswer((_) async => result);

      await service.createInvite(email: 'new@test.com', role: 'manager');

      final captured = verify(() => callable.call<dynamic>(captureAny())).captured.single
          as Map;
      expect(captured, {
        'email': 'new@test.com',
        'role': 'manager',
        'tenantId': tenantId,
      });
    });

    test('throws immediately without calling the function when there is no active tenant', () async {
      final noTenantService = InviteService(FakeFirebaseFirestore(), functions, null);

      await expectLater(
        () => noTenantService.createInvite(email: 'x@test.com', role: 'employee'),
        throwsException,
      );
      verifyNever(() => callable.call<dynamic>(any()));
    });

    test('wraps a FirebaseFunctionsException in a friendlier message', () async {
      when(() => callable.call<dynamic>(any())).thenThrow(
        FirebaseFunctionsException(message: 'already invited', code: 'already-exists'),
      );

      await expectLater(
        () => service.createInvite(email: 'dup@test.com', role: 'employee'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to send invite'),
        )),
      );
    });
  });
}
