import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/crm/models/crm_models.dart';
import '../../features/crm/services/crm_service.dart';
import '../../features/projects/models/pmo_models.dart';
import '../../features/projects/services/pmo_service.dart';
import '../../features/finance/models/finance_models.dart';
import '../../features/finance/services/finance_service.dart';
import '../../features/supply_chain/services/scm_service.dart';
import '../../features/supply_chain/models/scm_models.dart';
import '../../features/equipment/models/equipment_models.dart';
import 'bpf_service.dart';

final bpfOrchestratorProvider = Provider<BpfOrchestrator>((ref) {
  return BpfOrchestrator(
    ref.read(bpfServiceProvider),
    ref.read(crmServiceProvider),
    ref.read(pmoServiceProvider),
    ref.read(financeServiceProvider),
    ref.read(scmServiceProvider),
  );
});

class BpfOrchestrator {
  final BpfService bpfService;
  final CrmService crmService;
  final PmoService pmoService;
  final FinanceService financeService;
  final ScmService scmService;

  BpfOrchestrator(
    this.bpfService,
    this.crmService,
    this.pmoService,
    this.financeService,
    this.scmService,
  );

  /// Converts a Lead to an Opportunity and advances the BPF stage
  Future<String> convertLeadToOpportunity(Lead lead, String bpfId) async {
    final opp = Opportunity(
      id: '',
      name: '${lead.company} Opportunity',
      accountId: lead.convertedAccountId ?? '',
      primaryContactId: lead.convertedContactId ?? '',
      stage: 'Prospecting',
      amount: 0,
      probability: 20,
      forecastCategory: 'Pipeline',
      leadSource: lead.leadSource,
      nextStep: '',
      ownerId: lead.ownerId,
      expectedCloseDate: DateTime.now().add(const Duration(days: 30)),
    );
    final oppId = await crmService.createOpportunity(opp);

    // Update lead via service — Lead has no copyWith, update via map
    final updatedLead = Lead(
      id: lead.id,
      firstName: lead.firstName,
      lastName: lead.lastName,
      company: lead.company,
      email: lead.email,
      phone: lead.phone,
      leadSource: lead.leadSource,
      status: 'Converted',
      rating: lead.rating,
      aiLeadScore: lead.aiLeadScore,
      sequenceId: lead.sequenceId,
      ownerId: lead.ownerId,
      isConverted: true,
      convertedAccountId: lead.convertedAccountId,
      convertedContactId: lead.convertedContactId,
      convertedOpportunityId: oppId,
      createdAt: lead.createdAt,
      updatedAt: DateTime.now(),
    );
    await crmService.updateLead(updatedLead);

    await bpfService.advanceStage(
      bpfId,
      'opportunity_management',
      newlyLinkedRecords: {'opportunityId': oppId},
    );

    return oppId;
  }

  /// Converts an Opportunity to a Quote and advances the BPF stage
  Future<String> createQuoteFromOpportunity(Opportunity opp, String bpfId) async {
    final quoteNumber = 'QT-${DateTime.now().millisecondsSinceEpoch}';
    final quote = Quote(
      id: '',
      quoteNumber: quoteNumber,
      opportunityId: opp.id,
      accountId: opp.accountId,
      status: 'Draft',
      subtotal: opp.amount,
      discount: 0,
      tax: 0,
      grandTotal: opp.amount,
      termsAndConditions: '',
      isSyncing: false,
      ownerId: opp.ownerId,
      expirationDate: DateTime.now().add(const Duration(days: 14)),
    );
    final quoteId = await crmService.createQuote(quote);

    await bpfService.advanceStage(
      bpfId,
      'quoting_and_proposals',
      newlyLinkedRecords: {'quoteId': quoteId},
    );

    return quoteId;
  }

