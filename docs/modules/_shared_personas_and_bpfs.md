# Shared Reference: Personas, Business Process Flows & IA Note

**This is the single source of truth for personas and cross-module journeys, referenced by every doc in `docs/modules/`. Do not restate persona profiles or BPF stage sequences inside a per-module doc — link here instead** (e.g. `See [_shared_personas_and_bpfs.md#persona-hr-safety-officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer)`).

## Provenance

The 13 personas and 6 BPFs below were originally drafted in an earlier Google Antigravity/Gemini agent session working on this same repo, in a document titled *"Comprehensive Enterprise Platform Roadmap."* That document was never committed to this repo — it only survived inside Antigravity's own internal session history (`~/.gemini/antigravity/brain/677bf103-9e2e-4532-a24f-a4bb77f1a614/`, which is itself a git-backed working directory). It was recovered on 2026-07-27 via `git log -S"Personas and User Journeys" -- implementation_plan.md` inside that session's history, followed by `git show <commit>^:implementation_plan.md` to retrieve the full pre-truncation text. Nothing below is invented — it is the recovered original content, lightly reorganized for citation, cross-checked against the current codebase (see "Implementation status" per BPF).

## IA Taxonomy Note (unresolved conflict — documented, not resolved)

Three different information-architecture narratives exist for this app across its own docs:

1. **"4-Hub Command Center"** (root `README.md`): Home / Safety & Risk / People & Health / Operations & Assets.
2. **"7-Pillar Business OS"** (`docs/dynamics_365_masterplan.md`): Finance, Supply Chain Management, Human Resources, Project Operations, Sales, Customer Service, Field Service.
3. **"8-Compartment" taxonomy** (recovered roadmap, Phase 1): Finance, Supply Chain Management, Human Resources, Project Operations, Sales, Customer Service, Field Service, System Administration.

The `docs/modules/` doc set (this file and all 28 module docs) adopts **taxonomy #3 (8-compartment)** as its organizing spine, because it is the most granular of the three and is the origin of the persona set below. This is a documentation-consistency choice only — **it does not resolve which IA is the product's actual current direction**; that remains an open product decision. Every module doc carries a one-line pointer back to this note rather than re-litigating it.

One deliberate tension worth surfacing explicitly: the 8-compartment taxonomy buckets 7 SHEQ-domain modules (`safety`, `health`, `training`, `workers_comp`, `compliance`, `environment`, plus `people`) under **"Human Resources,"** and the primary persona for most of them is named "The HR & Safety Officer." Given Sentinel1's origin as a SHEQ (Safety/Health/Environment/Quality) platform, SHEQ arguably deserves to be treated as a peer pillar to HR rather than a subfunction of it. This doc set does not silently smooth that over — it inherits the recovered taxonomy's wording as-is and flags the tension here, once.

---

## Personas

<a id="persona-hr-safety-officer"></a>
### 1. The HR & Safety Officer
**Module focus:** Human Resources (people, safety, health, training, workers_comp, compliance, environment)
**Key journeys (cross-module):**
- *Talent Acquisition & Onboarding*: Review Job Application (Public) → Send Invite → Create Employee Profile → Generate Competency Passport → Allocate Mandatory Course.
- *Contractor Safety Compliance (deep-linked)*: Review Contractor Profile (Project Ops) → Send Safety File Request → Receive & Review Uploaded Safety File → Approve Safety File → Generate & Issue Contractor Personnel Safety Passport (QR code).
- *Incident Management*: Receive Incident Report → Log Safety Hazard → Trigger CAPA (Corrective Action) → Log Workers Comp Claim.
- *Occupational Health*: Log Baseline Medical → Record First Aid Incident → Log Workplace Hygiene Audit.
- *Safety Compliance*: Issue Permit to Work → Issue PPE → Register Compliance Document → Host Toolbox Talk → Conduct BBS (Behavior-Based Safety) Observation.

<a id="persona-scm-facilities-manager"></a>
### 2. The Supply Chain & Facilities Manager
**Module focus:** Supply Chain Management (supply_chain, property, equipment, contractors)
**Key journeys (cross-module):**
- *Procurement & Inventory*: Generate Purchase Order → Approve Transfer Order → Update Inventory Item → Auto-generate AP Invoice (Finance).
- *Asset Lifecycle*: Register Equipment/Asset → Track Maintenance Schedule.
- *Environmental Control*: Log Hazardous Waste → Record Spill Incident → Monitor Environmental Footprint → Link to Corporate Compliance Report.

