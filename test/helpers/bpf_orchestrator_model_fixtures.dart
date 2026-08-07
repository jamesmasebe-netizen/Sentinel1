// Domain-model builders with sensible defaults for BpfOrchestrator tests.
// Split out from bpf_orchestrator_fixtures.dart to respect the 200-line
// threshold (AGENTS.md §4). Kept here (rather than duplicated per test file)
// since BpfOrchestrator's methods take these full domain models as
// parameters.
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/features/crm/models/crm_models.dart';
import 'package:sentinel1/features/equipment/models/equipment_models.dart';
import 'package:sentinel1/features/finance/models/finance_models.dart';
import 'package:sentinel1/features/projects/models/project_models.dart';
import 'package:sentinel1/features/supply_chain/models/scm_models.dart';

import 'bpf_orchestrator_fixtures.dart' show bpfTestTenantId;

Lead buildTestLead({
  String id = 'LEAD-1',
  String company = 'Acme Corp',
  String ownerId = 'owner-1',
  String? convertedAccountId,
  String? convertedContactId,
}) {
  return Lead(
    id: id,
    firstName: 'Jane',
    lastName: 'Doe',
    company: company,
    email: 'jane@acme.test',
    phone: '+27000000000',
    leadSource: 'Website',
    status: 'Open',
    rating: 'Hot',
    aiLeadScore: 80,
    ownerId: ownerId,
    isConverted: false,
    convertedAccountId: convertedAccountId,
    convertedContactId: convertedContactId,
  );
}

Opportunity buildTestOpportunity({
  String id = 'OPP-1',
  String accountId = 'ACC-1',
  String ownerId = 'owner-1',
  double amount = 1000,
}) {
  return Opportunity(
    id: id,
    name: 'Test Opportunity',
    accountId: accountId,
    primaryContactId: 'CON-1',
    stage: 'Prospecting',
    amount: amount,
    probability: 20,
    forecastCategory: 'Pipeline',
    leadSource: 'Website',
    nextStep: '',
    ownerId: ownerId,
  );
}

Quote buildTestQuote({
  String id = 'QT-1',
  String opportunityId = 'OPP-1',
  String accountId = 'ACC-1',
  String ownerId = 'owner-1',
  double subtotal = 1000,
}) {
  return Quote(
    id: id,
    opportunityId: opportunityId,
    accountId: accountId,
    quoteNumber: 'QT-0001',
    status: 'Draft',
    subtotal: subtotal,
    discount: 0,
    tax: 0,
    grandTotal: subtotal,
    termsAndConditions: '',
    isSyncing: false,
    ownerId: ownerId,
  );
}

Project buildTestProject({
  String id = 'PRJ-1',
  String? accountId = 'ACC-1',
  String projectLead = 'owner-1',
}) {
  return Project(
    id: id,
    tenantId: bpfTestTenantId,
    propertyId: '',
    accountId: accountId,
    name: 'Test Project',
    description: 'desc',
    category: 'Maintenance',
    startDate: DateTime.now(),
    targetEndDate: DateTime.now().add(const Duration(days: 90)),
    projectLead: projectLead,
    status: 'Draft',
  );
}

PurchaseOrder buildTestPurchaseOrder({
  String id = 'PO-1',
  String status = 'Draft',
  String vendorId = 'VEND-1',
  double totalAmount = 500,
}) {
  return PurchaseOrder(
    id: id,
    poNumber: 'PO-0001',
    vendorId: vendorId,
    warehouseId: 'WH-1',
    status: status,
    totalAmount: totalAmount,
  );
}

Invoice buildTestInvoice({String id = 'INV-1', String invoiceType = 'AR'}) {
  return Invoice(
    id: id,
    invoiceType: invoiceType,
    invoiceDate: DateTime.now(),
    dueDate: DateTime.now().add(const Duration(days: 30)),
    status: 'Draft',
    currencyCode: 'ZAR',
    grossAmount: 0,
    taxAmount: 0,
    netAmount: 0,
  );
}

EquipmentModel buildTestEquipment({
  String? id = 'EQ-1',
  String status = 'InStock',
}) {
  return EquipmentModel(
    id: id,
    equipmentName: 'Excavator',
    assetTag: 'AST-001',
    location: 'Yard A',
    manufacturer: 'Caterpillar',
    category: 'Heavy Machinery',
    status: status,
    nextInspectionDate: DateTime.now().add(const Duration(days: 90)),
    daysUntilInspection: 90,
    authorId: 'owner-1',
    createdAt: DateTime.now(),
    tenantId: bpfTestTenantId,
  );
}

/// Fallback values mocktail needs whenever a test uses `any()`/`captureAny()`
/// for these custom model types. Call once from a `setUpAll` in each test
/// file that stubs a domain-service method taking one of these as an arg.
void registerBpfOrchestratorFallbackValues() {
  registerFallbackValue(buildTestLead());
  registerFallbackValue(buildTestOpportunity());
  registerFallbackValue(buildTestQuote());
  registerFallbackValue(buildTestProject());
  registerFallbackValue(buildTestPurchaseOrder());
  registerFallbackValue(buildTestInvoice());
  registerFallbackValue(<String, dynamic>{});
}
