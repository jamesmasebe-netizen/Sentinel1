import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_service_models.dart';
import '../../../core/providers/app_providers.dart';

final customerServiceServiceProvider = Provider<CustomerServiceService>((ref) {
  return CustomerServiceService(ref.watch(tenantDocProvider));
});

class CustomerServiceService {
  final DocumentReference _tenantDoc;

  CustomerServiceService(this._tenantDoc);

  // --- Tickets ---

  Future<String> createTicket(Ticket ticket) async {
    final docRef = await _tenantDoc.firestore
        .collection('cs_tickets')
        .add(ticket.toJson());
    return docRef.id;
  }

  Future<Ticket?> getTicket(String ticketId) async {
    final doc = await _tenantDoc.collection('cs_tickets').doc(ticketId).get();
    if (doc.exists && doc.data() != null) {
      return Ticket.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateTicket(Ticket ticket) async {
    await _tenantDoc.firestore
        .collection('cs_tickets')
        .doc(ticket.id)
        .update(ticket.toJson());
  }

  Future<void> deleteTicket(String ticketId) async {
    await _tenantDoc.collection('cs_tickets').doc(ticketId).delete();
  }

  Stream<List<Ticket>> streamTickets() {
    return _tenantDoc.collection('cs_tickets').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Ticket.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // --- Ticket Messages ---

  Future<String> createTicketMessage(
    String ticketId,
    TicketMessage message,
  ) async {
    final docRef = await _tenantDoc.firestore
        .collection('cs_tickets')
        .doc(ticketId)
        .collection('messages')
        .add(message.toJson());
    return docRef.id;
  }

  Stream<List<TicketMessage>> streamTicketMessages(String ticketId) {
    return _tenantDoc.firestore
        .collection('cs_tickets')
        .doc(ticketId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TicketMessage.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  // --- Knowledge Articles ---

  Future<String> createKnowledgeArticle(KnowledgeArticle article) async {
    final docRef = await _tenantDoc.firestore
        .collection('cs_knowledge_articles')
        .add(article.toJson());
    return docRef.id;
  }

  Future<KnowledgeArticle?> getKnowledgeArticle(String articleId) async {
    final doc =
        await _tenantDoc.firestore
            .collection('cs_knowledge_articles')
            .doc(articleId)
            .get();
    if (doc.exists && doc.data() != null) {
      return KnowledgeArticle.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateKnowledgeArticle(KnowledgeArticle article) async {
    await _tenantDoc.firestore
        .collection('cs_knowledge_articles')
        .doc(article.id)
        .update(article.toJson());
  }

  Future<void> deleteKnowledgeArticle(String articleId) async {
    await _tenantDoc.firestore
        .collection('cs_knowledge_articles')
        .doc(articleId)
        .delete();
  }

  Stream<List<KnowledgeArticle>> streamKnowledgeArticles() {
    return _tenantDoc.collection('cs_knowledge_articles').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => KnowledgeArticle.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // --- SLA Instances ---

  Future<String> createSlaInstance(
    String ticketId,
    SlaInstance slaInstance,
  ) async {
    final docRef = await _tenantDoc.firestore
        .collection('cs_tickets')
        .doc(ticketId)
        .collection('sla_kpi_instances')
        .add(slaInstance.toJson());
    return docRef.id;
  }

  Stream<List<SlaInstance>> streamSlaInstances(String ticketId) {
    return _tenantDoc.firestore
        .collection('cs_tickets')
        .doc(ticketId)
        .collection('sla_kpi_instances')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SlaInstance.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  // --- Assets ---

  Future<String> createAsset(CsAsset asset) async {
    final docRef = await _tenantDoc.collection('cs_assets').add(asset.toJson());
    return docRef.id;
  }

  Future<CsAsset?> getAsset(String assetId) async {
    final doc = await _tenantDoc.collection('cs_assets').doc(assetId).get();
    if (doc.exists && doc.data() != null) {
      return CsAsset.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateAsset(CsAsset asset) async {
    await _tenantDoc.firestore
        .collection('cs_assets')
        .doc(asset.id)
        .update(asset.toJson());
  }

  Future<void> deleteAsset(String assetId) async {
    await _tenantDoc.collection('cs_assets').doc(assetId).delete();
  }

  Stream<List<CsAsset>> streamAssets() {
    return _tenantDoc.collection('cs_assets').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CsAsset.fromJson(doc.data(), doc.id))
          .toList();
    });
  }
}
