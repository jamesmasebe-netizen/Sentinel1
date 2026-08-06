// Shared container harness for FinanceService tests, following
// TEST_STRATEGY.md §3's exact override pattern: financeServiceProvider is
// built from tenantDocProvider, itself built from firestoreProvider +
// currentTenantIdProvider — so tests override those two rather than
// financeServiceProvider directly, keeping the real provider wiring under
// test. Model builders (buildTestJournalEntry, etc.) live in
// finance_service_model_fixtures.dart, split out to respect the 200-line
// threshold (AGENTS.md §4) — import both from test files that need them.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/features/finance/services/finance_service.dart';

const financeTestTenantId = 'test-tenant';

/// Reads a raw document directly at tenants/{financeTestTenantId}/{collection}/{id}
/// — bypassing FinanceService entirely — so tests can assert on-disk field
/// shape/values independent of the Dart model's fromJson interpretation.
Future<DocumentSnapshot<Map<String, dynamic>>> readTenantDoc(
  FirebaseFirestore db,
  String collection,
  String id,
) {
  return db
      .collection('tenants')
      .doc(financeTestTenantId)
      .collection(collection)
      .doc(id)
      .get();
}

/// Bundles a real FinanceService (via financeServiceProvider) with the
/// underlying FakeFirebaseFirestore so tests can both call the service and
/// inspect/seed raw documents directly.
class FinanceTestHarness {
  final ProviderContainer container;
  final FakeFirebaseFirestore db;

  FinanceTestHarness._(this.container, this.db);

  FinanceService get service => container.read(financeServiceProvider);

  static FinanceTestHarness build() {
    final db = FakeFirebaseFirestore();
    final container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        currentTenantIdProvider.overrideWithValue(financeTestTenantId),
      ],
    );
    return FinanceTestHarness._(container, db);
  }
}
