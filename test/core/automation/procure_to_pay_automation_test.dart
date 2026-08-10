// Tests for ProcureToPayAutomation.triggerPoReceived (lib/core/automation/procure_to_pay_automation.dart)
// — previously had zero direct test coverage anywhere (confirmed via grep across test/), despite
// being a real, live cross-module automation: marks the PO Received, creates an AP invoice, and
// increments each received item's stock level. Reached only through BpfOrchestrator.
// receivePurchaseOrderGoods, which every existing test (bpf_orchestrator_other_flows_test.dart)
// exercises with this class fully mocked — so the real implementation itself was never actually run
// by any test. Added directly alongside adding InventoryTransaction writing to this same method
// (see docs/testing/TEST_BACKLOG.md's "Flagged-not-fixed follow-up pass"), to regression-guard both
// the pre-existing stock-increment behavior and the new transaction-ledger write together.
//
// ScmService is real (fake_cloud_firestore-backed) since the stock/transaction writes are exactly
// what this test proves. FinanceService is mocked — its own invoice-creation logic is out of scope
// here (covered elsewhere), and mocking it keeps this test from needing a second real Firestore
// fixture for a concern this file doesn't otherwise touch.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/automation/procure_to_pay_automation.dart';
import 'package:sentinel1/features/finance/models/finance_models.dart';
import 'package:sentinel1/features/finance/services/finance_service.dart';
import 'package:sentinel1/features/supply_chain/models/scm_models.dart';
import 'package:sentinel1/features/supply_chain/services/scm_service.dart';

class MockFinanceService extends Mock implements FinanceService {}

void main() {
  setUpAll(() {
    registerFallbackValue(Invoice(
      id: '',
      invoiceType: 'AP',
      invoiceNumber: '',
      invoiceDate: DateTime(2026, 1, 1),
      dueDate: DateTime(2026, 1, 1),
      status: 'DRAFT',
      currencyCode: 'ZAR',
      grossAmount: 0,
      taxAmount: 0,
      netAmount: 0,
    ));
  });

  late FakeFirebaseFirestore firestore;
  late ScmService scmService;
  late MockFinanceService financeService;
  late ProcureToPayAutomation automation;
  const tenantId = 'tenant-p2p-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    scmService = ScmService(firestore.collection('tenants').doc(tenantId));
    financeService = MockFinanceService();
    when(() => financeService.createInvoice(any())).thenAnswer((_) async {});
    automation = ProcureToPayAutomation(scmService, financeService);
  });

  PurchaseOrder buildPo({String id = 'po-1', String status = 'Draft'}) {
    return PurchaseOrder(id: id, poNumber: 'PO-100$id', status: status, totalAmount: 500);
  }

  test('increments the received item\'s stock level by quantityOrdered when quantityReceived is unset',
      () async {
    await scmService.createInventoryItem(InventoryItem(
      id: 'item-bolt',
      sku: 'SKU-BOLT',
      name: 'Steel Bolt',
      itemType: 'RAW_MATERIAL',
      unitOfMeasure: 'each',
      valuationMethod: 'FIFO',
      lifecycleStatus: 'Active',
      stockLevel: 10,
    ));
    final po = buildPo();
    await scmService.createPurchaseOrder(po);
    await scmService.createPurchaseOrderLine(po.id, PurchaseOrderLine(
      id: 'line-1',
      itemId: 'item-bolt',
      quantityOrdered: 30,
    ));

    await automation.triggerPoReceived(po);

    final item = await scmService.getInventoryItem('item-bolt');
    expect(item!.stockLevel, 40); // 10 existing + 30 ordered
  });

  test('prefers quantityReceived over quantityOrdered when a partial/over receipt is recorded',
      () async {
    await scmService.createInventoryItem(InventoryItem(
      id: 'item-panel',
      sku: 'SKU-PANEL',
      name: 'Solar Panel',
      itemType: 'COMPONENT',
      unitOfMeasure: 'each',
      valuationMethod: 'FIFO',
      lifecycleStatus: 'Active',
      stockLevel: 0,
    ));
    final po = buildPo(id: 'po-2');
    await scmService.createPurchaseOrder(po);
    await scmService.createPurchaseOrderLine(po.id, PurchaseOrderLine(
      id: 'line-1',
      itemId: 'item-panel',
      quantityOrdered: 20,
      quantityReceived: 18, // 2 short-shipped
    ));

    await automation.triggerPoReceived(po);

    final item = await scmService.getInventoryItem('item-panel');
    expect(item!.stockLevel, 18);
  });

  test('writes a matching InventoryTransaction referencing the PO, alongside the stock update',
      () async {
    await scmService.createInventoryItem(InventoryItem(
      id: 'item-widget',
      sku: 'SKU-WIDGET',
      name: 'Widget',
      itemType: 'RAW_MATERIAL',
      unitOfMeasure: 'each',
      valuationMethod: 'FIFO',
      lifecycleStatus: 'Active',
      stockLevel: 5,
    ));
    final po = buildPo(id: 'po-3');
    await scmService.createPurchaseOrder(po);
    await scmService.createPurchaseOrderLine(po.id, PurchaseOrderLine(
      id: 'line-1',
      itemId: 'item-widget',
      quantityOrdered: 15,
    ));

    await automation.triggerPoReceived(po);

    final transactions = await scmService.streamInventoryTransactions('item-widget').first;
    expect(transactions, hasLength(1));
    expect(transactions.single.type, 'RECEIPT');
    expect(transactions.single.quantity, 15);
    expect(transactions.single.resultingStockLevel, 20);
    expect(transactions.single.referenceId, 'po-3');
  });

  test('marks a non-Received PO as Received', () async {
    final po = buildPo(id: 'po-4', status: 'Draft');
    await scmService.createPurchaseOrder(po);

    await automation.triggerPoReceived(po);

    final updated = await scmService.getPurchaseOrder('po-4');
    expect(updated!.status, 'Received');
  });

  test('creates an AP invoice for the PO\'s vendor and amount', () async {
    final po = PurchaseOrder(id: 'po-5', poNumber: 'PO-1005', vendorId: 'VEND-1', status: 'Draft', totalAmount: 750);
    await scmService.createPurchaseOrder(po);

    await automation.triggerPoReceived(po);

    final captured = verify(() => financeService.createInvoice(captureAny())).captured.single as Invoice;
    expect(captured.vendorId, 'VEND-1');
    expect(captured.grossAmount, 750);
    expect(captured.invoiceNumber, 'AP-PO-1005');
  });

  test('does nothing to inventory when a PO has no lines', () async {
    final po = buildPo(id: 'po-6');
    await scmService.createPurchaseOrder(po);

    await automation.triggerPoReceived(po);

    // No throw, and nothing to assert on inventory since there's no linked item — this documents
    // the graceful no-lines behavior.
  });
}
