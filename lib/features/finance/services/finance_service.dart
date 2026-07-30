import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_models.dart';
import '../../../core/providers/app_providers.dart';

final financeServiceProvider = Provider<FinanceService>((ref) {
  return FinanceService(ref.watch(tenantDocProvider));
});

class FinanceService {
  final DocumentReference _tenantDoc;

  FinanceService(this._tenantDoc);

  // GeneralLedgerAccount CRUD
  Future<void> createGeneralLedgerAccount(GeneralLedgerAccount account) async {
    await _tenantDoc
        .collection('fin_chart_of_accounts')
        .doc(account.id)
        .set(account.toJson());
  }

  Future<GeneralLedgerAccount?> getGeneralLedgerAccount(String id) async {
    final doc =
        await _tenantDoc.collection('fin_chart_of_accounts').doc(id).get();
    if (!doc.exists) return null;
    return GeneralLedgerAccount.fromJson(doc.data()!, doc.id);
  }

  Future<void> updateGeneralLedgerAccount(GeneralLedgerAccount account) async {
    await _tenantDoc
        .collection('fin_chart_of_accounts')
        .doc(account.id)
        .update(account.toJson());
  }

  Future<void> deleteGeneralLedgerAccount(String id) async {
    await _tenantDoc.collection('fin_chart_of_accounts').doc(id).delete();
  }

  // JournalEntry CRUD
  Future<void> createJournalEntry(
    JournalEntry entry,
    List<JournalLine> lines,
  ) async {
    final batch = _tenantDoc.firestore.batch();
    final entryRef = _tenantDoc.collection('fin_journal_headers').doc(entry.id);

    batch.set(entryRef, entry.toJson());

    for (var line in lines) {
      final lineRef = entryRef.collection('lines').doc(line.id);
      batch.set(lineRef, line.toJson());
    }

    await batch.commit();
  }

  Future<JournalEntry?> getJournalEntry(String id) async {
    final doc =
        await _tenantDoc.collection('fin_journal_headers').doc(id).get();
    if (!doc.exists) return null;
    return JournalEntry.fromJson(doc.data()!, doc.id);
  }

  Future<List<JournalLine>> getJournalLines(String journalEntryId) async {
    final qs =
        await _tenantDoc
            .collection('fin_journal_headers')
            .doc(journalEntryId)
            .collection('lines')
            .get();
    return qs.docs
        .map((doc) => JournalLine.fromJson(doc.data(), doc.id))
        .toList();
  }

  // docs/schema_finance.md's core principle: "Posted transactions cannot be
  // deleted or modified. Corrections require a reversing entry." Neither
  // method enforced this before (F-311) — check the CURRENTLY PERSISTED
  // status, not the incoming object's, since legitimately transitioning a
  // draft *into* POSTED must still be allowed.
  static const _immutableStatuses = {'POSTED', 'REVERSED'};

  Future<void> _assertMutable(String id, String action) async {
    final doc =
        await _tenantDoc.collection('fin_journal_headers').doc(id).get();
    final currentStatus = doc.data()?['status'] as String?;
    if (currentStatus != null && _immutableStatuses.contains(currentStatus)) {
      throw StateError(
        'Cannot $action journal entry $id: it is $currentStatus. '
        'Posted/reversed entries are immutable — create a reversing entry instead.',
      );
    }
  }

  Future<void> updateJournalEntry(JournalEntry entry) async {
    await _assertMutable(entry.id, 'modify');
    await _tenantDoc
        .collection('fin_journal_headers')
        .doc(entry.id)
        .update(entry.toJson());
  }

  Future<void> deleteJournalEntry(String id) async {
    await _assertMutable(id, 'delete');
    await _tenantDoc.collection('fin_journal_headers').doc(id).delete();
  }

