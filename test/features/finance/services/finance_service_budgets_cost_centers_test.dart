// Tests for FinanceService's BudgetPlan + CostCenter CRUD and list streams.
// Same harness/conventions as finance_service_gl_accounts_test.dart. Bundled
// into one file (both are small, structurally-identical CRUD blocks) to
// avoid a proliferation of near-empty files while staying under the
// 200-line threshold.
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

  group('BudgetPlan CRUD', () {
    test('create + get round-trips planned/actual amounts', () async {
      final plan = buildTestBudgetPlan(
        id: 'BUD-10',
        plannedAmount: 50000.0,
        actualAmount: 12000.0,
        variance: -38000.0,
      );
      await harness.service.createBudgetPlan(plan);

      final fetched = await harness.service.getBudgetPlan('BUD-10');
      expect(fetched, isNotNull);
      expect(fetched!.plannedAmount, 50000.0);
      expect(fetched.actualAmount, 12000.0);
      expect(fetched.variance, -38000.0);
    });

    test('getBudgetPlan returns null for a nonexistent id', () async {
      expect(await harness.service.getBudgetPlan('nope'), isNull);
    });

    test('update persists changed status', () async {
      await harness.service
          .createBudgetPlan(buildTestBudgetPlan(id: 'BUD-11'));
      await harness.service.updateBudgetPlan(
        buildTestBudgetPlan(id: 'BUD-11', status: 'Active'),
      );
      final fetched = await harness.service.getBudgetPlan('BUD-11');
      expect(fetched!.status, 'Active');
    });

    test('delete removes the document', () async {
      await harness.service
          .createBudgetPlan(buildTestBudgetPlan(id: 'BUD-12'));
      await harness.service.deleteBudgetPlan('BUD-12');
      expect(await harness.service.getBudgetPlan('BUD-12'), isNull);
    });

    test('streamBudgetPlans emits live updates', () async {
      final emissions = <List<BudgetPlan>>[];
      final sub = harness.service.streamBudgetPlans().listen(emissions.add);
      addTearDown(sub.cancel);

      await harness.service
          .createBudgetPlan(buildTestBudgetPlan(id: 'BUD-20'));
      await Future.delayed(Duration.zero);
      expect(emissions.last.map((b) => b.id), ['BUD-20']);
    });
  });

  group('CostCenter CRUD', () {
    test('create + get round-trips budget/spend', () async {
      final center = buildTestCostCenter(
        id: 'CC-10',
        code: 'MKT',
        name: 'Marketing',
        totalBudget: 20000.0,
        totalSpend: 4500.0,
      );
      await harness.service.createCostCenter(center);

      final fetched = await harness.service.getCostCenter('CC-10');
      expect(fetched, isNotNull);
      expect(fetched!.code, 'MKT');
      expect(fetched.totalBudget, 20000.0);
      expect(fetched.totalSpend, 4500.0);
    });

    test('getCostCenter returns null for a nonexistent id', () async {
      expect(await harness.service.getCostCenter('nope'), isNull);
    });

    test('update persists changed spend + active flag', () async {
      await harness.service.createCostCenter(buildTestCostCenter(id: 'CC-11'));
      await harness.service.updateCostCenter(
        buildTestCostCenter(id: 'CC-11', totalSpend: 999.0, isActive: false),
      );
      final fetched = await harness.service.getCostCenter('CC-11');
      expect(fetched!.totalSpend, 999.0);
      expect(fetched.isActive, isFalse);
    });

    test('delete removes the document', () async {
      await harness.service.createCostCenter(buildTestCostCenter(id: 'CC-12'));
      await harness.service.deleteCostCenter('CC-12');
      expect(await harness.service.getCostCenter('CC-12'), isNull);
    });

    test('streamCostCenters emits live updates', () async {
      final emissions = <List<CostCenter>>[];
      final sub = harness.service.streamCostCenters().listen(emissions.add);
      addTearDown(sub.cancel);

      await harness.service.createCostCenter(buildTestCostCenter(id: 'CC-20'));
      await Future.delayed(Duration.zero);
      expect(emissions.last.map((c) => c.id), ['CC-20']);
    });
  });
}
