// Tests for lib/features/dashboard/providers/dashboard_providers.dart.
//
// FIXED (this pass, see docs/testing/TEST_BACKLOG.md's "Flagged-not-fixed follow-up pass" for
// T3-DASHBOARD): every calculation provider in this file (dashboardLtifrHistoryProvider,
// dashboardHiraMatrixProvider, dashboardOhsComplianceProvider, dashboardTrainingProvider,
// dashboardCapaProvider, dashboardWasteProvider) previously returned hardcoded, made-up numbers
// whenever the real query returned zero documents (or there was no active tenant), instead of
// representing "no data yet" — a direct violation of AGENTS.md §2's "No Hardcoded Data" rule. Each
// now returns null for "no data recorded at all" (an empty collection, or no active tenant); a
// collection that has real documents but legitimately computes to zero (e.g. 0 incidents this
// month) still returns a real, informative zero value, not null — the two are semantically
// different and are tested separately below. The corresponding chart widgets in
// lib/features/dashboard/widgets/ render GEmptyChartState (core/widgets/ds_widgets.dart) on null.
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

    test('returns null (not a fabricated 94.0) when there is no real data at all', () async {
      final result = await container.read(dashboardOhsComplianceProvider.future);
      expect(result, isNull);
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

    test('returns null (not a fabricated 60/40) when there is no real data at all', () async {
      final result = await container.read(dashboardCapaProvider.future);
      expect(result, isNull);
    });
  });

  group('dashboardWasteProvider', () {
    // FIXED 2026-08-07: this provider previously read data['type'] and parsed a unit-embedded
    // quantity string, but the real writer (EnvironmentService.createWasteManifest, formerly
    // waste_form.dart directly) has always written a separate 'wasteType' string field and a
    // bare numeric 'quantity' field with its own 'unit' field — so the categorization loop never
    // matched a real document and this provider always fell into its hardcoded fallback
    // regardless of real data volume (see docs/testing/TEST_BACKLOG.md T3-ENVIRONMENT). This test
    // now seeds the real write shape.
    test('parses and buckets real waste_manifests entries by wasteType, converting kg to tonnes', () async {
      final col = firestore.tenantCollection(tenantId, 'waste_manifests');
      await col.add({'siteId': tenantId, 'wasteType': 'Recyclable', 'quantity': 2000, 'unit': 'kg'});
      await col.add({'siteId': tenantId, 'wasteType': 'General Waste', 'quantity': 1.5, 'unit': 'tons'});
      await col.add({'siteId': tenantId, 'wasteType': 'Hazardous', 'quantity': 500, 'unit': 'kg'});

      final result = await container.read(dashboardWasteProvider.future);

      expect(result!['Recycle'], 2.0); // 2000kg -> 2.0 tonnes
      expect(result['General'], 1.5); // unit != 'kg', taken as-is
      expect(result['Haz'], 0.5); // 500kg -> 0.5 tonnes
    });

    test('returns null (not a fabricated {Recycle: 1.5, General: 2.0, Haz: 0.5}) when there is no real data',
        () async {
      final result = await container.read(dashboardWasteProvider.future);
      expect(result, isNull);
    });
  });

  group('dashboardHiraMatrixProvider', () {
    test('buckets real risk_assessments by likelihood/severity into a 5x5 matrix', () async {
      final col = firestore.tenantCollection(tenantId, 'risk_assessments');
      await col.add({'siteId': tenantId, 'likelihood': 'rare', 'severity': 'catastrophic'});
      await col.add({'siteId': tenantId, 'likelihood': 'rare', 'severity': 'catastrophic'});
      await col.add({'siteId': tenantId, 'likelihood': 'almost certain', 'severity': 'negligible'});

      final result = await container.read(dashboardHiraMatrixProvider.future);

      expect(result![0], 2); // row 0 (catastrophic) x col 0 (rare)
      expect(result[24], 1); // row 4 (negligible) x col 4 (almost certain)
      expect(result.fold<int>(0, (s, v) => s + v), 3);
    });

    test('returns null (not a fabricated matrix) when there is no real data at all', () async {
      final result = await container.read(dashboardHiraMatrixProvider.future);
      expect(result, isNull);
    });
  });

  group('dashboardTrainingProvider', () {
    test('computes real Valid+Expiring-Soon percentages per training category', () async {
      final col = firestore.tenantCollection(tenantId, 'competency_passports');
      await col.add({'siteId': tenantId, 'certification': 'First Aid Level 1', 'status': 'Valid'});
      await col.add({'siteId': tenantId, 'certification': 'First Aid Level 1', 'status': 'Expired'});
      await col.add({'siteId': tenantId, 'certification': 'SHE Rep / Samtrac', 'status': 'Valid'});

      final result = await container.read(dashboardTrainingProvider.future);

      expect(result!['First Aid'], 50.0);
      expect(result['SHE Rep'], 100.0);
      expect(result['Fire Fighting'], 0.0); // real zero: no matching records, not "unknown"
    });

    test('returns null (not a fabricated 90/65/100) when there is no real data at all', () async {
      final result = await container.read(dashboardTrainingProvider.future);
      expect(result, isNull);
    });
  });

  group('dashboardLtifrHistoryProvider', () {
    test('returns real zeros (not null) when the tenant has no incidents at all — a genuine "0" result', () async {
      final result = await container.read(dashboardLtifrHistoryProvider.future);

      expect(result, isNotNull);
      expect(result, everyElement(0.0));
    });

    test('returns null when there is no active tenant at all, distinct from a real zero-incident result', () async {
      final noTenantContainer = ProviderContainer(overrides: [
        firestoreProvider.overrideWithValue(firestore),
        currentTenantIdProvider.overrideWithValue(null),
      ]);
      addTearDown(noTenantContainer.dispose);

      final result = await noTenantContainer.read(dashboardLtifrHistoryProvider.future);

      expect(result, isNull);
    });
  });
}
