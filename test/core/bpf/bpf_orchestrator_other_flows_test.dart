// Tests for BpfOrchestrator's remaining domain flows: Procure-to-Pay, Asset
// Lifecycle, Issue-to-Resolution, and Hire-to-Retire. See
// bpf_orchestrator_test.dart for the full rationale (no gating exists in
// this file; what's tested is correct domain-service wiring + correct
// hardcoded stage advancement).
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/features/finance/models/finance_models.dart';

import '../../helpers/bpf_orchestrator_fixtures.dart';
import '../../helpers/bpf_orchestrator_model_fixtures.dart';

void main() {
  setUpAll(registerBpfOrchestratorFallbackValues);

  late BpfOrchestratorHarness h;

  setUp(() {
    h = BpfOrchestratorHarness.build();
    addTearDown(h.container.dispose);
  });

  group('Procure to Pay', () {
    test('createPurchaseOrder creates the PO and starts a new BPF at '
        'purchase_order stage', () async {
      final po = buildTestPurchaseOrder(id: 'PO-1');
      when(() => h.scm.createPurchaseOrder(any())).thenAnswer((_) async {});

      final bpfId = await h.orchestrator.createPurchaseOrder(po);

      verify(() => h.scm.createPurchaseOrder(po)).called(1);
      final instance = await h.readInstance(bpfId);
      expect(instance, isNotNull);
      expect(instance!['bpfTypeId'], 'procure_to_pay');
      expect(instance['currentStageId'], 'purchase_order');
      expect(instance['linkedRecordIds'], {'purchase_order': 'PO-1'});
    });

    test('receivePurchaseOrderGoods triggers the P2P automation and advances '
        'the linked BPF instance to goods_receipt', () async {
      final po = buildTestPurchaseOrder(id: 'PO-2');
      final bpfId = await seedBpfInstance(h.db,
          bpfTypeId: 'procure_to_pay',
          currentStageId: 'purchase_order',
          linkedRecordIds: {'purchase_order': 'PO-2'});

      when(() => h.p2p.triggerPoReceived(any())).thenAnswer((_) async {});

      await h.orchestrator.receivePurchaseOrderGoods(po);

      verify(() => h.p2p.triggerPoReceived(po)).called(1);
      final instance = await h.readInstance(bpfId);
      expect(instance!['currentStageId'], 'goods_receipt');
    });

    test('receivePurchaseOrderGoods is a no-op on the BPF when no instance '
        'is linked to that PO (does not throw)', () async {
      final po = buildTestPurchaseOrder(id: 'PO-ORPHAN');
      when(() => h.p2p.triggerPoReceived(any())).thenAnswer((_) async {});

      await h.orchestrator.receivePurchaseOrderGoods(po);

      verify(() => h.p2p.triggerPoReceived(po)).called(1);
      // No exception thrown, nothing to assert on BPF state — this documents
      // the graceful-no-instance-found behavior.
    });

    test('createInvoiceFromPurchaseOrder creates an AP invoice for the '
        'vendor and advances to ap_invoice with apInvoiceId linked',
        () async {
      final po =
          buildTestPurchaseOrder(id: 'PO-3', vendorId: 'VEND-9', totalAmount: 750);
      final bpfId = await seedBpfInstance(h.db,
          bpfTypeId: 'procure_to_pay',
          currentStageId: 'goods_receipt',
          linkedRecordIds: {'purchase_order': 'PO-3'});

      when(() => h.finance.createInvoice(any())).thenAnswer((_) async {});

      final invoiceId =
          await h.orchestrator.createInvoiceFromPurchaseOrder(po, bpfId);

      final createdInvoice =
          verify(() => h.finance.createInvoice(captureAny())).captured.single
              as Invoice;
      expect(createdInvoice.invoiceType, 'AP');
      expect(createdInvoice.vendorId, 'VEND-9');
      expect(createdInvoice.grossAmount, 750);

      final instance = await h.readInstance(bpfId);
      expect(instance!['currentStageId'], 'ap_invoice');
      expect(instance['linkedRecordIds']['apInvoiceId'], invoiceId);
    });
  });

  group('Asset Lifecycle', () {
    test('deployEquipment deploys the equipment to the employee and '
        'advances to deployment with employeeId linked', () async {
      final equipment = buildTestEquipment(id: 'EQ-1');
      final bpfId = await seedBpfInstance(h.db,
          bpfTypeId: 'asset_lifecycle', currentStageId: 'acquisition');

      when(() => h.equipment.deployEquipment('EQ-1', 'EMP-5'))
          .thenAnswer((_) async {});

      await h.orchestrator.deployEquipment(equipment, 'EMP-5', bpfId);

      verify(() => h.equipment.deployEquipment('EQ-1', 'EMP-5')).called(1);
      final instance = await h.readInstance(bpfId);
      expect(instance!['currentStageId'], 'deployment');
      expect(instance['linkedRecordIds'], {'employeeId': 'EMP-5'});
    });
  });

  group('Issue to Resolution', () {
    test('createCapaFromIncident creates the CAPA linked to the incident and '
        'advances to capa with capaId linked', () async {
      final bpfId = await seedBpfInstance(h.db,
          bpfTypeId: 'issue_to_resolution', currentStageId: 'investigation');

      when(() => h.safety.createCapa(any()))
          .thenAnswer((_) async => 'CAPA-1');

      final capaId = await h.orchestrator.createCapaFromIncident(
          'INC-1', bpfId, 'Fix guardrail', 'Install missing guardrail');

      final capaData =
          verify(() => h.safety.createCapa(captureAny())).captured.single
              as Map;
      expect(capaData['incidentId'], 'INC-1');
      expect(capaData['title'], 'Fix guardrail');
      expect(capaData['status'], 'Open');

      final instance = await h.readInstance(bpfId);
      expect(instance!['currentStageId'], 'capa');
      expect(instance['linkedRecordIds'], {'capaId': capaId});
    });
  });

  group('Hire to Retire', () {
    test('completeOnboarding marks the employee Active and advances to '
        'active with deploymentStatus linked', () async {
      final bpfId = await seedBpfInstance(h.db,
          bpfTypeId: 'hire_to_retire', currentStageId: 'onboarding');

      when(() => h.hr.updateEmployee('EMP-7', any()))
          .thenAnswer((_) async {});

      await h.orchestrator.completeOnboarding('EMP-7', bpfId);

      final updateData =
          verify(() => h.hr.updateEmployee('EMP-7', captureAny())).captured
              .single as Map;
      expect(updateData, {'employmentStatus': 'Active'});

      final instance = await h.readInstance(bpfId);
      expect(instance!['currentStageId'], 'active');
      expect(instance['linkedRecordIds'], {'deploymentStatus': 'Active'});
    });
  });
}
