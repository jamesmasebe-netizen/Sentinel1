// Tests for BillingService (lib/features/billing/services/billing_service.dart).
//
// FIXED 2026-08-07: BillingService previously hardcoded
// `FirebaseFunctions.instance`/`FirebaseFirestore.instance` as field
// initializers instead of accepting them via constructor — unlike every
// other service in this codebase (FinanceService, SafetyService, etc.),
// which made it impossible to override with a fake/mock in tests. Fixed by
// injecting both, matching the established pattern (billingServiceProvider
// now watches firebaseFunctionsProvider/firestoreProvider, mirroring
// InviteService).
//
// getSubscriptionStream is tested against a real fake_cloud_firestore
// instance (pure read/parse logic, no rules-relevant behavior). The two
// Cloud Functions wrappers (createStripeCheckoutSession/openBillingPortal)
// are tested with FirebaseFunctions/HttpsCallable mocked via mocktail — the
// real business logic they call (createStripeCheckoutSession/
// createBillingPortalSession Cloud Functions) already has full emulator-
// backed coverage from T2-003 (firebase/functions/test/rules/billing.test.ts);
// what's worth verifying client-side is that BillingService invokes the
// RIGHT callable with the RIGHT payload shape and handles the response/error
// correctly — the same class of "wrong name/wrong field" bug found
// repeatedly elsewhere this session. url_launcher's platform channel is
// mocked via the package's own documented UrlLauncherPlatform test seam
// (url_launcher_platform_interface) rather than skipped.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:sentinel1/features/billing/models/subscription_models.dart';
import 'package:sentinel1/features/billing/services/billing_service.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<dynamic> {}

class MockUrlLauncherPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

