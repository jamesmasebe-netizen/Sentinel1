// Regression test for a real bug found 2026-08-07 (see docs/testing/TEST_BACKLOG.md): Project's
// toFirestore() wrote the tenant-scoping field as 'tenantId', but fromFirestore() read it back as
// data['siteId'], and every query filtering this collection (projectsProvider, and others under
// lib/features/projects/) filters on 'siteId'. Since no project document ever actually had a
// 'siteId' field, every project was invisible to every one of those queries — the Projects Hub,
// dashboard, schedule board, control tower, journal entry form, and contractor inductions tab all
// read through projectsProvider. Fixed by writing 'siteId' instead of 'tenantId'.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/projects/models/project_models.dart';

void main() {
  group('Project.toFirestore/fromFirestore', () {
    late FakeFirebaseFirestore firestore;
    const tenantId = 'tenant-a';

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    Project buildProject() {
      return Project(
        id: '',
        tenantId: tenantId,
        propertyId: '',
        name: 'Test Project',
        description: 'A project',
        category: 'Maintenance',
        startDate: DateTime(2026, 1, 1),
        targetEndDate: DateTime(2026, 4, 1),
      );
    }

    test('a written project is findable via the same siteId-filtered query projectsProvider uses',
        () async {
      final ref = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('projects')
          .add(buildProject().toFirestore());

      final results = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('projects')
          .where('siteId', isEqualTo: tenantId)
          .get();

      expect(results.docs.map((d) => d.id), contains(ref.id));
    });

    test('round-trips tenantId through toFirestore -> fromFirestore intact', () async {
      final ref = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('projects')
          .add(buildProject().toFirestore());

      final snapshot = await ref.get();
      final roundTripped = Project.fromFirestore(snapshot);

      expect(roundTripped.tenantId, tenantId);
    });

    test('a document written with the old, buggy field name is NOT found by the real query — proves the bug this test guards against',
        () async {
      await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('projects')
          .add({...buildProject().toFirestore(), 'tenantId': tenantId, 'siteId': null});

      final results = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('projects')
          .where('siteId', isEqualTo: tenantId)
          .get();

      expect(results.docs, isEmpty);
    });
  });
}
