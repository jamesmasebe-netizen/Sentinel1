import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crm_models.dart';
import '../../../core/providers/app_providers.dart';

final crmServiceProvider = Provider<CrmService>((ref) {
  return CrmService(ref.watch(tenantDocProvider));
});

/// Deal/DealStage (the 'deals' collection, plus createDeal/updateDeal/deleteDeal/streamDeals)
/// removed 2026-08-12 — merged into Opportunity (see pipeline_kanban_screen.dart's header
/// comment). It was a second, independently-routed sales pipeline with no real Account/Contact
/// links (customerName was a free-text string), genuinely duplicating Opportunity's own live,
/// BPF-integrated pipeline.
class CrmService {
  final DocumentReference _tenantDoc;

  CrmService(this._tenantDoc);

  // ---------- ACCOUNTS ----------

  Future<void> createAccount(Account account) async {
    final docRef = _tenantDoc.collection('accounts').doc();
    final data = account.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  Future<void> updateAccount(Account account) async {
    final data = account.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _tenantDoc.collection('accounts').doc(account.id).update(data);
  }

  Future<void> deleteAccount(String accountId) async {
    await _tenantDoc.collection('accounts').doc(accountId).delete();
  }

  Stream<List<Account>> streamAccounts() {
    return _tenantDoc.collection('accounts').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Account.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Future<Account?> getAccount(String accountId) async {
    final doc = await _tenantDoc.collection('accounts').doc(accountId).get();
    if (!doc.exists) return null;
    return Account.fromJson(doc.data()!, doc.id);
  }

  Stream<Account?> streamAccount(String accountId) {
    return _tenantDoc.collection('accounts').doc(accountId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return Account.fromJson(doc.data()!, doc.id);
    });
  }

  // ---------- CONTACTS ----------

  Future<void> createContact(Contact contact) async {
    final docRef = _tenantDoc.collection('contacts').doc();
    final data = contact.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  Future<void> updateContact(Contact contact) async {
    final data = contact.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _tenantDoc.collection('contacts').doc(contact.id).update(data);
  }

  Future<void> deleteContact(String contactId) async {
    await _tenantDoc.collection('contacts').doc(contactId).delete();
  }

  Stream<List<Contact>> streamContacts(String accountId) {
    return _tenantDoc
        .collection('contacts')
        .where('accountId', isEqualTo: accountId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Contact.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  Future<Contact?> getContact(String contactId) async {
    final doc = await _tenantDoc.collection('contacts').doc(contactId).get();
    if (!doc.exists) return null;
    return Contact.fromJson(doc.data()!, doc.id);
  }

  // ---------- LEADS ----------

  Future<void> createLead(Lead lead) async {
    final docRef = _tenantDoc.collection('leads').doc();
    final data = lead.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  Future<void> updateLead(Lead lead) async {
    final data = lead.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _tenantDoc.collection('leads').doc(lead.id).update(data);
  }

  Future<void> deleteLead(String leadId) async {
    await _tenantDoc.collection('leads').doc(leadId).delete();
  }

  Stream<List<Lead>> streamLeads() {
    return _tenantDoc.collection('leads').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Lead.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<Lead?> streamLead(String leadId) {
    return _tenantDoc.collection('leads').doc(leadId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Lead.fromJson(doc.data()!, doc.id);
    });
  }

  Future<Lead?> getLead(String leadId) async {
    final doc = await _tenantDoc.collection('leads').doc(leadId).get();
    if (!doc.exists) return null;
    return Lead.fromJson(doc.data()!, doc.id);
  }

  // ---------- OPPORTUNITIES ----------

  Future<String> createOpportunity(Opportunity opp) async {
    final docRef = _tenantDoc.collection('opportunities').doc();
    final data = opp.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
    return docRef.id;
  }

  Future<void> updateOpportunity(Opportunity opp) async {
    final data = opp.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _tenantDoc.collection('opportunities').doc(opp.id).update(data);
  }

  Future<void> deleteOpportunity(String oppId) async {
    await _tenantDoc.collection('opportunities').doc(oppId).delete();
  }

  Stream<List<Opportunity>> streamOpportunities() {
    return _tenantDoc.collection('opportunities').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Opportunity.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<Opportunity?> streamOpportunity(String oppId) {
    return _tenantDoc.collection('opportunities').doc(oppId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return Opportunity.fromJson(doc.data()!, doc.id);
    });
  }

  Future<Opportunity?> getOpportunity(String oppId) async {
    final doc = await _tenantDoc.collection('opportunities').doc(oppId).get();
    if (!doc.exists) return null;
    return Opportunity.fromJson(doc.data()!, doc.id);
  }

  // ---------- QUOTES ----------

  Future<String> createQuote(Quote quote) async {
    final docRef = _tenantDoc.collection('quotes').doc();
    final data = quote.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
    return docRef.id;
  }

  Future<void> updateQuote(Quote quote) async {
    final data = quote.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _tenantDoc.collection('quotes').doc(quote.id).update(data);
  }

  Future<void> deleteQuote(String quoteId) async {
    await _tenantDoc.collection('quotes').doc(quoteId).delete();
  }

  Stream<List<Quote>> streamQuotes(String opportunityId) {
    return _tenantDoc
        .collection('quotes')
        .where('opportunityId', isEqualTo: opportunityId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Quote.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<Quote?> streamQuote(String quoteId) {
    return _tenantDoc.collection('quotes').doc(quoteId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Quote.fromJson(doc.data()!, doc.id);
    });
  }

  Future<Quote?> getQuote(String quoteId) async {
    final doc = await _tenantDoc.collection('quotes').doc(quoteId).get();
    if (!doc.exists) return null;
    return Quote.fromJson(doc.data()!, doc.id);
  }

  // ---------- CAMPAIGNS ----------

  Future<void> createCampaign(Campaign campaign) async {
    final docRef = _tenantDoc.collection('campaigns').doc();
    final data = campaign.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  Future<void> updateCampaign(Campaign campaign) async {
    final data = campaign.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _tenantDoc.collection('campaigns').doc(campaign.id).update(data);
  }

  Future<void> deleteCampaign(String campaignId) async {
    await _tenantDoc.collection('campaigns').doc(campaignId).delete();
  }

  Stream<List<Campaign>> streamCampaigns() {
    return _tenantDoc.collection('campaigns').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Campaign.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Future<Campaign?> getCampaign(String campaignId) async {
    final doc = await _tenantDoc.collection('campaigns').doc(campaignId).get();
    if (!doc.exists) return null;
    return Campaign.fromJson(doc.data()!, doc.id);
  }

  // ---------- CUSTOMER JOURNEYS ----------

  Future<void> createCustomerJourney(CustomerJourney journey) async {
    final docRef = _tenantDoc.collection('customerJourneys').doc();
    final data = journey.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  Future<void> updateCustomerJourney(CustomerJourney journey) async {
    final data = journey.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _tenantDoc
        .collection('customerJourneys')
        .doc(journey.id)
        .update(data);
  }

  Stream<List<CustomerJourney>> streamJourneysForLead(String leadId) {
    return _tenantDoc
        .collection('customerJourneys')
        .where('leadId', isEqualTo: leadId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CustomerJourney.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<CustomerJourney?> streamJourney(String journeyId) {
    return _tenantDoc
        .collection('customerJourneys')
        .doc(journeyId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return CustomerJourney.fromJson(doc.data()!, doc.id);
        });
  }

  // ---------- ACTIVITIES ----------

  Future<void> createActivity(Activity activity) async {
    final docRef = _tenantDoc.collection('activities').doc();
    final data = activity.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  Future<void> updateActivity(Activity activity) async {
    final data = activity.toJson();
    await _tenantDoc.collection('activities').doc(activity.id).update(data);
  }

  Future<void> deleteActivity(String activityId) async {
    await _tenantDoc.collection('activities').doc(activityId).delete();
  }

  Stream<List<Activity>> streamActivities({
    String? regardingType,
    String? regardingId,
  }) {
    Query query = _tenantDoc.collection('activities');
    if (regardingType != null) {
      query = query.where('regardingType', isEqualTo: regardingType);
    }
    if (regardingId != null) {
      query = query.where('regardingId', isEqualTo: regardingId);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                Activity.fromJson(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    });
  }

  // ---------- LEAD CONVERSION ----------

  /// Creates a new Account + Contact for a converting Lead, atomically. This is the account/contact
  /// half of lead conversion; the Opportunity itself and the Lead's own converted* fields are the
  /// caller's responsibility (see BpfOrchestrator.convertLeadToOpportunity, the only real caller —
  /// it also needs to advance the BPF stage, which this service has no notion of). Previously this
  /// method did all four steps (Account, Contact, Opportunity, Lead update) itself, but nothing
  /// ever called it — the live "Convert Lead" button always called BpfOrchestrator's separate,
  /// incomplete implementation instead, which built the Opportunity from Lead.convertedAccountId/
  /// convertedContactId directly. Those are only ever set by conversion itself, so every real
  /// conversion produced an Opportunity with a blank account/contact link. Split out just the
  /// account/contact creation so BpfOrchestrator can use it while keeping the Opportunity defaults
  /// and BPF wiring it already had right (see its own doc comment for why its stage/probability/
  /// forecastCategory values are the ones that survived, not this method's former ones).
  Future<Map<String, String>> createAccountAndContactForLead(Lead lead) async {
    final batch = _tenantDoc.firestore.batch();

    final accountRef = _tenantDoc.collection('accounts').doc();
    final accountData =
        Account(
          id: '',
          name: lead.company,
          industry: 'Unknown',
          website: '',
          annualRevenue: 0.0,
          employeeCount: 0,
          ownerId: lead.ownerId,
          status: 'Active',
          relationshipHealth: 'Good',
        ).toJson();
    accountData['createdAt'] = FieldValue.serverTimestamp();
    accountData['updatedAt'] = FieldValue.serverTimestamp();
    batch.set(accountRef, accountData);

    final contactRef = _tenantDoc.collection('contacts').doc();
    final contactData =
        Contact(
          id: '',
          accountId: accountRef.id,
          firstName: lead.firstName,
          lastName: lead.lastName,
          email: lead.email,
          phone: lead.phone,
          mobile: '',
          jobTitle: '',
          department: '',
          leadSource: lead.leadSource,
          isPrimary: true,
          ownerId: lead.ownerId,
        ).toJson();
    contactData['createdAt'] = FieldValue.serverTimestamp();
    contactData['updatedAt'] = FieldValue.serverTimestamp();
    batch.set(contactRef, contactData);

    await batch.commit();

    return {'accountId': accountRef.id, 'contactId': contactRef.id};
  }
}
