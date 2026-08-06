// Tests for FinanceService's GeneralLedgerAccount CRUD + list stream.
// Uses fake_cloud_firestore per TEST_STRATEGY.md's provider/service-test
// row; asserts no authorization behavior. financeServiceProvider is built
// through tenantDocProvider (firestoreProvider + currentTenantIdProvider),
// so the harness overrides those two rather than financeServiceProvider
// itself, per TEST_STRATEGY.md §3.
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

  group('GeneralLedgerAccount CRUD', () {
    test('create + get round-trips all fields, seeded under tenant path',
        () async {
      final account = buildTestGLAccount(
        id: 'ACC-500',
        accountNumber: '5000',
        name: 'Office Supplies',
        type: 'EXPENSE',
      );

      await harness.service.createGeneralLedgerAccount(account);

      // Confirm the document actually landed at tenants/{tenantId}/... —
      // not the collection root — matching tenantCollection()'s resolution.
      final raw = await harness.db
          .collection('tenants')
          .doc(financeTestTenantId)
          .collection('fin_chart_of_accounts')
          .doc('ACC-500')
          .get();
      expect(raw.exists, isTrue);
      expect(raw.data(), containsPair('account_number', '5000'));
      expect(raw.data(), containsPair('type', 'EXPENSE'));

      final fetched = await harness.service.getGeneralLedgerAccount('ACC-500');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Office Supplies');
      expect(fetched.accountNumber, '5000');
      expect(fetched.type, 'EXPENSE');
      expect(fetched.isActive, isTrue);
    });

    test('getGeneralLedgerAccount returns null for a nonexistent id',
        () async {
      final fetched = await harness.service.getGeneralLedgerAccount('nope');
      expect(fetched, isNull);
    });

    test('update persists changed fields', () async {
      await harness.service
          .createGeneralLedgerAccount(buildTestGLAccount(id: 'ACC-501'));

      await harness.service.updateGeneralLedgerAccount(
        buildTestGLAccount(id: 'ACC-501', name: 'Renamed', isActive: false),
      );

      final fetched = await harness.service.getGeneralLedgerAccount('ACC-501');
      expect(fetched!.name, 'Renamed');
      expect(fetched.isActive, isFalse);
    });

    test('delete removes the document', () async {
      await harness.service
          .createGeneralLedgerAccount(buildTestGLAccount(id: 'ACC-502'));
      await harness.service.deleteGeneralLedgerAccount('ACC-502');

      final fetched = await harness.service.getGeneralLedgerAccount('ACC-502');
      expect(fetched, isNull);
    });
  });

  group('streamAllGLAccounts', () {
    test('emits live updates as accounts are created', () async {
      final emissions = <List<GeneralLedgerAccount>>[];
      final sub = harness.service.streamAllGLAccounts().listen(emissions.add);
      addTearDown(sub.cancel);

      await harness.service
          .createGeneralLedgerAccount(buildTestGLAccount(id: 'A1'));
      await Future.delayed(Duration.zero);
      expect(emissions.last.map((a) => a.id), ['A1']);

      await harness.service.createGeneralLedgerAccount(
        buildTestGLAccount(id: 'A2', name: 'Accounts Receivable'),
      );
      await Future.delayed(Duration.zero);
      expect(emissions.last.map((a) => a.id).toSet(), {'A1', 'A2'});
    });
  });
}