  Future<void> reverseJournalEntry(String originalId) async {
    final doc =
        await _tenantDoc.collection('fin_journal_headers').doc(originalId).get();
    if (!doc.exists) {
      throw StateError('Journal entry $originalId not found.');
    }
    
    final original = JournalEntry.fromJson(doc.data()!, doc.id);
    if (original.status != 'POSTED') {
      throw StateError(
        'Cannot reverse journal entry $originalId because it is not POSTED '
        '(current status: ${original.status}).'
      );
    }

    final lines = await getJournalLines(originalId);
    
    final batch = _tenantDoc.firestore.batch();
    final newEntryRef = _tenantDoc.collection('fin_journal_headers').doc();
    
    final reversalEntry = JournalEntry(
      id: newEntryRef.id,
      transactionDate: DateTime.now(),
      sourceModule: original.sourceModule,
      sourceReferenceId: original.sourceReferenceId,
      type: 'REVERSAL',
      description: 'Reversal of ${original.id}: ${original.description}',
      status: 'DRAFT',
      currencyCode: original.currencyCode,
      baseCurrencyCode: original.baseCurrencyCode,
      exchangeRate: original.exchangeRate,
      totalDebit: original.totalCredit,
      totalCredit: original.totalDebit,
      baseTotalDebit: original.baseTotalCredit,
      baseTotalCredit: original.baseTotalDebit,
      reversesJournalId: original.id,
    );
    
    batch.set(newEntryRef, reversalEntry.toJson());
    
    for (var line in lines) {
      final newLineRef = newEntryRef.collection('lines').doc();
      final newLine = JournalLine(
        id: newLineRef.id,
        accountId: line.accountId,
        costCenterId: line.costCenterId,
        projectId: line.projectId,
        debitAmount: line.creditAmount,
        creditAmount: line.debitAmount,
        baseDebitAmount: line.baseCreditAmount,
        baseCreditAmount: line.baseDebitAmount,
        description: line.description,
        taxCodeId: line.taxCodeId,
      );
      batch.set(newLineRef, newLine.toJson());
    }
    
    // Mark original as REVERSED
    final originalRef = _tenantDoc.collection('fin_journal_headers').doc(originalId);
    batch.update(originalRef, {'status': 'REVERSED'});
    
    await batch.commit();
  }

  // Invoice CRUD (Handling both AP and AR)
  String _getInvoiceCollection(String type) {
    return type == 'AP' ? 'fin_ap_invoices' : 'fin_ar_invoices';
  }

  Future<void> createInvoice(Invoice invoice) async {
    await _tenantDoc
        .collection(_getInvoiceCollection(invoice.invoiceType))
        .doc(invoice.id)
        .set(invoice.toJson());
  }

  Future<Invoice?> getInvoice(String id, {required String type}) async {
    final doc =
        await _tenantDoc.collection(_getInvoiceCollection(type)).doc(id).get();
    if (!doc.exists) return null;
    return Invoice.fromJson(doc.data()!, doc.id, type: type);
  }

  Future<void> updateInvoice(Invoice invoice) async {
    await _tenantDoc
        .collection(_getInvoiceCollection(invoice.invoiceType))
        .doc(invoice.id)
        .update(invoice.toJson());
  }

  Future<void> deleteInvoice(String id, {required String type}) async {
    await _tenantDoc.collection(_getInvoiceCollection(type)).doc(id).delete();
  }

  // TaxCode CRUD
  Future<void> createTaxCode(TaxCode taxCode) async {
    await _tenantDoc
        .collection('fin_tax_codes')
        .doc(taxCode.id)
        .set(taxCode.toJson());
  }

  Future<TaxCode?> getTaxCode(String id) async {
    final doc = await _tenantDoc.collection('fin_tax_codes').doc(id).get();
    if (!doc.exists) return null;
    return TaxCode.fromJson(doc.data()!, doc.id);
  }

  Future<void> updateTaxCode(TaxCode taxCode) async {
    await _tenantDoc
        .collection('fin_tax_codes')
        .doc(taxCode.id)
        .update(taxCode.toJson());
  }

  Future<void> deleteTaxCode(String id) async {
    await _tenantDoc.collection('fin_tax_codes').doc(id).delete();
  }

  // --- STREAMS ---