void main() {
  const tenantId = 'tenant-billing-1';

  setUpAll(() {
    registerFallbackValue(const LaunchOptions());
  });

  group('getSubscriptionStream', () {
    late FakeFirebaseFirestore firestore;
    late BillingService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = BillingService(MockFirebaseFunctions(), firestore);
    });

    Future<void> seed(Map<String, dynamic> data) async {
      await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('subscription')
          .doc('status')
          .set(data);
    }

    test('emits null when no subscription document exists', () async {
      final result = await service.getSubscriptionStream(tenantId).first;
      expect(result, isNull);
    });

    test('parses tier/status/stripeCustomerId from a real document', () async {
      await seed({
        'tenantId': tenantId,
        'tier': 'premium',
        'status': 'active',
        'stripeCustomerId': 'cus_123',
        'stripeSubscriptionId': 'sub_456',
      });

      final result = await service.getSubscriptionStream(tenantId).first;

      expect(result, isNotNull);
      expect(result!.tier, SubscriptionTier.premium);
      expect(result.status, 'active');
      expect(result.stripeCustomerId, 'cus_123');
      expect(result.stripeSubscriptionId, 'sub_456');
    });

    test('defaults an unrecognized tier string to free', () async {
      await seed({'tenantId': tenantId, 'tier': 'not-a-real-tier', 'status': 'active'});

      final result = await service.getSubscriptionStream(tenantId).first;

      expect(result!.tier, SubscriptionTier.free);
    });

    test('parses currentPeriodEnd from a Timestamp', () async {
      final periodEnd = DateTime.utc(2026, 12, 31);
      await seed({
        'tenantId': tenantId,
        'tier': 'enterprise',
        'status': 'active',
        'currentPeriodEnd': Timestamp.fromDate(periodEnd),
      });

      final result = await service.getSubscriptionStream(tenantId).first;

      expect(result!.currentPeriodEnd!.isAtSameMomentAs(periodEnd), isTrue);
    });

    test('a document with no fields at all still parses without throwing, defaulting to free/inactive',
        () async {
      await seed({});

      final result = await service.getSubscriptionStream(tenantId).first;

      expect(result!.tier, SubscriptionTier.free);
      expect(result.status, 'inactive');
    });
  });

  group('createStripeCheckoutSession', () {
    late MockFirebaseFunctions functions;
    late MockHttpsCallable callable;
    late BillingService service;
    late MockUrlLauncherPlatform urlLauncher;

    setUp(() {
      functions = MockFirebaseFunctions();
      callable = MockHttpsCallable();
      service = BillingService(functions, FakeFirebaseFirestore());
      urlLauncher = MockUrlLauncherPlatform();
      UrlLauncherPlatform.instance = urlLauncher;

      when(() => functions.httpsCallable('createStripeCheckoutSession'))
          .thenReturn(callable);
    });

    test('calls the createStripeCheckoutSession callable with tenantId, and launches the returned url',
        () async {
      final result = MockHttpsCallableResult();
      when(() => result.data).thenReturn({'url': 'https://checkout.stripe.com/session-1'});
      when(() => callable.call<dynamic>(any())).thenAnswer((_) async => result);
      when(() => urlLauncher.canLaunch(any())).thenAnswer((_) async => true);
      when(() => urlLauncher.launchUrl(any(), any())).thenAnswer((_) async => true);

      await service.createStripeCheckoutSession(tenantId);

      final captured = verify(() => callable.call<dynamic>(captureAny())).captured.single
          as Map;
      expect(captured['tenantId'], tenantId);
      expect(captured.containsKey('priceId'), isFalse);
      verify(() => urlLauncher.launchUrl('https://checkout.stripe.com/session-1', any()))
          .called(1);
    });

    test('includes priceId in the payload when supplied', () async {
      final result = MockHttpsCallableResult();
      when(() => result.data).thenReturn({'url': 'https://checkout.stripe.com/session-2'});
      when(() => callable.call<dynamic>(any())).thenAnswer((_) async => result);
      when(() => urlLauncher.canLaunch(any())).thenAnswer((_) async => true);
      when(() => urlLauncher.launchUrl(any(), any())).thenAnswer((_) async => true);

      await service.createStripeCheckoutSession(tenantId, priceId: 'price_enterprise_mock');

      final captured = verify(() => callable.call<dynamic>(captureAny())).captured.single
          as Map;
      expect(captured['priceId'], 'price_enterprise_mock');
    });

    test('does not attempt to launch anything when the callable returns no url', () async {
      final result = MockHttpsCallableResult();
      when(() => result.data).thenReturn(<String, dynamic>{});
      when(() => callable.call<dynamic>(any())).thenAnswer((_) async => result);

      await service.createStripeCheckoutSession(tenantId);

      verifyNever(() => urlLauncher.launchUrl(any(), any()));
    });

    test('wraps a callable failure in a friendly exception rather than letting it propagate raw',
        () async {
      when(() => callable.call<dynamic>(any()))
          .thenThrow(Exception('backend exploded'));

      await expectLater(
        () => service.createStripeCheckoutSession(tenantId),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to create checkout session'),
        )),
      );
    });
  });

  group('openBillingPortal', () {
    late MockFirebaseFunctions functions;
    late MockHttpsCallable callable;
    late BillingService service;
    late MockUrlLauncherPlatform urlLauncher;

    setUp(() {
      functions = MockFirebaseFunctions();
      callable = MockHttpsCallable();
      service = BillingService(functions, FakeFirebaseFirestore());
      urlLauncher = MockUrlLauncherPlatform();
      UrlLauncherPlatform.instance = urlLauncher;

      when(() => functions.httpsCallable('createBillingPortalSession'))
          .thenReturn(callable);
    });

    test('calls createBillingPortalSession with tenantId and launches the returned url', () async {
      final result = MockHttpsCallableResult();
      when(() => result.data).thenReturn({'url': 'https://billing.stripe.com/portal-1'});
      when(() => callable.call<dynamic>(any())).thenAnswer((_) async => result);
      when(() => urlLauncher.canLaunch(any())).thenAnswer((_) async => true);
      when(() => urlLauncher.launchUrl(any(), any())).thenAnswer((_) async => true);

      await service.openBillingPortal(tenantId);

      final captured = verify(() => callable.call<dynamic>(captureAny())).captured.single
          as Map;
      expect(captured, {'tenantId': tenantId});
      verify(() => urlLauncher.launchUrl('https://billing.stripe.com/portal-1', any()))
          .called(1);
    });

    test('wraps a callable failure in a friendly exception', () async {
      when(() => callable.call<dynamic>(any()))
          .thenThrow(Exception('no stripe customer'));

      await expectLater(
        () => service.openBillingPortal(tenantId),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to open billing portal'),
        )),
      );
    });
  });
}
