// Tests for HRService (lib/features/people/services/hr_service.dart) — the
// Department/JobRole/OhsRole CRUD service. Not to be confused with the
// unrelated, unreachable HRService class in
// lib/features/people/providers/hr_provider.dart (see that file's own
// comment and TEST_BACKLOG.md for the duplicate-name/dead-code finding);
// this is the real one, injected into BpfOrchestrator and reachable from
// org_config_screen.dart.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/people/models/hr_models.dart';
import 'package:sentinel1/features/people/services/hr_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late HRService service;
  const tenantId = 'tenant-hr-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = HRService(firestore.collection('tenants').doc(tenantId));
  });

  group('Department', () {
    test('createDepartment writes with siteId matching the tenant doc id', () async {
      await service.createDepartment(Department(name: 'Engineering'));

      final docs = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('departments')
          .get();

      expect(docs.docs, hasLength(1));
      expect(docs.docs.single.data()['name'], 'Engineering');
      expect(docs.docs.single.data()['siteId'], tenantId);
    });

    test('updateDepartment merges the given fields into the existing doc', () async {
      final ref = firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('departments')
          .doc('dept-1');
      await ref.set({'name': 'Old Name', 'siteId': tenantId});

      await service.updateDepartment('dept-1', {'name': 'New Name'});

      final doc = await ref.get();
      expect(doc.data()!['name'], 'New Name');
    });

    test('deleteDepartment removes the doc', () async {
      final ref = firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('departments')
          .doc('dept-2');
      await ref.set({'name': 'To Delete', 'siteId': tenantId});

      await service.deleteDepartment('dept-2');

      final doc = await ref.get();
      expect(doc.exists, isFalse);
    });
  });

  group('JobRole', () {
    test('createJobRole writes with siteId matching the tenant doc id', () async {
      await service.createJobRole(JobRole(title: 'Site Foreman', isLegalAppointment: true));

      final docs = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('job_roles')
          .get();

      expect(docs.docs.single.data()['title'], 'Site Foreman');
      expect(docs.docs.single.data()['isLegalAppointment'], isTrue);
      expect(docs.docs.single.data()['siteId'], tenantId);
    });

    test('deleteJobRole removes the doc', () async {
      final ref = firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('job_roles')
          .doc('role-1');
      await ref.set({'title': 'To Delete', 'siteId': tenantId});

      await service.deleteJobRole('role-1');

      expect((await ref.get()).exists, isFalse);
    });
  });

  group('OhsRole', () {
    test('createOhsRole writes with siteId matching the tenant doc id', () async {
      await service.createOhsRole(OhsRole(title: 'First Aider'));

      final docs = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('ohs_roles')
          .get();

      expect(docs.docs.single.data()['title'], 'First Aider');
      expect(docs.docs.single.data()['siteId'], tenantId);
    });

    test('updateOhsRole merges the given fields into the existing doc', () async {
      final ref = firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('ohs_roles')
          .doc('ohs-1');
      await ref.set({'title': 'Old Title', 'siteId': tenantId});

      await service.updateOhsRole('ohs-1', {'title': 'Fire Warden'});

      expect((await ref.get()).data()!['title'], 'Fire Warden');
    });
  });
}
