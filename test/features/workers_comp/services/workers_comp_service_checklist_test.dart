// Tests for WorkersCompService's compliance-checklist surface
// (lib/features/workers_comp/services/workers_comp_service.dart) — split from the claims half
// (workers_comp_service_claims_test.dart) to respect the 200-line threshold (AGENTS.md §4).
// Covers the collection previously seeded/toggled/streamed inline by ComplianceTab
// (_seedDefaults/_toggle), Wave 2b, 2026-08-06.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/features/workers_comp/services/workers_comp_service.dart';

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

void main() {
  late FakeFirebaseFirestore db;
  late ProviderContainer container;
  late WorkersCompService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(db),
      currentTenantIdProvider.overrideWithValue(_tenantId),
    ]);
    addTearDown(container.dispose);
    service = container.read(workersCompServiceProvider);
  });

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> rawChecklist() async {
    final snap =
        await db.collection('tenants').doc(_tenantId).collection('coida_compliance_checklist').get();
    return snap.docs;
  }

  group('seedComplianceChecklist', () {
    test(
        'creates exactly 10 fixed-id docs with the exact field shape ComplianceTab previously wrote inline',
        () async {
      await service.seedComplianceChecklist();

      final docs = await rawChecklist();
      expect(docs, hasLength(10));
      expect(docs.map((d) => d.id).toSet(), {for (var i = 0; i < 10; i++) 'item_$i'});

      final item0 = docs.firstWhere((d) => d.id == 'item_0').data();
      expect(item0.keys.toSet(), {'label', 'done', 'order'});
      expect(item0['label'], 'Register with COIDA Fund (RAF)');
      expect(item0['done'], false);
      expect(item0['order'], 0);

      final item9 = docs.firstWhere((d) => d.id == 'item_9').data();
      expect(item9['label'], 'Death benefit notifications processed');
      expect(item9['order'], 9);
    });

    test('re-seeding is idempotent — fixed ids overwrite in place rather than duplicating',
        () async {
      await service.seedComplianceChecklist();
      // Mark one item done, then re-seed — the fixed-id batch.set overwrite should reset it,
      // exactly like ComplianceTab's original _seedDefaults would if re-triggered.
      final firstDocs = await rawChecklist();
      await service.toggleComplianceItem(firstDocs.first.id, true);

      await service.seedComplianceChecklist();

      final docs = await rawChecklist();
      expect(docs, hasLength(10));
      expect(docs.every((d) => d.data()['done'] == false), isTrue);
    });
  });

  group('toggleComplianceItem', () {
    test('updates only the done field, leaving label/order untouched', () async {
      await service.seedComplianceChecklist();

      await service.toggleComplianceItem('item_3', true);

      final data = (await rawChecklist()).firstWhere((d) => d.id == 'item_3').data();
      expect(data['done'], true);
      expect(data['label'], 'Medical reports obtained from treating doctor');
      expect(data['order'], 3);

      await service.toggleComplianceItem('item_3', false);
      final dataAfter = (await rawChecklist()).firstWhere((d) => d.id == 'item_3').data();
      expect(dataAfter['done'], false);
    });
  });

  group('streamComplianceChecklist', () {
    test('returns items ordered by order, scoped to this tenant only', () async {
      await service.seedComplianceChecklist();
      // A checklist item belonging to another tenant must not leak in.
      await db
          .collection('tenants')
          .doc(_otherTenantId)
          .collection('coida_compliance_checklist')
          .add({'label': 'Other Tenant Item', 'done': false, 'order': -1});

      final items = await service.streamComplianceChecklist().first;

      expect(items, hasLength(10));
      expect(items.map((i) => i.order), List.generate(10, (i) => i));
      expect(items.map((i) => i.label), isNot(contains('Other Tenant Item')));
      expect(items.first.label, 'Register with COIDA Fund (RAF)');
      expect(items.last.label, 'Death benefit notifications processed');
    });
  });
}