  /// Converts a Quote to a Project and advances the BPF stage
  Future<String> createProjectFromQuote(Quote quote, String bpfId) async {
    final projectId = 'PRJ-${DateTime.now().millisecondsSinceEpoch}';
    final project = Project(
      projectId: projectId,
      clientId: quote.accountId,
      contractId: '',
      name: 'Project for ${quote.quoteNumber}',
      description: 'Auto-generated from quote',
      status: 'Planning',
      projectManagerId: quote.ownerId,
      revenueRecognitionMethod: 'Milestone',
      allocatedEmployeeIds: [],
      allocatedContractorIds: [],
      allocatedAssetIds: [],
    );
    await pmoService.createProject(project);

    // Also mark quote as accepted
    final acceptedQuote = Quote(
      id: quote.id,
      quoteNumber: quote.quoteNumber,
      opportunityId: quote.opportunityId,
      accountId: quote.accountId,
      status: 'Accepted',
      subtotal: quote.subtotal,
      discount: quote.discount,
      tax: quote.tax,
      grandTotal: quote.grandTotal,
      termsAndConditions: quote.termsAndConditions,
      isSyncing: quote.isSyncing,
      ownerId: quote.ownerId,
      expirationDate: quote.expirationDate,
      billingAddress: quote.billingAddress,
      shippingAddress: quote.shippingAddress,
    );
    await crmService.updateQuote(acceptedQuote);

    await bpfService.advanceStage(
      bpfId,
      'project_execution',
      newlyLinkedRecords: {'projectId': projectId},
    );

    return projectId;
  }

  /// Creates an Invoice from a Project and advances the BPF stage
  Future<String> createInvoiceFromProject(Project project, String bpfId) async {
    final invoiceId = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    final invoice = Invoice(
      id: invoiceId,
      invoiceNumber: invoiceId,
      customerId: project.clientId,
      invoiceType: 'AR',
      grossAmount: 0, // To be filled by user
      taxAmount: 0,
      netAmount: 0,
      status: 'Draft',
      currencyCode: 'ZAR',
      dueDate: DateTime.now().add(const Duration(days: 30)),
      invoiceDate: DateTime.now(),
    );
    await financeService.createInvoice(invoice);

    await bpfService.advanceStage(
      bpfId,
      'billing_and_collection',
      newlyLinkedRecords: {'invoiceId': invoiceId},
    );

    return invoiceId;
  }

  /// Procure to Pay: Creates an AP Invoice from a Purchase Order
  Future<String> createInvoiceFromPurchaseOrder(PurchaseOrder po, String bpfId) async {
    final invoiceId = 'AP-INV-${DateTime.now().millisecondsSinceEpoch}';
    final invoice = Invoice(
      id: invoiceId,
      invoiceNumber: invoiceId,
      vendorId: po.vendorId,
      invoiceType: 'AP',
      grossAmount: po.totalAmount,
      taxAmount: 0,
      netAmount: po.totalAmount,
      status: 'Draft',
      currencyCode: 'ZAR',
      dueDate: DateTime.now().add(const Duration(days: 30)),
      invoiceDate: DateTime.now(),
    );
    await financeService.createInvoice(invoice);

    await bpfService.advanceStage(
      bpfId,
      'ap_invoice',
      newlyLinkedRecords: {'apInvoiceId': invoiceId},
    );

    return invoiceId;
  }

  /// Asset Lifecycle: Deploys an equipment item (changes status to deployed)
  Future<void> deployEquipment(EquipmentModel equipment, String projectId, String bpfId) async {
    // We would normally update the equipment document here via EquipmentService
    // But since it's just handled directly in firestore in UI for now, we'll
    // just advance the BPF stage.
    await bpfService.advanceStage(
      bpfId,
      'deployment',
      newlyLinkedRecords: {'projectId': projectId},
    );
  }

  /// Issue to Resolution: Generates a CAPA from an Incident and advances the BPF stage
  Future<String> createCapaFromIncident(String incidentId, String bpfId) async {
    // Generates a mock CAPA ID and links it.
    final capaId = 'CAPA-${DateTime.now().millisecondsSinceEpoch}';

    // In a real implementation we would write to safetyService.createCapa(...)

    await bpfService.advanceStage(
      bpfId,
      'capa',
      newlyLinkedRecords: {'capaId': capaId},
    );

    return capaId;
  }

  /// Hire to Retire: Marks an employee as Active after onboarding
  Future<void> completeOnboarding(String employeeId, String bpfId) async {
    // In a real implementation we would update EmployeeProfile to "Active" via HR service

    await bpfService.advanceStage(
      bpfId,
      'active',
      newlyLinkedRecords: {'deploymentStatus': 'Active'},
    );
  }
}