<a id="persona-project-risk-manager"></a>
### 3. The Project & Risk Manager
**Module focus:** Project Operations (projects, risk, operations)
**Key journeys (cross-module):**
- *Project Execution*: Create PMO Project → Define WBS (Work Breakdown Structure) → Assign Subcontractors (Add Contractor) → Initiate Contractor Safety File Request.
- *Resource Management*: Approve Time Entries → Approve Expense Reports → Trigger Client Invoice Generation (Finance).
- *Risk Management*: Conduct Dynamic Risk Assessment (DRA) for site tasks → Perform formal HIRA → Implement Bowtie Mitigations → Link to Strategic Risk Register.

<a id="persona-finance-controller"></a>
### 4. The Finance Controller
**Module focus:** Finance (finance, billing)
**Key journeys (cross-module):**
- *Ledger Management*: Create General Ledger Journal Entry → Process Payroll Integrations (HR & Payroll).
- *Billing & AP/AR*: Receive Timesheet Data (Project Ops) → Generate & Send Invoice → Track Software Subscriptions → Reconcile Accounts.

<a id="persona-sales-cs-agent"></a>
### 5. The Sales & Customer Success Agent
**Module focus:** Sales, Customer Service (crm, customer_service)
**Key journeys (cross-module):**
- *Lead to Cash (CRM)*: Capture Lead → Nurture to Opportunity → Generate & Send Quote → Auto-create Project upon Won Opportunity (Project Ops).
- *Support Resolution*: Receive Customer Ticket → Dispatch Field Agent → Publish Knowledge Base Article for self-service.

<a id="persona-field-service-responder"></a>
### 6. The Field Service & Emergency Responder
**Module focus:** Field Service (field_service, emergency)
**Key journeys (cross-module):**
- *Field Dispatch*: Receive Work Order → Optimize Dispatcher Route → Service Customer Asset → Complete Action Form.
- *Emergency Preparedness*: Log Emergency Drill → Inspect Emergency Equipment.

<a id="persona-executive"></a>
### 7. The Executive / C-Suite (Decision Maker)
**Module focus:** System Administration, Analytics (dashboard, executive, ai_tools, copilot)
**Key journeys (cross-module):**
- *Strategic Oversight*: View BI Dashboards → Drill down via deep links into specific Projects or High-Risk CAPAs → Monitor Corporate Strategic Risks → Review Corporate Compliance and Integration Configs.

<a id="persona-employee-self-service"></a>
### 8. The Employee (Self-Service)
**Module focus:** Cross-functional
**Key journeys (cross-module):**
- *Daily Operations*: Submit Leave Request → Submit Expense Form → Submit Time Entry → Sign off on Toolbox Talk → Conduct peer BBS Observation → View personal Competency Passport (via QR scan).

<a id="persona-external-contractor"></a>
### 9. The External Contractor / Vendor
**Module focus:** Project Operations, Human Resources (contractors, public)
**Key journeys (cross-module):**
- *Site Access & Compliance*: Receive Safety File Request → Upload Compliance Docs/Safety File → Acknowledge Site Rules → Receive digital Contractor Safety Passport (QR code) for gate access → Request Permit to Work.

<a id="persona-qc-compliance-manager"></a>
### 10. The Quality Control (QC) & Compliance Manager
**Module focus:** Compliance, Operations, Human Resources (compliance, safety, training)
**Key journeys (cross-module):**
- *Quality Assurance*: Track ISO Certifications → Issue Non-Conformance Reports (NCRs via CAPA Form) → Conduct Internal System Audits → Link findings to Employee Training records.

<a id="persona-environmental-officer"></a>
### 11. The Environmental & Sustainability Officer
**Module focus:** Environment, Supply Chain (environment, supply_chain)
**Key journeys (cross-module):**
- *ESG Management*: Monitor Carbon Footprint/Emissions Data → Conduct Waste Disposal Audits (cross-referenced with Supply Chain inventory) → Manage Spill Response Plans → Generate ESG Reporting Data.

<a id="persona-it-systems-admin"></a>
### 12. The IT / Systems Administrator
**Module focus:** System Administration (auth, settings, ai_tools, copilot, notifications)
**Key journeys (cross-module):**
- *System Management*: Configure 3rd Party Integrations → Manage User Role Permissions → Monitor Background Sync Queues → Train AI Chatbot parameters.

<a id="persona-security-gate-access"></a>
### 13. The Security / Gate Access Personnel
**Module focus:** Operations, Project Operations (property, contractors)
**Key journeys (cross-module):**
- *Site Access Control*: Scan Employee/Contractor QR Code → View Real-Time Compliance Status → Verify Approved Scope of Work → Verify active Project/Job Allocation → Verify Linked Permits to Work (PTWs) → Grant/Deny Site Access.

---

## Business Process Flows (BPFs)

