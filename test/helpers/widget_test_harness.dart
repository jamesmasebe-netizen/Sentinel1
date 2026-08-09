// Shared scaffolding for widget tests (testWidgets/pumpWidget), introduced with the first real
// widget-test pass (T3-WIDGETS). Mirrors the ProviderContainer(overrides: [...]) convention
// TEST_STRATEGY.md §3 already documents for service/provider tests, adapted for a real widget
// pump — see TEST_STRATEGY.md §8 "Widget testing convention" for the binding rules this exists to
// codify (never call Firebase.initializeApp() in a test; isMockLoggedInProvider is the identity
// shortcut; the SnackBar/offline-queue timing gotchas).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

/// A ProviderContainer pre-loaded with the "logged in as the built-in dev-admin identity"
/// shortcut (`isMockLoggedInProvider`), which is what lets userProfileProvider/
/// currentTenantIdProvider resolve to a canned profile (uid 'dev-admin-123', tenantId
/// 'sentinel-dev') without ever reaching authStateProvider/FirebaseAuth.instance — the reason a
/// full widget pump can avoid Firebase.initializeApp() at all. `firestore` defaults to a fresh
/// FakeFirebaseFirestore(); pass one in if the test needs to seed data before building the
/// container. `extraOverrides` is for provider/service seams a specific screen needs (e.g.
/// offlineSyncServiceProvider, ledgerPostingServiceProvider, aiComplianceServiceProvider).
ProviderContainer buildLoggedInContainer({
  FakeFirebaseFirestore? firestore,
  List<Override> extraOverrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      firestoreProvider.overrideWithValue(firestore ?? FakeFirebaseFirestore()),
      isMockLoggedInProvider.overrideWith((ref) => true),
      ...extraOverrides,
    ],
  );
}

/// A MockOfflineSyncService with queueOperation stubbed to resolve — the override every screen
/// that writes through FirestoreService.createDocument/updateDocument needs (offlineSyncServiceProvider
/// is otherwise the REAL OfflineSyncService, whose Hive queue box is never initialized outside
/// main.dart's boot sequence, so a real write attempt throws LateInitializationError). Assertions
/// against a screen's write should verify the CAPTURED queueOperation call args (collection path +
/// data map), not look for a document landing in the fake Firestore — with this mock in place,
/// nothing actually reaches Firestore, matching every other FirestoreService-routed test in this
/// suite (see e.g. test/features/property/services/property_service_test.dart).
MockOfflineSyncService buildMockOfflineSync() {
  final mock = MockOfflineSyncService();
  when(() => mock.queueOperation(
        operation: any(named: 'operation'),
        collection: any(named: 'collection'),
        data: any(named: 'data'),
        documentId: any(named: 'documentId'),
      )).thenAnswer((_) async => 'queued-op-1');
  return mock;
}

/// Wraps [child] so it's reachable by pushing a real Navigator route from a host Scaffold's
/// "Open" button — required for any widget under test whose submit flow calls
/// Navigator.pop(context) (pumping it directly as MaterialApp(home: ...) leaves nothing to pop
/// into). Tap `find.text('Open')` to push [child] onto the stack.
Widget hostedUnderPushedRoute(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => child),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Wraps [child] directly under MaterialApp(home: ...) — for widgets whose submit flow does NOT
/// call Navigator.pop (e.g. JournalEntryForm, which only shows a SnackBar + fires a callback).
Widget hostedDirectly(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

/// Wraps a trigger button that opens [document] via DocumentReviewDialog.show(...) — exercises
/// the widget's real entry point, which also solves the "needs a route to pop into" requirement
/// for free (the dialog route itself is what Navigator.pop closes).
Widget hostedDialogTrigger(
  ProviderContainer container,
  void Function(BuildContext context) onOpenPressed,
) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => onOpenPressed(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
}
