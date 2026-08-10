// Tests for BpfService (lib/core/bpf/bpf_service.dart) — the actual
// state-mutation layer BpfOrchestrator delegates every stage change to.
//
// FIXED 2026-08-06 (see docs/testing/TEST_BACKLOG.md T1-004 resolved note):
// reading bpf_orchestrator.dart, bpf_service.dart, and bpf_models.dart in
// full found NO gating/validation logic anywhere in the BPF engine —
// `advanceStage`/`startBpf` accepted any stage id string unconditionally,
// with no check against the type's `BpfDefinition`. That silently broke the
// BpfRibbonWidget for the Lead-to-Cash flow in production (three of
// bpf_orchestrator.dart's hardcoded next-stage ids didn't exist in
// leadToCashDefinition — see bpf_orchestrator_test.dart) and for two other
// startBpf call sites (equipment_asset_tab.dart, incident_detail_sheet.dart).
// BpfService now validates via bpf_definitions.dart's registry: both
// `startBpf` and `advanceStage` reject a stage id the type's BpfDefinition
// doesn't declare, and `advanceStage` also rejects advancing an instance
// whose status isn't 'in_progress'.
//
// Deliberately NOT enforced: strict next-index-only ordering (i.e. rejecting
// a "backwards" or same-stage transition). project_providers.dart's
// approveStage() legitimately calls `advanceStage(bpfId, stageId)` with the
// SAME stage id as the project stage just being approved (see that file's
// comment: "BPF stage IDs map 1:1 to Project stage IDs") — enforcing strict
// ordering here would break that real call site. Existence-checking closes
// the "any garbage string" hole without that regression risk; order
// enforcement is a separate, larger product decision left for later.
//
// Requires fake_cloud_firestore because `advanceStage` reads-then-writes the
// instance doc to run at all — the transition mechanics are not separable
// from Firestore access in this implementation.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/bpf/bpf_service.dart';

const _tenantId = 'test-tenant';

