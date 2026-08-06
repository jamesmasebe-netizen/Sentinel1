// Stream coverage for DraService (lib/features/risk/services/dra_service.dart) — split from
// dra_service_test.dart to respect the 200-line file threshold (AGENTS.md §4). See that file for
// createAssessment coverage (including the F-306 dual-write regression guard) and
// dra_service_kpi_test.dart for the derived-metric coverage.
//
// Data is seeded directly via a raw Firestore write (not service.createAssessment(), which now
// queues through FirestoreService's offline sync rather than writing synchronously) — these tests
// exercise the read side only.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/features/risk/models/dynamic_risk_assessment.dart';
import 'package:sentinel1/features/risk/services/dra_service.dart';

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

DynamicRiskAssessment _buildAssessment({
  required String title,
  String siteId = _tenantId,
}) {
  return DynamicRiskAssessment(
    siteId: siteId,
    title: title,
    taskDescription: title,
    location: 'Tank Farm B',
    riskLevel: 'High',
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

  Future<void> seedRawDoc(
    DynamicRiskAssessment a, {
    String tenantId = _tenantId,
  }) async {
    await db
        .collection('tenants')
        .doc(tenantId)
        .collection('dynamic_risk_assessments')
        .add(a.toFirestore());
  }

  group('streamSiteAssessments', () {
    test('returns only this tenant\'s DRAs, newest first, default limit 50', () async {
      await seedRawDoc(_buildAssessment(title: 'Older'));
      await Future.delayed(const Duration(milliseconds: 5));
      await seedRawDoc(_buildAssessment(title: 'Newer'));
      await seedRawDoc(
        _buildAssessment(title: 'Other Tenant', siteId: _otherTenantId),
        tenantId: _otherTenantId,
      );

      final docs = await service.streamSiteAssessments().first;

      expect(docs.map((d) => d.title), ['Newer', 'Older']);
    });

    test('respects a custom limit (feeds the "recent" list capped at 10)', () async {
      for (var i = 0; i < 3; i++) {
        await seedRawDoc(_buildAssessment(title: 'DRA $i'));
        await Future.delayed(const Duration(milliseconds: 5));
      }

      final docs = await service.streamSiteAssessments(limit: 2).first;

      expect(docs, hasLength(2));
      expect(docs.first.title, 'DRA 2');
    });
  });

  group('streamAllSiteAssessments', () {
    test('is siteId-filtered but unordered/unlimited, excluding other tenants', () async {
      await seedRawDoc(_buildAssessment(title: 'A'));
      await seedRawDoc(_buildAssessment(title: 'B'));
      await seedRawDoc(
        _buildAssessment(title: 'Other Tenant', siteId: _otherTenantId),
        tenantId: _otherTenantId,
      );

      final docs = await service.streamAllSiteAssessments().first;

      expect(docs.map((d) => d.title).toSet(), {'A', 'B'});
    });
  });
}
