import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/customer_service/models/customer_service_models.dart';
import '../../features/customer_service/services/customer_service_service.dart';
import '../../features/field_service/models/field_service_models.dart';
import '../../features/field_service/services/field_service_service.dart';

final issueToResolutionAutomationProvider =
    Provider<IssueToResolutionAutomation>((ref) {
      final customerService = ref.watch(customerServiceServiceProvider);
      final fieldService = ref.watch(fieldServiceServiceProvider);

      return IssueToResolutionAutomation(
        customerService: customerService,
        fieldService: fieldService,
      );
    });

class IssueToResolutionAutomation {
  final CustomerServiceService _customerService;
  final FieldServiceService _fieldService;

  IssueToResolutionAutomation({
    required CustomerServiceService customerService,
    required FieldServiceService fieldService,
  }) : _customerService = customerService,
       _fieldService = fieldService;

  /// Automates the cross-pillar logic of escalating a customer service ticket.
  /// If the ticket severity is 'Critical', an emergency WorkOrder is generated
  /// in the Field Service module.
  Future<void> escalateTicketToWorkOrder(Ticket ticket) async {
    // 1. Escalate the ticket by updating its status and escalation flags
    final updatedTicket = Ticket(
      id: ticket.id,
      ticketId: ticket.ticketId,
      customerId: ticket.customerId,
      contactId: ticket.contactId,
      parentTicketId: ticket.parentTicketId,
      assetId: ticket.assetId,
      title: ticket.title,
      description: ticket.description,
      status: 'Escalated',
      resolutionType: ticket.resolutionType,
      priority: ticket.priority,
      severity: ticket.severity,
      channel: ticket.channel,
      assignedTo: ticket.assignedTo,
      workstreamId: ticket.workstreamId,
      queueId: ticket.queueId,
      entitlementId: ticket.entitlementId,
      isEscalated: true,
      escalationLevel: ticket.escalationLevel + 1,
      slaStatus: ticket.slaStatus,
      slaTimers: ticket.slaTimers,
      tags: ticket.tags,
      customFields: ticket.customFields,
      copilotSummary: ticket.copilotSummary,
      sentimentTrend: ticket.sentimentTrend,
      firstResponseAt: ticket.firstResponseAt,
      createdAt: ticket.createdAt,
      updatedAt: DateTime.now(),
      resolvedAt: ticket.resolvedAt,
      closedAt: ticket.closedAt,
    );

    await _customerService.updateTicket(updatedTicket);

    // 2. Generate an emergency WorkOrder if the severity is Critical
    if (ticket.severity.toLowerCase() == 'critical') {
      final docId =
          FirebaseFirestore.instance.collection('work_orders').doc().id;
      final workOrder = WorkOrder(
        id: docId,
        workOrderNumber: 'WO-${DateTime.now().millisecondsSinceEpoch}',
        status: 'UNSCHEDULED',
        priority: 'EMERGENCY',
        customerId: ticket.customerId ?? 'UNKNOWN_CUSTOMER',
        assetId: ticket.assetId,
        description:
            'Auto-generated from Critical Ticket: ${ticket.ticketId} - ${ticket.title}\n\n${ticket.description ?? ""}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _fieldService.createWorkOrder(workOrder);
    }
  }
}