void main() {
  late FakeFirebaseFirestore db;
  late BpfService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = BpfService(db, _tenantId);
  });

  DocumentReference<Map<String, dynamic>> instanceDoc(String id) => db
      .collection('tenants')
      .doc(_tenantId)
      .collection('bpf_instances')
      .doc(id);

  group('startBpf', () {
    test('creates an instance with the given type/stage/status and linked record',
        () async {
      final id = await service.startBpf(
          'procure_to_pay', 'requisition', 'purchase_order', 'PO-001');

      final snap = await instanceDoc(id).get();
      expect(snap.exists, isTrue);
      final data = snap.data()!;
      expect(data['bpfTypeId'], 'procure_to_pay');
      expect(data['currentStageId'], 'requisition');
      expect(data['status'], 'in_progress');
      expect(data['linkedRecordIds'], {'purchase_order': 'PO-001'});
      expect(data['startedAt'], isA<Timestamp>());
      expect(data['stageStartedAt'], isA<Timestamp>());
    });
  });

  group('advanceStage — valid advancement', () {
    test('updates currentStageId and refreshes stageStartedAt', () async {
      final id = await service.startBpf(
          'lead_to_cash', 'lead', 'leadId', 'LEAD-1');
      final before = (await instanceDoc(id).get()).data()!['stageStartedAt']
          as Timestamp;

      await Future.delayed(const Duration(milliseconds: 5));
      await service.advanceStage(id, 'opportunity');

      final after = await instanceDoc(id).get();
      expect(after.data()!['currentStageId'], 'opportunity');
      final afterStamp = after.data()!['stageStartedAt'] as Timestamp;
      expect(afterStamp.microsecondsSinceEpoch,
          greaterThanOrEqualTo(before.microsecondsSinceEpoch));
    });

    test('merges newlyLinkedRecords into existing linkedRecordIds without dropping old keys',
        () async {
      final id = await service.startBpf(
          'lead_to_cash', 'lead', 'leadId', 'LEAD-2');

      await service.advanceStage(id, 'opportunity',
          newlyLinkedRecords: {'opportunityId': 'OPP-1'});
      await service.advanceStage(id, 'quote',
          newlyLinkedRecords: {'quoteId': 'QT-1'});

      final data = (await instanceDoc(id).get()).data()!;
      expect(data['linkedRecordIds'], {
        'leadId': 'LEAD-2',
        'opportunityId': 'OPP-1',
        'quoteId': 'QT-1',
      });
      expect(data['currentStageId'], 'quote');
    });

    test('BpfInstance.fromMap round-trips correctly through toMap', () async {
      final id = await service.startBpf(
          'asset_lifecycle', 'acquisition', 'equipment', 'EQ-1');
      await service.advanceStage(id, 'deployment',
          newlyLinkedRecords: {'employeeId': 'EMP-9'});

      final instance = await service.streamBpfInstance(id).first;
      expect(instance, isNotNull);
      expect(instance!.currentStageId, 'deployment');
      expect(instance.linkedRecordIds['employeeId'], 'EMP-9');
      expect(instance.status, 'in_progress');
    });
  });

  group('advanceStage — gating', () {
    test('rejects a stage id with no relationship to any BpfDefinition',
        () async {
      final id = await service.startBpf(
          'hire_to_retire', 'recruitment', 'employee', 'EMP-1');

      // 'not_a_real_stage' is not present in hireToRetireDefinition.stages.
      await expectLater(
        service.advanceStage(id, 'not_a_real_stage'),
        throwsA(isA<ArgumentError>()),
      );

      final data = (await instanceDoc(id).get()).data()!;
      expect(data['currentStageId'], 'recruitment');
    });

    test('rejects advancing an instance that is not in_progress', () async {
      final id = await service.startBpf(
          'hire_to_retire', 'onboarding', 'employee', 'EMP-1b');
      await service.completeBpf(id);

      await expectLater(
        service.advanceStage(id, 'active'),
        throwsA(isA<StateError>()),
      );

      final data = (await instanceDoc(id).get()).data()!;
      expect(data['currentStageId'], 'onboarding');
      expect(data['status'], 'completed');
    });

    test('allows moving "backwards" to an earlier real stage — no order '
        'enforcement (see file header: project_providers.dart depends on '
        'same-stage re-advancement working)', () async {
      final id = await service.startBpf(
          'hire_to_retire', 'active', 'employee', 'EMP-2');

      // hireToRetireDefinition order is recruitment -> onboarding -> active
      // -> offboarding. Going from 'active' back to 'recruitment' is a real,
      // defined stage, so existence-checking gating allows it.
      await service.advanceStage(id, 'recruitment');

      final data = (await instanceDoc(id).get()).data()!;
      expect(data['currentStageId'], 'recruitment');
    });

    test('does not enforce a "requires safety clearance" concept — '
        'advancing into a SHEQ-gated stage (project_lifecycle stage_2) '
        'never checks safety compliance', () async {
      final id = await service.startBpf(
          'project_lifecycle', 'stage_1', 'project', 'PRJ-1');

      // stage_2 ("Controlling a Stage") is documented as having SHEQ
      // compliance monitoring in effect. It's a real, defined stage, so
      // BpfService's existence-only gating allows the transition — no
      // safety/compliance precondition is (yet) enforced here.
      await service.advanceStage(id, 'stage_2');

      final data = (await instanceDoc(id).get()).data()!;
      expect(data['currentStageId'], 'stage_2');
    });

    test('advancing a non-existent bpfId is a silent no-op, not an error',
        () async {
      await service.advanceStage('does-not-exist', 'some_stage');
      final snap = await instanceDoc('does-not-exist').get();
      expect(snap.exists, isFalse);
    });
  });

  group('startBpf — gating', () {
    test('rejects a starting stage id with no relationship to the '
        'BpfDefinition', () async {
      await expectLater(
        service.startBpf('asset_lifecycle', 'equipment', 'equipment', 'EQ-9'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('allows a bpfTypeId with no registered BpfDefinition through '
        'unchecked', () async {
      final id = await service.startBpf(
          'not_a_registered_type', 'whatever_stage', 'thing', 'T-1');
      final data = (await instanceDoc(id).get()).data()!;
      expect(data['currentStageId'], 'whatever_stage');
    });
  });

  group('completeBpf', () {
    test('sets status to completed without altering currentStageId', () async {
      final id = await service.startBpf(
          'issue_to_resolution', 'logged', 'incident', 'INC-1');
      await service.advanceStage(id, 'capa');

      await service.completeBpf(id);

      final data = (await instanceDoc(id).get()).data()!;
      expect(data['status'], 'completed');
      expect(data['currentStageId'], 'capa');
    });
  });

  group('streamBpfInstancesByRecord', () {
    test('finds instances linked to a given record type/id', () async {
      final id = await service.startBpf(
          'procure_to_pay', 'requisition', 'purchase_order', 'PO-777');
      await service.startBpf(
          'procure_to_pay', 'requisition', 'purchase_order', 'PO-888');

      final results =
          await service.streamBpfInstancesByRecord('purchase_order', 'PO-777')
              .first;

      expect(results, hasLength(1));
      expect(results.single.id, id);
    });
  });

  group('streamInstancesByType', () {
    // Backs AssetLifecycleScreen's fleet-wide view (lib/features/equipment/screens/
    // asset_lifecycle_screen.dart) — every equipment's asset_lifecycle progress at
    // once, as opposed to streamBpfInstancesByRecord's single-record scope.
    test('finds every instance of the given bpfTypeId across the tenant, regardless of record',
        () async {
      final assetId = await service.startBpf(
          'asset_lifecycle', 'acquisition', 'equipment', 'EQ-1');
      await service.startBpf(
          'asset_lifecycle', 'acquisition', 'equipment', 'EQ-2');
      await service.startBpf(
          'procure_to_pay', 'requisition', 'purchase_order', 'PO-999');

      final results = await service.streamInstancesByType('asset_lifecycle').first;

      expect(results, hasLength(2));
      expect(results.map((r) => r.id), contains(assetId));
      expect(results.every((r) => r.bpfTypeId == 'asset_lifecycle'), isTrue);
    });

    test('returns an empty list when no instance of that type exists', () async {
      final results = await service.streamInstancesByType('asset_lifecycle').first;

      expect(results, isEmpty);
    });
  });
}
