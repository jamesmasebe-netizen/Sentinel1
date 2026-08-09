// Integration test: incident reporting golden path (T3-INTEGRATION).
//
// Runs the REAL app assembly (real main.dart-equivalent Firebase boot, real GoRouter, real
// AuthService.devBypassLogin — Firebase Auth anonymous sign-in + a real Firestore users/{uid}
// profile write) against the LOCAL Firebase Emulator Suite (Auth + Firestore + Functions), not
// production — matching TEST_STRATEGY.md §1's binding mock-vs-emulator rule: this is exactly the
// class of test ("correctness depends on firestore.rules enforcement") the emulator exists for.
//
// Requires the emulator suite running with functions included, since firestore.rules'
// belongsToTenant() checks request.auth.token.tenantId — an Auth CUSTOM CLAIM, not a Firestore
// field — and nothing sets that claim except the syncUserClaims Firestore-trigger Cloud Function
// reacting to the users/{uid} write AuthService._getOrCreateProfile() makes. Start with:
//   cd firebase/functions && npm run build && cd ../..
//   firebase emulators:start --only auth,firestore,functions
// then, in another terminal:
//   flutter test integration_test/incident_reporting_test.dart -d macos
//
// Does NOT call main() or modify lib/main.dart — replicates the relevant parts of its bootstrap
// here, redirected at the emulators, so production boot code is never touched for test purposes.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/main.dart';

const _databaseId = 'ai-studio-4bb0fb1c-c6d6-4397-a015-156f3ff9dfb5';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('incident reporting golden path: dev-bypass login -> report a Minor incident -> it lands in Firestore',
      (tester) async {
    await dotenv.load(fileName: '.env');
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
      ),
    );

    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    final firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: _databaseId);
    firestore.useFirestoreEmulator('localhost', 8080);

    await Hive.initFlutter();
    final preferencesBox = await Hive.openBox<bool>('preferences');
    addTearDown(() async {
      await preferencesBox.close();
    });

    final container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
    ]);
    addTearDown(container.dispose);
    await container.read(offlineSyncServiceProvider).initialize();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const XMSystemApp()),
    );
    await tester.pumpAndSettle();

    // ─── Dev-bypass login (real Firebase Auth anonymous sign-in against the emulator) ───
    expect(find.text('Bypass Login (Dev)'), findsOneWidget);
    await tester.tap(find.text('Bypass Login (Dev)'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // The signInAnonymously()+profile-write completed and the router redirected away from
    // /login the instant isAuthenticatedProvider flipped true — but the *incident write* below
    // additionally needs the syncUserClaims trigger to have set the tenantId/role custom claims
    // on the ID token, which races the Firestore trigger's own completion (a real, pre-existing
    // race in AuthService.devBypassLogin itself, not something to paper over). Poll for the
    // claim rather than assuming a fixed delay is enough.
    final user = FirebaseAuth.instance.currentUser;
    expect(user, isNotNull);
    var hasTenantClaim = false;
    for (var attempt = 0; attempt < 20 && !hasTenantClaim; attempt++) {
      final tokenResult = await user!.getIdTokenResult(true);
      hasTenantClaim = tokenResult.claims?['tenantId'] != null;
      if (!hasTenantClaim) await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    expect(hasTenantClaim, isTrue,
        reason: 'syncUserClaims did not set the tenantId custom claim within 10s — is the '
            'functions emulator running (firebase emulators:start --only auth,firestore,functions)?');

    // ─── Navigate directly to the Safety Hub — this test is about the incident-reporting flow
    // itself, not launchpad tile-tapping, so drive GoRouter directly rather than coupling to
    // launchpad UI text/layout that can change independently of this flow. ───
    final routerContext = tester.element(find.byType(Scaffold).first);
    GoRouter.of(routerContext).go('/safety');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report Incident').first);
    await tester.pumpAndSettle();

    // ─── Fill and submit the golden-path (Minor severity) incident ───
    final title = 'Integration test incident ${DateTime.now().millisecondsSinceEpoch}';
    await tester.enterText(find.widgetWithText(TextFormField, 'Incident Title *'), title);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Detailed Description *'),
      'Created by the incident-reporting integration test golden path.',
    );

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ─── Verify: the incident actually landed in the real (emulated) tenant-scoped Firestore
    // path, past real firestore.rules enforcement — not a fake/mock, the actual point of this
    // being an integration test rather than another widget test. ───
    final matches = await firestore
        .collection('tenants')
        .doc('LDN-01')
        .collection('incidents')
        .where('title', isEqualTo: title)
        .get();
    expect(matches.docs, hasLength(1));
    expect(matches.docs.single.data()['status'], 'Open');
    expect(matches.docs.single.data()['severity'], 'Minor');
  });
}
