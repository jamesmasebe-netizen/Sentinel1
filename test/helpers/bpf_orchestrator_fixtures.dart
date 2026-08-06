// Shared mock/container setup for BpfOrchestrator tests. Mocks every
// domain-service dependency BpfOrchestrator is constructed with (per
// bpf_orchestrator.dart's constructor) via mocktail, and wires a real
// BpfService backed by fake_cloud_firestore so the actual stage-write
// behavior is exercised (not re-mocked) — matching TEST_STRATEGY.md's
// guidance to prefer overriding the provider a stream/service comes from
// rather than bypassing the real provider logic.
// Domain-model builders (buildTestLead, buildTestOpportunity, etc.) and
// registerBpfOrchestratorFallbackValues() live in
// bpf_orchestrator_model_fixtures.dart (split out to respect the 200-line
// threshold, AGENTS.md §4) — import both from test files that need them.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/automation/procure_to_pay_automation.dart';
import 'package:sentinel1/core/bpf/bpf_orchestrator.dart';
import 'package:sentinel1/core/bpf/bpf_service.dart';
import 'package:sentinel1/features/crm/services/crm_service.dart';
import 'package:sentinel1/features/equipment/services/equipment_service.dart';
import 'package:sentinel1/features/finance/services/finance_service.dart';
import 'package:sentinel1/features/people/services/hr_service.dart';
import 'package:sentinel1/features/projects/services/pmo_service.dart';
import 'package:sentinel1/features/safety/services/safety_service.dart';
import 'package:sentinel1/features/supply_chain/services/scm_service.dart';

const bpfTestTenantId = 'test-tenant';

class MockCrmService extends Mock implements CrmService {}

class MockPmoService extends Mock implements PmoService {}

class MockFinanceService extends Mock implements FinanceService {}

class MockScmService extends Mock implements ScmService {}

class MockEquipmentService extends Mock implements EquipmentService {}

class MockProcureToPayAutomation extends Mock
    implements ProcureToPayAutomation {}

class MockSafetyService extends Mock implements SafetyService {}

class MockHRService extends Mock implements HRService {}

/// Bundles the orchestrator under test with its mocked domain-service
/// dependencies and the real (fake-Firestore-backed) BpfService, so tests
/// can both stub domain-service calls and assert real persisted stage state.
class BpfOrchestratorHarness {
  final ProviderContainer container;
  final FakeFirebaseFirestore db;
  final MockCrmService crm;
  final MockPmoService pmo;
  final MockFinanceService finance;
  final MockScmService scm;
  final MockEquipmentService equipment;
  final MockProcureToPayAutomation p2p;
  final MockSafetyService safety;
  final MockHRService hr;

  BpfOrchestratorHarness._({
    required this.container,
    required this.db,
    required this.crm,
    required this.pmo,
    required this.finance,
    required this.scm,
    required this.equipment,
    required this.p2p,
    required this.safety,
    required this.hr,
  });

  BpfOrchestrator get orchestrator => container.read(bpfOrchestratorProvider);

  BpfService get bpfService => container.read(bpfServiceProvider);

  Future<Map<String, dynamic>?> readInstance(String bpfId) async {
    final snap = await db
        .collection('tenants')
        .doc(bpfTestTenantId)
        .collection('bpf_instances')
        .doc(bpfId)
        .get();
    return snap.data();
  }

  static BpfOrchestratorHarness build() {
    final db = FakeFirebaseFirestore();
    final crm = MockCrmService();
    final pmo = MockPmoService();
    final finance = MockFinanceService();
    final scm = MockScmService();
    final equipment = MockEquipmentService();
    final p2p = MockProcureToPayAutomation();
    final safety = MockSafetyService();
    final hr = MockHRService();

    final container = ProviderContainer(overrides: [
      bpfServiceProvider
          .overrideWithValue(BpfService(db, bpfTestTenantId)),
      crmServiceProvider.overrideWithValue(crm),
      pmoServiceProvider.overrideWithValue(pmo),
      financeServiceProvider.overrideWithValue(finance),
      scmServiceProvider.overrideWithValue(scm),
      equipmentServiceProvider.overrideWithValue(equipment),
      procureToPayAutomationProvider.overrideWithValue(p2p),
      safetyServiceProvider.overrideWithValue(safety),
      hrServiceProvider.overrideWithValue(hr),
    ]);

    return BpfOrchestratorHarness._(
      container: container,
      db: db,
      crm: crm,
      pmo: pmo,
      finance: finance,
      scm: scm,
      equipment: equipment,
      p2p: p2p,
      safety: safety,
      hr: hr,
    );
  }
}

/// Seeds a bpf_instances doc directly (bypassing BpfService.startBpf) so
/// orchestrator tests can set up "already in progress at stage X" fixtures
/// without depending on startBpf's own correctness.
Future<String> seedBpfInstance(
  FirebaseFirestore db, {
  required String bpfTypeId,
  required String currentStageId,
  Map<String, String> linkedRecordIds = const {},
}) async {
  final ref = db
      .collection('tenants')
      .doc(bpfTestTenantId)
      .collection('bpf_instances')
      .doc();
  await ref.set({
    'bpfTypeId': bpfTypeId,
    'currentStageId': currentStageId,
    'status': 'in_progress',
    'linkedRecordIds': linkedRecordIds,
    'startedAt': Timestamp.now(),
    'stageStartedAt': Timestamp.now(),
  });
  return ref.id;
}
