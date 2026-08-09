// Widget tests for IncidentReportForm (T3-WIDGETS) — this session's first real widget-test pass.
// See docs/testing/TEST_STRATEGY.md §8 for the conventions established here (ProviderScope
// overrides via UncontrolledProviderScope, isMockLoggedInProvider as the identity shortcut, never
// pumpAndSettle() across a toast/Navigator.pop, the offline-queue fire-and-forget timing gotcha).
//
// Scope: golden path (Minor severity), the required-field validation guard, and the
// Major/Critical -> auto-CAPA + event branch (the screen's actual safety-critical logic, kept
// despite Tier 3's "don't chase every branch" restraint since this is one of TEST_STRATEGY.md's
// own named DoD examples). NOT covered, deliberately avoided rather than mocked: photo upload
// (direct FirebaseStorage.instance call, guarded by `if (_photoFile != null)` — never tapping
// Camera/Gallery avoids it entirely), the GPS button (real Geolocator plugin call — typing the
// Location field directly avoids it), date/time picker interaction (accepts the DateTime.now()
// default), and the "not logged in" throw branch (would need firebase_auth_mocks' MockFirebaseAuth
// wired through the real authStateProvider chain instead of isMockLoggedInProvider — flagged as a
// gap, not fixed, in docs/testing/TEST_BACKLOG.md's T3-WIDGETS entry).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/events/app_event_bus.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/safety/screens/incident_report_form.dart';

import '../../../helpers/widget_test_harness.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(OfflineOperation.create);
    registerFallbackValue(<String, dynamic>{});
  });

  Future<void> pumpAndOpenForm(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      hostedUnderPushedRoute(container, const IncidentReportForm()),
    );
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('golden path: fills required fields, queues the create, pops the route', (
    tester,
  ) async {
    final mockOfflineSync = buildMockOfflineSync();
    final container = buildLoggedInContainer(extraOverrides: [
      offlineSyncServiceProvider.overrideWithValue(mockOfflineSync),
    ]);
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future); // pre-warm, per TEST_STRATEGY.md §3

    await pumpAndOpenForm(tester, container);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Incident Title *'),
      'Forklift near miss',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Detailed Description *'),
      'A forklift nearly collided with a pedestrian near loading bay 3.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Location'),
      'Warehouse B',
    );

    await tester.tap(find.text('Submit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final captured = verify(() => mockOfflineSync.queueOperation(
          operation: captureAny(named: 'operation'),
          collection: captureAny(named: 'collection'),
          data: captureAny(named: 'data'),
          documentId: captureAny(named: 'documentId'),
        )).captured;
    expect(captured.length, 4); // one call x 4 named args (operation/collection/data/documentId)
    expect(captured[0], OfflineOperation.create);
    expect(captured[1], 'tenants/sentinel-dev/incidents');
    final data = captured[2] as Map<String, dynamic>;
    expect(data['title'], 'Forklift near miss');
    expect(data['description'], 'A forklift nearly collided with a pedestrian near loading bay 3.');
    expect(data['type'], 'Injury'); // default
    expect(data['severity'], 'Minor'); // default
    expect(data['status'], 'Open');
    expect(data['location'], 'Warehouse B');
    expect(data['reportedBy'], 'dev-admin-123');
    expect(data['tenantId'], 'sentinel-dev');
    expect(captured[3], isNull); // no documentId — createDocument auto-generates one

    // Advance past the MaterialPageRoute's exit transition (~300ms) so the popped route is
    // actually detached, not just mid-animation — a bare pump() only advances one frame.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(IncidentReportForm), findsNothing);
  });

  testWidgets('required-field validation guard: blocks submit with no Firestore write or navigation', (
    tester,
  ) async {
    final mockOfflineSync = buildMockOfflineSync();
    final container = buildLoggedInContainer(extraOverrides: [
      offlineSyncServiceProvider.overrideWithValue(mockOfflineSync),
    ]);
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);

    await pumpAndOpenForm(tester, container);

    // Title/Description left empty.
    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(find.text('Required'), findsNWidgets(2)); // title + description
    verifyNever(() => mockOfflineSync.queueOperation(
          operation: any(named: 'operation'),
          collection: any(named: 'collection'),
          data: any(named: 'data'),
          documentId: any(named: 'documentId'),
        ));
    expect(find.byType(IncidentReportForm), findsOneWidget); // still on the form, not popped
  });

  testWidgets('Major severity: creates the incident AND an auto-CAPA, fires HighRiskIncidentReportedEvent', (
    tester,
  ) async {
    final mockOfflineSync = buildMockOfflineSync();
    final container = buildLoggedInContainer(extraOverrides: [
      offlineSyncServiceProvider.overrideWithValue(mockOfflineSync),
    ]);
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);

    final firedEvents = <AppEvent>[];
    final sub = container.read(appEventBusProvider).stream.listen(firedEvents.add);
    addTearDown(sub.cancel);

    await pumpAndOpenForm(tester, container);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Incident Title *'),
      'Chemical spill in mixing area',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Detailed Description *'),
      'A significant chemical spill occurred during mixing.',
    );

    // Open the Severity dropdown (currently showing 'Minor') and select 'Major'.
    await tester.tap(find.text('Minor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Major'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final calls = verify(() => mockOfflineSync.queueOperation(
          operation: captureAny(named: 'operation'),
          collection: captureAny(named: 'collection'),
          data: captureAny(named: 'data'),
          documentId: captureAny(named: 'documentId'),
        )).captured;
    // 4 captured values per call (operation/collection/data/documentId), 2 calls expected.
    expect(calls.length, 8);
    final collections = [calls[1], calls[5]];
    expect(collections, containsAll(['tenants/sentinel-dev/incidents', 'tenants/sentinel-dev/capas']));

    final capaData = (calls[1] == 'tenants/sentinel-dev/capas' ? calls[2] : calls[6])
        as Map<String, dynamic>;
    expect(capaData['title'], 'Automatic CAPA: Chemical spill in mixing area');
    expect(capaData['type'], 'Corrective');
    expect(capaData['priority'], 'High');

    expect(firedEvents, hasLength(1));
    expect(firedEvents.single, isA<HighRiskIncidentReportedEvent>());

    // Two sequential FirestoreService.createDocument calls (incident, then CAPA) chain more
    // awaits than the Minor-severity golden path, so give it a couple more pump cycles to fully
    // resolve before the route pop is expected to have landed.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(IncidentReportForm), findsNothing);
  });
}
