// Derived-metric coverage for DraService/dra_service.dart's providers — split from
// dra_service_test.dart to respect the 200-line file threshold (AGENTS.md §4).
//
// Covers draKpiCountsProvider (RiskCommandCenterScreen's KPI grid) and
// DraService.streamOpenAssessmentsCount/streamControlStrength (RiskHubScreen's metric cards,
// consumed directly by the widget rather than via the deprecated StreamProvider.stream
// accessor — see dra_service.dart's doc comments). Also locks in the documented, unresolved
// F-306 gap: no write path in this app ever sets `status: 'Approved'`, so "unapproved"/"open"
// counts are always the full total and control strength is always 0% once any DRA exists with
// no `Approved` status — asserted here as real, current behavior, not something this extraction
// fixes.
//
// Data is seeded directly via a raw Firestore write (not service.createAssessment(), which now
// queues through FirestoreService's offline sync rather than writing synchronously) — these tests
// exercise the read/aggregation side only; createAssessment()'s own behavior is covered in
// dra_service_test.dart.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/features/risk/models/dynamic_risk_assessment.dart';
import 'package:sentinel1/features/risk/services/dra_service.dart';

const _tenantId = 'test-tenant';

DynamicRiskAssessment _buildAssessment({
  required String title,
  String? riskLevel,
  String status = 'Pending',
}) {
  return DynamicRiskAssessment(
    siteId: _tenantId,
    title: title,
    taskDescription: title,
    riskLevel: riskLevel,
    status: status,
  );
}

void main() {
  late FakeFirebaseFirestore db;
  late ProviderContainer container;
  late DraService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        currentTenantIdProvider.overrideWithValue(_tenantId),
      ],
    );
    addTearDown(container.dispose);
    service = container.read(draServiceProvider);
  });

  Future<void> seedRawDoc(DynamicRiskAssessment a) async {
    await db
        .collection('tenants')
        .doc(_tenantId)
        .collection('dynamic_risk_assessments')
        .add(a.toFirestore());
  }

  group('draKpiCountsProvider', () {
    test('buckets by riskLevel and counts unapproved (status != Approved)', () async {
      await seedRawDoc(_buildAssessment(title: 'e1', riskLevel: 'Extreme'));
      await seedRawDoc(_buildAssessment(title: 'h1', riskLevel: 'High'));
      await seedRawDoc(_buildAssessment(title: 'h2', riskLevel: 'High'));
      await seedRawDoc(_buildAssessment(title: 'm1', riskLevel: 'Medium'));
      await seedRawDoc(_buildAssessment(title: 'l1', riskLevel: 'Low'));
      // No riskLevel at all — matches none of the 4 buckets, still counts toward total/unapproved.
      await seedRawDoc(_buildAssessment(title: 'unset'));

      // Let the underlying stream settle before reading the derived provider.
      await container.read(draAllSiteAssessmentsProvider.future);
      final counts = container.read(draKpiCountsProvider).value!;

      expect(counts.total, 6);
      expect(counts.extreme, 1);
      expect(counts.high, 2);
      expect(counts.medium, 1);
      expect(counts.low, 1);
      // None of these DRAs has status == 'Approved' — all 6 count as unapproved.
      expect(counts.unapproved, 6);
    });

    test('a DRA with status Approved is excluded from the unapproved count', () async {
      await seedRawDoc(
        _buildAssessment(title: 'approved', riskLevel: 'Low', status: 'Approved'),
      );
      await seedRawDoc(_buildAssessment(title: 'pending', riskLevel: 'Low'));

      await container.read(draAllSiteAssessmentsProvider.future);
      final counts = container.read(draKpiCountsProvider).value!;

      expect(counts.total, 2);
      expect(counts.unapproved, 1);
    });
  });

  group('streamOpenAssessmentsCount', () {
    test('counts every DRA when none is Approved (current real-world behavior)', () async {
      await seedRawDoc(_buildAssessment(title: 'a'));
      await seedRawDoc(_buildAssessment(title: 'b'));

      final result = await service.streamOpenAssessmentsCount().first;

      expect(result, '2');
    });

    test('excludes a DRA whose status is explicitly Approved', () async {
      await seedRawDoc(_buildAssessment(title: 'approved', status: 'Approved'));
      await seedRawDoc(_buildAssessment(title: 'pending'));

      final result = await service.streamOpenAssessmentsCount().first;

      expect(result, '1');
    });
  });

  group('streamControlStrength', () {
    test('floors at 80% while the collection is empty', () async {
      final result = await service.streamControlStrength().first;

      expect(result, '80%');
    });

    test('computes the real percentage once DRAs exist, 0% when none is Approved', () async {
      await seedRawDoc(_buildAssessment(title: 'a'));
      await seedRawDoc(_buildAssessment(title: 'b'));

      final result = await service.streamControlStrength().first;

      // Mirrors RiskHubScreen's previous inline calc exactly: the 80% floor only applies to an
      // empty collection, not to a non-empty one with zero approvals.
      expect(result, '0%');
    });

    test('reflects a mix of approved/unapproved DRAs correctly', () async {
      await seedRawDoc(_buildAssessment(title: 'a', status: 'Approved'));
      await seedRawDoc(_buildAssessment(title: 'b'));

      final result = await service.streamControlStrength().first;

      expect(result, '50%');
    });
  });
}
