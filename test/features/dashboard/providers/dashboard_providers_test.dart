// Tests for lib/features/dashboard/providers/dashboard_providers.dart.
//
// REAL FINDING, NOT FIXED (see docs/testing/TEST_BACKLOG.md T3-DASHBOARD): every calculation
// provider in this file (dashboardLtifrHistoryProvider, dashboardHiraMatrixProvider,
// dashboardOhsComplianceProvider, dashboardTrainingProvider, dashboardCapaProvider,
// dashboardWasteProvider — all 6, confirmed by reading the whole file) returns hardcoded,
// made-up numbers whenever the real query returns zero documents (or there's no active tenant),
// instead of representing "no data yet". This directly violates AGENTS.md §2's binding rule:
// "No Hardcoded Data: Never use static, hardcoded, or placeholder data for business metrics. If a
// feature is incomplete, disable the relevant button or feature instead of faking the data." On a
// SHEQ platform, a brand-new tenant (or one that simply hasn't populated a given collection yet)
// would see fabricated compliance/CAPA/waste percentages on the main dashboard
// (control_tower_screen.dart) indistinguishable from real data. The 3 providers tested below
// (dashboardOhsComplianceProvider, dashboardCapaProvider, dashboardWasteProvider) each have a
// paired test proving the fake-fallback path fires — these are NOT regression tests for a fix
// (there isn't one yet); they're the concrete evidence for this finding. Not fixed here because a
// proper fix means designing an actual empty-state UI for each of 6 charts, not a mechanical code
// change — the same "needs a product decision" bar as T2-BPFORCHESTRATOR/T3-CRM's unfixed findings.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';
import 'package:sentinel1/features/dashboard/providers/dashboard_providers.dart';

void main() {
  const tenantId = 'tenant-dash-1';
  late FakeFirebaseFirestore firestore;
  late ProviderContainer container;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
      currentTenantIdProvider.overrideWithValue(tenantId),
    ]);
    addTearDown(container.dispose);
  });

  group('dashboardOhsComplianceProvider', () {
    test('computes the real Valid+Expiring-Soon percentage from competency_passports', () async {
      final col = firestore.tenantCollection(tenantId, 'competency_passports');
      await col.add({'siteId': tenantId, 'status': 'Valid'});
      await col.add({'siteId': tenantId, 'status': 'Expiring Soon'});
      await col.add({'siteId': tenantId, 'status': 'Expired'});
      await col.add({'siteId': tenantId, 'status': 'Expired'});

      final result = await container.read(dashboardOhsComplianceProvider.future);

      expect(result, 50.0); // 2 of 4 valid/expiring
    });

    test('FINDING: returns a hardcoded 94.0 fallback when there is no real data at all, not a "no data" signal',
        () async {
      final result = await container.read(dashboardOhsComplianceProvider.future);
      expect(result, 94.0);
    });
  });

  group('dashboardCapaProvider', () {
    test('computes real closed/open percentages from capas', () async {
      final col = firestore.tenantCollection(tenantId, 'capas');
      await col.add({'siteId': tenantId, 'status': 'Closed'});
      await col.add({'siteId': tenantId, 'status': 'Resolved'});
      await col.add({'siteId': tenantId, 'status': 'Open'});
      await col.add({'siteId': tenantId, 'status': 'In Progress'});

      final result = await container.read(dashboardCapaProvider.future);

      expect(result, {'closed': 50.0, 'open': 50.0});
    });

    test('FINDING: returns a hardcoded 60/40 fallback when there is no real data at all', () async {
      final result = await container.read(dashboardCapaProvider.future);
      expect(result, {'closed': 60.0, 'open': 40.0});
    });
  });

  group('dashboardWasteProvider', () {
    test('parses and buckets real waste_manifests entries by type, converting kg to tonnes', () async {
      final col = firestore.tenantCollection(tenantId, 'waste_manifests');
      await col.add({'siteId': tenantId, 'type': 'Recyclable', 'quantity': '2000 kg'});
      await col.add({'siteId': tenantId, 'type': 'General Waste', 'quantity': '1.5 tonnes'});
      await col.add({'siteId': tenantId, 'type': 'Hazardous', 'quantity': '500 kg'});

      final result = await container.read(dashboardWasteProvider.future);

      expect(result['Recycle'], 2.0); // 2000kg -> 2.0 tonnes
      expect(result['General'], 1.5); // no 'kg' in string, taken as-is
      expect(result['Haz'], 0.5); // 500kg -> 0.5 tonnes
    });

    test('FINDING: returns a hardcoded fallback {Recycle: 1.5, General: 2.0, Haz: 0.5} when there is no real data',
        () async {
      final result = await container.read(dashboardWasteProvider.future);
      expect(result, {'Recycle': 1.5, 'General': 2.0, 'Haz': 0.5});
    });
  });
}
