// Tests for CrmService (lib/features/crm/services/crm_service.dart) —
// Lead/Opportunity/Quote/Account CRUD, the core Lead-to-Cash data layer.
//
// FIXED (see docs/testing/TEST_BACKLOG.md's "Flagged-not-fixed follow-up pass" for T3-CRM):
// CrmService used to have its own full convertLeadToOpportunity (Account + Contact + Opportunity +
// Lead update) that nothing ever called — the real "Convert Lead" button
// (lead_detail_screen.dart) always called BpfOrchestrator.convertLeadToOpportunity instead, which
// built its Opportunity from Lead.convertedAccountId/convertedContactId directly (always null on a
// real, not-yet-converted lead), so every real conversion produced an Opportunity with a blank
// account/contact link. Rather than keep two divergent implementations in sync, CrmService now
// exposes just the account/contact half as createAccountAndContactForLead (tested below);
// BpfOrchestrator calls it and keeps doing the Opportunity/Lead/BPF-stage wiring it already had —
// see bpf_orchestrator_test.dart for that side. The dead version's own Opportunity defaults
// (lowercase 'qualification'/'pipeline', probability as a 0-1 fraction) were themselves latent bugs
// — crm_models.dart/opportunity_form.dart use capitalized stage/forecastCategory strings and store
// probability as a 0-100 number (opportunity_detail_screen.dart renders `probability.toInt()}%`) —
// so BpfOrchestrator's existing values were kept, not the removed method's.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/crm/models/crm_models.dart';
import 'package:sentinel1/features/crm/services/crm_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late CrmService service;
  const tenantId = 'tenant-crm-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = CrmService(firestore.collection('tenants').doc(tenantId));
  });

  Lead buildLead({String id = 'lead-1', String? convertedAccountId, String? convertedContactId}) {
    return Lead(
      id: id,
      firstName: 'Jane',
      lastName: 'Doe',
      company: 'Acme Corp',
      email: 'jane@acme.test',
      phone: '+27000000000',
      leadSource: 'Website',
      status: 'Open',
      rating: 'Hot',
      aiLeadScore: 80,
      ownerId: 'owner-1',
      isConverted: false,
      convertedAccountId: convertedAccountId,
      convertedContactId: convertedContactId,
    );
  }

  group('Lead', () {
    test('createLead writes to the tenant-scoped leads collection', () async {
      await service.createLead(buildLead());

      final docs = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('leads')
          .get();
      expect(docs.docs.single.data()['company'], 'Acme Corp');
    });

    test('streamLeads returns only this tenant\'s leads', () async {
      await service.createLead(buildLead(id: 'lead-a'));
      await firestore
          .collection('tenants')
          .doc('other-tenant')
          .collection('leads')
          .doc('lead-b')
          .set(buildLead(id: 'lead-b').toJson());

      final result = await service.streamLeads().first;

      expect(result, hasLength(1));
      expect(result.single.company, 'Acme Corp');
    });

    // updateLead/deleteLead/convertLeadToOpportunity all operate on a specific lead.id via
    // .doc(lead.id) — but createLead (like createAccount) ignores the input's id and
    // auto-generates one, so these tests seed directly at a known path rather than going
    // through createLead first (that combination is exercised by the createLead test above).
    test('updateLead persists changed fields', () async {
      final leadRef = firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('leads')
          .doc('lead-1');
      await leadRef.set(buildLead().toJson());

      await service.updateLead(buildLead(convertedAccountId: 'ACC-1'));

      final doc = await leadRef.get();
      expect(doc.data()!['convertedAccountId'], 'ACC-1');
    });

    test('deleteLead removes the doc', () async {
      final leadRef = firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('leads')
          .doc('lead-1');
      await leadRef.set(buildLead().toJson());

      await service.deleteLead('lead-1');

      expect((await leadRef.get()).exists, isFalse);
    });
  });

  group('createAccountAndContactForLead', () {
    test('creates a real Account and Contact for the lead, atomically', () async {
      final lead = buildLead();

      final ids = await service.createAccountAndContactForLead(lead);

      expect(ids['accountId'], isNotEmpty);
      expect(ids['contactId'], isNotEmpty);

      final accountDoc = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('accounts')
          .doc(ids['accountId'])
          .get();
      expect(accountDoc.data()!['name'], 'Acme Corp');

      final contactDoc = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('contacts')
          .doc(ids['contactId'])
          .get();
      expect(contactDoc.data()!['accountId'], ids['accountId']);
      expect(contactDoc.data()!['firstName'], 'Jane');
      expect(contactDoc.data()!['email'], 'jane@acme.test');
    });
  });

  group('Opportunity', () {
    test('createOpportunity returns a real generated id and persists the record', () async {
      final opp = Opportunity(
        id: '',
        name: 'Acme - Opportunity',
        accountId: 'ACC-1',
        primaryContactId: 'CON-1',
        stage: 'Prospecting',
        amount: 5000,
        probability: 20,
        forecastCategory: 'Pipeline',
        leadSource: 'Website',
        nextStep: '',
        ownerId: 'owner-1',
      );

      final id = await service.createOpportunity(opp);

      final doc = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('opportunities')
          .doc(id)
          .get();
      expect(doc.data()!['accountId'], 'ACC-1');
      expect(doc.data()!['amount'], 5000);
    });
  });

  group('Quote', () {
    test('createQuote returns a real generated id and persists the record', () async {
      final quote = Quote(
        id: '',
        opportunityId: 'OPP-1',
        accountId: 'ACC-1',
        quoteNumber: 'QT-0001',
        status: 'Draft',
        subtotal: 1000,
        discount: 0,
        tax: 0,
        grandTotal: 1000,
        termsAndConditions: '',
        isSyncing: false,
        ownerId: 'owner-1',
      );

      final id = await service.createQuote(quote);

      final doc = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('quotes')
          .doc(id)
          .get();
      expect(doc.data()!['opportunityId'], 'OPP-1');
      expect(doc.data()!['status'], 'Draft');
    });

    // Regression guard: streamQuotes previously queried the root-level `quotes` collection
    // (`_tenantDoc.firestore.collection('quotes')`) while createQuote/updateQuote/deleteQuote
    // all correctly used the tenant-scoped path — meaning it could never find anything
    // createQuote actually wrote. Reachable via opportunity_detail_screen.dart's Quotes
    // section, which always rendered empty. Fixed 2026-08-07 (see TEST_BACKLOG.md T3-CRM).
    test('streamQuotes filters by opportunityId', () async {
      final quoteA = Quote(
        id: '',
        opportunityId: 'OPP-1',
        accountId: 'ACC-1',
        quoteNumber: 'QT-A',
        status: 'Draft',
        subtotal: 1000,
        discount: 0,
        tax: 0,
        grandTotal: 1000,
        termsAndConditions: '',
        isSyncing: false,
        ownerId: 'owner-1',
      );
      final quoteB = Quote(
        id: '',
        opportunityId: 'OPP-2',
        accountId: 'ACC-2',
        quoteNumber: 'QT-B',
        status: 'Draft',
        subtotal: 2000,
        discount: 0,
        tax: 0,
        grandTotal: 2000,
        termsAndConditions: '',
        isSyncing: false,
        ownerId: 'owner-1',
      );
      await service.createQuote(quoteA);
      await service.createQuote(quoteB);

      final result = await service.streamQuotes('OPP-1').first;

      expect(result, hasLength(1));
      expect(result.single.quoteNumber, 'QT-A');
    });
  });

  group('Account', () {
    test('createAccount persists the full record, findable via streamAccounts', () async {
      final account = Account(
        id: '',
        name: 'Acme Corp',
        industry: 'Manufacturing',
        website: 'https://acme.test',
        annualRevenue: 1000000,
        employeeCount: 50,
        ownerId: 'owner-1',
        status: 'Active',
        relationshipHealth: 'Good',
      );
      await service.createAccount(account);

      final result = await service.streamAccounts().first;

      expect(result, hasLength(1));
      expect(result.single.name, 'Acme Corp');
      expect(result.single.employeeCount, 50);
    });
  });

  group('Contact', () {
    // Regression guard: streamContacts had the exact same root-vs-tenant-collection bug as
    // streamQuotes above (same fix, same commit) — reachable via opportunity_form.dart's
    // contact picker.
    test('streamContacts filters by accountId', () async {
      final contactA = Contact(
        id: '',
        accountId: 'ACC-1',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@acme.test',
        phone: '',
        mobile: '',
        jobTitle: '',
        department: '',
        leadSource: 'Website',
        isPrimary: true,
        ownerId: 'owner-1',
      );
      final contactB = Contact(
        id: '',
        accountId: 'ACC-2',
        firstName: 'John',
        lastName: 'Smith',
        email: 'john@other.test',
        phone: '',
        mobile: '',
        jobTitle: '',
        department: '',
        leadSource: 'Website',
        isPrimary: true,
        ownerId: 'owner-1',
      );
      await service.createContact(contactA);
      await service.createContact(contactB);

      final result = await service.streamContacts('ACC-1').first;

      expect(result, hasLength(1));
      expect(result.single.firstName, 'Jane');
    });
  });
}
