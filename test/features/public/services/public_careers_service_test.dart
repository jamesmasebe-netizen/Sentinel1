// Tests for PublicCareersService (lib/features/public/services/public_careers_service.dart) —
// the service layer behind the unauthenticated public careers portal (`/careers/:tenantSlug`).
//
// Unlike every other module's service extracted this session, this one is deliberately NOT
// routed through FirestoreService/currentTenantIdProvider — there is no signed-in user on this
// screen. See the class doc comment for why routing submitApplication through
// FirestoreService.createDocument would actually break real submissions (its audit-log write
// requires belongsToTenant(tenantId), which an anonymous applicant can never satisfy).
//
// FIXED (recruitment pipeline redesign — see docs/testing/TEST_BACKLOG.md T3-PUBLIC): this used to
// be a real finding, not fixed — submitApplication writes to `job_applications`, but nothing in
// lib/ ever read that collection; the internal recruiter Kanban read a different, unpopulated
// collection (`candidates`), populated only by dead code (`ApplicationFormWidget`, reachable only
// from the equally-dead `PublicCareersPortal` — both deleted as part of this fix, fully superseded
// by this live path). `HRService.convertApplicationToCandidate` is now the bridge: a recruiter
// reviews a `job_applications` entry in RecruitmentDashboardScreen's Applications Inbox tab and
// explicitly promotes it into a real `candidates` pipeline entry — the `isExternal: true` flag
// here was the signal this deliberate raw-inbox/reviewed-pipeline split was intended, not a
// wrong-collection-name typo.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/public/services/public_careers_service.dart';

void main() {
  const tenantId = 'tenant-public-1';

  late FakeFirebaseFirestore firestore;
  late PublicCareersService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = PublicCareersService(firestore);
  });

  group('resolveTenantId', () {
    test('returns the tenantId for a known slug', () async {
      await firestore
          .collection('public_tenant_directory')
          .doc('acme-corp')
          .set({'tenantId': tenantId});

      final result = await service.resolveTenantId('acme-corp');

      expect(result, tenantId);
    });

    test('returns null for an unknown slug', () async {
      final result = await service.resolveTenantId('nonexistent-slug');

      expect(result, isNull);
    });
  });

  group('streamPublishedJobs', () {
    test('returns only Published postings for the given tenant', () async {
      final col = firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('job_requisitions');
      await col.add({
        'title': 'Site Safety Officer',
        'department': 'SHEQ',
        'location': 'Johannesburg',
        'employmentType': 'Full-time',
        'requirements': '5+ years experience',
        'status': 'Published',
      });
      await col.add({'title': 'Draft Role', 'status': 'Draft'});
      await firestore
          .collection('tenants')
          .doc('other-tenant')
          .collection('job_requisitions')
          .add({'title': 'Other Tenant Role', 'status': 'Published'});

      final result = await service.streamPublishedJobs(tenantId).first;

      expect(result, hasLength(1));
      expect(result.single.title, 'Site Safety Officer');
      expect(result.single.department, 'SHEQ');
      expect(result.single.location, 'Johannesburg');
      expect(result.single.employmentType, 'Full-time');
      expect(result.single.requirements, '5+ years experience');
    });
  });

  group('submitApplication', () {
    test('writes the expected field shape to the tenant-scoped job_applications collection',
        () async {
      await service.submitApplication(
        tenantId: tenantId,
        jobId: 'job-1',
        jobTitle: 'Site Safety Officer',
        applicantName: 'Jane Doe',
        email: 'jane@example.test',
        phone: '+27000000000',
        resumeLink: 'https://drive.google.com/resume',
      );

      final docs = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('job_applications')
          .get();
      expect(docs.docs, hasLength(1));
      final data = docs.docs.single.data();
      expect(data['jobId'], 'job-1');
      expect(data['jobTitle'], 'Site Safety Officer');
      expect(data['applicantName'], 'Jane Doe');
      expect(data['email'], 'jane@example.test');
      expect(data['phone'], '+27000000000');
      expect(data['resumeLink'], 'https://drive.google.com/resume');
      expect(data['status'], 'New');
      expect(data['isExternal'], true);
    });
  });
}
