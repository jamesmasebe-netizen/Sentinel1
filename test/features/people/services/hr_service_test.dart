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

  group('Recruitment: job_applications -> candidates bridge', () {
    // Recruitment pipeline redesign — see docs/testing/TEST_BACKLOG.md T3-PUBLIC. Real applications
    // land in job_applications (via PublicCareersService.submitApplication); this is the bridge a
    // recruiter uses to promote one into the tracked candidates pipeline.
    Future<String> seedApplication({
      String jobId = 'req-1',
      String applicantName = 'Jane Doe',
      String status = 'New',
    }) async {
      final ref = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('job_applications')
          .add({
        'jobId': jobId,
        'jobTitle': 'Site Safety Officer',
        'applicantName': applicantName,
        'email': 'jane@example.test',
        'phone': '+27000000000',
        'resumeLink': 'https://drive.google.com/resume',
        'status': status,
        'appliedAt': DateTime(2026, 1, 1),
        'isExternal': true,
      });
      return ref.id;
    }

    test('streamJobApplications filters by jobId', () async {
      await seedApplication(jobId: 'req-1', applicantName: 'Jane Doe');
      await seedApplication(jobId: 'req-2', applicantName: 'Other Applicant');

      final result = await service.streamJobApplications('req-1').first;

      expect(result, hasLength(1));
      expect(result.single.applicantName, 'Jane Doe');
    });

    test('convertApplicationToCandidate creates a real Candidate AND marks the application Converted',
        () async {
      final appId = await seedApplication();
      final application = (await service.streamJobApplications('req-1').first).single;

      await service.convertApplicationToCandidate(
        application,
        requisitionId: 'req-1',
        department: 'SHEQ',
      );

      final candidates = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('candidates')
          .get();
      expect(candidates.docs, hasLength(1));
      final candidateData = candidates.docs.single.data();
      expect(candidateData['requisitionId'], 'req-1');
      expect(candidateData['name'], 'Jane Doe');
      expect(candidateData['title'], 'Site Safety Officer');
      expect(candidateData['department'], 'SHEQ');
      expect(candidateData['stage'], 'Applied');
      expect(candidateData['resumeUrl'], 'https://drive.google.com/resume');

      final applicationDoc = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('job_applications')
          .doc(appId)
          .get();
      expect(applicationDoc.data()!['status'], 'Converted');
    });
  });

  group('Public careers page setup', () {
    test('claimTenantSlug writes a root-level public_tenant_directory doc pointing at this tenant',
        () async {
      await service.claimTenantSlug('acme-corp');

      final doc = await firestore.collection('public_tenant_directory').doc('acme-corp').get();
      expect(doc.data()!['tenantId'], tenantId);
    });

    test('getClaimedSlugForTenant finds the slug already claimed for this tenant', () async {
      await firestore
          .collection('public_tenant_directory')
          .doc('acme-corp')
          .set({'tenantId': tenantId});
      await firestore
          .collection('public_tenant_directory')
          .doc('other-co')
          .set({'tenantId': 'other-tenant'});

      final result = await service.getClaimedSlugForTenant();

      expect(result, 'acme-corp');
    });

    test('getClaimedSlugForTenant returns null when this tenant has not claimed a slug', () async {
      final result = await service.getClaimedSlugForTenant();

      expect(result, isNull);
    });
  });
}