  Stream<JournalEntry?> streamJournalEntry(String id) {
    return _tenantDoc
        .collection('fin_journal_headers')
        .doc(id)
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? JournalEntry.fromJson(doc.data()!, doc.id) : null,
        );
  }

  Stream<List<JournalLine>> streamJournalLines(String journalEntryId) {
    return _tenantDoc
        .collection('fin_journal_headers')
        .doc(journalEntryId)
        .collection('lines')
        .snapshots()
        .map(
          (qs) =>
              qs.docs
                  .map((doc) => JournalLine.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  Stream<Invoice?> streamInvoice(String id, {required String type}) {
    return _tenantDoc
        .collection(_getInvoiceCollection(type))
        .doc(id)
        .snapshots()
        .map(
          (doc) =>
              doc.exists
                  ? Invoice.fromJson(doc.data()!, doc.id, type: type)
                  : null,
        );
  }

  // --- LIST STREAMS (ALL ENTITIES) ---

  Stream<List<GeneralLedgerAccount>> streamAllGLAccounts() {
    return _tenantDoc
        .collection('fin_chart_of_accounts')
        .snapshots()
        .map(
          (qs) =>
              qs.docs
                  .map(
                    (doc) => GeneralLedgerAccount.fromJson(doc.data(), doc.id),
                  )
                  .toList(),
        );
  }

  Stream<List<JournalEntry>> streamAllJournalEntries() {
    return _tenantDoc
        .collection('fin_journal_headers')
        .snapshots()
        .map(
          (qs) =>
              qs.docs
                  .map((doc) => JournalEntry.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  Stream<List<Invoice>> streamAllInvoices({String? type}) {
    if (type != null) {
      return _tenantDoc
          .collection(_getInvoiceCollection(type))
          .snapshots()
          .map(
            (qs) =>
                qs.docs
                    .map(
                      (doc) => Invoice.fromJson(doc.data(), doc.id, type: type),
                    )
                    .toList(),
          );
    }
    // Merge both AP and AR streams
    final apStream = _tenantDoc
        .collection('fin_ap_invoices')
        .snapshots()
        .map(
          (qs) =>
              qs.docs
                  .map(
                    (doc) => Invoice.fromJson(doc.data(), doc.id, type: 'AP'),
                  )
                  .toList(),
        );
    final arStream = _tenantDoc
        .collection('fin_ar_invoices')
        .snapshots()
        .map(
          (qs) =>
              qs.docs
                  .map(
                    (doc) => Invoice.fromJson(doc.data(), doc.id, type: 'AR'),
                  )
                  .toList(),
        );
    return apStream.asyncExpand(
      (apList) => arStream.map((arList) => [...apList, ...arList]),
    );
  }

  Stream<List<TaxCode>> streamAllTaxCodes() {
    return _tenantDoc
        .collection('fin_tax_codes')
        .snapshots()
        .map(
          (qs) =>
              qs.docs
                  .map((doc) => TaxCode.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  // --- BUDGET PLAN CRUD ---

  Future<void> createBudgetPlan(BudgetPlan plan) async {
    await _tenantDoc
        .collection('fin_budget_models')
        .doc(plan.id)
        .set(plan.toJson());
  }

  Future<BudgetPlan?> getBudgetPlan(String id) async {
    final doc = await _tenantDoc.collection('fin_budget_models').doc(id).get();
    if (!doc.exists) return null;
    return BudgetPlan.fromJson(doc.data()!, doc.id);
  }

  Future<void> updateBudgetPlan(BudgetPlan plan) async {
    await _tenantDoc
        .collection('fin_budget_models')
        .doc(plan.id)
        .update(plan.toJson());
  }

  Future<void> deleteBudgetPlan(String id) async {
    await _tenantDoc.collection('fin_budget_models').doc(id).delete();
  }

  Stream<List<BudgetPlan>> streamBudgetPlans() {
    return _tenantDoc
        .collection('fin_budget_models')
        .snapshots()
        .map(
          (qs) =>
              qs.docs
                  .map((doc) => BudgetPlan.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  // --- COST CENTER CRUD ---

  Future<void> createCostCenter(CostCenter center) async {
    await _tenantDoc
        .collection('fin_cost_centers')
        .doc(center.id)
        .set(center.toJson());
  }

  Future<CostCenter?> getCostCenter(String id) async {
    final doc = await _tenantDoc.collection('fin_cost_centers').doc(id).get();
    if (!doc.exists) return null;
    return CostCenter.fromJson(doc.data()!, doc.id);
  }

  Future<void> updateCostCenter(CostCenter center) async {
    await _tenantDoc
        .collection('fin_cost_centers')
        .doc(center.id)
        .update(center.toJson());
  }

  Future<void> deleteCostCenter(String id) async {
    await _tenantDoc.collection('fin_cost_centers').doc(id).delete();
  }

  Stream<List<CostCenter>> streamCostCenters() {
    return _tenantDoc
        .collection('fin_cost_centers')
        .snapshots()
        .map(
          (qs) =>
              qs.docs
                  .map((doc) => CostCenter.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }
}