These are macro-journeys spanning multiple modules and personas — implemented in code as a central BPF Engine (`lib/core/bpf/`): `bpf_models.dart` (`BpfInstance` — current stage + `linkedRecordIds`), `bpf_service.dart` (`BpfService.advanceStage()` — writes `currentStageId`/`linkedRecordIds` onto a `tenants/{tenantId}/bpf_instances/{id}` document; this is *pure stage tracking*, it has no side effects of its own), `bpf_orchestrator.dart` (a Riverpod service meant to perform the actual cross-module business logic *and then* call `advanceStage`), `bpf_ribbon_widget.dart` (the visual stepper injected into relevant screens), plus one stage-definition file per flow (each defining only 4 generic stages tagged with a single `expectedRecordType` — e.g. `employee`, `incident`, `equipment`, `project` — not the rich per-module stage detail the original roadmap narrative describes).

**Important correction (verified 2026-07-27 by reading `bpf_orchestrator.dart` directly, not just confirming file existence):** all 6 stage-definition files exist, but **only Lead to Cash is genuinely implemented end-to-end**. The other 5 range from partial to explicitly stubbed:

| BPF | Implementation depth | Evidence |
|---|---|---|
| Lead to Cash | **Fully wired** | `convertLeadToOpportunity()` → `createQuoteFromOpportunity()` → `createProjectFromQuote()` → `createInvoiceFromProject()` each perform real Firestore writes via `CrmService`/`PmoService`/`FinanceService` *and* call `advanceStage()` |
| Procure to Pay | **Partially wired** | Only the final step, `createInvoiceFromPurchaseOrder()` (PO → AP Invoice via `FinanceService`), exists in the orchestrator. Earlier stages (PO creation, SHEQ compliance verification, goods receipt) have no orchestrator method — if they exist at all, they're unwired UI/service calls with no stage-advance hook |
| Asset Lifecycle | **Stubbed** | `deployEquipment()`'s own code comment: *"We would normally update the equipment document here via EquipmentService but... it's just handled directly in firestore in UI for now, we'll just advance the BPF stage."* Advances the tracking record only; no real equipment-status side effect from this method |
| Issue to Resolution | **Stubbed** | `createCapaFromIncident()`'s own code comment: *"Generates a mock CAPA ID... In a real implementation we would write to safetyService.createCapa(...)"* Advances the tracking record only; no real CAPA is created by this method |
| Hire to Retire | **Stubbed** | `completeOnboarding()`'s own code comment: *"In a real implementation we would update EmployeeProfile to 'Active' via HR service."* Advances the tracking record only; `EmployeeProfile.employmentStatus` is not actually updated by this method |
| Project Concept to Close | **Ribbon-only, no orchestrator wiring** | No `bpf_orchestrator.dart` method references `project_lifecycle`'s stage IDs (`concept`/`planning`/`execution`/`closure`) at all. `bpf_ribbon_widget.dart` is confirmed injected into `ProjectDetailsScreen` (per the recovered plan's Sprint D task list), so the visual stepper renders, but nothing in the orchestrator advances it automatically |

**Why this matters for the module docs below:** each module doc's "BPF Participation" section states the *narrative* stage participation (preserved from the recovered roadmap, per the user's instruction not to drop any previously-defined journey content) but must also carry this implementation-depth finding in its Known Gaps section wherever relevant — narrated journeys and actual wired behavior are not the same thing here, and conflating them would misrepresent the app's real state.

<a id="bpf-lead-to-cash"></a>
### 1. Lead to Cash
*(Sales → Project Ops → SHEQ → Finance)*
**Flow:** Lead (CRM) → Opportunity → Quote → Project Auto-Creation → Project Execution (Time & Expense Logging + Baseline SHEQ Assessment (HIRA/DRA) + SHEQ Compliance Monitoring) → Client Invoice Generation.
**Personas:** Sales Agent, Project Manager, Safety Officer, Finance Controller.
**Modules:** crm, customer_service, finance, billing, projects.
**Code:** `lib/core/bpf/lead_to_cash_bpf.dart`.

<a id="bpf-procure-to-pay"></a>
### 2. Procure to Pay
*(Supply Chain → SHEQ → Finance)*
**Flow:** Purchase Order Creation → Supplier SHEQ Compliance Verification (Safety Officer vets supplier certifications/safety records) → Supplier Fulfillment → Inventory Update (Goods Receipt) → AP Invoice Auto-Generation → Payment Ledger Entry.
**Personas:** Supply Chain Manager, Safety Officer, Finance Controller.
**Modules:** supply_chain, finance, contractors, property.
**Code:** `lib/core/bpf/procure_to_pay_bpf.dart`.

<a id="bpf-hire-to-retire"></a>
### 3. Hire to Retire
*(Human Resources → SHEQ)*
**Flow:** Job Application → Candidate Invite → Employee Profile Creation → Baseline Medical & Training Allocation → Leave/Payroll Tracking → Offboarding.
**Personas:** HR Manager, Safety Officer, Employee.
**Modules:** people, training, health, workers_comp, compliance.
**Code:** `lib/core/bpf/hire_to_retire_bpf.dart`.

