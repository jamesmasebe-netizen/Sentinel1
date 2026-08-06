// Model builder functions for FinanceService tests — sensible defaults with
// named-parameter overrides, mirroring bpf_orchestrator_model_fixtures.dart.
// Split out of finance_service_fixtures.dart to respect the 200-line
// threshold (AGENTS.md §4).
import 'package:sentinel1/features/finance/models/finance_models.dart';

JournalEntry buildTestJournalEntry({
  String id = 'JE-001',
  DateTime? transactionDate,
  String sourceModule = 'GL',
  String type = 'STANDARD',
  String description = 'Test journal entry',
  String status = 'DRAFT',
  String currencyCode = 'USD',
  double totalDebit = 100.0,
  double totalCredit = 100.0,
  String? reversesJournalId,
}) {
  return JournalEntry(
    id: id,
    transactionDate: transactionDate ?? DateTime(2026, 1, 15),
    sourceModule: sourceModule,
    type: type,
    description: description,
    status: status,
    currencyCode: currencyCode,
    totalDebit: totalDebit,
    totalCredit: totalCredit,
    reversesJournalId: reversesJournalId,
  );
}

JournalLine buildTestJournalLine({
  String id = 'JL-001',
  String accountId = 'ACC-100',
  double debitAmount = 100.0,
  double creditAmount = 0.0,
  String? costCenterId,
  String? description,
}) {
  return JournalLine(
    id: id,
    accountId: accountId,
    debitAmount: debitAmount,
    creditAmount: creditAmount,
    costCenterId: costCenterId,
    description: description,
  );
}

GeneralLedgerAccount buildTestGLAccount({
  String id = 'ACC-100',
  String accountNumber = '1000',
  String name = 'Cash',
  String type = 'ASSET',
  bool isActive = true,
  bool isReconciliationAccount = false,
}) {
  return GeneralLedgerAccount(
    id: id,
    accountNumber: accountNumber,
    name: name,
    type: type,
    isActive: isActive,
    isReconciliationAccount: isReconciliationAccount,
  );
}

Invoice buildTestInvoice({
  String id = 'INV-001',
  String invoiceType = 'AR',
  String? vendorId,
  String? customerId = 'CUST-1',
  DateTime? invoiceDate,
  DateTime? dueDate,
  String status = 'OPEN',
  String currencyCode = 'USD',
  double grossAmount = 200.0,
  double taxAmount = 20.0,
  double netAmount = 180.0,
  double? amountPaidOrReceived,
}) {
  return Invoice(
    id: id,
    invoiceType: invoiceType,
    vendorId: vendorId,
    customerId: customerId,
    invoiceDate: invoiceDate ?? DateTime(2026, 1, 1),
    dueDate: dueDate ?? DateTime(2026, 2, 1),
    status: status,
    currencyCode: currencyCode,
    grossAmount: grossAmount,
    taxAmount: taxAmount,
    netAmount: netAmount,
    amountPaidOrReceived: amountPaidOrReceived,
  );
}

TaxCode buildTestTaxCode({
  String id = 'TAX-001',
  String code = 'STD',
  String jurisdictionId = 'US-CA',
  String name = 'Standard Rate',
  String taxType = 'SALES',
  double rate = 0.0725,
  bool isActive = true,
}) {
  return TaxCode(
    id: id,
    code: code,
    jurisdictionId: jurisdictionId,
    name: name,
    taxType: taxType,
    rate: rate,
    isActive: isActive,
  );
}

BudgetPlan buildTestBudgetPlan({
  String id = 'BUD-001',
  String name = 'FY26 Ops',
  String fiscalYear = '2026',
  String fiscalPeriod = 'Q1',
  double plannedAmount = 10000.0,
  double actualAmount = 0.0,
  double variance = 0.0,
  double variancePercentage = 0.0,
  String status = 'Draft',
  String notes = '',
}) {
  return BudgetPlan(
    id: id,
    name: name,
    fiscalYear: fiscalYear,
    fiscalPeriod: fiscalPeriod,
    plannedAmount: plannedAmount,
    actualAmount: actualAmount,
    variance: variance,
    variancePercentage: variancePercentage,
    status: status,
    notes: notes,
  );
}

CostCenter buildTestCostCenter({
  String id = 'CC-001',
  String code = 'OPS',
  String name = 'Operations',
  bool isActive = true,
  double totalBudget = 5000.0,
  double totalSpend = 0.0,
}) {
  return CostCenter(
    id: id,
    code: code,
    name: name,
    isActive: isActive,
    totalBudget: totalBudget,
    totalSpend: totalSpend,
  );
}
