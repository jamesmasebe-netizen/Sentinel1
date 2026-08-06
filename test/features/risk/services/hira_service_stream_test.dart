// Stream coverage for HiraService (lib/features/risk/services/hira_service.dart) — split from
// hira_service_test.dart to respect the 200-line file threshold (AGENTS.md §4). See that file
// for createAssessment coverage (including the HIRA field-name regression guard).
//
// Data is seeded directly via a raw Firestore write (not service.createAssessment(), which now
// queues through FirestoreService's offline sync rather than writing synchronously) — these tests
// exercise the read side only.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/models/safety_models.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/features/risk/services/hira_service.dart';

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

RiskAssessment _buildAssessment({
  String title = 'Working at Heights',
  String siteId = _tenantId,
}) {
  return RiskAssessment(
    siteId: siteId,
    title: title,
    hazard: 'Fall from scaffold',
    likelihood: 'Possible',
    severity: 'Major',
    inherentRiskScore: 12,
    riskRating: 'High',
    status: 'active',
    assessorId: 'user-1',
  );
}

void main() {
  late FakeFirebaseFirestore db;
  late ProviderContainer container;
  late HiraService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        currentTenantIdProvider.overrideWithValue(_tenantId),
      ],
    );
    addTearDown(container.dispose);
    service = container.read(hiraServiceProvider);
  });

  Future<void> seedRawDoc(RiskAssessment a, {String tenantId = _tenantId}) async {
    await db
        .collection('tenants')
        .doc(tenantId)
        .collection('risk_assessments')
        .add(a.toFirestore());
  }

  group('streamAssessments', () {
    test('returns only this tenant\'s HIRA records, newest first', () async {
      await seedRawDoc(_buildAssessment(title: 'Older'));
      await Future.delayed(const Duration(milliseconds: 5));
      await seedRawDoc(_buildAssessment(title: 'Newer'));
      await seedRawDoc(
        _buildAssessment(title: 'Other Tenant', siteId: _otherTenantId),
        tenantId: _otherTenantId,
      );

      final docs = await service.streamAssessments().first;

      expect(docs.map((d) => d.title), ['Newer', 'Older']);
    });
  });

  group('streamAllAssessments', () {
    test('includes every document under the tenant path regardless of siteId field', () async {
      // Unlike streamAssessments(), this feeds RiskMatrixWidget's heatmap and mirrors its
      // previous inline query: no `where('siteId', ...)` filter at all.
      await seedRawDoc(_buildAssessment(title: 'Site A', siteId: 'site-a'));
      await seedRawDoc(_buildAssessment(title: 'Site B', siteId: 'site-b'));

      final docs = await service.streamAllAssessments().first;

      expect(docs.map((d) => d.title).toSet(), {'Site A', 'Site B'});
    });

    test('does not include another tenant\'s documents', () async {
      await seedRawDoc(_buildAssessment(title: 'Mine'));
      await seedRawDoc(
        _buildAssessment(title: 'Not Mine', siteId: _otherTenantId),
        tenantId: _otherTenantId,
      );

      final docs = await service.streamAllAssessments().first;

      expect(docs.map((d) => d.title), ['Mine']);
    });
  });
}
