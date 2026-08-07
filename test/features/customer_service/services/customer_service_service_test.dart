// Tests for CustomerServiceService (lib/features/customer_service/services/customer_service_service.dart).
//
// The SLA instance tests below are the regression guard for a real, pre-existing bug fixed
// 2026-08-07 (see docs/testing/TEST_BACKLOG.md T3-CUSTOMERSERVICE): createSlaInstance/
// streamSlaInstances write to tenants/{tenantId}/cs_tickets/{ticketId}/sla_kpi_instances/{id} (a
// subcollection nested under the ticket), but firestore.rules declared sla_kpi_instances as a
// top-level collection — a completely different path. Since Firestore rule matching is
// structural, writes here fell through to the absolute deny-all fallback and were always
// rejected against real, rules-enforced Firestore (independent of anything else fixed this
// session — the fallback was always `if false`). fake_cloud_firestore doesn't enforce rules, so
// this test can't catch the rules mismatch itself (that's covered by
// firebase/functions/test/rules/crm_cs_fieldservice_cluster_distinctive.test.ts's new
// sla_kpi_instances block) — what it proves here is that the service layer's path shape is
// exactly what was cross-checked against the now-fixed rule.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/customer_service/models/customer_service_models.dart';
import 'package:sentinel1/features/customer_service/services/customer_service_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late CustomerServiceService service;
  const tenantId = 'tenant-cs-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = CustomerServiceService(firestore.collection('tenants').doc(tenantId));
  });

  group('Ticket', () {
    test('createTicket persists and is findable via streamTickets', () async {
      final id = await service.createTicket(Ticket(
        id: '',
        ticketId: 'TKT-001',
        title: 'Broken widget',
      ));

      final result = await service.streamTickets().first;

      expect(result, hasLength(1));
      expect(result.single.id, id);
      expect(result.single.title, 'Broken widget');
      expect(result.single.status, 'New');
    });

    test('updateTicket persists changed fields', () async {
      final id = await service.createTicket(Ticket(id: '', ticketId: 'TKT-002', title: 'Issue'));
      final ticket = await service.getTicket(id);

      await service.updateTicket(Ticket(
        id: id,
        ticketId: ticket!.ticketId,
        title: ticket.title,
        status: 'Resolved',
      ));

      final updated = await service.getTicket(id);
      expect(updated!.status, 'Resolved');
    });

    test('deleteTicket removes the doc', () async {
      final id = await service.createTicket(Ticket(id: '', ticketId: 'TKT-003', title: 'To delete'));

      await service.deleteTicket(id);

      expect(await service.getTicket(id), isNull);
    });
  });

  group('TicketMessage', () {
    test('createTicketMessage nests under the ticket and streams in timestamp order', () async {
      final ticketId = await service.createTicket(Ticket(id: '', ticketId: 'TKT-004', title: 'Thread'));
      await service.createTicketMessage(ticketId, TicketMessage(id: '', senderType: 'customer', content: 'First'));
      await service.createTicketMessage(ticketId, TicketMessage(id: '', senderType: 'agent', content: 'Second'));

      final result = await service.streamTicketMessages(ticketId).first;

      expect(result, hasLength(2));
      expect(result.map((m) => m.content), ['First', 'Second']);
    });
  });

  group('SlaInstance — nested under cs_tickets/{ticketId}, not top-level (see file header)', () {
    test('createSlaInstance nests under the ticket and is findable via streamSlaInstances', () async {
      final ticketId = await service.createTicket(Ticket(id: '', ticketId: 'TKT-005', title: 'SLA ticket'));

      await service.createSlaInstance(ticketId, SlaInstance(id: '', kpiType: 'first_response'));

      final result = await service.streamSlaInstances(ticketId).first;
      expect(result, hasLength(1));
      expect(result.single.kpiType, 'first_response');

      // Confirms the write really landed nested under the ticket, not at a top-level collection.
      final nestedDoc = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('cs_tickets')
          .doc(ticketId)
          .collection('sla_kpi_instances')
          .get();
      expect(nestedDoc.docs, hasLength(1));
    });
  });

  group('KnowledgeArticle', () {
    test('createKnowledgeArticle persists and is findable via streamKnowledgeArticles', () async {
      await service.createKnowledgeArticle(KnowledgeArticle(
        id: '',
        articleNumber: 'KA-001',
        title: 'How to reset your password',
      ));

      final result = await service.streamKnowledgeArticles().first;

      expect(result, hasLength(1));
      expect(result.single.title, 'How to reset your password');
    });
  });

  group('CsAsset', () {
    test('createAsset persists and is findable via streamAssets', () async {
      await service.createAsset(CsAsset(id: '', name: 'Widget Pro 3000'));

      final result = await service.streamAssets().first;

      expect(result, hasLength(1));
      expect(result.single.name, 'Widget Pro 3000');
    });
  });
}
