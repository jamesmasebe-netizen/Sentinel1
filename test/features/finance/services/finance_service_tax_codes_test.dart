// Tests for FinanceService's TaxCode CRUD + list stream. Same harness/
// conventions as finance_service_gl_accounts_test.dart.
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

  group('TaxCode CRUD', () {
    test('create + get round-trips rate and jurisdiction', () async {
      final taxCode = buildTestTaxCode(
        id: 'TAX-VAT',
        code: 'VAT-STD',
        jurisdictionId: 'UK',
        taxType: 'VAT',
        rate: 0.20,
      );

      await harness.service.createTaxCode(taxCode);

      final fetched = await harness.service.getTaxCode('TAX-VAT');
      expect(fetched, isNotNull);
      expect(fetched!.code, 'VAT-STD');
      expect(fetched.jurisdictionId, 'UK');
      expect(fetched.taxType, 'VAT');
      expect(fetched.rate, 0.20);
    });

    test('getTaxCode returns null for a nonexistent id', () async {
      expect(await harness.service.getTaxCode('nope'), isNull);
    });

    test('update persists changed rate and active flag', () async {
      await harness.service
          .createTaxCode(buildTestTaxCode(id: 'TAX-1', rate: 0.10));

      await harness.service.updateTaxCode(
        buildTestTaxCode(id: 'TAX-1', rate: 0.15, isActive: false),
      );

      final fetched = await harness.service.getTaxCode('TAX-1');
      expect(fetched!.rate, 0.15);
      expect(fetched.isActive, isFalse);
    });

    test('delete removes the document', () async {
      await harness.service.createTaxCode(buildTestTaxCode(id: 'TAX-2'));
      await harness.service.deleteTaxCode('TAX-2');
      expect(await harness.service.getTaxCode('TAX-2'), isNull);
    });
  });

  group('streamAllTaxCodes', () {
    test('emits live updates as tax codes are created', () async {
      final emissions = <List<TaxCode>>[];
      final sub = harness.service.streamAllTaxCodes().listen(emissions.add);
      addTearDown(sub.cancel);

      await harness.service.createTaxCode(buildTestTaxCode(id: 'T1'));
      await Future.delayed(Duration.zero);
      expect(emissions.last.map((t) => t.id), ['T1']);

      await harness.service.createTaxCode(buildTestTaxCode(id: 'T2'));
      await Future.delayed(Duration.zero);
      expect(emissions.last.map((t) => t.id).toSet(), {'T1', 'T2'});
    });
  });
}
