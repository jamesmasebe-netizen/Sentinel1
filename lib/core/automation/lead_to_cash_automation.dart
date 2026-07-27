import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/crm/models/crm_models.dart';
import '../../features/crm/services/crm_service.dart';
import '../../features/finance/models/finance_models.dart';
import '../../features/finance/services/finance_service.dart';
import '../../features/supply_chain/models/scm_models.dart';
import '../../features/supply_chain/services/scm_service.dart';

final leadToCashAutomationProvider = Provider<LeadToCashAutomation>((ref) {
  return LeadToCashAutomation(
    ref.watch(crmServiceProvider),
    ref.watch(financeServiceProvider),
    ref.watch(scmServiceProvider),
  );
});

class LeadToCashAutomation {
  final CrmService crmService;
  final FinanceService financeService;
  final ScmService scmService;

  LeadToCashAutomation(this.crmService, this.financeService, this.scmService);

  Future<void> triggerOpportunityWon(Opportunity opp) async {
    // 1. Create Sales Order in SCM
    final salesOrder = SalesOrder(
      id: '',
      orderNumber: 'SO-${DateTime.now().millisecondsSinceEpoch}',
      accountId: opp.accountId,
      status: 'Pending',
      orderDate: DateTime.now(),
      totalAmount: opp.amount,
    );
    await scmService.createSalesOrder(salesOrder);

    // 2. Draft Invoice in Finance
    final invoice = Invoice(
      id: '',
      invoiceType: 'AR',
      customerId: opp.accountId,
      invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      invoiceDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      status: 'DRAFT',
      currencyCode: 'USD',
      grossAmount: opp.amount,
      taxAmount: 0.0,
      netAmount: opp.amount,
    );
    await financeService.createInvoice(invoice);
  }
}
