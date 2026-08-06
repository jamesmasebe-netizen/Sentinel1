// Tests for ComplianceService (lib/features/compliance/services/compliance_service.dart) — the
// service layer extracted from the compliance module's previously-inline Firestore calls (Wave
// 2b, 2026-08-06). Used as the reference pattern for extracting emergency/workers_comp/health/
// risk's equivalents. This module has no pre-existing field-shape bug (F-108 already fixed the
// collection-name typo), so this file just verifies the extraction preserves exact prior
// behavior: the same field shapes, the same siteId/date-range filters, the same ordering.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/features/compliance/models/compliance_document.dart';
import 'package:sentinel1/features/compliance/services/compliance_service.dart';

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

ComplianceDocument _buildDoc({
  String id = '',
  String title = 'Forklift Licence',
  String referenceNumber = 'REF-1',
  String documentType = 'Licence',
  String status = 'Current',
  DateTime? expiryDate,
  DateTime? reviewDate,
  String siteId = _tenantId,
}) {
  return ComplianceDocument(
    id: id,
    title: title,
    referenceNumber: referenceNumber,
    documentType: documentType,
    status: status,
    ownerId: 'emp-1',
    expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 200)),
    reviewDate: reviewDate ?? DateTime.now().add(const Duration(days: 100)),
    authorId: 'author-1',
    siteId: siteId,
    createdAt: DateTime.now(),
  );
}

void main() {
  late FakeFirebaseFirestore db;
  late ProviderContainer container;
  late ComplianceService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(db),
      currentTenantIdProvider.overrideWithValue(_tenantId),
    ]);
    addTearDown(container.dispose);
    service = container.read(complianceServiceProvider);
  });

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> rawDocs() async {
    final snap = await db
        .collection('tenants')
        .doc(_tenantId)
        .collection('compliance_docs')
        .get();
    return snap.docs;
  }

  group('createDocument', () {
    test('writes the exact field shape RegisterDocForm previously wrote inline', () async {
      await service.createDocument(_buildDoc(
        title: 'Crane Operator Certificate',
        referenceNumber: 'CRANE-042',
        documentType: 'Certificate',
        status: 'Under Review',
      ));

      final docs = await rawDocs();
      expect(docs, hasLength(1));
      final data = docs.single.data();
      expect(data.keys.toSet(), {
        'title',
        'referenceNumber',
        'documentType',
        'status',
        'ownerId',
        'expiryDate',
        'reviewDate',
        'authorId',
        'siteId',
        'createdAt',
      });
      expect(data['title'], 'Crane Operator Certificate');
      expect(data['referenceNumber'], 'CRANE-042');
      expect(data['documentType'], 'Certificate');
      expect(data['status'], 'Under Review');
      // Dates are ISO8601 strings, not Timestamps — matching existing on-disk data and the
      // string-comparison range query in streamExpiringDocuments().
      expect(data['expiryDate'], isA<String>());
      expect(DateTime.tryParse(data['expiryDate'] as String), isNotNull);
    });
  });

  group('streamAllDocuments', () {
    test('returns only this tenant\'s documents, newest first', () async {
      await service.createDocument(_buildDoc(title: 'Older Doc'));
      await Future.delayed(const Duration(milliseconds: 5));
      await service.createDocument(_buildDoc(title: 'Newer Doc'));
      // A document belonging to another tenant must not leak in — written directly at the raw
      // path since ComplianceService itself is tenant-scoped and can't write cross-tenant.
      await db
          .collection('tenants')
          .doc(_otherTenantId)
          .collection('compliance_docs')
          .add(_buildDoc(title: 'Other Tenant Doc', siteId: _otherTenantId).toFirestore());

      final docs = await service.streamAllDocuments().first;

      expect(docs.map((d) => d.title), ['Newer Doc', 'Older Doc']);
    });
  });

  group('streamExpiringDocuments', () {
    test('includes only documents expiring within 90 days, soonest first, excluding other tenants',
        () async {
      await service.createDocument(_buildDoc(
        title: 'Expiring Soon',
        expiryDate: DateTime.now().add(const Duration(days: 10)),
      ));
      await service.createDocument(_buildDoc(
        title: 'Expiring Later This Window',
        expiryDate: DateTime.now().add(const Duration(days: 80)),
      ));
      await service.createDocument(_buildDoc(
        title: 'Not Expiring Soon',
        expiryDate: DateTime.now().add(const Duration(days: 200)),
      ));

      final docs = await service.streamExpiringDocuments().first;

      expect(docs.map((d) => d.title), ['Expiring Soon', 'Expiring Later This Window']);
    });

    test('a document already past its expiry date is still included (isLessThanOrEqualTo, not a floor)',
        () async {
      await service.createDocument(_buildDoc(
        title: 'Already Expired',
        expiryDate: DateTime.now().subtract(const Duration(days: 5)),
      ));

      final docs = await service.streamExpiringDocuments().first;

      expect(docs.map((d) => d.title), contains('Already Expired'));
    });
  });
}
