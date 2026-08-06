// Tests for FinanceService's Invoice CRUD, including the AP/AR collection
// routing (`_getInvoiceCollection`) and the AP+AR-merging `streamAllInvoices`
// (no `type` arg) — real branching/merge logic, not just pass-through CRUD.
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/finance/models/finance_models.dart';

import '../../../helpers/finance_service_fixtures.dart';
import '../../../helpers/finance_service_model_fixtures.dart';

void main() {
  late FinanceTestHarness harness;

  setUp(() {
    harness = FinanceTestHarness.build();
    addTearDown(harness.container.dispose);
  });

  group('Invoice CRUD + AP/AR routing', () {
    test('AP invoice is written to fin_ap_invoices, not fin_ar_invoices',
        () async {
      await harness.service.createInvoice(
        buildTestInvoice(id: 'INV-AP-1', invoiceType: 'AP', vendorId: 'V1'),
      );

      final apRaw = await harness.db
          .collection('tenants')
          .doc(financeTestTenantId)
          .collection('fin_ap_invoices')
          .doc('INV-AP-1')
          .get();
      expect(apRaw.exists, isTrue);
      // Model writes the AP-specific amount key.
      expect(apRaw.data(), isNot(contains('amount_received')));

      final arRaw = await harness.db
          .collection('tenants')
          .doc(financeTestTenantId)
          .collection('fin_ar_invoices')
          .doc('INV-AP-1')
          .get();
      expect(arRaw.exists, isFalse);
    });

    test('AR invoice is written to fin_ar_invoices, not fin_ap_invoices',
        () async {
      await harness.service.createInvoice(
        buildTestInvoice(id: 'INV-AR-1', invoiceType: 'AR', customerId: 'C1'),
      );

      final arRaw = await harness.db
          .collection('tenants')
          .doc(financeTestTenantId)
          .collection('fin_ar_invoices')
          .doc('INV-AR-1')
          .get();
      expect(arRaw.exists, isTrue);

      final apRaw = await harness.db
          .collection('tenants')
          .doc(financeTestTenantId)
          .collection('fin_ap_invoices')
          .doc('INV-AR-1')
          .get();
      expect(apRaw.exists, isFalse);
    });

    test('amountPaidOrReceived round-trips via amount_paid for AP', () async {
      await harness.service.createInvoice(buildTestInvoice(
        id: 'INV-AP-2',
        invoiceType: 'AP',
        amountPaidOrReceived: 75.0,
      ));
      final fetched =
          await harness.service.getInvoice('INV-AP-2', type: 'AP');
      expect(fetched!.amountPaidOrReceived, 75.0);
    });

    test('amountPaidOrReceived round-trips via amount_received for AR',
        () async {
      await harness.service.createInvoice(buildTestInvoice(
        id: 'INV-AR-2',
        invoiceType: 'AR',
        amountPaidOrReceived: 60.0,
      ));
      final fetched =
          await harness.service.getInvoice('INV-AR-2', type: 'AR');
      expect(fetched!.amountPaidOrReceived, 60.0);
    });

    test('getInvoice with the wrong type returns null (different collection)',
        () async {
      await harness.service.createInvoice(
        buildTestInvoice(id: 'INV-AP-3', invoiceType: 'AP'),
      );
      expect(await harness.service.getInvoice('INV-AP-3', type: 'AR'), isNull);
    });

    test('update persists changed status', () async {
      await harness.service
          .createInvoice(buildTestInvoice(id: 'INV-AR-3', invoiceType: 'AR'));
      await harness.service.updateInvoice(
        buildTestInvoice(id: 'INV-AR-3', invoiceType: 'AR', status: 'PAID'),
      );
      final fetched =
          await harness.service.getInvoice('INV-AR-3', type: 'AR');
      expect(fetched!.status, 'PAID');
    });

    test('delete removes the document', () async {
      await harness.service
          .createInvoice(buildTestInvoice(id: 'INV-AR-4', invoiceType: 'AR'));
      await harness.service.deleteInvoice('INV-AR-4', type: 'AR');
      expect(await harness.service.getInvoice('INV-AR-4', type: 'AR'), isNull);
    });
  });

  group('streamAllInvoices', () {
    test('type: "AP" only emits AP invoices', () async {
      await harness.service
          .createInvoice(buildTestInvoice(id: 'S-AP', invoiceType: 'AP'));
      await harness.service
          .createInvoice(buildTestInvoice(id: 'S-AR', invoiceType: 'AR'));

      final first =
          await harness.service.streamAllInvoices(type: 'AP').first;
      expect(first.map((i) => i.id), ['S-AP']);
    });

    test('no type merges AP and AR invoices into one list', () async {
      await harness.service.createInvoice(
        buildTestInvoice(id: 'M-AP', invoiceType: 'AP', vendorId: 'V1'),
      );
      await harness.service.createInvoice(
        buildTestInvoice(id: 'M-AR', invoiceType: 'AR', customerId: 'C1'),
      );

      final emissions = <List<Invoice>>[];
      final sub = harness.service.streamAllInvoices().listen(emissions.add);
      addTearDown(sub.cancel);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(emissions, isNotEmpty);
      final ids = emissions.last.map((i) => i.id).toSet();
      expect(ids, {'M-AP', 'M-AR'});
    });
  });
}
