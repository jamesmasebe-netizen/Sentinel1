# projects — Module Journey Doc

**Path:** `lib/features/projects/`  |  **Compartment:** Project Operations  |  **README.md exists:** yes (`lib/features/projects/README.md` — brief agent-facing manifest; flags `project_details_screen.dart` as "extremely large" and directs agents to its `widgets/` subdirectory instead. This doc is the fuller human-facing companion, not a replacement, and follows that same guidance — individual tab/widget files were read directly rather than the (247-line, actually not that large) screen shell itself)
**Last verified against:** 2026-07-27

## 1. Product Understanding

`projects` is Sentinel1's largest Project Operations module (50 files, 8 screens) and implements the **Project Concept to Close** BPF's namesake domain: project lifecycle, WBS/Gantt scheduling, resource allocation (personnel/contractors/equipment), the SHEQ Safety File & Resource Audit subprocess (viewer side), time & expense logging, cost/schedule performance tracking, and a revenue-recognition ledger UI.

**Foundational finding, confirmed by reading code, that shapes everything below: the module contains two entirely separate, non-interoperating "Project" implementations.**
1. **The live system** — `models/project_models.dart`'s `Project` (SHEQ-integrated: embedded `stages`/`tasks`, `safetyFileScore`, `overallRiskLevel`, `totalNcrs`), `providers/project_providers.dart`, `ProjectService`, feeding the actually-routed `project_dashboard_screen.dart` and `project_details_screen.dart` (plural — confirmed at `router.dart:257-268` as the screens behind `/projects` and `/projects/:id`). Firestore path: `tenants/{tenantId}/projects/{id}` (via the `tenantCollection()` extension).
2. **An orphaned parallel system** — `models/pmo_models.dart` (field-for-field identical to `docs/schema_pmo.md`'s `projects`/`wbs`/`time_entries`/`expenses`/`actuals` schema), `services/pmo_service.dart` (`PmoService`), `providers/pmo_providers.dart`, consumed only by `screens/project_detail_screen.dart` (**singular** — confirmed via repo-wide grep to have **zero** references from `router.dart` or any other screen; dead code), `screens/wbs_task_detail_screen.dart` (reachable only from that same dead screen), and three unused forms (`pmo_project_form.dart`, `pmo_wbs_task_form.dart`, `pmo_time_entry_form.dart` — confirmed zero references anywhere outside their own files). That's 7 of the module's 50 files (14%) forming a self-contained island with no UI entry point.

Why this matters is detailed in §3 and §5: `PmoService` has a path bug that makes it write **outside tenant scope entirely**, and it's the service `BpfOrchestrator.createProjectFromQuote()` (the Lead-to-Cash handoff) actually calls.

**In scope:** project lifecycle/WBS/Gantt, resource allocation, safety-file-audit viewing, time & expense logging, cost/schedule (CPI/SPI) tracking, revenue-recognition ledger UI.
**Out of scope:** creating risk assessments/permits/incidents themselves (`risk`/`safety` — this module only links to and displays them), contractor compliance document review itself (`contractors`).
**IA placement:** Project Operations compartment (8-compartment taxonomy). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `projects` | Entry screen(s) |
|---|---|---|---|
| [Project & Risk Manager](_shared_personas_and_bpfs.md#persona-project-risk-manager) (primary) | Project Execution: Create PMO Project → Define WBS → Assign Subcontractors → Initiate Contractor Safety File Request | `new_project_dialog_content.dart` (create) → `custom_gantt_chart/gantt_add_task_dialog.dart` (WBS/tasks) → `assign_contractor_dialog.dart` (contractors) → `ohs_file_content.dart` (safety file view) | `project_dashboard_screen.dart`, `project_details_screen.dart` |
| Project & Risk Manager | Resource Management: Approve Time Entries → Approve Expense Reports → Trigger Client Invoice Generation | `timesheet_entry_screen.dart` (Time — **not real, see §7**), `expense_entry_screen.dart`/`expense_form_dialog.dart` (Expense — real), `revenue_recognition_screen.dart` (Invoice/billing view — **not real, see §7**) | `project_operations_hub_screen.dart` |
| [Executive/C-Suite](_shared_personas_and_bpfs.md#persona-executive) (secondary) | Strategic Oversight (partial) | Portfolio KPIs, PRINCE2 domain overview | `project_dashboard_screen.dart` (`dashboard_kpis.dart`, `dashboard_prince2_overview.dart`) |

## 3. BPF Participation
| BPF | Stage(s) this module implements (narrative) | Code reference |
|---|---|---|
| [Project Concept to Close](_shared_personas_and_bpfs.md#bpf-project-concept-to-close) (namesake) | Project Initiation → WBS Definition → Resource Allocation → Safety File & Resource Audit subprocess → QR Passport Issuance → On-Site Execution → Time & Expense Logging → Client Billing → Project Close | `lib/core/bpf/project_lifecycle_bpf.dart` (4 generic stages: concept/planning/execution/closure, `expectedRecordType: 'project'`) |
| [Lead to Cash](_shared_personas_and_bpfs.md#bpf-lead-to-cash) | Project Auto-Creation (downstream target of a Won Opportunity/accepted Quote) | `lib/core/bpf/bpf_orchestrator.dart`'s `createProjectFromQuote()` |

**Project Concept to Close — confirmed ribbon-only, independently verified.** Grepped `bpf_orchestrator.dart` directly for the stage-definition IDs `concept`/`planning`/`execution`/`closure`: zero matches. No orchestrator method references this BPF's stages at all — confirming the shared doc's finding firsthand rather than by citation. `BpfRibbonWidget(bpfTypeId: 'project_lifecycle', ...)` **is** confirmed rendered — inside `widgets/project_tabs/overview_tab.dart` (the Overview tab of the live, routed `ProjectDetailsScreen`), so the ribbon is visible in the actual product, not just in the dead PMO screen (which also renders a `BpfRibbonWidget`, but wired to `lead_to_cash_bpf.dart` instead — a second, apparently mismatched BPF reference inside dead code, not worth over-weighting since that screen is unreachable). Nothing advances the ribbon automatically; it can only ever show its initial/default stage.

**Important nuance the shared doc's framing doesn't fully capture: the module is not actually missing stage-gating logic — it built its own, separate from the BPF engine.** `Project.stages` (a `List<ProjectStage>` embedded directly in the project document, `project_models.dart`) is a **real**, independently-implemented 6-stage PRINCE2 workflow (`Starting Up a Project`, `Initiating a Project`, `Controlling a Stage`, `Managing Stage Boundaries`, `Managing Product Delivery`, `Closing a Project` — hardcoded as `_defaultStages` in `new_project_dialog_content.dart` and applied to every new project). `widgets/project_tabs/workflow_tab.dart` renders this list and lets a manager approve each stage; `ProjectService.approveStage()` (`project_providers.dart`) enforces a genuine compliance lock — stages flagged `requiresSafetyClearance: true` are rejected with a thrown exception unless `safetyFileScore >= 75` **and** `totalNcrs == 0`, and a rejected approval calls `triggerSafetyActionItem()` to write an urgent `actionItems` doc. This is real, substantive logic — it just runs entirely outside the shared `bpf_instances`/`BpfOrchestrator` machinery the rest of the doc set evaluates. Net effect: the *shared BPF ribbon* for this flow is decorative, but the *module's own* stage-gate is not.

**Lead to Cash's `createProjectFromQuote()` — real code, but its write target is unreachable, which the shared doc's "genuinely-wired cross-module touchpoint" framing doesn't capture.** The method is real (not a stub/comment like the other four BPFs): it constructs a `pmo_models.dart` `Project` and calls `pmoService.createProject(project)`, then `bpfService.advanceStage()`. But `PmoService`'s constructor is handed a `DocumentReference` (`tenants/{tenantId}` doc, from `tenantDocProvider`) and then does `_tenantDoc.firestore.collection('projects')` — calling `.firestore` on a `DocumentReference` returns the **root** `FirebaseFirestore` instance, discarding the tenant path entirely. Contrast with the correct pattern used elsewhere in this same module (`ProjectService`, `project_providers.dart`) and in `operations`' `ActionTrackerService`/`InventoryService`, which call `.collection()` **directly on** the tenant `DocumentReference` (or use the `tenantCollection(tenantId, ...)` extension) to get `tenants/{tenantId}/{collection}`. So:
- `PmoService.createProject()` writes to **root-level** `/projects/{id}`, `/projects/{id}/wbs/{taskId}`, `/time_entries/{id}`, `/expenses/{id}`, `/actuals/{id}` — not `tenants/{tenantId}/...` anything.
- `firestore.rules` only grants access under `match /tenants/{tenantId} { match /projects/{projectId} {...} }`. A root-level `/projects/{id}` document isn't matched by that block or even by the tenant-scoped catch-all (§7's other findings) — it falls to the file's **final** rule, `match /{document=**} { allow read, write: if false; }`, an unconditional deny.
- Even hypothetically bypassing rules, the live `projectsProvider`/`projectProvider` (`project_providers.dart`) only stream `tenants/{tenantId}/projects` — they would never see a project `PmoService` created.
- The only Dart code that ever reads `PmoService`'s output is the dead `project_detail_screen.dart`/`wbs_task_detail_screen.dart` pair from §1.

So the single cross-module BPF touchpoint this module owns is real, non-stub *code*, but — verified by reading `PmoService`, the tenant-scoping extension, and `firestore.rules` together — it targets a Firestore location that is simultaneously rules-rejected and invisible to every routed screen in the module.

## 4. Screens & UI Elements Inventory
| Screen | Route or entry point | Purpose / wiring |
|---|---|---|
| `project_dashboard_screen.dart` | `/projects` | Portfolio list + KPIs (`dashboard_kpis.dart`, `dashboard_prince2_overview.dart`); real, `projectsProvider`-backed |
| `project_details_screen.dart` | `/projects/:id` | **The live detail screen** — 6-tab shell (Overview/Workflow/Timeline & Tasks/Safety & Compliance/Resources/Cost & Budget, last gated to lead-or-admin); each tab is its own file under `widgets/project_tabs/` |
| `project_detail_screen.dart` | **Unreachable — dead code** | Singular-named duplicate; 4-tab PMO-backed detail screen (Overview/WBS Tasks/Time Entries/Expenses); zero references from `router.dart` or any other file (§1, §3) |
| `project_operations_hub_screen.dart` | `/projects-ops` | Project picker + 4 action tiles (Gantt Chart, Timesheet Entry, Expense Entry, Revenue Recognition). **Uses raw `Navigator.push`/`MaterialPageRoute` for all three in-module tiles** — an AGENTS.md §1 "Deep Sub-Navigation" violation (should be `UIUtils.showSideSheet`) |
| `revenue_recognition_screen.dart` | `/revenue-recognition` | 930-line ASC 606 ledger UI. **Confirmed 100% hardcoded** — see §7 |
| `timesheet_entry_screen.dart` | Pushed from the hub (no route) | Log-hours form. **Confirmed banned-stub** — see §7 |
| `expense_entry_screen.dart` | Pushed from the hub (no route) | Real: writes via `projectServiceProvider.addExpense()` |
| `wbs_task_detail_screen.dart` | Pushed only from the dead `project_detail_screen.dart` | PMO-island WBS task detail; unreachable in practice (§1) |

`project_details_screen.dart`'s 6 tabs (all real Riverpod/Firestore-backed unless noted): `overview_tab.dart` (incl. `BpfRibbonWidget`, edit dialogs), `workflow_tab.dart` (PRINCE2 stage approval, §3), `timeline_tab.dart` (thin wrapper around `CustomGanttChart`), `safety_tab.dart` (via `safety_compliance_data_fetcher.dart` — **has a live bug**, §7), `resources_tab.dart` (sub-tabs: `ContractorsTab`, personnel, equipment — all real), `financials_tab.dart` (CPI/SPI + expense list, real).

## 5. Backend & Database

**Live models — `models/project_models.dart`:**
| Model | Key fields | Collection |
|---|---|---|
| `Project` | tenantId, propertyId, name, category, startDate, targetEndDate, budget, actualSpend, projectLead/fallbackContact, allocatedEmployeeIds/ContractorIds/AssetIds, overallRiskLevel, safetyFileScore, totalNcrs, status, `stages: List<ProjectStage>`, `tasks: List<ProjectTask>` | `tenants/{tenantId}/projects` |
| `ProjectStage` | stageName, order, status, approvedBy/At, requiresSafetyClearance | embedded in `Project.stages` |
| `ProjectTask` | title, startDate/endDate, progress, assignedTo, riskLevel, isMilestone, parentId, taskType | embedded in `Project.tasks` |
| `ProjectNCR` | projectId, description, severity, status, reportedDate | (model exists; no confirmed write path found in this pass) |
| `ProjectExpense` | projectId, description, amount, category, loggedAt, loggedBy | `tenants/{tenantId}/expenses` |

**Orphaned PMO models — `models/pmo_models.dart`** (mirrors `docs/schema_pmo.md` almost exactly): `Project` (clientId, contractId, projectManagerId, `budget: BudgetModel`, revenueRecognitionMethod), `WbsTask`, `TimeEntry`, `Expense`, `Actual` — all root-level collections per §3.

**Firestore rules check:** `tenants/{tenantId}/projects` is explicitly declared (`firestore.rules`: managers CRUD, all tenant members read) — the live system is covered. Root-level `/projects`, `/time_entries`, `/expenses`, `/actuals` (the PMO island's actual write targets) are covered by **nothing** — not even the tenant-scoped catch-all, since they aren't nested under `tenants/{tenantId}` at all; they hit the file's final global `allow read, write: if false`. Two further naming drifts observed from this module's own code (detailed in §7): `dynamic_risk_assessments`/`strategic_risks` (read by `safety_tab.dart` and `gantt_task_editor_sheet.dart`) and `safetyFileSubmissions` (read by `ohs_file_content.dart`/`contractor_card.dart`, camelCase) are absent from `firestore.rules` even though a same-meaning, differently-cased collection (`safety_file_submissions`) *is* declared.

**Cloud Functions:** `revenue_recognition_screen.dart` has **zero** references to `revRecEngine`, `httpsCallable`, or `FirebaseFunctions` anywhere in its 930 lines — confirmed by direct grep of the file. It is not merely "not calling the function," it never attempts to; see §7.

**Providers — `providers/project_providers.dart`:** `projectsCollectionProvider`, `projectsProvider` (StreamProvider, live), `projectProvider.family` (live), `projectExpensesProvider.family`, `projectRiskLevelProvider.family` (pure computed, not DB-backed), `projectServiceProvider` → `ProjectService` (correct tenant-scoping, human-readable `PRJ-XXX` ID generator via counter transaction — follows AGENTS.md's ID rule correctly), plus a family of subcollection streams: `projectContractorsProvider`, `projectIncidentsProvider`, `projectCapasProvider`, `projectDependenciesProvider`, `projectLinkedRisksProvider`, `projectLinkedNcrsProvider`, `projectLinkedIncidentsProvider`, `projectLinkedCapasProvider` (all real, all reading `projects/{id}/{subcollection}` — though several of these subcollections have no confirmed writer, see §8). **`providers/pmo_providers.dart`:** 4 more `StreamProvider`s, all PMO-island-only (§1).

## 6. Cross-Module Links
- **Lead to Cash → projects**: `createProjectFromQuote()` — real code, unreachable write target (§3).
- **risk**: `safety_tab.dart` and `custom_gantt_chart/gantt_task_editor_sheet.dart` both read a project-linked risk's detail by trying 3 collections in sequence — `risk_assessments` (HIRA), `dynamic_risk_assessments` (DRA), `strategic_risks` — directly confirming from the `projects` side the same 3-collection split documented independently in `risk.md`. `gantt_task_editor_sheet.dart` also writes to `taskLinkedRisks` when a Gantt task is linked to a risk.
- **safety**: `IncidentReportForm` and `PermitToWorkScreen` opened as side-sheets from the project quick-allocate menu; `SafetyTab` displays permits filtered by `riskAssessmentId`.
- **contractors**: `ContractorsTab`/`ContractorCard`/`OHSFileContent` — real, reads `contractors` and `safetyFileSubmissions`/`findings` — this is the live implementation of the Safety File & Resource Audit subprocess's *viewing* side (status/score/findings display); no code in this module *writes* a safety file submission (that's `contractors`' side, out of scope here).
- **people**: `EmployeeSelector` (stage approver picker in `workflow_tab.dart`, project lead/fallback picker in `new_project_dialog_content.dart`), `employeesProvider` (`resources_tab.dart`'s personnel allocation).
- **equipment**: `equipmentListProvider` (`resources_tab.dart`'s equipment allocation, filters out `'Locked Out'` items).
- **operations**: `ProjectDashboardScreen` is embedded directly (as a side-sheet) inside `operations`' own hub grid (`operations_hub_modules.dart`) — a real, if slightly unusual, cross-module UI embed (see `operations.md` §6).
- **AppEventBus:** zero usage anywhere in `lib/features/projects/` (confirmed by grep for both `AppEventBus` and `.fire(`) — no event fires on project creation, stage approval, or stage-clearance failure, despite `triggerSafetyActionItem()` being exactly the kind of cross-module side effect AGENTS.md §5 describes the bus for.

## 7. Known Gaps

### Rules-vs-code gaps
- `dynamic_risk_assessments` and `strategic_risks` (read by `safety_tab.dart` via `safety_compliance_data_fetcher.dart`, and by `gantt_task_editor_sheet.dart`) are undeclared in `firestore.rules`; reads still succeed via the tenant-scoped catch-all, but this module never writes to them so the catch-all's `allow write: if false` isn't exercised from here (the write-side impact belongs to `risk.md`).
- `safetyFileSubmissions` (camelCase — read by `ohs_file_content.dart` and `contractor_card.dart`) vs the rules-declared `safety_file_submissions` (snake_case): same drift pattern the reusable context flagged for `risk`, independently confirmed here in a different module. Read-only impact from this module's side (catch-all permits tenant reads regardless of name).
- The PMO island's root-level collections (`/projects`, `/time_entries`, `/expenses`, `/actuals`) are **not reachable by any rule in the file, including the catch-all** — see §3/§5. This is a stricter failure mode than the usual "falls to catch-all" pattern documented elsewhere in this doc set.
- `BaseIncident` (AGENTS.md §5, absent repo-wide per the [shared doc](_shared_personas_and_bpfs.md#related-rules-vs-code-gap-applicable-wherever-relevant-below)): not directly applicable to this module's own models, noted only because `projectIncidentsProvider`/`projectLinkedIncidentsProvider` surface incident data owned by `safety`.

### DB-to-UI alignment audit
`new_project_dialog_content.dart` vs `Project` model:
| Field | Status | Note |
|---|---|---|
| `propertyId` | **Missing** | Hardcoded to the literal string `'default-property'` at creation (line 104); the model field exists and the README describes it as "Linked Property," but the create form exposes no control for it at all — every project gets the same placeholder value |
| `projectLead` / `fallbackContact` | Correct | Both use `EmployeeSelector` |
| `allocatedContractorIds` | Correct | `SearchableStringMultiSelect` |
| `allocatedAssetIds` | Correct | `EquipmentMultiSelector` (filters to non-locked-out equipment) |
| `stages` | Correct (by design) | Not a form field — every new project is seeded with the same hardcoded 6-stage PRINCE2 template (`_defaultStages`), which is a deliberate business rule, not an omission |

### Other
- **`revenue_recognition_screen.dart` is entirely hardcoded mock data**, not a partially-wired Cloud Function integration as the module's assignment brief suspected. The file's own section headers say so: `// ─── Mock Data Models ───` and `// ─── Mock Journal Entries ───`. Five `_JournalEntry` records are `const`-declared in the file; the only live `StateProvider` (`_ledgerFilterProvider`) filters that static list client-side. No `projectId` parameter, no Firestore read of any kind, no reference to `revRecEngine`, `revenue_schedules`, or `finance_journals` anywhere in the file. This is a more complete AGENTS.md §2 "No Hardcoded Data" violation than a merely-unwired button — the entire screen, including its numbers, is fabricated.
- **`timesheet_entry_screen.dart` is a confirmed banned-stub** (AGENTS.md §3): `_submit()` has no Firestore call, no provider, no service reference of any kind — its own code comment reads `// Simulate timesheet submission`. It shows a raw `ScaffoldMessenger.showSnackBar` (also an AGENTS.md §1 violation — should be `UIUtils.showToast`) and pops the screen. The BPF narrative's "Time & Expense Logging" step is therefore only half-real: Expense is a genuine write path, Time is not.
- **Live bug: `safety_compliance_data_fetcher.dart` hardcodes an empty-string tenant ID.** All five of its queries (`risk_assessments`, `dynamic_risk_assessments`, `strategic_risks`, `permits`, `actionItems`) call `fs.tenantCollection('', ...)` — literally passing `''` instead of the real tenant ID (contrast with `gantt_task_editor_sheet.dart`, which correctly reads `ref.read(currentTenantIdProvider)` for the identical lookup). Since `tenantCollection()` resolves to `collection('tenants').doc(tenantId)...`, this targets `tenants/''/...` — not any real tenant. **Practical effect: the "Safety & Compliance Metrics" tab's Risk Assessments / Permits / Action Items sections cannot ever show real data for any tenant**, regardless of what's actually in the database.
- **The PMO island (§1) is 7 of the module's 50 files with no UI entry point** — `pmo_service.dart`, `pmo_providers.dart`, `project_detail_screen.dart`, `wbs_task_detail_screen.dart`, `pmo_project_form.dart`, `pmo_wbs_task_form.dart`, `pmo_time_entry_form.dart`. Its only live caller is the Lead-to-Cash orchestrator (§3).
- **Navigation-rule violations**: `project_operations_hub_screen.dart` uses `Navigator.push`/`MaterialPageRoute` for its Gantt/Timesheet/Expense tiles instead of `UIUtils.showSideSheet` (AGENTS.md §1).
- **IA/taxonomy conflict**: see [_shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Was the PMO island (`pmo_*`) an earlier implementation later superseded by `project_models.dart`'s richer SHEQ-integrated `Project`, with the orchestrator's `createProjectFromQuote()` simply never migrated to match? The field shapes (flat `budget: double` vs nested `BudgetModel`, `projectLead` vs `projectManagerId`, `targetEndDate` vs `endDate`) suggest the live model evolved away from the PMO one rather than the reverse.
- Should `createProjectFromQuote()` be repointed at `ProjectService.createProject()` (the live path) to actually make the Lead-to-Cash → Projects handoff functional, or is `docs/schema_pmo.md`'s schema the intended long-term direction, with `project_models.dart` the thing to migrate away from?
- Is `revenue_recognition_screen.dart` meant to be backed by `revRecEngine` (which exists and watches `project_milestones`, per the reusable context) plus a real `revenue_schedules` subcollection, or was it always intended as a static design mock that hasn't been wired yet?
- Is `ProjectNCR` (model exists) actually created anywhere in the app, or is `Project.totalNcrs` maintained by some other mechanism entirely (manual field update, Cloud Function) not found in this pass?
- Should `timesheet_entry_screen.dart` be wired to a real `TimeEntry`-equivalent write against the live (not PMO) data model, given `expense_entry_screen.dart` already demonstrates the pattern to follow?
