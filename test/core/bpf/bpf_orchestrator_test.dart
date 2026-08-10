// Tests for BpfOrchestrator (lib/core/bpf/bpf_orchestrator.dart) — the
// Lead-to-Cash chain: convertLeadToOpportunity -> createQuoteFromOpportunity
// -> createProjectFromQuote -> createInvoiceFromProject.
//
// REAL BUG FOUND AND FIXED 2026-08-06 (see docs/testing/TEST_BACKLOG.md
// T1-004 resolved note): before this fix, three of this file's hardcoded
// next-stage ids ('opportunity_management', 'quoting_and_proposals',
// 'billing_and_collection') did not exist anywhere in leadToCashDefinition
// (lead_to_cash_bpf.dart), whose real stage ids are lead/opportunity/
// quote/project_execution/invoice. Because BpfService.advanceStage had no
// validation, this silently wrote an unrecognized currentStageId —
// BpfRibbonWidget's `definition.stages.indexWhere(...)` then returned -1, so
// the ribbon rendered with NO stage highlighted as current/completed for
// most of the Lead-to-Cash flow, despite F-004 in docs/fixes/FIX_LIST.md
// being marked [DONE] with "ribbon visually advances" as its own stated
// verification criterion. Fixed by correcting the three stage ids below to
// match the real definition, and BpfService now rejects an unrecognized
// stage id outright (see bpf_service_test.dart) so this class of bug can't
// silently ship again.
//
// What this file covers: each orchestrator method wires the RIGHT
// domain-service call with the RIGHT data and advances the BPF to the RIGHT
// (now-verified-real) next stage with the RIGHT linked-record keys. Gating
// itself (stage-id validity, in-progress status) lives in and is tested by
// bpf_service_test.dart — this file does not re-test that, only that the
// orchestrator passes it correct arguments.
//
// Domain services are mocked (mocktail) so this file isolates the
// orchestrator's own wiring logic. BpfService is real, backed by
// fake_cloud_firestore, so stage persistence is genuinely exercised rather
// than re-mocked (per TEST_STRATEGY.md's guidance to override the provider
// a service is built from, not bypass the real logic).
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/features/crm/models/crm_models.dart';
import 'package:sentinel1/features/finance/models/finance_models.dart';
import 'package:sentinel1/features/projects/models/project_models.dart';

import '../../helpers/bpf_orchestrator_fixtures.dart';
import '../../helpers/bpf_orchestrator_model_fixtures.dart';