<a id="bpf-issue-to-resolution"></a>
### 4. Issue to Resolution / Incident Lifecycle
*(Customer Service/EHS → Field Service/Safety)*
**Flow:** Customer Ticket or Safety Incident Report → Action Form/Hazard Log → Work Order → Field Dispatch or Mitigation → Resolution & Close.
**Personas:** Field Service Responder, Safety Officer, Customer Success Agent.
**Modules:** safety, risk, customer_service, field_service, emergency.
**Code:** `lib/core/bpf/issue_to_resolution_bpf.dart`.

<a id="bpf-project-concept-to-close"></a>
### 5. Project Concept to Close
*(Project Ops → SHEQ → HR/Contractors → Finance)*
**Flow:** Project Initiation → WBS Definition → Comprehensive Resource Allocation (internal employees, external contractors, physical assets/vehicles/tools) → **Safety File & Resource Audit subprocess** (Project Manager initiates Safety File Request → Contractors upload compliance docs → SHEQ Officer audits the entire project ecosystem — human, asset, and contractor compliance files — providing per-document feedback with traceable findings statuses (Pending/Resolved/Rejected) → Unified Project Compliance Report → Approval) → QR Passport Issuance → On-Site Execution (Security scans QR to verify PTW & Scope) → Time & Expense Logging → Client Billing → Project Close.
**Personas:** Project Manager, External Contractor, Safety Officer, Security Personnel, Finance Controller.
**Modules:** projects, operations, risk, finance, contractors.
**Code:** `lib/core/bpf/project_lifecycle_bpf.dart`.

<a id="bpf-asset-lifecycle"></a>
### 6. Asset Lifecycle Management
*(Supply Chain → SHEQ → Field Service → Environment)*
**Flow:** Asset Registration (Equipment/Property) → Asset SHEQ Risk Assessment → Scheduled Maintenance (Work Order) → Dispatch Route → On-Site Field Tech SHEQ Check (LOTO, Permit to Work verification) → Emergency Management (if asset fails critically, trigger Emergency Drill/Response protocol) → Decommissioning (Waste/Spill Log if hazardous).
**Personas:** Facilities Manager, Field Technician, SHEQ Manager.
**Modules:** equipment, property, supply_chain, field_service.
**Code:** `lib/core/bpf/asset_lifecycle_bpf.dart`.

**Modules with zero BPF participation, narratively or in code** (a correct finding, not a gap): `auth`, `settings`, `dashboard`, `ai_tools`, `copilot`, `executive`, `notifications`, `public`.

**Modules named in the original narrative's persona/BPF journeys but with no dedicated stage or `expectedRecordType` in the actual 4-stage code definitions** (`health`, `training`, `workers_comp`, `compliance` under Hire to Retire; `environment` under Asset Lifecycle/Procure to Pay; `risk`, `customer_service`, `field_service`, `emergency` under Issue to Resolution; `operations`, `contractors` under Project Concept to Close): these modules are documented as *narrative* BPF participants in their own module docs (preserving the recovered content per the user's instruction), each with a note that the code-level `BpfStageDefinition`s only carry a single `expectedRecordType` (`employee`/`incident`/`equipment`/`project`) and don't reference these modules directly — narrated participation, not confirmed code-level wiring.

---

## Database-to-UI Alignment Audit Methodology

Recovered from the original roadmap's "Phase 3" and applied per-module in each doc's **Known Gaps → DB-to-UI alignment** section:

1. Identify the module's primary Firestore-backed model(s): shared (`lib/core/models/`) or per-feature (`lib/features/<name>/models/`).
2. Identify the corresponding create/edit form file(s) (`*_form.dart` / `*_form_sheet.dart`) in that module.
3. For each model field, classify against the form:
   - **Correct** — present, right widget type (lookup/dropdown for foreign-key-style fields like `managerEmployeeId`, date picker for dates, etc.)
   - **Wrong widget** — e.g. a foreign-key field rendered as free text instead of a lookup (the exact pattern the original audit named for `employee_profile_form.dart` and `permit_form_sheet.dart`)
   - **Missing** — field exists on the model, absent from the form
   - **Orphan** — form field with no backing model field
4. Only non-"Correct" rows are listed — this is a findings list, not an exhaustive field-by-field matrix, per module.

## Related rules-vs-code gap, applicable wherever relevant below
`BaseIncident` is mandated by `.agents/AGENTS.md` §5 ("Polymorphism for Shared Concepts... e.g. `BaseIncident` for Safety and Environmental incidents") but **does not exist anywhere in the codebase** (confirmed via repo-wide search, 2026-07-27). Every module doc whose domain conceptually extends an incident (`safety`, `risk`, `health`, `workers_comp`, `emergency`, `field_service`) flags this once in its own Known Gaps section rather than re-explaining it.
