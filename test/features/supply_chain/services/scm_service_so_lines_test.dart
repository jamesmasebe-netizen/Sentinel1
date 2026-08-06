// Tests for ScmService's SalesOrderLine/so_lines CRUD (lib/features/supply_chain/services/
// scm_service.dart), added while fixing a real bug found in Tier 2 testing: `runMrp`
// (firebase/functions/src/mrpEngine.ts) computed demand from a `lines` field that never existed
// on SalesOrder — there was no SalesOrderLine model or so_lines subcollection at all. This file
// covers just the new CRUD surface (mirrors PurchaseOrderLine/po_lines, untested elsewhere too);
// full ScmService coverage remains Tier 3 scope per TEST_BACKLOG.md's module cross-reference.
//
// Uses the same ProviderContainer-override pattern as finance_service_test.dart: override
// firestoreProvider/currentTenantIdProvider (which scmServiceProvider is built from via
// tenantDocProvider) rather than instantiating ScmService directly.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/features/supply_chain/models/scm_models.dart';
import 'package:sentinel1/features/supply_chain/services/scm_service.dart';

const _tenantId = 'test-tenant';

void main() {
  late FakeFirebaseFirestore db;
  late ProviderContainer container;
  late ScmService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(db),
      currentTenantIdProvider.overrideWithValue(_tenantId),
    ]);
    addTearDown(container.dispose);
    service = container.read(scmServiceProvider);
  });

  DocumentReference<Map<String, dynamic>> lineDoc(String soId, String lineId) => db
      .collection('tenants')
      .doc(_tenantId)
      .collection('sales_orders')
      .doc(soId)
      .collection('so_lines')
      .doc(lineId);

  test('createSalesOrderLine writes the exact snake_case field shape runMrp reads', () async {
    await service.createSalesOrderLine(
      'so-1',
      SalesOrderLine(id: 'line-1', itemId: 'item-bolt', quantity: 30, unitPrice: 2.5),
    );

    final snap = await lineDoc('so-1', 'line-1').get();
    expect(snap.exists, isTrue);
    expect(snap.data(), {
      'item_id': 'item-bolt',
      'quantity': 30.0,
      'unit_price': 2.5,
    });
  });

  test('getSalesOrderLines returns all lines for an order, parsed back correctly', () async {
    await service.createSalesOrderLine(
      'so-2',
      SalesOrderLine(id: 'line-a', itemId: 'item-a', quantity: 5),
    );
    await service.createSalesOrderLine(
      'so-2',
      SalesOrderLine(id: 'line-b', itemId: 'item-b', quantity: 10),
    );

    final lines = await service.getSalesOrderLines('so-2');

    expect(lines, hasLength(2));
    final byId = {for (final l in lines) l.id: l};
    expect(byId['line-a']!.itemId, 'item-a');
    expect(byId['line-a']!.quantity, 5);
    expect(byId['line-b']!.itemId, 'item-b');
    expect(byId['line-b']!.quantity, 10);
  });

  test('getSalesOrderLine returns null for a non-existent line', () async {
    final line = await service.getSalesOrderLine('so-3', 'no-such-line');
    expect(line, isNull);
  });

  test('updateSalesOrderLine overwrites the existing line quantity', () async {
    await service.createSalesOrderLine(
      'so-4',
      SalesOrderLine(id: 'line-1', itemId: 'item-x', quantity: 5),
    );

    await service.updateSalesOrderLine(
      'so-4',
      SalesOrderLine(id: 'line-1', itemId: 'item-x', quantity: 12),
    );

    final line = await service.getSalesOrderLine('so-4', 'line-1');
    expect(line!.quantity, 12);
  });

  test('deleteSalesOrderLine removes the line', () async {
    await service.createSalesOrderLine(
      'so-5',
      SalesOrderLine(id: 'line-1', itemId: 'item-x', quantity: 5),
    );

    await service.deleteSalesOrderLine('so-5', 'line-1');

    final snap = await lineDoc('so-5', 'line-1').get();
    expect(snap.exists, isFalse);
  });

  test('lines are scoped per sales order — another order\'s lines are not returned', () async {
    await service.createSalesOrderLine(
      'so-6a',
      SalesOrderLine(id: 'line-1', itemId: 'item-shared', quantity: 1),
    );
    await service.createSalesOrderLine(
      'so-6b',
      SalesOrderLine(id: 'line-1', itemId: 'item-shared', quantity: 2),
    );

    final linesA = await service.getSalesOrderLines('so-6a');
    expect(linesA, hasLength(1));
    expect(linesA.single.quantity, 1);
  });
}