void main() {
  setUpAll(registerBpfOrchestratorFallbackValues);

  late BpfOrchestratorHarness h;

  setUp(() {
    h = BpfOrchestratorHarness.build();
    addTearDown(h.container.dispose);
  });

  group('convertLeadToOpportunity', () {
    test('creates a real Account/Contact first, links the opportunity and lead to them, and '
        'advances to opportunity with the new opportunityId linked', () async {
      // A real, not-yet-converted Lead has no convertedAccountId/convertedContactId — those are
      // only ever set BY conversion. Pre-populating them here (as this test used to) would mask
      // the exact bug this test now guards against: the orchestrator used to build the
      // Opportunity straight from these (always-null, on a real lead) fields instead of actually
      // creating an Account/Contact — see bpf_orchestrator.dart's doc comment on this method.
      final lead = buildTestLead(id: 'LEAD-1');
      final bpfId = await seedBpfInstance(h.db,
          bpfTypeId: 'lead_to_cash', currentStageId: 'lead');

      when(() => h.crm.createAccountAndContactForLead(any()))
          .thenAnswer((_) async => {'accountId': 'ACC-NEW', 'contactId': 'CON-NEW'});
      when(() => h.crm.createOpportunity(any()))
          .thenAnswer((_) async => 'OPP-NEW');
      when(() => h.crm.updateLead(any())).thenAnswer((_) async {});

      final oppId = await h.orchestrator.convertLeadToOpportunity(lead, bpfId);

      expect(oppId, 'OPP-NEW');

      verify(() => h.crm.createAccountAndContactForLead(lead)).called(1);

      final createdOpp =
          verify(() => h.crm.createOpportunity(captureAny())).captured.single
              as Opportunity;
      expect(createdOpp.accountId, 'ACC-NEW');
      expect(createdOpp.primaryContactId, 'CON-NEW');
      expect(createdOpp.stage, 'Prospecting');
      expect(createdOpp.probability, 20);
      expect(createdOpp.forecastCategory, 'Pipeline');

      final updatedLead =
          verify(() => h.crm.updateLead(captureAny())).captured.single
              as Lead;
      expect(updatedLead.status, 'Converted');
      expect(updatedLead.isConverted, isTrue);
      expect(updatedLead.convertedAccountId, 'ACC-NEW');
      expect(updatedLead.convertedContactId, 'CON-NEW');
      expect(updatedLead.convertedOpportunityId, 'OPP-NEW');

      final instance = await h.readInstance(bpfId);
      expect(instance!['currentStageId'], 'opportunity');
      expect(instance['linkedRecordIds'], {'opportunityId': 'OPP-NEW'});
    });
  });

  group('createQuoteFromOpportunity', () {
    test('creates a quote tied to the opportunity and advances to '
        'quote with quoteId linked', () async {
      final opp = buildTestOpportunity(id: 'OPP-1', accountId: 'ACC-1');
      final bpfId = await seedBpfInstance(h.db,
          bpfTypeId: 'lead_to_cash',
          currentStageId: 'opportunity',
          linkedRecordIds: {'opportunityId': 'OPP-1'});

      when(() => h.crm.createQuote(any())).thenAnswer((_) async => 'QT-NEW');

      final quoteId =
          await h.orchestrator.createQuoteFromOpportunity(opp, bpfId);

      expect(quoteId, 'QT-NEW');
      final createdQuote =
          verify(() => h.crm.createQuote(captureAny())).captured.single
              as Quote;
      expect(createdQuote.opportunityId, 'OPP-1');
      expect(createdQuote.accountId, 'ACC-1');
      expect(createdQuote.status, 'Draft');

      final instance = await h.readInstance(bpfId);
      expect(instance!['currentStageId'], 'quote');
      expect(instance['linkedRecordIds'], {
        'opportunityId': 'OPP-1',
        'quoteId': 'QT-NEW',
      });
    });
  });

  group('createProjectFromQuote', () {
    test('creates a project, marks the quote Accepted, and advances to '
        'project_execution with projectId linked', () async {
      final quote = buildTestQuote(id: 'QT-1', accountId: 'ACC-1');
      final bpfId = await seedBpfInstance(h.db,
          bpfTypeId: 'lead_to_cash',
          currentStageId: 'quote',
          linkedRecordIds: {'quoteId': 'QT-1'});

      when(() => h.projectService.createProject(any()))
          .thenAnswer((_) async => 'PRJ-NEW');
      when(() => h.crm.updateQuote(any())).thenAnswer((_) async {});

      final projectId =
          await h.orchestrator.createProjectFromQuote(quote, bpfId);

      expect(projectId, 'PRJ-NEW');

      final createdProject =
          verify(() => h.projectService.createProject(captureAny()))
              .captured
              .single as Project;
      expect(createdProject.accountId, 'ACC-1');
      // Regression guard for the bug this fix addresses (see
      // docs/testing/TEST_BACKLOG.md T2-BPFORCHESTRATOR): the project must
      // carry real stages, or the project detail screen has nothing to
      // render and no project_lifecycle BPF instance gets auto-started.
      expect(createdProject.stages, isNotEmpty);
      expect(createdProject.stages.map((s) => s.id),
          containsAll(['stage_0', 'stage_1', 'stage_2', 'stage_3', 'stage_4', 'stage_5']));

      final acceptedQuote =
          verify(() => h.crm.updateQuote(captureAny())).captured.single
              as Quote;
      expect(acceptedQuote.status, 'Accepted');
      expect(acceptedQuote.id, 'QT-1');

      final instance = await h.readInstance(bpfId);
      expect(instance!['currentStageId'], 'project_execution');
      expect(instance['linkedRecordIds']['projectId'], projectId);
    });
  });

  group('createInvoiceFromProject', () {
    test('creates an AR invoice for the project and advances to '
        'invoice with invoiceId linked', () async {
      final project = buildTestProject(id: 'PRJ-1', accountId: 'ACC-1');
      final bpfId = await seedBpfInstance(h.db,
          bpfTypeId: 'lead_to_cash',
          currentStageId: 'project_execution',
          linkedRecordIds: {'projectId': 'PRJ-1'});

      when(() => h.finance.createInvoice(any())).thenAnswer((_) async {});

      final invoiceId =
          await h.orchestrator.createInvoiceFromProject(project, bpfId);

      final createdInvoice =
          verify(() => h.finance.createInvoice(captureAny())).captured.single
              as Invoice;
      expect(createdInvoice.customerId, 'ACC-1');
      expect(createdInvoice.invoiceType, 'AR');
      expect(createdInvoice.id, invoiceId);

      final instance = await h.readInstance(bpfId);
      expect(instance!['currentStageId'], 'invoice');
      expect(instance['linkedRecordIds']['invoiceId'], invoiceId);
    });
  });
}
