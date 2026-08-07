// Tests for PublicCareersService (lib/features/public/services/public_careers_service.dart) —
// the service layer behind the unauthenticated public careers portal (`/careers/:tenantSlug`).
//
// Unlike every other module's service extracted this session, this one is deliberately NOT
// routed through FirestoreService/currentTenantIdProvider — there is no signed-in user on this
// screen. See the class doc comment for why routing submitApplication through
// FirestoreService.createDocument would actually break real submissions (its audit-log write
// requires belongsToTenant(tenantId), which an anonymous applicant can never satisfy).
//
// REAL FINDING, NOT FIXED (see docs/testing/TEST_BACKLOG.md T3-PUBLIC): submitApplication writes
// to `job_applications`, exactly matching this collection's existing rules
// (allow create: if true) and the shape the pre-extraction widget already wrote. But nothing
// anywhere in lib/ ever reads job_applications — the internal recruiter Kanban board
// (RecruitmentDashboardScreen, lib/features/people/screens/recruitment_dashboard_screen.dart)
// reads a *different* collection (`candidates`, via candidatesProvider), populated by a
// *different*, unreachable dead-code form (ApplicationFormWidget, reachable only from the
// equally-dead PublicCareersPortal). Every real external application submitted through the real,
// routed public careers page is therefore invisible to recruiters today. Not fixed here: whether
// to redirect writes into `candidates` is a product decision, not a mechanical fix — the
// `isExternal: true` flag on job_applications suggests a deliberate (but never built) separate
// external-applicant triage step was intended, rather than a simple wrong-collection-name typo.
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
        'jobTitle': 'Site Safety Officer',
        'department': 'SHEQ',
        'location': 'Johannesburg',
        'employmentType': 'Full-time',
        'requirements': '5+ years experience',
        'status': 'Published',
      });
      await col.add({'jobTitle': 'Draft Role', 'status': 'Draft'});
      await firestore
          .collection('tenants')
          .doc('other-tenant')
          .collection('job_requisitions')
          .add({'jobTitle': 'Other Tenant Role', 'status': 'Published'});

      final result = await service.streamPublishedJobs(tenantId).first;

      expect(result, hasLength(1));
      expect(result.single.jobTitle, 'Site Safety Officer');
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
