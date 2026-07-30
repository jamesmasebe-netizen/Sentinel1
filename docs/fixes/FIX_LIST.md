# Sentinel1 Fix List

Implementation-ready index of every Critical/High/Medium finding from `docs/modules/_known_gaps_rollup.md`. Each item is meant to be picked up on its own by a Claude Code session with no other context loaded than the item itself and, where noted, its linked source doc.

**109 items total**: Wave 0 (3 systemic fixes) → Wave 1/Critical (33 items) → Wave 2/High (35 items) → Wave 3/Medium (38 items). This is larger than an earlier ~41-item estimate because drafting each item at file-level precision split several rollup summary rows into multiple atomic fixes (e.g. one "FK-as-textfield" rollup row became a distinct item per file).

**How to use this file:**
- Work waves in order (0 → 1 → 2 → 3). Within a wave, items with no `Depends on` can be done in any order or in parallel across separate sessions/branches.
- Every item has: Severity, Module(s)/File(s), Depends on, Source link, Current behavior, Required fix, Verification. Read "Current behavior" and "Required fix" fully before starting — don't start from the title alone.
- IDs are namespaced by owner-batch, not strict document order: `F-001`–`F-019` are cross-cutting items (span multiple modules, drafted with full-rollup visibility to avoid duplicating module-local items); `F-1xx` HR/SHEQ, `F-2xx` SCM, `F-3xx` Project Ops + Finance, `F-4xx` Sales/CS/Field Service, `F-5xx` System Admin. Document order follows wave/severity, not ID order.
- "Verification" steps assume a runnable dev environment (`flutter run`) and, where a Cloud Function changed, `firebase emulators:start` or a deploy to a non-prod project. None of these have been executed as part of drafting this list — they're the acceptance bar for whoever implements the fix.
- **Status marker:** `### [DONE] F-xxx: ...` means the fix has been implemented and verified (compiles clean, behavior spot-checked, or otherwise confirmed against the "Verification" section). `### F-xxx: ...` with no marker means outstanding. Items that were resolved via an explicit product/architecture decision rather than a straightforward fix carry a dated **Decision (resolved YYYY-MM-DD)** or **Resolved YYYY-MM-DD** note inline in the body, above or in place of "Required fix," explaining the reasoning.

---

## Wave 0 — Systemic Fixes (do these first)

### [DONE] F-001: Add explicit Firestore rules for all undeclared collections
**Severity:** Critical
**Module(s) / File(s):** `firestore.rules` (single file)
**Depends on:** none
**Source:** `docs/modules/_known_gaps_rollup.md` §1.1 (pattern summary); per-module §5 sections have each module's exact collection list

**Current behavior:** `firestore.rules` explicitly declares rules for 24 collections (`employees`, `projects`, `incidents`, `permits`, `training_records`, `equipment`, `loto_events`, `work_orders` [+`tasks` subcollection], `contractors`, `contractor_documents`, `compliance_prescreens`, `findings`, `bpf_instances`, `invoices`, `journal_entries`, `leads`, `opportunities`, `quotes`, `accounts`, `risk_assessments`, `hazards`, `purchase_orders`, `inventory`, `safety_file_submissions`, `contractor_safety_files`) plus a catch-all at line 220 (`match /{collection}/{docId} { allow read: if belongsToTenant(tenantId); allow write: if false; }`). Every collection the app actually writes to that isn't in that explicit list falls to the catch-all and **cannot be written to by any client, ever, as deployed** (reads still work via the catch-all). Confirmed independently across the whole app; the real collections currently blocked are:
- `safety`: `capas`, `bbs_observations`, `ppe_compliance`, `ppe_inventory`
- `health`: `medical_records`, `hygiene_surveys`, `first_aid_log`, `first_aid_logs` (both spellings — see F-1xx cluster item for the naming-drift fix, but both need rules regardless)
- `training`: `courses`, `enrollments`, `training_enrollments`, `toolbox_talks`
- `workers_comp`: `coida_claims`
- `compliance`: `compliance_docs`, `compliance_documents` (both spellings — same note as health)
- `environment`: `waste_manifests`, `environmental_spills`, `esg_metrics`
- `operations`: `actionItems`, `capas` (dup of safety's), `bbs_observations` (dup), `dynamic_risk_assessments`, `inventory_items`, `warehouses`, `integrations`
- `risk`: `dynamic_risk_assessments` (dup), `strategic_risks`, `bowtie_analyses`
- `finance`: `fin_ap_invoices`, `fin_ar_invoices`, `fin_journal_headers`, `fin_chart_of_accounts`, `fin_tax_codes`, `budgetPlans`, `costCenters`
- `customer_service`: all `cs_*` collections (`cs_tickets`, `cs_customers`, `cs_assets`, etc. — enumerate from `customer_service_service.dart` at implementation time)
- `field_service`: `route_plans`, `customer_assets`, `iot_devices` (`work_orders` itself is already declared)
- `property`: `properties`, `property_projects`, `property_utilities`, `legal_appointments`, `property_leases`, `property_assets` (**all 6** of this module's collections — this one blocks a real, correctly-built, reachable form, unlike most instances of this pattern which block unreachable/mocked screens)
- `public`: `job_requisitions` (read side — also needs an auth exemption, see the note below), `job_applications` (write side, currently blocked for every caller including authenticated ones)
- `emergency`: `emergency_drills`, `emergency_equipment`
- `supply_chain`: `inventory_items` (the collection code actually uses — `inventory` is declared but unused), `warehouses` (dup of operations'), `assets`, `sales_orders`, `transfer_orders`, `mrp_suggestions`, `warehouseBinLocations`, `vendorPerformanceMetrics`, `boms`
- `people`: `payroll_ledgers`, `compensation_plans`, `performance_reviews` — **these need stricter, role-scoped rules, not just the standard tenant-catch-all shape**, since they're compensation/payroll data (e.g. `allow read: if belongsToTenant(tenantId) && (isManager() || request.auth.uid == resource.data.employeeId)`, not a blanket tenant-wide read)
- `notifications`: `notifications`, `fcm_tokens`
- `billing`: `subscription` (moot until F-4xx's billing fixes land, but declare it now so the rule exists when the write path is fixed)
- `crm`: `contacts`, `campaigns`, `customerJourneys`, `activities`, `deals` (leads/opportunities/quotes/accounts already declared)

**Required fix:** For each collection above, add a `match /{collectionName}/{docId} { ... }` block inside `match /tenants/{tenantId} { ... }` (following the existing pattern already used for the 24 declared collections — `allow read: if belongsToTenant(tenantId);` plus role-gated writes using the existing `isManager()`/`isSheqOfficer()`/`isAdmin()` helpers, matching the access level each module doc's persona mapping implies). Use tighter, per-field-scoped rules for `payroll_ledgers`/`compensation_plans`/`performance_reviews` as noted above. For `public`'s `job_requisitions`/`job_applications`, these need to work for **unauthenticated** users — add a separate top-level `match` block outside `/tenants/{tenantId}` (parallel to the existing `match /users/{userId}` block) with `allow read: if true` (or scoped to `status == 'open'`) for requisitions and `allow create: if true` for applications, since the public careers portal is meant to be reachable pre-login (see F-4xx's `public` module item — this rules fix is necessary but not sufficient on its own to make `public` reachable).

**Verification:** `firebase deploy --only firestore:rules --project <non-prod-project>` (or `firebase emulators:start --only firestore` and point the app at the emulator), then exercise one create flow per newly-declared collection (e.g., submit the training "Allocate Course" form, submit a Property, submit an Emergency Drill) and confirm the write succeeds instead of throwing a `PERMISSION_DENIED` error. Run `firebase firestore:rules:test` or equivalent if a rules test harness exists; if not, this manual per-collection sweep is the acceptance bar.

---

### [DONE] F-002: Fix hardcoded empty-string tenant ID in 3 files
**Severity:** Critical
**Module(s) / File(s):** `lib/features/training/providers/training_providers.dart` (lines 10, 26, 71), `lib/features/projects/**/safety_compliance_data_fetcher.dart` (lines 15, 26, 38, 53, 68), `lib/features/public/widgets/job_application_form.dart` (`_submit()`)
**Depends on:** none (independent of F-001, though both need to land before these read/write paths work end-to-end)
**Source:** `docs/modules/_known_gaps_rollup.md` §1.2; `docs/modules/training.md`, `docs/modules/projects.md`, `docs/modules/public.md` §7

**Current behavior:** Three files call `tenantCollection("", <name>)` / `.tenantCollection('', <name>)` with a **literal empty string** instead of the real tenant ID, confirmed by direct grep:
```
training_providers.dart:10:  return firestore.tenantCollection("", 'courses').snapshots().map((snap) {
training_providers.dart:26:      .tenantCollection("", 'enrollments')
training_providers.dart:71:        .tenantCollection("", 'courses')
safety_compliance_data_fetcher.dart:15:        await fs.tenantCollection('', 'risk_assessments').doc(id).get();
safety_compliance_data_fetcher.dart:26:        await fs.tenantCollection('', 'dynamic_risk_assessments').doc(id).get();
safety_compliance_data_fetcher.dart:38:        await fs.tenantCollection('', 'strategic_risks').doc(id).get();
safety_compliance_data_fetcher.dart:53:            .tenantCollection('', 'permits')
safety_compliance_data_fetcher.dart:68:          .tenantCollection('', 'actionItems')
```
Each targets `tenants/''/...` — a tenant that doesn't exist — so these reads/writes can never return real data for any tenant. `training_providers.dart`'s sibling functions and `safety_compliance_data_fetcher.dart`'s own `gantt_task_editor_sheet.dart` counterpart both correctly use `ref.read(currentTenantIdProvider)` for the identical lookup, confirming this is a copy-paste-shaped bug, not an intentional design. `job_application_form.dart._submit()` has the same shape but doesn't attempt tenant resolution at all (no `?? ""` fallback even) — the most direct instance of the three.

**Required fix:** In each of the 3 files, replace the literal `""`/`''` argument with the real tenant ID the surrounding code (or module) already has access to — `ref.read(currentTenantIdProvider)` (the pattern used correctly elsewhere in the same files/modules) for `training_providers.dart` and `safety_compliance_data_fetcher.dart`. For `job_application_form.dart`, this module has no authenticated tenant context (see F-001's public-rules note and F-4xx's `public` module item) — resolve what "tenant" a public job application should be scoped to as part of that broader public-reachability fix, not by inventing a tenant ID here in isolation.

**Verification:** For `training_providers.dart`: open the Manager Training Dashboard and Course Player screens with seeded data present under a real tenant, confirm courses/enrollments now load instead of showing empty/loading state indefinitely. For `safety_compliance_data_fetcher.dart`: open a Project's "Safety & Compliance Metrics" tab, confirm Risk Assessments/Permits/Action Items sections populate with real counts instead of always showing zero. For `job_application_form.dart`: resolve alongside F-4xx's `public` fix; verify together.

---

### [DONE] F-003: Wire `setCustomUserClaims` so `firestore.rules` has a real claims producer
**Severity:** Critical
**Module(s) / File(s):** New Cloud Function in `firebase/functions/src/` (the actively-developed codebase); `lib/core/services/auth_service.dart` (client-side token refresh)
**Depends on:** none — this should land alongside or before F-001, since F-001's new rules are just as dependent on working claims as the 24 already-declared collections are
**Source:** `docs/modules/auth.md` §7; `firestore.rules` itself (read directly during this planning pass)

**Current behavior:** Every single rule in `firestore.rules` — not just the newly-added ones from F-001, but all 24 already-declared collections and the tenant-root `match /tenants/{tenantId}` block itself — depends on `belongsToTenant(tenantId)`, which calls `getUserTenantId()` (`request.auth.token.tenantId`) and, for writes, `isManager()`/`isAdmin()`/`isSheqOfficer()`, which call `getUserRole()` (`request.auth.token.role`). Both are Firebase Auth **custom claims**. Grepping both Cloud Functions codebases (`firebase/functions/src/`, `functions/src/`) for `setCustomUserClaims` returns zero matches — nothing in the deployed backend ever sets these claims on any user's token. Separately, `auth_service.dart`'s `_getOrCreateProfile()` (lines ~143–160) writes `role: 'employee'` and `tenantId: FirebaseConfig.defaultSiteId` onto the `users/{uid}` Firestore *document* on first login — so the intended role/tenant values do exist and are computed correctly, they just never make it onto the Auth token the rules actually check. **If `firestore.rules` as committed is the ruleset actually deployed to the live Firebase project, this means no authenticated user can satisfy `belongsToTenant()` for anything, and every tenant-scoped read/write in the entire app would fail with `PERMISSION_DENIED`** — this is a more foundational blocker than any single collection being undeclared (F-001 fixes are necessary but insufficient without this). Whether this rules file is in fact the live deployed one wasn't verified as part of the documentation pass (out of scope for a local-repo audit) — treat this fix as required regardless, since the committed rules assume it.

**Required fix:** Add a Cloud Function that sets custom claims from the `users/{uid}` document's `role`/`tenantId` fields, and call it at the right moment in the auth lifecycle. Recommended shape: a 2nd-gen Firestore trigger (`onDocumentWritten` on `users/{userId}`, in a new `firebase/functions/src/authClaims.ts`) that calls `admin.auth().setCustomUserClaims(userId, { role: data.role, tenantId: data.tenantId })` whenever the profile document is created or its `role`/`tenantId` fields change — this piggybacks on `_getOrCreateProfile()`'s existing write with no client-side change needed for the *setting* side. On the client side, custom claims only appear in a token after it's refreshed — add `await FirebaseAuth.instance.currentUser?.getIdToken(true)` immediately after `_getOrCreateProfile()` returns in `auth_service.dart`'s three call sites (lines ~53, 75, 91), so a freshly-created or freshly-claimed user doesn't have to sign out/in again before their first Firestore call succeeds.

**Verification:** Sign up a brand-new user through the real (non-bypass) login flow against the emulator or a non-prod project, then immediately attempt a tenant-scoped read (e.g., load the People hub). Confirm it succeeds without a permission error, and confirm via `firebase auth:export` or the Firebase console that the new user's custom claims include `role` and `tenantId` matching their `users/{uid}` document. Regression-check an existing user whose `role` changes (e.g., promoted to `manager`) — confirm the trigger fires again and their claims update without manual intervention.

---

## Wave 1 — Critical

### Cross-cutting

### [DONE] F-004: Wire `BpfOrchestrator` into the Lead-to-Cash flow — "Convert Lead"/"Generate Quote"/"Accept Quote" actions are inert placeholders
**Severity:** Critical
**Module(s) / File(s):** `lib/features/crm/screens/lead_detail_screen.dart`, `opportunity_detail_screen.dart`, `quote_detail_screen.dart`, `lib/core/bpf/bpf_orchestrator.dart`
**Depends on:** F-301 (must fix root-level write bug before orchestration works), F-008 (must have BPF orchestration logic correctly structured)
**Source:** `docs/modules/crm.md` §3/§7 (Lead-to-Cash BPF implementation-depth finding); `docs/modules/_known_gaps_rollup.md` §1

**Current behavior:** "Convert Lead" and "Generate Quote" buttons were placeholders — no `BpfOrchestrator` logic fired from any of the three CRM detail screens, so the BPF ribbon never advanced and no downstream Project/Invoice record was created from a won deal.

**Required fix:** Wire the `BpfOrchestrator` methods into `lead_detail_screen.dart`, `opportunity_detail_screen.dart`, and `quote_detail_screen.dart` via `bpfOrchestratorProvider`, following the logic in `bpf_orchestrator.dart`. On the Quote screen's "Accept"/"Won" action, wire `createProjectFromQuote()` — only after F-301 is fixed. On the resulting Project (or wherever client billing is triggered), wire `createInvoiceFromProject()`. Each call site should handle the returned ID (navigate to the newly-created record) and surface errors via `UIUtils.showToast`, not a raw exception.

**Verification:** Starting from a fresh Lead in a dev/emulator tenant, walk the full flow through the UI: convert to Opportunity → generate Quote → accept Quote → confirm a real `Project` document appears in `tenants/{tenantId}/projects` (not the root-level path — this is exactly what F-301 fixes) → confirm the `BpfRibbonWidget` on each screen visually advances to the next stage after each action, not just on manual refresh.

---

### [DONE] F-005: Implement Asset Lifecycle's equipment deployment (currently a stage-tracking stub)
**Severity:** Critical
**Module(s) / File(s):** `lib/core/bpf/bpf_orchestrator.dart` (`deployEquipment()`), `lib/features/equipment/services/` (wherever `EquipmentService` lives)
**Depends on:** F-001, F-003
**Source:** `docs/modules/_known_gaps_rollup.md` §1 implementation-depth table; `docs/modules/equipment.md` §3/§7

**Current behavior:** `BpfOrchestrator.deployEquipment(equipment, projectId, bpfId)`'s own code comment states: *"We would normally update the equipment document here via EquipmentService but... it's just handled directly in firestore in UI for now, we'll just advance the BPF stage."* It calls `advanceStage()` only — no equipment document is updated, so the BPF tracking record and the equipment's real status can drift apart.

**Required fix:** Inside `deployEquipment()`, before (or alongside) the `advanceStage()` call, add a real `EquipmentService` call that sets the deployed equipment's status/location/assigned-project fields to reflect deployment (mirror whatever "handled directly in firestore in UI" currently does today — find that existing inline UI logic first via `grep -rn "assignedToId\|equipmentName" lib/features/equipment/` and move/reuse it here rather than duplicating a second implementation, then have the UI call this orchestrator method instead of writing to Firestore directly). Also see `equipment.md`'s separate DB-to-UI finding that the status enum used elsewhere in this module can't represent `'Locked Out'` — align on the enum's true value set as part of this change if it's touched.

**Resolved 2026-07-30:** `EquipmentService.deployEquipment()` now exists and is called from `BpfOrchestrator.deployEquipment()`, which updates `status`/`assignedToId` before advancing the BPF stage. The equipment-registration form's "Assigned To / Inspector" field feeds an *employee* ID through this whole chain, not a project ID — the parameters were renamed `projectId` → `assignedToId` throughout (`equipment_service.dart`, `bpf_orchestrator.dart`) to match, including the BPF instance's `linkedRecordIds` key (`'projectId'` → `'employeeId'`). Also fixed in the same pass: `equipment_asset_tab.dart`'s `startBpf()` call used `recordType: 'equipmentId'`, which didn't match `AssetDetailScreen`'s `BpfRibbonWidget(recordType: 'equipment', ...)` lookup — the asset_lifecycle ribbon could never find its instance; corrected to `'equipment'` on both sides. `'Locked Out'` is not part of this enum's dropdown — see F-215's own resolved decision for why it's a gated action, not a status value.

**Verification:** Deploy an equipment item to a project through the UI; confirm both the `bpf_instances` tracking record advances *and* the equipment document's own status/assignment fields update, visible on the Equipment detail screen without a manual refresh trick.

---

### [DONE] F-006: Implement Issue-to-Resolution's CAPA creation (currently a mock-ID stub)
**Severity:** Critical
**Module(s) / File(s):** `lib/core/bpf/bpf_orchestrator.dart` (`createCapaFromIncident()`), `lib/features/safety/` (wherever CAPA creation logic/service lives — check `capa_form.dart` first)
**Depends on:** F-001, F-003
**Source:** `docs/modules/_known_gaps_rollup.md` §1 implementation-depth table; `docs/modules/safety.md` §3/§7

**Current behavior:** `BpfOrchestrator.createCapaFromIncident(incidentId, bpfId)`'s own code comment: *"Generates a mock CAPA ID and links it... In a real implementation we would write to safetyService.createCapa(...)."* It generates a fake ID string and calls `advanceStage()` — no real `capas` document is ever created by this method (the real CAPA-creation path, if any, is `capa_form.dart`'s free-text `rca` field writing directly to the separate `capas` collection, disconnected from this orchestrator entirely).

**Required fix:** Replace the mock-ID generation with a real call into whatever service `capa_form.dart` uses to write `capas` documents (or extract that write into a shared `SafetyService.createCapa()` if it doesn't already exist as a reusable method), passing through the real incident context. Wire this method to be called from wherever "escalate incident to CAPA" should happen in the UI (likely `incident_report_form.dart` or an incident detail screen action — confirm the intended trigger point against the Issue-to-Resolution journey in `_shared_personas_and_bpfs.md`).

**Verification:** From a real Incident record, trigger the CAPA-escalation action; confirm a real document appears in `capas` with fields matching what `capa_form.dart` would produce (not a placeholder), and confirm the BPF ribbon advances to the CAPA stage.

---

### [DONE] F-007: Implement Hire-to-Retire's onboarding completion (currently a stage-only stub)
**Severity:** Critical
**Module(s) / File(s):** `lib/core/bpf/bpf_orchestrator.dart` (`completeOnboarding()`), `lib/features/people/screens/employee_360_profile_screen.dart`
**Depends on:** F-001, F-003
**Source:** `docs/modules/_known_gaps_rollup.md` §1 implementation-depth table; `docs/modules/people.md` §3/§7

**Current behavior:** `BpfOrchestrator.completeOnboarding` was a stub — it advanced the BPF stage but didn't actually trigger `HrService` to update the employee's `employmentStatus`. The profile screen also relied on a hardcoded "Complete Onboarding" check against `emp['status']` rather than a real action.

**Required fix:** Add a real `HrService` call to `BpfOrchestrator.completeOnboarding(employeeId)`. Wire this method to be called from wherever onboarding is marked complete in the UI (`employee_hub_screen.dart`/`employee_360_profile_screen.dart`).

**Verification:** Mark an employee as onboarding complete; verify `employmentStatus` goes to `Active` in Firestore, and the BPF ribbon advances alongside it.

---

### [DONE] F-008: Design and implement stage-advancement for Project-Concept-to-Close and the remaining Procure-to-Pay stages
**Severity:** Critical
**Module(s) / File(s):** `lib/core/bpf/` (`bpf_orchestrator.dart`, `project_lifecycle_bpf.dart`), `lib/features/projects/providers/project_providers.dart` (`ProjectService.createProject()`/`approveStage()`)
**Depends on:** BPF data models (complete)
**Source:** `docs/modules/_known_gaps_rollup.md` §1, Phase 1 priority

**Current behavior:** Projects and POs advance their own status strings, leaving the BPF ribbon as a dead UI element that doesn't sync with actual data.

**Required fix:**
- For Projects: add a call to `BpfService.advanceStage()` (or a thin orchestrator wrapper) at the same point(s) `ProjectService.approveStage()` already commits a stage transition, so the BPF instance always mirrors the real state — never advance the BPF independently of `approveStage()`.
- For Procure-to-Pay: add orchestrator methods for PO creation (`startBpf` + initial stage) and goods receipt (`advanceStage` to reflect inventory update), calling through to the real `ScmService` writes that already exist for these actions in the UI, the same pattern as F-005/F-006/F-007.

**Decision (resolved 2026-07-28, per PMI/PMBOK stage-gate governance principles):** the BPF instance must be a passive mirror of the project's own authoritative `stages` field, not an independently-advanced tracker — a single source of truth for "what stage is this project in," with the BPF ribbon as a read-mostly reflection. `approveStage()` is the one legitimate place a project stage transitions; `BpfOrchestrator`/`BpfService` never initiate a transition on their own.

**Resolved 2026-07-30:** `approveStage()`'s `advanceStage()` mirror call was already correctly wired, but two bugs kept it non-functional: (1) no `startBpf()` call existed anywhere for `project_lifecycle`, so no BPF instance was ever created for a project — `approveStage()`'s `bpfQuery` always came back empty and the ribbon rendered as `SizedBox.shrink()`. Fixed by adding a `startBpf('project_lifecycle', project.stages.first.id, 'project', shortId)` call inside `ProjectService.createProject()`. (2) `project_lifecycle_bpf.dart`'s stage definitions used an invented 4-stage vocabulary (`concept`/`planning`/`execution`/`closure`) that didn't match any real `Project.stages[].id` — every project is actually seeded with the 6-stage PRINCE2 lifecycle (`stage_0`…`stage_5`: Starting Up / Initiating / Controlling a Stage / Managing Stage Boundaries / Managing Product Delivery / Closing, per `new_project_dialog_content.dart`'s `_defaultStages`), so `currentStageId` could never match a `BpfStageDefinition.id` even once an instance existed. Fixed by rewriting `project_lifecycle_bpf.dart`'s 4 stages into the real 6 `stage_0`…`stage_5` IDs/titles. The Procure-to-Pay half was already correctly implemented and is unaffected by this fix.

**Verification:** `flutter analyze` shows zero errors. Creating a project triggers `startBpf()` and the ribbon renders immediately at "Starting Up a Project (SU)". Approving a stage in the UI updates both the project document and the `bpf_instances` record synchronously, and the ribbon highlights the correct stage. Creating a PO correctly triggers `startBpf()` for Procure-to-Pay.

---

### [DONE] F-009: Fix `employeeName` never written on create, breaking 3 list/card displays
**Severity:** 1-Critical
**Module/Files:** `features/health/widgets/medical_form.dart`, `features/training/widgets/record_form_sheet.dart`, `features/training/widgets/allocate_course_form.dart`
**Depends on:** none
**Source:** `_known_gaps_rollup.md`
**Current behavior:** Forms only select employeeId. The list views require `employeeName` to display titles, causing them to all read "Unknown Employee". `allocate_course_form` misses `assignedAt`, rendering it invisible in dashboard queries.
**Required fix:** Look up employee names against the `employeesProvider` to write `employeeName`. Ensure `allocate_course_form.dart` writes `assignedAt`.
**Verification:** Forms write `employeeName` correctly, and allocations appear on dashboard.

---

### [DONE] F-010: Fix scheduled Cloud Functions querying flat collections the app never writes to
**Severity:** Critical
**Module(s) / File(s):** `firebase/functions/src/index.ts` (`onIncidentCreated`, `checkPermitExpiry`, `checkCoidaOverdue`, `checkTrainingExpiry`)
**Depends on:** none
**Source:** `docs/modules/safety.md` §7 ("Cloud Function path mismatch")

**Current behavior:** These 4 functions — one Firestore-create trigger and 3 scheduled (`onSchedule`) functions meant to alert on critical incidents, expiring permits, overdue COIDA claims, and expiring training — query/listen on flat, top-level collection paths (e.g. `incidents/{id}`, a top-level `permits` collection). Every collection in this app is written tenant-scoped (`tenants/{tenantId}/incidents/...` per `firestore.rules`' own structure). None of these 4 functions can currently fire against real data, silently — a Firestore trigger on a path that's never written never invokes, and a scheduled function querying an empty flat collection just finds nothing and exits quietly, with no error to signal the mismatch.

**Required fix:** Convert each function's query/trigger path to be tenant-aware. For the `onDocumentCreated` trigger (`onIncidentCreated`), change the trigger path from `incidents/{incidentId}` to `tenants/{tenantId}/incidents/{incidentId}` (2nd-gen triggers support wildcard path segments — the function gains a `tenantId` param from the event context). For the 3 scheduled functions, replace the flat single-collection query with a `collectionGroup()` query (e.g. `db.collectionGroup('permits').where(...)`) so it matches the field across every tenant's subcollection, or if per-tenant iteration is preferable, list `tenants/` documents first and query each tenant's subcollection in a loop.

**Verification:** Deploy to the emulator or a non-prod project; create a real Critical-severity incident under a real tenant and confirm `onIncidentCreated` fires (check function logs). Seed a permit expiring within the alert window under a real tenant, manually invoke the scheduled function (`firebase functions:shell` or the emulator's scheduler trigger), confirm it identifies the permit — repeat for the COIDA and training-expiry functions.

---


### HR/SHEQ Cluster

### [DONE] F-104: Reconcile `first_aid_form.dart`/`first_aid_tab.dart`'s colliding collection names (`first_aid_logs` vs `first_aid_log`)

**Severity:** 1-Critical
**Module(s) / File(s):** `lib/features/health/widgets/first_aid_form.dart` (line 50), `lib/features/health/widgets/first_aid_tab.dart` (line 72)
**Depends on:** none
**Source:** `docs/modules/health.md` §5, §7
**Current behavior:** Form submitted to `first_aid_logs` but tab read from `first_aid_log`.
**Required fix:** Pick one collection name and make both files agree on it.
**Verification:** Forms match and display works properly.

---

### [DONE] F-105: Consolidate or cross-reference the three mutually-unaware "enrollment" collections (`enrollments`, `training_enrollments`, `training_records`)

**Severity:** Critical
**Module(s) / File(s):** `lib/features/training/screens/course_player_screen.dart` (writes `enrollments`), `lib/features/training/widgets/allocate_course_form.dart` (writes `training_enrollments`), `lib/features/training/widgets/record_form_sheet.dart` (writes `training_records`), `lib/features/training/providers/training_providers.dart`, `lib/features/training/screens/manager_training_dashboard.dart`, `lib/features/training/widgets/training_records_tab.dart`, `lib/features/training/widgets/expiry_alerts_tab.dart`, `lib/features/people/screens/training_lms_tab.dart`
**Depends on:** F-001 (all 3 collections need write rules before this is testable end-to-end), F-002 (`training_providers.dart`'s phantom-tenant-ID bug blocks reading `courses`/`enrollments` independent of this item's own scope)
**Source:** `docs/modules/training.md` §5, §7 ("Three-way collection split for 'enrollment'"); `docs/modules/_known_gaps_rollup.md` §2 (Critical severity table)

**Current behavior:** Three separate, mutually-unaware Firestore collections all represent some flavor of "an employee is/was assigned to or completed something," with zero cross-reference between any of them:
| Collection | Written by | Read by |
|---|---|---|
| `enrollments` | `course_player_screen.dart`'s `_markComplete()` — updates an existing enrollment at lines 31-38, or creates a new one at lines 39-51 — self-service LMS completions | `training_providers.dart`'s `enrollmentsProvider` → `my_learning_tab.dart` |
| `training_enrollments` | `allocate_course_form.dart:42` — manager-assigned mandatory course allocations | `manager_training_dashboard.dart:63`; also cross-module by `people`'s `training_lms_tab.dart:47` |
| `training_records` | `record_form_sheet.dart:49` — compliance/certification records | `training_records_tab.dart:56`, `expiry_alerts_tab.dart:24`; also cross-module by `safety`'s `passport_compliance_checker.dart`/`qr_scanner_screen.dart` |

None of the three writers checks whether a matching record already exists in either of the other two collections before writing, and none share a document-ID scheme that would let them be joined after the fact. Concretely: a manager allocating a course via `allocate_course_form.dart` has no way of knowing whether the same employee already completed the same course via `course_player_screen.dart` — different collection, no shared key — and neither flow ever produces a `training_records` compliance entry, so a manager-allocated or self-completed course never shows up as a "certification on file" for expiry-tracking or for `safety`'s passport-compliance checks. This is a genuine architecture/data-model question, not a one-line fix: the three collections currently encode three different real concepts (LMS content-completion, manager assignment/due-date tracking, and formal compliance/certification-with-expiry), and it's plausible they're meant to stay separate but cross-referenced, rather than merged into one.

**Required fix:** This needs a product/data-model decision before implementation, similar in shape to F-017/F-018's cross-cutting "decide first" items: (a) **merge** — collapse to a single collection with a `recordType` discriminator field (`lms_completion`/`manager_allocation`/`compliance_certification`) and migrate all read sites to filter on it; or (b) **cross-reference, keep separate** — add an optional `linkedEnrollmentId`/`linkedRecordId` field so e.g. `allocate_course_form.dart` can check `enrollments` for an existing completion before creating a redundant `training_enrollments` entry, and so completing an allocated course could auto-create (or update) a corresponding `training_records` entry. Given `training_records` already has established downstream consumers outside this module (`safety`'s compliance checker), option (b) is very likely the lower-risk direction — if the implementing session isn't confident which to pick, leave this flagged as an Open Question rather than guessing. At minimum, regardless of which option is chosen, `manager_training_dashboard.dart` should be able to show whether an allocated course was already completed by the assignee, which it currently cannot do at all.

**Verification:** Allocate a course to an employee via `allocate_course_form.dart`, then complete that same course as that employee via `course_player_screen.dart`; confirm the Manager Training Dashboard reflects the completion (status changes from "Assigned" to something indicating completion) instead of showing the allocation as perpetually outstanding. If the chosen option adds a `training_records` linkage, confirm the newly-completed course also surfaces correctly in `training_records_tab.dart`/`expiry_alerts_tab.dart` and in `safety`'s passport compliance check for the same employee.

---

### [DONE] F-108: Collection-name mismatch — `register_doc_form.dart` writes `compliance_documents`, both read tabs query `compliance_docs`

**Severity:** Critical
**Module(s) / File(s):** `lib/features/compliance/widgets/register_doc_form.dart` (line 49), `lib/features/compliance/widgets/register_tab.dart` (line 53), `lib/features/compliance/widgets/expiring_tab.dart` (line 26)
**Depends on:** none
**Source:** `docs/modules/compliance.md` §5, §7 (DB-to-UI alignment audit); `docs/modules/_known_gaps_rollup.md` §2 (Critical severity table)

**Current behavior:** `register_doc_form.dart`'s submit handler writes new documents to `collection: 'compliance_documents'` (line 49). Both of this module's read-side tabs query a **different** collection: `register_tab.dart`'s list stream uses `.tenantCollection(..., 'compliance_docs')` (line 53), and `expiring_tab.dart`'s expiry-filtered stream does the same (`'compliance_docs'`, line 26). Every document registered through this module's own form is therefore invisible in both of this module's own list tabs — nothing written is ever visible anywhere in the module, unconditionally, for every tenant. This supersedes any field-level comparison; the rest of the field names (`title`, `referenceNumber`, `documentType`, `status`, `expiryDate`, `reviewDate`, `ownerId`) are otherwise correctly matched between the form and the read views (`doc_list_item.dart`). `compliance_docs` is the more likely "intended" name — 2 read-side files agree on it against 1 write-side file — making `register_doc_form.dart` the file to fix rather than the two tabs.

**Required fix:** Change `register_doc_form.dart:49`'s `collection: 'compliance_documents'` to `collection: 'compliance_docs'`, matching both read-side tabs. If any real documents already exist under `compliance_documents` in a non-dev environment, migrate them to `compliance_docs` as part of this fix rather than abandoning them. This bug and F-109 (module reachability) are independent of each other — both need fixing before any real user can use this module end-to-end, but neither fix depends on the other, and they can be done in either order or in parallel.

**Verification:** Register a new document through `RegisterDocForm`; confirm it appears immediately in `RegisterTab`'s list (and in `ExpiringTab` if its expiry date is within 90 days) with no query change needed on the read side.

---

### [DONE] F-109: `ComplianceDocsScreen` has zero confirmed entry points anywhere in the app

**Severity:** Critical
**Module(s) / File(s):** `lib/features/compliance/screens/compliance_docs_screen.dart`, `lib/config/router.dart`, `lib/features/dashboard/screens/business_os_launchpad.dart` (line 153)
**Depends on:** none
**Source:** `docs/modules/compliance.md` §4, §7 ("Fully unreachable module"); `docs/modules/_known_gaps_rollup.md` §2 (Critical severity table), §1.7

**Current behavior:** `ComplianceDocsScreen` is never instantiated anywhere in `lib/` outside its own class declaration — confirmed by a repo-wide search for `ComplianceDocsScreen(`, which returns exactly one hit (`compliance_docs_screen.dart:14`, the constructor definition itself), and a second search for any import of `compliance_docs_screen.dart` from outside its own directory, which returns zero results. No `router.dart` route, no `UIUtils.showSideSheet` call, no button or menu item anywhere reaches it. Compounding this, `business_os_launchpad.dart`'s "Compliance" tile is declared with `route: '/compliance'` (`business_os_launchpad.dart:149-154`) and its `onTap` calls `context.go(route)` (line 325) — but `router.dart` defines no `/compliance` path anywhere (confirmed against every `path:` declaration in the file), so tapping the tile hits the global `errorBuilder`'s "Page Not Found" `Scaffold` (`router.dart:64-65`). Of all 6 modules in this HR/SHEQ batch, this is the only one where the **primary** screen itself — not a sub-screen, like `safety`'s orphan QR passport screens (which have a reachable parent hub, unlike this module) — has no confirmed way to reach it at all. Even `training`'s equivalent broken-tile bug (F-106) has a working secondary path via the People Hub; `compliance` has none.

**Required fix:** Add a `/compliance` `GoRoute` in `router.dart` pointing at `ComplianceDocsScreen` — the Launchpad tile already assumes this route exists, so this is the more direct fix than changing the tile itself. This bug is independent of F-108 (the collection-name mismatch): fixing reachability alone does not fix the broken CRUD, and fixing the collection name alone does not make the screen reachable — both are required before this module works for a real user end-to-end.

**Verification:** From the main Business OS Launchpad, tap the "Compliance" tile; confirm it opens `ComplianceDocsScreen`'s 3-tab shell (Register / Expiring / Framework) instead of "Page Not Found."

---

### SCM Cluster

### [DONE] F-201: MRP engine's three-way field-name mismatch for stock quantity (schema doc / Dart model / Cloud Function)
**Severity:** 1-Critical
**Module/Files:** `firebase/functions/src/mrpEngine.ts`
**Depends on:** none
**Source:** `_known_gaps_rollup.md`
**Current behavior:** `mrpEngine.ts` reads `quantityOnHand` but client writes `stock_level`.
**Required fix:** Change `mrpEngine.ts` to read `stock_level`.
**Verification:** MRP properly factors in inventory.

---

### [DONE] F-202: Add a Purchase Order line-items sub-form — a PO can currently only ever be created header-only
**Severity:** Critical
**Module(s) / File(s):** `lib/features/supply_chain/screens/purchase_order_detail_screen.dart` (`_buildLinesTab`); `lib/features/supply_chain/widgets/purchase_order_form.dart`; `lib/features/supply_chain/services/scm_service.dart` (no changes needed — CRUD already exists); `firestore.rules` (new nested rule needed — see Required fix)
**Depends on:** F-001 (`po_lines` writes need explicit rules coverage — see Required fix; this subcollection is not currently declared anywhere in `firestore.rules`, not even nested under the already-declared `purchase_orders` block, so it is a gap F-001's enumerated collection list does not yet cover)
**Source:** `docs/modules/supply_chain.md` §5, §7 (DB-to-UI alignment audit: "PO line items | Missing entirely")

**Current behavior:** No widget anywhere in the module writes to the `po_lines` subcollection. `PurchaseOrderForm` (`purchase_order_form.dart`, 238 lines) only has fields for `PurchaseOrder` header data (`poNumber`, `vendorId`, `warehouseId`, `status`, `orderDate`, `expectedDeliveryDate`, `currency`, `totalAmount`) — no line-item section exists in its `build()` method at all. `PurchaseOrderDetailScreen`'s "PO Lines" tab (`_buildLinesTab`, `purchase_order_detail_screen.dart:182-240`) is read-only display: a `ListView.separated` rendering `PurchaseOrderLine` fields (item, ordered/received quantity, unit price) with no add/edit/delete action anywhere in the method. This is not a missing-backend gap — `ScmService` already has complete, working CRUD for this exact subcollection: `createPurchaseOrderLine`, `updatePurchaseOrderLine`, `deletePurchaseOrderLine`, `getPurchaseOrderLine(s)` (`scm_service.dart:114-146`), operating on `_purchaseOrdersRef.doc(poId).collection('po_lines')` (`scm_service.dart:111-112`), and the `PurchaseOrderLine` model (`scm_models.dart:228-261`, fields `itemId`/`quantityOrdered`/`quantityReceived`/`unitPrice`) is complete. A Purchase Order is largely useless without lines — this is the module's most consequential missing write path, independent of and additional to F-014's separate finding that the detail screen itself has no navigation entry point yet.

**Required fix:** Add a firestore.rules nested rule for the subcollection inside the existing `match /purchase_orders/{poId} { ... }` block (`firestore.rules:193-197`) — e.g. `match /po_lines/{lineId} { allow read: if belongsToTenant(tenantId); allow create, update: if belongsToTenant(tenantId) && isManager(); allow delete: if belongsToTenant(tenantId) && isAdmin(); }`, mirroring `work_orders`' existing `tasks` nested-subcollection pattern (`firestore.rules:95`) as the template — flag this explicitly to whoever implements F-001, since it's a subcollection gap that list doesn't enumerate. Then build a line-item editor: the most natural placement is an "Add Line" action on `PurchaseOrderDetailScreen`'s existing "PO Lines" tab (a FAB or button opening a small form via `UIUtils.showSideSheet`, per AGENTS.md §1) capturing `itemId` (as a proper lookup over `ScmService.streamInventoryItems()`/`getInventoryItems()`, not a plain `TextFormField` — follow the pattern F-011 already prescribes for this exact FK-as-textfield category elsewhere in this module), `quantityOrdered`, and `unitPrice`, then calling `ScmService.createPurchaseOrderLine(poId, line)` on submit with the standard defensive `isLoading`/try-catch pattern. Alternatively, if lines should be entered at PO-creation time rather than added after the fact, extend `PurchaseOrderForm` itself with a dynamic add/remove line-row list submitted in the same transaction as the header — either shape is acceptable, but pick one rather than leaving header-only creation as the only path.

**Verification:** Open a real Purchase Order's detail screen, add 2–3 line items through the new UI, and confirm they appear immediately in the "PO Lines" tab (real-time, no manual refresh) with correct ordered/received quantities and computed subtotals. Inspect Firestore directly and confirm the documents exist under `purchase_orders/{poId}/po_lines/{lineId}` with the rules change deployed and the write succeeding (not silently rejected).

---

### [DONE] F-214: Add the missing `/equipment` route — the module's main screen is disconnected from its launchpad tile
**Severity:** Critical
**Module(s) / File(s):** `lib/config/router.dart`
**Depends on:** none
**Source:** `docs/modules/_known_gaps_rollup.md` §2 (Critical table: "equipment | /equipment has no route anywhere in router.dart — the app's best-built screen (real form, real BPF ribbon) is disconnected from the launchpad tile that's supposed to open it"); `docs/modules/equipment.md` §4, §7, §8

**Current behavior:** `business_os_launchpad.dart`'s "Equipment" tile (`business_os_launchpad.dart:82-87`) sets `route: '/equipment'`. Reading the complete `router.dart` (281 lines, confirmed by `wc -l`) top to bottom, and confirmed by grep for `equip`, there is no `GoRoute` anywhere with `path: '/equipment'`. `router.dart`'s own `errorBuilder` (`router.dart:64-81`) renders a "Page Not Found" / "Route not found: ${state.uri}" screen, so tapping the tile doesn't crash — it lands on this generic error screen instead. `EquipmentManagementScreen` (`equipment_management_screen.dart`) is never imported or constructed anywhere in `lib/` outside its own file (confirmed by grep) — no route, no side-sheet call, no other module's deep link reaches it. This disconnects the module's most complete, best-built screen (a genuinely well-implemented 3-tab shell with a real, defensively-written create form and the app's second real `BpfRibbonWidget` instance, per `equipment.md` §1) from the app's main navigation entirely. As a direct consequence, `/loto-management` — a route that does exist and works — is also practically unreachable in the shipped UI, since its only in-app trigger is an AppBar button inside `EquipmentManagementScreen` (`equipment.md` §4), which never gets a chance to render.

**Required fix:** Add `GoRoute(path: '/equipment', pageBuilder: (c, s) => const NoTransitionPage(child: EquipmentManagementScreen()))` inside the `ShellRoute`'s `routes` list in `router.dart` (alongside the other feature-hub routes — e.g. next to the `/properties` or `/loto-management` entries), and add the corresponding import `import '../features/equipment/screens/equipment_management_screen.dart';` at the top of the file, alongside the existing `loto_management_screen.dart` import (`router.dart:50`).

**Verification:** From the launchpad, tap the "Equipment" tile; confirm it now opens `EquipmentManagementScreen` (Assets/Inspections/Maintenance tabs) instead of the "Page Not Found" screen. From there, tap the AppBar button into LOTO Management and confirm `/loto-management` is now reachable through normal in-app navigation, not just by typing the URL/deep link directly.

---

### [DONE] F-215: Equipment status dropdown is missing the `'Locked Out'` option the rest of the module depends on
**Severity:** Critical
**Module(s) / File(s):** `lib/features/equipment/widgets/equipment_asset_tab.dart`
**Depends on:** none (related to F-005, which fixes `BpfOrchestrator.deployEquipment()`'s stub — but F-005 doesn't touch this dropdown or `lockoutFailedEquipment()` at all, so this is the form-side half of the same broader "equipment status can't reach its own automation-driven state" story, not a strict dependency)
**Source:** `docs/modules/_known_gaps_rollup.md` §3 (positive findings: "equipment's create form — only one gap (a status enum missing 'Locked Out') across 7 fields"); `docs/modules/equipment.md` §5, §7, §8

**Current behavior:** `EquipmentAssetTab`'s inline create form's status `DropdownButtonFormField` (`equipment_asset_tab.dart:245-267`) offers exactly 4 options: `['Operational', 'Under Maintenance', 'Out of Service', 'Decommissioned']` (`equipment_asset_tab.dart:252-257`) — `'Locked Out'` is not one of them. Three other places in this same module actively check for exactly that literal string: `LotoBadge` (`loto_badge.dart:15`: `if (status != 'Locked Out')`), `AssetDetailScreen`'s conditional badge (`asset_detail_screen.dart:103`: `if (asset.status == 'Locked Out')`), and `lockedOutEquipmentProvider`'s underlying query (`loto_automation.dart:90`: `.where('status', isEqualTo: 'Locked Out')`). The only code path that ever writes `status: 'Locked Out'` is `LotoAutomation.lockoutFailedEquipment()` (`loto_automation.dart:20`), which itself has zero call sites anywhere in the app (confirmed by grep) — no UI button anywhere ever locks out an item. Consequently, `lockedOutEquipmentProvider`/`LotoManagementScreen` will show an empty state in the shipped app regardless of real equipment condition — not because nothing is locked out, but because nothing in the running UI can ever produce that state in the first place.

**Decision (resolved 2026-07-29, per ISO 45001 and NEBOSH LOTO/isolation principles): Option (b) — automation/workflow-driven, NOT a manually-selectable dropdown value.** Reasoning:
- **Hierarchy of controls (ISO 45001 Clause 8.1.2):** Lockout-Tagout is an engineering/procedural control that exists specifically to prevent unexpected re-energization during hazardous conditions. Equating it with routine administrative states (`Under Maintenance`, `Out of Service`) in one freely-editable field collapses a safety-critical control into a data-entry choice, which undermines the control itself.
- **Lock–Tag–Try and asymmetric authority for removal (NEBOSH isolation/permit-to-work syllabus; mirrors OSHA 1910.147's "authorized employee" concept):** applying an isolation should be broadly accessible — any employee identifying a hazard should be able to trigger it, matching ISO 45001 Clause 5.4's worker-participation principle — but *removing* one is a distinct, higher-authority action requiring verification that it's actually safe (guards restored, area clear, isolation device physically removed), not just re-selecting "Operational" in the same dropdown used for everything else.
- **Documented information / auditability (ISO 45001 Clauses 7.5, 9.1):** a real lockout event should carry who applied it, why, when, and who verified/authorized its removal — an audit trail, not a mutable field with no history.

**Required fix:** Do not add `'Locked Out'` to `equipment_asset_tab.dart`'s dropdown — keep it to the 4 routine states. Instead: (1) add an "Isolate / Lock Out Equipment" action on `AssetDetailScreen` (pairs naturally with fixing that screen's no-op edit button — see the companion item), open to any authenticated user, requiring a mandatory reason/hazard field, calling `LotoAutomation.lockoutFailedEquipment()` rather than a raw status write; (2) add a separate "Verify & Return to Service" action for removal, gated to `isManager() || isSheqOfficer()` (matching the role pattern already used throughout `firestore.rules`), with a short confirmation checklist (guards restored / area clear / isolation device removed) mirroring NEBOSH's try-out verification step; (3) record who applied/removed the lock and why — reuse whatever audit-logging pattern the app already has for `findings`/`contractor_documents` if one exists, rather than inventing a new one. Group/multi-lock support (several trades each applying their own lock, all of which must clear before release) is standard NEBOSH content for complex isolations but is a v2 enhancement, not required for this fix — don't over-scope it given the app's current single-lock-per-asset data model.

**Verification:** Trigger "Isolate / Lock Out Equipment" from `AssetDetailScreen` with a reason; confirm `LotoBadge`, the detail screen's conditional badge, and `LotoManagementScreen` all correctly reflect the locked-out state. Confirm the manual create/edit dropdown still correctly excludes "Locked Out" as a directly-selectable option. As a non-manager/non-SHEQ user, confirm "Verify & Return to Service" is unavailable or rejected; as a manager, confirm completing it returns the asset to "Operational" and the audit trail records both the lock and the unlock events with who/when/why.

---

### [DONE] F-220: Fix `safetyFileSubmissions`/`safety_file_submissions` collection name typo hiding real safety-file approvals
**Severity:** Critical
**Module(s) / File(s):** `lib/features/contractors/widgets/contractor_projects_sheet.dart`
**Depends on:** none
**Source:** `docs/modules/_known_gaps_rollup.md` §2 (Critical table: "contractors | camelCase/snake_case collection typo (safetyFileSubmissions vs safety_file_submissions) hides real safety-file approvals one screen away"); `docs/modules/contractors.md` §5, §7

**Current behavior:** `ContractorProjectsSheet._fetchProjectsForContractor()` queries `.tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'safetyFileSubmissions')` — camelCase (`contractor_projects_sheet.dart:79-82`). The real collection — written to by the safety-file submission flow, read correctly one screen further into the same drill-down by `SafetyFileSubmissionView` (`safety_file_submission_view.dart:114-118`: `.tenantCollection(..., 'safety_file_submissions')`), and the exact name explicitly declared in `firestore.rules` (`match /safety_file_submissions/{submissionId}`, `firestore.rules:206-210`) — is `safety_file_submissions`, snake_case. Nothing anywhere ever writes to a collection literally named `safetyFileSubmissions` (confirmed by grep), so this query always returns an empty result set. Consequently, every project card `ContractorProjectsSheet` renders (`contractor_projects_sheet.dart:333-459`) permanently shows "Not Submitted" and the summary pills at the top always compute `0` "OHS Approved" (`contractor_projects_sheet.dart:243-276`), regardless of how many real, approved safety-file submissions actually exist for that contractor/project pair — submissions that are visible and correctly rendered one tap further into `SafetyFileSubmissionView`.

**Required fix:** Change `contractor_projects_sheet.dart:81` from `'safetyFileSubmissions'` to `'safety_file_submissions'`, matching `safety_file_submission_view.dart`'s already-correct usage and the rules-declared name exactly.

**Verification:** With a real, `finalized` (approved) safety-file submission seeded for a contractor/project pair, open that contractor's project sheet (`ContractorList` → tap contractor → `ContractorProjectsSheet`) and confirm the project card now shows "OHS Approved" with the real score, and the summary pills correctly count it, instead of unconditionally showing "Not Submitted" / 0 approved.

---

### Project Ops + Finance Cluster

### [DONE] F-301: Fix `PmoService`'s tenant-scoping bug — writes escape to Firestore root instead of `tenants/{tenantId}/...`
**Severity:** Critical
**Module(s) / File(s):** `lib/features/projects/services/pmo_service.dart` (19 of its 27 methods; see Current behavior for the exact split)
**Depends on:** none (self-contained fix to this file's own Firestore path construction — see Required fix for the important *forward* relationship with F-004)
**Source:** `docs/modules/projects.md` §3, §5, §7 (PMO island / Lead-to-Cash sections); `docs/modules/_known_gaps_rollup.md` §2 Critical table (`projects` | "PMO island's root collections aren't reachable by any rule, including the catch-all — stricter failure than the usual pattern")

**Current behavior:** `PmoService`'s constructor (`pmo_service.dart:6-13`) is injected with `_tenantDoc`, the result of `ref.watch(tenantDocProvider)` — a `DocumentReference` whose own doc comment at `lib/core/providers/app_providers.dart:123-124` states: "Resolves the base document reference for the current tenant. Use this provider in all service classes instead of root collection references." In other words, `_tenantDoc` already *is* `tenants/{tenantId}`, correctly scoped, handed to the service ready to use. Despite this, 19 of the file's 27 methods discard that scoping by calling `.firestore` on it first before calling `.collection(...)` — e.g. `createProject()`:
```
17:    await _tenantDoc.firestore
18:        .collection('projects')
19:        .doc(project.projectId)
20:        .set(project.toJson());
```
and `updateProject()`:
```
30:    await _tenantDoc.firestore
31:        .collection('projects')
32:        .doc(project.projectId)
33:        .update(project.toJson());
```
`DocumentReference.firestore` returns the root `FirebaseFirestore` instance the document belongs to, not a scoped handle — so `.firestore.collection('projects')` resolves to the **root-level** `/projects` collection, not `tenants/{tenantId}/projects`. The identical `.firestore.collection(...)` jump recurs in every `create*`/`update*`/`stream*` method for `Project`, `WbsTask`, `TimeEntry`, `Expense`, and `Actual`, plus `WbsTask`'s own `getWbsTask()`/`deleteWbsTask()` — 19 methods in total, writing/reading root-level `/projects/{id}`, `/projects/{id}/wbs/{taskId}`, `/time_entries/{id}`, `/expenses/{id}`, `/actuals/{id}`. The file is internally inconsistent about this: exactly 8 methods — `getProject()` (line 24), `deleteProject()` (line 37), `getTimeEntry()` (line 137), `deleteTimeEntry()` (line 150), `getExpense()` (line 175), `deleteExpense()` (line 188), `getActual()` (line 213), `deleteActual()` (line 226) — call `.collection(...)` **directly on `_tenantDoc`**, with no `.firestore` hop, and are therefore correctly tenant-scoped (e.g. line 24: `await _tenantDoc.collection('projects').doc(projectId).get();`). Every comparable service in this codebase gets this right throughout: `ProjectService` (`lib/features/projects/providers/project_providers.dart:102-140`) uses `_firestore.tenantCollection(_tenantId, 'projects')`, and `operations`' `ActionTrackerService` (`lib/features/operations/services/action_tracker_service.dart:30-31`) uses `_tenantDoc.collection('actionItems')` directly on its own injected tenant doc — the exact same constructor shape `PmoService` has, done correctly.

Two compounding effects, both already flagged independently in `projects.md` but worth restating precisely as one root cause here: (1) `firestore.rules` only grants access under `match /tenants/{tenantId} { match /projects/{projectId} {...} }` — a root-level `/projects/{id}` document isn't matched by that block, nor by the tenant-scoped catch-all (`match /{collection}/{docId}` is itself nested inside `match /tenants/{tenantId}`), so it falls to the file's final, unconditional `match /{document=**} { allow read, write: if false; }`. This is a stricter failure mode than the usual "undeclared collection falls to the tenant catch-all" pattern F-001 fixes elsewhere — no rules change can fix this, because the write target itself is at the wrong path. This is also why the PMO island's screens (`project_detail_screen.dart`, `wbs_task_detail_screen.dart`, the 3 unused `pmo_*_form.dart` files) are unreachable in practice even setting aside that nothing links to them: their data can never legally exist. (2) Even ignoring rules entirely, the live, routed screens (`project_dashboard_screen.dart`, `project_details_screen.dart`) are fed by `projectsProvider`/`projectProvider`, which stream `tenants/{tenantId}/projects` (`project_providers.dart`) — they would never surface a document `PmoService` wrote, hypothetically-permitted rules or not.

This matters well beyond the PMO island's own 7 dead files: `BpfOrchestrator.createProjectFromQuote()` — the Lead-to-Cash handoff F-004 wires into the UI — calls `pmoService.createProject(project)` as its actual write. **F-004 wires the *calling* side correctly, but landing F-004 without this fix first means every project Lead-to-Cash creates would silently misfile to root-level `/projects/{id}`** — rejected by rules, invisible to the real `projectsProvider`-backed screens — while `bpfService.advanceStage()` (called immediately after, unconditionally, inside the same orchestrator method) would still report success and advance the BPF ribbon as if a real, findable project now exists. Sequence this fix before or alongside F-004, and re-run F-004's own acceptance test (a real `Project` document appearing in `tenants/{tenantId}/projects`) after this lands even if F-004 was implemented and "verified" earlier.

**Required fix:** In `pmo_service.dart`, remove the `.firestore` hop from all 19 affected methods so every method is consistent with the 8 that already work correctly — i.e. change `_tenantDoc.firestore.collection('projects')` to `_tenantDoc.collection('projects')` (and likewise for `'time_entries'`/`'expenses'`/`'actuals'`), preserving the rest of each call chain (`.doc(...)`, `.collection('wbs')`, `.where(...)`, `.snapshots()`, etc.) exactly as written. This is a mechanical, identically-shaped edit repeated 19 times in one file — no signature or caller changes needed, since `_tenantDoc.collection(x)` and `_tenantDoc.firestore.collection(x)` return the same `CollectionReference` type. Doing this also resolves `projects.md` §7's separately-listed "PMO island root-level collections unreachable by any rule" finding — it is not a distinct bug requiring its own rules change, it is the same root cause; once every method writes under `tenants/{tenantId}/...`, the already-declared `tenants/{tenantId}/projects` rule (`firestore.rules`, managers CRUD) covers the `Project`/`WbsTask` paths, and no new rule is needed for those specifically. `time_entries`/`expenses`/`actuals` would still need their own tenant-scoped rules declared (a small F-001-shaped addition) if the PMO island's `TimeEntry`/`Expense`/`Actual` CRUD is ever revived per `projects.md` §8's open question about whether it's superseded by the live model — out of scope for this item, which only fixes the path bug itself.

**Verification:** After the fix, call `PmoService.createProject()` (directly, or once F-004 is wired, through the full Lead-to-Cash flow) against a real tenant in the emulator and confirm the document appears at `tenants/{tenantId}/projects/{id}` — via the Firestore emulator UI or `firebase firestore:get` — not at root-level `/projects/{id}`. Repeat for `createWbsTask()`/`createTimeEntry()`/`createExpense()`/`createActual()`, confirming each lands under the tenant path. `flutter analyze` should show no new errors (the fix doesn't change any method signature). If F-004 has already landed by the time this is verified, re-run F-004's own verification step end-to-end and confirm the resulting project is now visible on `project_dashboard_screen.dart`, not merely present somewhere in Firestore.

---

### [DONE] F-302: `revenue_recognition_screen.dart` is 100% fabricated data, not a partially-wired integration
**Severity:** Critical
**Module(s) / File(s):** `lib/features/projects/screens/revenue_recognition_screen.dart`
**Depends on:** none
**Source:** `docs/modules/projects.md` §4, §7; `docs/modules/finance.md` §6; `docs/modules/_known_gaps_rollup.md` §1.8, §2 High table

**Current behavior:** The screen's own section headers announce what they are: `// ─── Mock Data Models ───` (line 4), `class _JournalEntry { ... }` (line 6), `// ─── Mock Journal Entries ───` (line 28), `final _mockEntries = [ ... ]` (line 30) — five `const`-shaped `_JournalEntry` records declared directly in the file. The screen's only live state, `_ledgerFilterProvider` (a `StateProvider`), filters that static list client-side (lines 109-110: `? _mockEntries : _mockEntries.where((e) => e.status == filter).toList()`). Confirmed by direct grep of the file: zero references to `revRecEngine`, `httpsCallable`, `FirebaseFunctions`, `project_milestones`, or `finance_journals`/`fin_journal_headers` anywhere in its 930 lines, and the screen accepts no `projectId` parameter at all — despite being reached (per `project_operations_hub_screen.dart`'s "Revenue Recognition" tile) as if it were a per-project ledger view. This is a materially more complete finding than "the button isn't wired to a backend yet": the numbers themselves — amounts, dates, statuses, descriptions — are invented and identical for every user, every project, every session. State plainly for whoever picks this up: an earlier planning pass suspected this screen was "partially wired to `revRecEngine`" (the real Cloud Function that does watch `tenants/{t}/project_milestones/{id}` and does write real `tenants/{t}/finance_journals` entries on milestone completion, per `finance.md` §5) — reading the file directly disproves that suspicion; there is no partial wiring of any kind, the screen never attempts a Firestore or Cloud Functions call.

**Required fix:** This needs a product decision before the mechanical rewrite, per `projects.md` §8's own open question: is this screen meant to be a live view over `revRecEngine`'s real output (watch `tenants/{tenantId}/finance_journals`, filtered to revenue-recognition-sourced entries, or a dedicated `revenue_schedules` subcollection if one gets introduced), or was it always a static design mock never wired up? AGENTS.md §2's explicit instruction — "If a feature is incomplete, disable the relevant button or feature instead of faking the data" — argues strongly for the live-data direction given `revRecEngine` already exists, already does real work, and currently has no confirmed consumer anywhere (`finance.md` §5's Cloud Functions table flags this exact gap from the other side). If adopted: accept a `projectId` (matching how the hub's other 3 tiles — Gantt/Timesheet/Expense — are all project-scoped), replace `_mockEntries` with a real `StreamProvider` over the tenant's journal collection (resolve which collection name per this cluster's F-313 naming-scheme decision — do not invent a fourth scheme here), and delete the `_JournalEntry` mock class and its `Mock Data Models`/`Mock Journal Entries` sections entirely. If the screen is instead meant to stay static for now, at minimum gate it behind a visible "preview/demo data" affordance rather than presenting fabricated dollar figures as live ledger entries with no indication they're fake.

**Verification:** Once wired, seed a real `project_milestones` document, transition it to `COMPLETED` so `revRecEngine` fires and writes a real journal entry, then open the Revenue Recognition screen for that project and confirm the new entry appears — not one of the 5 static records. Confirm the `_ledgerFilterProvider` status filter still works against the real stream. Grep the file post-fix for `_mockEntries`/`_JournalEntry` to confirm no trace remains.

---

### [DONE] F-303: `timesheet_entry_screen.dart` has no write path at all — a full banned-stub, not just a toast violation
**Severity:** Critical
**Module(s) / File(s):** `lib/features/projects/screens/timesheet_entry_screen.dart`
**Depends on:** none (F-013 separately tracks this same file's `ScaffoldMessenger` usage — fix both while in this file, but they are independent changes; do not treat F-013 as covering this item)
**Source:** `docs/modules/projects.md` §4, §7; `docs/modules/_known_gaps_rollup.md` §1.8, §2 High table (`projects` | "`timesheet_entry_screen.dart` has no Firestore call at all")

**Current behavior:** `_submit()` (lines 27-35) is the entire write path:
```
27:  void _submit() {
28:    if (_formKey.currentState!.validate()) {
29:      // Simulate timesheet submission
30:      ScaffoldMessenger.of(context).showSnackBar(
31:        const SnackBar(content: Text('Timesheet submitted successfully')),
32:      );
33:      Navigator.pop(context);
34:    }
35:  }
```
On successful form validation this method does nothing except show a message and close the screen — no `FirebaseFirestore` call, no service reference, no provider read of any kind anywhere in the file (confirmed by grep: its only imports are `flutter/material.dart` and `flutter_riverpod/flutter_riverpod.dart` — no `providers`/`services` import at all, unlike every other write-capable screen in this module). The screen collects real user input — task description, hours worked, a date via `showDatePicker` — validates it, then discards it. This is AGENTS.md §3's banned-stub prohibition in its purest form: the button *is* wired, validation *is* real, and the user is explicitly told the submission succeeded — but nothing is persisted anywhere. A user logging billable hours through this screen has no way to know their time was never recorded. Contrast with `expense_entry_screen.dart` — same module, same hub, same tile-row position — which does write real data via `projectServiceProvider.addExpense()`, confirming this is a single-screen gap, not a module-wide limitation. The BPF narrative's "Time & Expense Logging" step (`projects.md` §3) is therefore only half-real: Expense works, Time silently does not.

**Required fix:** Add a real write, following `expense_entry_screen.dart` as the direct template (same hub, same tile row, already correct). Write against the *live* data model (`project_models.dart`), not the orphaned `pmo_models.dart` `TimeEntry` — see F-301, this cluster's `PmoService` item: writing through that path would currently misfile the data to Firestore root even once wired, so it is not a safe shortcut here. Concretely: add a `TimeEntry`-shaped record + a `tenants/{tenantId}/projects/{id}/timeEntries` (or similarly-scoped) collection to `project_models.dart`/`ProjectService`, mirroring how `ProjectExpense` already works (`tenants/{tenantId}/expenses`, `ProjectService.addExpense()`) — confirm against `projects.md` §8's open question first if there's reason to prefer a different shape than a straight mirror of the Expense pattern. Wire `_submit()` to call it with proper `isLoading` state management per AGENTS.md §1 (a local `bool _isSubmitting` disabling the submit button during the write, the same pattern already used in `new_project_dialog_content.dart`/`dra_form.dart` elsewhere in this codebase). Swap the raw `ScaffoldMessenger` call for `UIUtils.showToast` while touching this method — that specific change is F-013's item, but there's no reason to leave a raw `ScaffoldMessenger` call as the very last line of a newly-real write path just because a different item nominally owns it.

**Verification:** Submit a real timesheet entry (task description, hours, date) through the UI; confirm a new document appears in Firestore under the tenant-scoped path chosen above, with fields matching what was entered — not just a toast and a screen pop. Confirm the entry is visible somewhere a Project Manager would actually look for it (a Timesheet/Time tab if one is added as part of this fix, or at minimum queryable against the project it was logged for).

---

### [DONE] F-306: `dra_form.dart` writes field names none of its own module's readers expect
**Severity:** Critical
**Module(s) / File(s):** `lib/features/risk/widgets/dra_form.dart` (writer); `lib/features/risk/widgets/dra_card.dart`, `lib/features/risk/screens/risk_command_center_screen.dart`, `lib/features/risk/screens/risk_hub_screen.dart` (readers)
**Depends on:** none (independent of F-001's `dynamic_risk_assessments` rules gap — that blocks the write outright; this bug means even a successful write renders wrong on every one of the module's 3 reading screens)
**Source:** `docs/modules/risk.md` §5, §7 (DB-to-UI alignment audit); `docs/modules/_known_gaps_rollup.md` §2 Critical table (`risk` | `dra_form.dart` writes `activity`/`area`; every reader expects `taskDescription`/`location`)

**Current behavior:** `DRAForm._submit()` writes to `dynamic_risk_assessments` with this payload (`dra_form.dart:58-74`):
```
58:            data: {
59:              'type': 'dra',
60:              'title': 'DRA: ${_taskCtrl.text.trim()}',
61:              'description': _hazards.join(', '),
62:              'activity': _taskCtrl.text.trim(),
63:              'area': _locCtrl.text.trim(),
64:              'hazardsIdentified': _hazards,
65:              'controlsApplied': _controls,
66:              'teamMembers': _teamMembers,
67:              'approverId': _approverId,
68:              'reviewDate': _reviewDate?.toIso8601String(),
69:              'isSafeToProceed': _isSafe,
70:              'assessedBy': profile.uid,
71:              'authorName': profile.displayName,
72:              'siteId': profile.tenantId,
73:              'createdAt': FieldValue.serverTimestamp(),
74:            },
```
Every screen that reads this collection back expects different field names than the ones actually written:

| Field read | Read by | Actually written by `dra_form.dart` as | Effect |
|---|---|---|---|
| `taskDescription` | `dra_card.dart:51` (card title) | `activity` (line 62) | Every DRA card's title always falls back to `'Untitled Assessment'` |
| `location` | `dra_card.dart:73-74,84` (location row) | `area` (line 63) | The location row's `data['location'] != null` guard is always false; it never renders |
| `task` | `risk_command_center_screen.dart:216,272` ("Recent Assessments" title / detail dialog) | `activity` (line 62) | Same `'Untitled Assessment'` fallback, independently, in a second screen |
| `riskLevel` | `risk_command_center_screen.dart:43,192` (Extreme/High/Medium/Low KPI grid) | *(never written — this form has no risk-scoring logic at all)* | Extreme/High/Medium/Low KPI counts are always 0 regardless of actual DRA content |
| `status` | `risk_hub_screen.dart:61,80` (Open Assessments / Control Strength KPIs) | *(never written — the form stores `isSafeToProceed: bool` instead, line 69)* | "Open Assessments" (`d.data()['status'] != 'Approved'`, line 61) always counts every DRA as open, since `status` is always absent/null; "Control Strength" (lines 76-83) computes `0%` once any DRA exists (`.where((d) => d.data()['status'] == 'Approved')` always finds zero matches) — the `'80%'` floor at line 77 only applies while the collection is empty |

This pattern is unique to DRA within the module: `hira_form.dart` (`_riskScore()`/`_riskLevel()`, writing `riskRating`) and `strategic_risk_form.dart` (its own `_riskScore()`/`_riskRating()`) both compute and write a real risk rating and are both read back correctly by their own screens — `risk.md` confirms this is the *only* one of the module's 4 sub-features with a field-mismatch problem; `bowtie_form.dart` has no confirmed mismatch either. Fields confirmed to work correctly end-to-end on DRA: `hazardsIdentified`, `controlsApplied`, `isSafeToProceed`, `createdAt`.

**Required fix:** Per `risk.md` §8's own framing — either direction resolves the mismatch, but the form is the more likely candidate to fix, since it is the outlier against its own module's sibling forms. Recommended: in `dra_form.dart`, rename the write payload's `activity`→`taskDescription` and `area`→`location` to match what `dra_card.dart`/`risk_command_center_screen.dart` already read; add a `status` field (e.g. a `'Pending'`/`'Approved'` workflow value, matching what the KPI cards' `'Approved'` check already implies) instead of relying solely on `isSafeToProceed`; and add risk-scoring logic that produces a `riskLevel` value from likelihood/severity-style inputs, using `hira_form.dart`'s `_riskScore()`/`_riskLevel()` pair as the direct template — same module, same shape of inputs feeding a computed rating. If the alternative direction is chosen instead (update the 3 reader files to match the form's actual field names), be aware `risk_hub_screen.dart`'s "Control Strength"/"Open Assessments" KPIs and `risk_command_center_screen.dart`'s Extreme/High/Medium/Low grid would then need an entirely new way to derive "approved"/"risk level" from `isSafeToProceed` alone, since the form currently captures no equivalent risk-rating input — this makes the form-side fix meaningfully less total work, not just an equally-valid alternative.

**Verification:** Submit a new DRA through `dra_form.dart` with a real task description, location, and non-trivial hazard/control detail; confirm its card shows the real task description as its title (not "Untitled Assessment") and displays the location row. Confirm `risk_command_center_screen.dart`'s "Recent Assessments" list shows the same real title, and that the Extreme/High/Medium/Low KPI grid's count increments correctly for the new assessment's computed risk level. Confirm `risk_hub_screen.dart`'s "Open Assessments" count includes the new (unapproved) DRA, and that "Control Strength" moves off the empty-collection `80%` floor once at least one DRA is marked approved.

---

### [DONE] F-309: Action Tracker's create form and its own model disagree with each other — and with the screen meant to read them back
**Severity:** Critical
**Module(s) / File(s):** `lib/features/operations/widgets/action_form.dart`, `lib/features/operations/models/action_tracker_models.dart` (`ActionItem`), `lib/features/operations/screens/action_tracker_screen.dart`, `lib/features/operations/services/action_tracker_service.dart` (correct, currently unused)
**Depends on:** none (independent of F-001's rules gap for `actionItems` — that blocks the write outright regardless of field names; this bug means even a rules-permitted write still wouldn't round-trip correctly)
**Source:** `docs/modules/operations.md` §5, §7 (DB-to-UI alignment audit); `docs/modules/_known_gaps_rollup.md` §2 Critical table (`operations` | Action Tracker's create form and its own read-side model disagree with each other)

**Current behavior:** Three compounding gaps in what should be a single vertical slice — this module's flagship feature:

1. **Create/read collection split.** `ActionTrackerScreen._setupStreams()` subscribes to exactly 6 `CollSource`s (`action_tracker_screen.dart:32-38`: `incidents`, `capas`, `permits`, `bbs_observations`, `dynamic_risk_assessments`, `hazards`) — `actionItems` is not among them. But the same screen's "+" FAB (`action_tracker_screen.dart:158-164`) opens `ActionForm` as a side-sheet, whose `_submit()` writes straight into `tenantCollection(tenantId, 'actionItems')` (`action_form.dart:37-52`). A user who taps "+", fills in a title/assignee/due-date, and submits sees a `'Action item created'` success toast (`action_form.dart:54-58`) — but the item they just created never appears in the list they created it from, because `actionItems` isn't one of the 6 collections the screen aggregates. The only place `actionItems` is read back at all is `operations_hub_metrics.dart`'s unrelated "Open Actions" KPI counter, one screen up.

2. **Form-vs-model field disagreement**, which surfaces as a second bug the moment gap 1 is naively fixed by simply adding `actionItems` to the aggregated list. `ActionItem` (`action_tracker_models.dart:6-16`) declares `id, collectionName, type, title, status, dueDate, assignee`. `ActionForm._submit()`'s write payload (`action_form.dart:43-52`) is:
```
43:          .add({
44:            'title': _titleController.text.trim(),
45:            'description': _descController.text.trim(),
46:            'assigneeId': _selectedEmployeeId,
47:            'status': 'Pending',
48:            'dueDate': _dueDate.toIso8601String(),
49:            'createdAt': DateTime.now().toIso8601String(),
50:            'siteId': siteId,
51:            'type': 'General',
52:          });
```
`collectionName` (needed to route status updates back to the item's real source collection) is never written. The model expects `assignee`; the form writes `assigneeId` instead — so `ActionItem.fromJson()`'s `json['assignee'] ?? 'Unassigned'` (`action_tracker_models.dart:26`) would always fall back to `'Unassigned'` for items created through this form, even though a real employee was selected via `EmployeeSelector`. `description`, `createdAt`, `siteId` are written but don't exist on `ActionItem` at all — silently dropped if ever read through the model.

3. **A real, correct implementation sits unused nearby.** `action_tracker_service.dart` defines `ActionTrackerService` — constructed with the same tenant-`DocumentReference` shape as `PmoService` (this cluster's F-301) but implemented correctly throughout (`_actionItemsCol => _tenantDoc.collection('actionItems')`, no root-escape bug) — plus real `actionItemsProvider`/`actionItemsByStatusProvider.family` `StreamProvider`s. `ActionItem.toJson()` (`action_tracker_models.dart:30-39`) already produces the *correct* field names. The bug is entirely that `ActionForm` bypasses this service and model altogether, hand-rolling its own `.add({...})` call with different field names, instead of constructing an `ActionItem` and calling `actionTrackerService.createActionItem(item)`. Confirmed unused: grepping `action_tracker_screen.dart`/`action_form.dart` for `actionTrackerServiceProvider`/`actionItemsProvider` returns no matches — the screen builds its own inline Firestore subscriptions instead of consuming the provider layer that already exists and already works.

**Required fix:** This is one fix, not three — route `ActionForm` and `ActionTrackerScreen` through the already-correct `ActionTrackerService`/`ActionItem` layer instead of each hand-rolling its own Firestore access:
- In `action_form.dart`, replace the raw `.tenantCollection(...).add({...})` call with constructing an `ActionItem` (`collectionName: 'actionItems'`, `assignee:` resolved to the selected employee's display name — matching how other selectors in this codebase resolve a name post-selection, e.g. `new_project_dialog_content.dart`'s lead-contact lookup) and calling `ref.read(actionTrackerServiceProvider).createActionItem(item)`.
- In `action_tracker_screen.dart`, add `actionItems` as a 7th aggregated source (either as a `CollSource` in `_collections`, or by merging `actionItemsProvider`'s stream alongside the existing 6 subscriptions) so manually-created action items appear in the same list they were created from.
- Decide what `description` should map to (the model has no field for it today — add one to `ActionItem`, or fold it into `title` at submit time) rather than silently dropping user-entered text.

**Verification:** Tap "+" on the Action Tracker screen, fill in a title, description, assignee, and due date, submit; confirm the new item appears in the tracker's own list immediately (not just in the hub's unrelated "Open Actions" KPI count) with the correct assignee name displayed, not `'Unassigned'`. Confirm the `operations_hub_metrics.dart` KPI count still increments correctly (unaffected by this change, since it already reads the same collection).

---

### [DONE] F-310: `schedule_board_screen.dart` is entirely hardcoded mock data with no Firestore write anywhere
**Severity:** Critical
**Module(s) / File(s):** `lib/features/operations/screens/schedule_board_screen.dart`
**Depends on:** none
**Source:** `docs/modules/operations.md` §4, §7; `docs/modules/_known_gaps_rollup.md` §1.8, §2 High table

**Current behavior:** The entire screen operates on 3 hardcoded, in-memory structures, confirmed by direct read of the file:
```
15:  // Mock data for resources (technicians/employees)
16:  final List<String> resources = ['John Doe', 'Jane Smith', 'Mike Johnson', 'Sarah Connor'];

18:  // Mock data for unassigned tasks
19:  final List<Map<String, dynamic>> unassignedTasks = [
20:    {'id': 'wo-1', 'title': 'WO #101', 'subtitle': 'HVAC Repair'},
21:    {'id': 'wo-2', 'title': 'WO #102', 'subtitle': 'Electrical Inspection'},
22:    {'id': 'wo-3', 'title': 'PMO-200', 'subtitle': 'Site Audit'},
23:  ];

26:  final Map<String, List<Map<String, dynamic>>> assignedTasks = {
27:    'John Doe': [],
```
4 hardcoded resource names, 3 hardcoded tasks whose IDs (`WO #101`/`WO #102`, `PMO-200`) suggest an intent to eventually pull real `field_service` Work Orders and `projects` PMO/task data — but nothing in the file references either module. Drag-and-drop assignment (`_assignTask()`, lines 33-51, wired to each `DragTarget.onAccept`, line 100) only mutates the local `assignedTasks`/`unassignedTasks` lists via `setState` — no `FirebaseFirestore`, no service call, no provider write anywhere in the file (confirmed by grep). Any assignment made on this board is lost the moment the user navigates away and returns.

**Required fix:** Replace the 3 hardcoded structures with real data: `resources` should come from `employeesProvider` — the same real, live provider `action_form.dart`/`new_project_dialog_content.dart` already use for personnel selection elsewhere in this app. `unassignedTasks` should come from a real query — per the mock IDs' own hint, most plausibly `field_service`'s unassigned/unscheduled `work_orders` merged with `projects`' live task data — but confirm which source is actually intended before implementing, since `operations.md` §8 raises this exact question and leaves it unresolved; flag as an open question to the implementer rather than guessing which module owns the canonical "schedulable task" concept. Once resolved, `_assignTask()` needs to persist the assignment somewhere durable — e.g. an `assignedToId`/`scheduledResourceId` field on the source Work Order/task document, written via whichever module's service already owns that record — instead of only calling `setState`.

**Verification:** Open the Schedule Board with real, seeded unassigned Work Orders/tasks and real employees; drag a task onto a resource; navigate away and back (or reload) and confirm the assignment persisted — the task should still show under that resource, not have reverted to unassigned. Confirm the source Work Order/task document's assignment field was actually updated in Firestore.

---

### [DONE] F-311: `updateJournalEntry()`/`deleteJournalEntry()` never enforce the immutability principle they're documented to have
**Severity:** Critical
**Module(s) / File(s):** `lib/features/finance/services/finance_service.dart` (`updateJournalEntry()`, `deleteJournalEntry()`)
**Depends on:** none (independent of F-001's rules-naming fix for `fin_journal_headers` — that gates whether the call reaches Firestore at all; this bug is about what happens once it does)
**Source:** `docs/schema_finance.md` line 5; `docs/modules/finance.md` §1, §7; `docs/modules/_known_gaps_rollup.md` §2 Critical table (`finance` | Immutability principle from `docs/schema_finance.md` unenforced)

**Current behavior:** `docs/schema_finance.md:5` states the module's second of four stated core principles: "**Immutability:** Posted transactions cannot be deleted or modified. Corrections require a reversing entry." `JournalEntry.status` (`finance_models.dart:80`) is documented as one of `"DRAFT", "PENDING_APPROVAL", "APPROVED", "POSTED", "REVERSED", "REJECTED"` — the model has everything needed to distinguish a posted entry from a draft one. But `finance_service.dart`'s actual mutation methods ignore `status` entirely:
```
78:  Future<void> updateJournalEntry(JournalEntry entry) async {
79:    await _tenantDoc
80:        .collection('fin_journal_headers')
81:        .doc(entry.id)
82:        .update(entry.toJson());
83:  }
84:
85:  Future<void> deleteJournalEntry(String id) async {
86:    await _tenantDoc.collection('fin_journal_headers').doc(id).delete();
87:  }
```
Both act unconditionally on any journal entry regardless of `status` — a `POSTED` entry (one that, per the schema doc's own model, has already affected the ledger) can be silently edited or deleted through the exact same code path as a `DRAFT` one, with no guard, no reversing-entry requirement, and no error. This is a real accounting-integrity gap, not a cosmetic one: any caller of `FinanceService` — today nothing is wired to the UI per this module's other findings, but this is exactly the kind of guard that belongs in the service layer itself rather than depending on the current UI simply not offering a delete button, since `LedgerPostingService`/`postJournalEntry` (see F-317, this cluster's item on that Cloud Function) or a future direct caller could invoke this method regardless of what today's UI happens to expose.

**Required fix:** In `updateJournalEntry()` and `deleteJournalEntry()`, fetch the current document's `status` before mutating (or use a Firestore transaction to check-then-act atomically, avoiding a race between the check and the write) and throw if `status == 'POSTED'` (or `'REVERSED'`) — matching the schema doc's principle exactly: reject the mutation rather than silently allowing it. Add a separate, explicit `reverseJournalEntry()` method implementing the documented correction path instead: create a new `JournalEntry` with inverted debit/credit amounts, set `reversesJournalId` (a field the model already declares) to point at the original, and set the original's own `status` to `'REVERSED'` — additive, not a change to the existing create path. Apply the same posted-status guard to other mutation methods in this service if they have an analogous "shouldn't change after X" concept per the schema doc — confirm against `docs/schema_finance.md` in full before assuming scope beyond journal entries.

**Verification:** Create a `JournalEntry` with `status: 'DRAFT'`; confirm `updateJournalEntry()`/`deleteJournalEntry()` still succeed against it. Transition it to `status: 'POSTED'` (directly in Firestore for test purposes, or via whatever posting flow exists once F-317 is wired), then confirm both methods now throw instead of silently succeeding. Call the new `reverseJournalEntry()` against the posted entry and confirm it produces a second, inverted entry and flips the original's status to `'REVERSED'`, leaving the original document's amounts untouched.

---

### [DONE] F-312: Dead `journalEntriesProvider`/`invoicesProvider` mean `FinanceHubScreen` can never show a real journal entry
**Severity:** Critical
**Module(s) / File(s):** `lib/features/finance/providers/finance_providers.dart` (`journalEntriesProvider`, `invoicesProvider`), `lib/features/finance/screens/finance_hub_screen.dart`
**Depends on:** none
**Source:** `docs/modules/finance.md` §5, §7; `docs/modules/_known_gaps_rollup.md` §2 Medium table (`finance` | `LedgerPostingService`... `journalEntriesProvider`/`invoicesProvider` are dead, so `FinanceHubScreen` always shows an empty journal list)

**Current behavior:** `finance_providers.dart:12-13`:
```
12:final journalEntriesProvider = StateProvider<List<JournalEntry>>((ref) => []);
13:final invoicesProvider = StateProvider<List<Invoice>>((ref) => []);
```
Both are plain `StateProvider`s seeded with an empty list and never written to anywhere — confirmed by repo-wide grep for `.notifier.state =` against either provider: zero matches. `invoicesProvider` additionally has zero *read* call sites anywhere in `lib/` (dead in both directions). `journalEntriesProvider` does have one consumer: `finance_hub_screen.dart:13` (`final journalEntries = ref.watch(journalEntriesProvider);`), feeding both the "Total Journal Entries" count (line 40: `Text('Total Journal Entries: ${journalEntries.length}')`) and the "Recent Journal Entries" list (lines 76-107) — both permanently show `0`/"No journal entries yet." regardless of how many real journal entries exist in Firestore for the tenant, because the provider backing them can structurally never contain anything. This is the module's own top-level hub screen (`/finance`, `router.dart:105`) — a real, reachable, first-screen-you-see gap, not a buried one. Note the contrast within the same screen: `glAccountsStreamProvider` (line 14) is a real `StreamProvider` correctly wired to `FinanceService.streamAllGLAccounts()`, so "Total Accounts" on the same card works correctly — this is a targeted gap in exactly 2 of the screen's data points, not a whole-screen failure.

**Required fix:** Replace both `StateProvider`s with real `StreamProvider`s following `glAccountsStreamProvider's own pattern 2 lines above them in the same file — e.g. `final journalEntriesStreamProvider = StreamProvider<List<JournalEntry>>((ref) { final service = ref.watch(financeServiceProvider); return service.streamAllJournalEntries(); });`, adding a `streamAllJournalEntries()`/`streamAllInvoices()` method to `FinanceService` if a collection-wide stream doesn't already exist (the service currently has per-ID stream methods like `streamJournalEntry(id)`/`streamInvoice(id, type: type)` — check whether a list-level stream needs adding, or whether it can be composed from an existing method). Update `finance_hub_screen.dart:13` to watch the new stream provider and handle its `AsyncValue` states (loading/error/data) the same way `accountsAsync.when(...)` already does two lines below it in the same build method, rather than reading a plain `List` directly. Note the naming decision in F-313 affects which underlying collection this new stream should query — sequence accordingly, or query whatever `FinanceService` currently targets and adjust once F-313 resolves.

**Verification:** Seed a real journal entry via `FinanceService.createJournalEntry()` (once F-001's rules fix allows the write to succeed) for a tenant, then open the Finance Hub and confirm "Total Journal Entries" reflects the real count and the entry appears in "Recent Journal Entries" — not the permanent zero/empty state.

---

### [DONE] F-319: The Stripe subscription billing pipeline is disconnected end-to-end — missing Cloud Function, 3-way path mismatch, and an unsatisfiable tier check
**Severity:** Critical
**Module(s) / File(s):** `lib/features/billing/services/billing_service.dart`, `lib/core/providers/subscription_provider.dart` (`isPremiumProvider`), `functions/src/billing.ts` (`stripeWebhook`, unexported), `functions/src/index.ts`
**Depends on:** none
**Source:** `docs/modules/billing.md` §5, §7; `docs/modules/_known_gaps_rollup.md` §2 Critical table (`billing`, both entries)

**Current behavior:** Three separate breaks, each independently confirmed, drafted as one item because a real fix requires resolving them together — fixing any one alone still leaves the "Upgrade to Premium" flow on `billing_portal_screen.dart` (this module's only real user action) non-functional:

1. **The Cloud Function the app calls doesn't exist.** `BillingService.createStripeCheckoutSession()` (`billing_service.dart:11-27`) calls `_functions.httpsCallable('createStripeCheckoutSession')`. Grepping both Cloud Functions codebases in full — `firebase/functions/src/` (`aiEngine`, `copilotEngine`, `hrEngine`, `index`, `iotEngine`, `mrpEngine`, `revRecEngine`, `routingEngine`, `taxEngine`) and `functions/src/` (`api`, `billing`, `index`, `prescreen_compliance`) — finds no function by this name in either. As committed, tapping "Upgrade to Premium" fails at runtime with a Cloud Functions not-found error, against either codebase.

2. **The legacy webhook that would update subscription state is unexported and writes the wrong path.** `functions/src/billing.ts` defines `stripeWebhook` (`onRequest`), handling `customer.subscription.{created,updated,deleted}` and writing:
```
57:  await db.collection("tenants").doc(tenantId).collection("billing").doc("subscription").set({
```
i.e. `tenants/{tenantId}/billing/subscription`. But `functions/src/index.ts` only exports `export * from './prescreen_compliance';` — `stripeWebhook` is never exported, so it cannot be deployed/reached at all, independent of the path problem. Even fully exported: `BillingService.getSubscriptionStream()` (`billing_service.dart:29-42`) reads `tenants/{tenantId}/subscription/status` — a different subcollection name (`billing` vs `subscription`) *and* a different document ID (`subscription` vs `status`) than what the webhook writes. Fully deployed, and genuinely receiving real Stripe events, this function's writes would still land somewhere the app never reads.

3. **The premium-check can never be satisfied by any value the rest of the pipeline produces.** `isPremiumProvider` (`subscription_provider.dart:5-14`):
```
13:  return subscription.tier == 'premium' || subscription.tier == 'enterprise';
```
Repo-wide grep for the literal string `'premium'` across `lib/`, `firebase/functions/`, and `functions/` returns exactly this one match. Nothing anywhere ever produces a `'premium'` tier value: `stripeWebhook`'s own default (line 55: `subscription.metadata?.tier || "pro"`) is `'pro'`, and the (separately dead, per F-016) `subscription_models.dart` enum only defines `free`/`pro`/`enterprise`. A tenant on the webhook's own default tier can never satisfy this check — only `'enterprise'` can, as the code stands. Even with breaks 1 and 2 both fixed, a tenant that successfully upgrades to the intended mid tier would still see `BillingPortalScreen` render as if they were still on the free tier.

**Required fix:**
- Write `createStripeCheckoutSession` into the actively-developed codebase (`firebase/functions/src/`) as a new `onCall` function — accept `tenantId`, create/reuse a Stripe Customer, create a Checkout Session for the desired plan, and return `{ url }` matching what `BillingService.createStripeCheckoutSession()` already expects back (`result.data['url']`, line 15).
- Move `stripeWebhook` into `firebase/functions/src/` (or re-export it from `firebase/functions/src/index.ts` if it stays in the legacy codebase — pick whichever this app's actual deploy target is; confirm against `firebase.json`'s functions config first, since `finance.md` §5 notes this file currently has no `functions` key, making deployment ambiguous), and fix it to write `tenants/{tenantId}/subscription/status` — matching what `BillingService.getSubscriptionStream()` already reads — instead of `tenants/{tenantId}/billing/subscription`. Add real Stripe signature verification while touching this function (its own comment admits this is currently skipped: "In a real app, use the raw buffer and stripe.webhooks.constructEvent").
- Resolve the tier-name bug by picking one direction and applying it everywhere: either change `isPremiumProvider` to check `'pro'` (matching what the webhook actually produces and what `SubscriptionTier`'s enum defines) instead of `'premium'`, or — if a distinct mid-tier "Premium" (as opposed to "Pro") was genuinely intended as a third tier between free and enterprise — add it properly to `SubscriptionTier`, the webhook's tier-selection logic, and the new Checkout Session function's plan mapping. Resolve `billing.md` §8's open question ("Is `isPremiumProvider`'s `'premium'` check a typo for `'pro'`, or was a third tier name once planned?") as part of implementing this, not left open.

**Verification:** Using the Stripe CLI (or emulator) against a non-prod project: tap "Upgrade to Premium" on `BillingPortalScreen`, confirm a real Checkout Session URL is returned and opens. Complete a test checkout, confirm the webhook fires and writes `tenants/{tenantId}/subscription/status` with the expected tier. Confirm `BillingPortalScreen` then reflects the paid tier (no longer showing the upgrade card) and `isPremiumProvider` returns `true` for that tenant — for whichever tier value the webhook actually produced, without needing a further code change to recognize it.

---
### Sales / Customer Service / Field Service Cluster

### [DONE] F-403: The central finding — two complete, parallel customer_service implementations; only the 100%-mocked one is reachable from navigation
**Severity:** Critical
**Module(s) / File(s):** `lib/features/customer_service/screens/customer_service_hub_screen.dart`, `omnichannel_chat_screen.dart`, `omnichannel_ticket_screen.dart`, `knowledge_base_screen.dart` (mock side); `lib/features/customer_service/screens/ticket_detail_screen.dart`, `knowledge_article_detail_screen.dart`, `lib/features/customer_service/widgets/ticket_form.dart`, `knowledge_article_form.dart` (real side, no changes needed to these 4 beyond what's covered by companion items); `lib/features/customer_service/models/customer_service_models.dart`, `lib/features/customer_service/services/customer_service_service.dart` (no changes needed); `lib/config/router.dart`
**Depends on:** F-001 (the real implementation's writes to `cs_tickets`/`cs_knowledge_articles`/`cs_assets`/subcollections are rules-blocked until then — wiring navigation alone is not sufficient to make this module fully functional end to end)
**Source:** `docs/modules/customer_service.md` §2, §4, §7 ("the central finding for this module")

**Current behavior:** Two complete, independently-built implementations of this module exist side by side, confirmed by reading every screen file in full and cross-referencing each class name against `router.dart` and a repo-wide grep. **The mock side (reachable from navigation, zero model/service usage):** `customer_service_hub_screen.dart` (routed at `/customer-service`, `router.dart:132-136`) renders a hardcoded "SLA Metrics" row (4 literal strings — `'15 mins'`/`'2.5 hours'`/`'4.8/5.0'`/`'3 Tickets'`, lines 44-80) and a `ListView.builder(itemCount: 10, ...)` of fabricated "Case #1000+index" tiles (lines 90-113); it imports neither `customer_service_models.dart` nor `customer_service_service.dart` anywhere. Its AppBar opens 2 further mock screens: `omnichannel_chat_screen.dart` (routed at `/omnichannel-chat`, `router.dart:169-170`) is a full chat UI backed entirely by a local `StateNotifierProvider` seeded with 5 hardcoded `_ChatMessage`s (lines 26-54), whose "Suggest AI Reply" button (line 323) inserts a hardcoded `_mockAiSuggestion` string constant (lines 76-79) instead of calling the real `aiSuggestReply` Cloud Function; and `knowledge_base_screen.dart` (opened via `Navigator.push`, hub lines 23-29 — a separate AGENTS.md §1 violation already covered by F-012, not restated here) has 5 hardcoded sidebar categories and 6 hardcoded article cards, zero Firestore reads, zero model import. A fourth mock screen, `omnichannel_ticket_screen.dart` (15 fake tickets), is not even reachable from the mock hub itself — confirmed by repo-wide grep, `OmnichannelTicketScreen(` matches only its own constructor declaration — so it is dead code on top of being mocked. **The real side (Firestore-backed via `CustomerServiceService`, zero navigation path):** `customer_service_models.dart` (`Ticket`/`TicketMessage`/`SlaInstance`/`KnowledgeArticle`/`CsAsset`) and `customer_service_service.dart` (writing real tenant-scoped documents to `cs_tickets`, `cs_tickets/{id}/messages`, `cs_tickets/{id}/sla_kpi_instances`, `cs_knowledge_articles`, `cs_assets`) are both fully and correctly implemented — real-time-first compliant per AGENTS.md §2, every list read a `Stream`. Four screens/widgets consume this layer correctly: `ticket_detail_screen.dart` (streams a `Ticket` plus its messages and SLA instances via `ticketFutureProvider`/`ticketMessagesStreamProvider`/`ticketSlaStreamProvider`, all backed by `customerServiceServiceProvider`), `knowledge_article_detail_screen.dart` (streams a `KnowledgeArticle` via `articleFutureProvider`), `ticket_form.dart` (`TicketForm`, calls `CustomerServiceService.createTicket()`/`updateTicket()`), and `knowledge_article_form.dart` (`KnowledgeArticleForm`, calls `createKnowledgeArticle()`/`updateKnowledgeArticle()`). Confirmed by grep: `TicketDetailScreen(`, `KnowledgeArticleDetailScreen(`, `TicketForm(`, `KnowledgeArticleForm(` each return exactly one match anywhere in `lib/` — their own constructor declarations. None is referenced from `router.dart`, from the mock hub, or from any other screen in the app. A user can open the app, navigate the entire reachable Customer Service surface, and never once touch a real Firestore document — every "ticket" and "article" they see is a compile-time literal.

**Required fix:** Per the module doc's own framing: wire the real implementation into navigation, retire or repurpose the mock one — do not build a third implementation. Concretely: (1) replace `customer_service_hub_screen.dart`'s hardcoded "Open Cases" list (lines 88-116) with a real stream over a `streamTickets()`-shaped method on `CustomerServiceService` (add one if it doesn't already exist, following `streamKnowledgeArticles()`'s existing pattern at `customer_service_service.dart:44-50`), each row's `onTap` opening `TicketDetailScreen(ticketId: ...)` via `UIUtils.showSideSheet`; (2) add a real "New Ticket"/"New Article" entry point (FAB or AppBar action) opening `TicketForm`/`KnowledgeArticleForm` via `UIUtils.showSideSheet`; (3) replace `knowledge_base_screen.dart`'s hardcoded article grid with a real stream over `streamKnowledgeArticles()`, each card opening `KnowledgeArticleDetailScreen`; (4) decide the fate of `omnichannel_chat_screen.dart` and `omnichannel_ticket_screen.dart` — both are UI-only shells with no corresponding real model, though a `Ticket`'s `TicketMessage` subcollection is the closest real analog for chat — either retrofit one of them to stream real `TicketMessage`s for a specific ticket (folding `omnichannel_chat_screen.dart`'s already-reasonable chat-bubble UI into `ticket_detail_screen.dart`'s messages panel, since both target the same underlying concept), or keep it as a distinct omnichannel-inbox view backed by a real cross-ticket message query — but do not leave it rendering invented conversations once the rest of the module is real. Delete `omnichannel_ticket_screen.dart` outright unless a concrete distinct purpose for it (separate from `ticket_detail_screen.dart`) is identified — it is already dead code today and duplicates ground `TicketDetailScreen` already covers correctly. This item does not need to independently fix the FK-field gaps on `ticket_form.dart` (see F-404) or the individual banned-stub callbacks on the surviving screens (see F-405) — treat this item as the navigation/reachability fix and let those two land alongside or after it.

**Verification:** From the Customer Service hub, reached via normal app navigation (not a debug route), create a real ticket through the newly-wired form, confirm it appears in the hub's list immediately (real-time, no manual refresh), tap into it, and confirm `TicketDetailScreen` renders that real document rather than a hardcoded one. Repeat for a Knowledge Article. Confirm `omnichannel_chat_screen.dart`/`omnichannel_ticket_screen.dart` no longer present invented conversations once their fate is decided and implemented.

---

### [DONE] F-404: `ticket_form.dart` is missing 7 of the `Ticket` model's reference fields entirely
**Severity:** High
**Module(s) / File(s):** `lib/features/customer_service/widgets/ticket_form.dart`
**Depends on:** none (independent of F-403's navigation fix — this bug exists in the form's own code regardless of whether the form is reachable yet)
**Source:** `docs/modules/customer_service.md` §7 (DB-to-UI alignment audit)

**Current behavior:** `ticket_form.dart` belongs to this module's real, Firestore-backed implementation (see F-403) — it correctly calls `CustomerServiceService.createTicket()`/`updateTicket()` (`ticket_form.dart:76,78`) with real defensive `_isLoading`/try-catch handling. But its state is limited to `_titleController`, `_descriptionController`, `_status`, `_priority`, `_severity`, `_channel`, `_isEscalated` (`ticket_form.dart:19-26`), and `_saveTicket()` constructs the `Ticket` it saves (`ticket_form.dart:59-73`) from only those 7 values plus `id`/`ticketId`/`createdAt`/`updatedAt`. Seven of the `Ticket` model's reference fields have **no corresponding field on the form at all** — not a wrong-widget bug like F-011's plain-`TextFormField` pattern, but fields entirely absent from both the form's state and its `build()` method: `customerId` (FK to `cs_customers`), `contactId` (FK to a contact record), `assetId` (FK to `cs_assets`), `assignedTo` (agent reference), `workstreamId`, `queueId`, `entitlementId`. Every ticket created or edited through this form silently gets `null` for all 7 fields — and because `_saveTicket()` never reads them from `widget.initialTicket` either, editing an existing ticket that *does* have these fields set (e.g. seeded directly in Firestore) silently wipes them on the first save through this form. (`parentTicketId` is absent from the form for the same reason, though it wasn't separately called out in this session's scope.) This directly breaks `ticket_detail_screen.dart`'s own "Assigned To" row (`ticket_detail_screen.dart:119`: `_buildDetailRow('Assigned To', ticket.assignedTo ?? 'Unassigned')`) for every ticket ever created through this form — it will always read "Unassigned."

**Required fix:** Add all 7 fields to the form. `assignedTo` should use `EmployeeSelector`, following exactly the pattern this same codebase already gets right one module over: `field_service`'s `work_order_form.dart` uses `EmployeeSelector` for its own agent/technician-reference fields (`assignedTechnicianId`, `dispatcherId`) instead of a plain text field or omitting them — use that as the direct template for `assignedTo` here (this form belongs to the real, salvageable implementation per F-403's diagnosis, so the fix template applies as-is, not with any adjustment). `assetId` can get a real searchable lookup today via `CustomerServiceService`'s existing `cs_assets` stream (`customer_service_service.dart:178-182`) — follow the `EmployeeSelector` pattern generically (search-as-you-type over a stream, storing the selected document's ID). `customerId`/`contactId` are FKs to a `cs_customers` collection (and a contact source) with no Dart model or service method anywhere yet, per `customer_service.md` §5 — flag these 2 as partially blocked pending that collection's own build-out rather than wiring a lookup against something that doesn't exist in code, but still add the field to the form (even as a plain, clearly-labeled `TextFormField` in the interim) so the value isn't silently dropped. `workstreamId`/`queueId`/`entitlementId` reference the schema doc's `cs_workstreams`/`cs_queues`/`cs_entitlements` collections, which also have no code representation (per `customer_service.md` §5) — same treatment: an interim plain field or an explicit Open Question, consistent with how F-011 handles similarly-blocked FK fields elsewhere in the app, per AGENTS.md §7's "never guess ambiguous requirements."

**Verification:** Create a ticket through the form with an assignee selected; confirm `ticket_detail_screen.dart`'s "Assigned To" row shows the real agent, not "Unassigned." Edit an existing ticket that has `assetId`/`customerId` set (seed directly in Firestore if no UI can set them yet) and confirm saving through the form no longer silently nulls those fields out.

---

### [DONE] F-407: 3-way `WorkOrder` shape collision — `FieldServiceService`, `iotTelemetryIngest`, and `loto_automation.dart` write 3 incompatible shapes to `work_orders`
**Severity:** Critical
**Module(s) / File(s):** `lib/features/field_service/models/work_order.dart` (candidate for deletion, see fix), `lib/features/field_service/providers/field_service_providers.dart` (`workOrdersProvider`, dead code, see fix), `lib/core/automation/loto_automation.dart`, `firebase/functions/src/iotEngine.ts` (`iotTelemetryIngest`)
**Depends on:** none
**Source:** `docs/modules/field_service.md` §5, §7; `docs/modules/_known_gaps_rollup.md` §1.10, §2 (Critical table: "`field_service` | 3-way `WorkOrder` shape collision (pattern §1.10); the one reachable detail screen is fed a hardcoded fake ID so it can only show 'not found'")

**Current behavior:** This module defines `WorkOrder` twice, and a third writer targets the same collection using neither Dart class. **Canonical shape:** `FieldServiceService` (`field_service_service.dart:19-22` `createWorkOrder()`, `:32-35` `updateWorkOrder()`) reads/writes `models/field_service_models.dart`'s rich `WorkOrder` (`work_order_number`, `status`, `priority`, `customer_id`, `scheduling{}`, `safety_requirements{}`, etc., all snake_case Firestore keys per `field_service_models.dart:58-116`) to `work_orders`. This is the shape the module's only real detail screen actually reads: `WorkOrderDetailsScreen` streams via `service.streamWorkOrder(widget.workOrderId)` (`work_order_details_screen.dart:37`) and renders `workOrder.workOrderNumber`/`.status`/`.priority`/`.customerId`/`.assignedTechnicianId`/`.iotContext` directly (`work_order_details_screen.dart:60,98,103,113,120,264-319`) — none of that data exists on the other 2 producers' documents. **Producer 2:** `LotoAutomation.lockoutFailedEquipment()` (`lib/core/automation/loto_automation.dart:36-45`, outside this module) constructs the *simple* `models/work_order.dart` `WorkOrder` (`id`, `title`, `description`, `status: 'Open'`, `scheduledDate` — camelCase, no `work_order_number`/`customer_id`/`priority` at all) and writes it via `.set(workOrder.toJson())` to the same tenant-scoped `work_orders` collection (`loto_automation.dart:45`). A LOTO-generated work order would render in `WorkOrderDetailsScreen` with a blank WO number ("WO: " with nothing after it), an empty Priority card, "Customer ID: " with nothing after it, and a `status` of `'Open'` — not one of the rich model's 8 documented enum values. The simple model's own dedicated Riverpod provider, `workOrdersProvider` (`field_service_providers.dart:5`), is confirmed dead — repo-wide grep shows zero consumers anywhere outside its own declaration — so at least the client-side read half of this shape has no live UI reader at all; only the LOTO writer keeps it alive. **Producer 3:** `iotEngine.ts`'s `iotTelemetryIngest` (`firebase/functions/src/iotEngine.ts:31-42`) writes a third, camelCase-but-different shape (`id`, `title`, `description`, `status: 'OPEN'`, `scheduledDate`, `assetId`, `customerId`) when a temperature reading exceeds 90 — and critically, it writes to `db.collection('work_orders').doc()` (`iotEngine.ts:31`), a **root-level** collection, not `tenants/{tenantId}/work_orders` the way every Dart write path in this module correctly does via `tenantCollection()`/`_tenantDoc`. This is more severe than a field-shape mismatch: a document created this way isn't just malformed, it is **structurally invisible** to `FieldServiceService.streamWorkOrders()`/`streamWorkOrder(id)` (both scoped under `_tenantDoc`, i.e. `tenants/{tenantId}/work_orders`) — no tenant's UI could ever list or open it, regardless of shape. (`work_orders` itself is already correctly declared in `firestore.rules:89`, so this is not a rules gap — Cloud Functions write via the Admin SDK, which bypasses rules entirely regardless.)

**Required fix:** Adopt the `FieldServiceService`/`field_service_models.dart` rich shape as canonical — it's the one with a real UI depending on it (`WorkOrderDetailsScreen`, its Tasks/IoT Context tabs, `WorkOrderForm`). (1) In `loto_automation.dart`, replace the import of `../../features/field_service/models/work_order.dart` (line 5) with the rich model's, and rebuild the constructed object using its schema — at minimum populate `workOrderNumber` (e.g. reuse the existing `'WO-LOTO-${DateTime.now().millisecondsSinceEpoch}'` string, `loto_automation.dart:36`, as the number rather than the document ID), `status` using one of the rich model's real enum values (`'DRAFT'` or `'SCHEDULED'`, not `'Open'`), `priority`, and `customerId` (an equipment-triggered internal work order may have no natural customer — flag as an Open Question rather than guessing a placeholder value if none is obvious), plus `description` mapped to the existing message. (2) In `iotEngine.ts`, fix both the shape (rich snake_case fields: `work_order_number`, `status` using a real enum value, `priority`, `customer_id`, `asset_id`) and the path — change `db.collection('work_orders').doc()` to write under the correct tenant document. This requires the function to know which tenant the triggering `deviceId`/`assetId` belongs to; since `iotTelemetryIngest` is an unauthenticated `onRequest` HTTP endpoint with no tenant context in its current payload (`deviceId`, `assetId`, `customerId`, `telemetry` — `iotEngine.ts:12`), either look up the owning tenant from the `customer_assets`/`iot_devices` document or require the ingest payload to include `tenantId` explicitly — a design decision for whoever implements it, flag rather than guess per AGENTS.md §7. (3) Delete `models/work_order.dart` and `workOrdersProvider`/its line in `field_service_providers.dart` once `loto_automation.dart` no longer references the simple model — reconfirm the zero-consumer grep for both at implementation time first.

**Verification:** Trigger `LotoAutomation.lockoutFailedEquipment()` (via whatever real UI action exists or a debug call) and confirm the resulting `work_orders` document opens correctly in `WorkOrderDetailsScreen` with a real WO number, status, and priority displayed — not blank fields. Deploy the corrected `iotTelemetryIngest` to the emulator, POST a payload with `temperature > 90`, and confirm the resulting document appears under the correct tenant's `work_orders` subcollection (not the Firestore root) and renders correctly when opened. `flutter analyze` after deleting `models/work_order.dart`/`workOrdersProvider` — confirm no new "undefined identifier" errors.

**Resolved 2026-07-30 (residual gap):** the tenant-scoping and `loto_automation.dart` shape fixes above had already landed, but `iotEngine.ts`'s `newWorkOrder` object still wrote 3 fields camelCase (`workOrderNumber`, `assetId`, `customerId`) while `WorkOrder.fromJson` reads everything snake_case — an IoT-triggered work order still rendered with a blank WO number/customer ID even after the path fix. Corrected to `work_order_number`/`asset_id`/`customer_id` to match the canonical shape; `created_at`/`updated_at`/`scheduling.scheduled_start` were already correctly snake_case.

---

### [DONE] F-408: `work_order_list_screen.dart` feeds `WorkOrderDetailsScreen` a hardcoded fake ID — the only reachable path to a real screen always renders "Work Order not found"
**Severity:** Critical
**Module(s) / File(s):** `lib/features/field_service/screens/work_order_list_screen.dart`
**Depends on:** none strictly (F-407's canonical-shape fix isn't required for this item's own verification — one real rich-shape `WorkOrder` document is enough to prove the fix — but implement alongside F-407 for full effect, since LOTO/IoT-created work orders will only display correctly here once that item also lands)
**Source:** `docs/modules/field_service.md` §4, §7; `docs/modules/_known_gaps_rollup.md` §2 (Critical table, same line as F-407)

**Current behavior:** `WorkOrderDetailsScreen` is a genuinely real, working screen — it streams a `WorkOrder` plus its `WorkOrderTask`s from Firestore via `FieldServiceService` and renders them correctly (see F-407). It has exactly one navigation path in the entire app: `work_order_list_screen.dart:66-77`, an `InkWell.onTap` that does `Navigator.push(context, MaterialPageRoute(builder: (context) => WorkOrderDetailsScreen(workOrderId: order['id'] as String)))`. But `work_order_list_screen.dart` never queries Firestore at all — `workOrders` (line 10) is a hardcoded `List<Map>` of 4 literal entries with fabricated IDs (`'WO-2026-101'`, `'WO-2026-102'`, `'WO-2026-103'`, `'WO-2026-104'`, lines 11-38) and fake `requiresPtw`/`ptwCompleted` booleans that don't correspond to any real `safety_requirements` data (consistent with `field_service.md` §5's finding that the PTW gating concept is aspirational-only in this module). None of these 4 IDs was ever written by `FieldServiceService.createWorkOrder()` or any other real path, so `WorkOrderDetailsScreen`'s `service.streamWorkOrder(widget.workOrderId)` call (`work_order_details_screen.dart:37`) always resolves to a document that doesn't exist, and the screen falls into its `workOrder == null` branch (`work_order_details_screen.dart:51-56`): `Center(child: Text('Work Order not found'))`. In practice, the only reachable path to this real, well-built screen can never show real data — a user tapping through the app's normal navigation always hits this dead end, regardless of how many real work orders actually exist in Firestore. The screen's own FAB (lines 167-170) and search action (AppBar, line 44) are also unconfigured `onPressed: () {}` stubs — noted as adjacent context, though this item's core defect is the fake-ID feed, not those 2 stubs.

**Required fix:** Replace the hardcoded `workOrders` list (lines 9-39) with a real stream: convert this screen to a `ConsumerWidget` and `ref.watch` a `StreamProvider` wrapping `FieldServiceService.streamWorkOrders()`, rendering each real `WorkOrder`'s `workOrderNumber`/`status`/`priority` in place of the dummy fields, and passing the real Firestore document ID (`workOrder.id`) into `WorkOrderDetailsScreen(workOrderId: workOrder.id)` instead of a literal string. Since `streamWorkOrders()` currently returns every work order in the tenant with no filtering, decide whether this list should scope to the current technician (mirroring the persona journey's "Receive Work Order" framing) or show the full dispatcher-level list — check `dispatcher_board_screen.dart` for an existing filtering convention to match rather than inventing a new one. The PTW warning banner (lines 111-159) should either be wired to the real `safetyRequirements` map once it exists on real documents, or removed until that data is real, rather than continuing to compute it from fields no real document has. Because the collection may legitimately be empty before any real work order exists, also add a real "Create Work Order" entry point on this screen (FAB, replacing the current stub at lines 167-170) opening `WorkOrderForm` via `UIUtils.showSideSheet` — `WorkOrderForm` is itself fully real and correctly wired to `FieldServiceService.createWorkOrder()`/`updateWorkOrder()` but currently has zero call sites anywhere in the app (confirmed by grep), so without this addition the list would only ever become non-empty via LOTO/IoT-triggered creation.

**Verification:** Create a real work order (via the newly-wired FAB → `WorkOrderForm`, or seeded directly in Firestore under the correct tenant), confirm it appears in `work_order_list_screen.dart`'s list in real time, tap it, and confirm `WorkOrderDetailsScreen` renders the real document instead of "Work Order not found." Confirm the list is empty (not showing the old fake 4 entries) when no real work orders exist for the tenant.

---

### [DONE] F-412: `emergency_broadcast_tab.dart`'s single button is a banned-stub in the most literal sense — a real Cloud Function and Dart wrapper already exist, both unused
**Severity:** Critical
**Module(s) / File(s):** `lib/features/emergency/widgets/emergency_broadcast_tab.dart`
**Depends on:** none (`emergency_drills`/`emergency_equipment` need F-001's rules fix, but `emergency_broadcasts` — this item's target write — goes through a Cloud Function via the Admin SDK, which bypasses `firestore.rules` entirely, so this item has no rules dependency)
**Source:** `docs/modules/emergency.md` §5, §7

**Current behavior:** `EmergencyBroadcastTab`'s entire body is one `FilledButton.icon` labeled "Initialize Test Broadcast" (`emergency_broadcast_tab.dart:42-55`), whose `onPressed` (lines 43-48) is exactly `UIUtils.showToast(context, 'Broadcast system initialized. Configure in FCM.')` — it correctly uses the mandated toast utility rather than a raw `SnackBar`, but calls nothing else. No Cloud Function invocation, no Firestore write, nothing. This is a banned-stub in the most literal sense found across this whole cluster: both halves of a real, correctly-implemented broadcast capability already exist and are simply never called from here. Backend: `sendEmergencyBroadcast` (`firebase/functions/src/index.ts:228-256`, a real `onCall` function) validates the caller is authenticated, sends a real FCM push to topic `site-{siteId}` with high-priority Android/APNs config (lines 238-243), and writes a real audit document to `emergency_broadcasts` (lines 245-251). Dart wrapper: `NotificationService.sendEmergencyBroadcast({required siteId, required message, required emergencyType})` (`lib/core/services/notification_service.dart:144-155`, outside this module) correctly calls `_functions.httpsCallable('sendEmergencyBroadcast')` (line 149) with the right argument shape, and is registered as `NotificationService.provider` (`notification_service.dart:16-18`). Confirmed by grep: `sendEmergencyBroadcast` has exactly 2 real matches in `lib/` — its own Dart wrapper definition, and (in the separate TypeScript codebase) the Cloud Function itself — zero call sites for the Dart method anywhere, including from this tab where it's obviously meant to be called. A user can tap this button believing they've triggered a real emergency broadcast; nothing is sent, and no audit record is created.

**Required fix:** Convert `EmergencyBroadcastTab` to a `ConsumerStatefulWidget` (or wrap the button in a `Consumer`) and wire its `onPressed` to call `ref.read(NotificationService.provider).sendEmergencyBroadcast(siteId: ..., message: ..., emergencyType: ...)` instead of just showing a toast. This needs real inputs the current UI doesn't collect at all — at minimum a message text field and an emergency-type selector (mirroring `drill_form_card.dart`'s `DropdownButtonFormField` pattern for a fixed type list, e.g. Fire/Medical/Security/Evacuation/Other) — add these above the button rather than sending a hardcoded test string, since a real emergency broadcast needs real operator-entered content. `siteId` should be sourced the same way this module's 2 real tabs already do (`ref.read(currentTenantIdProvider)`, per `drill_form_card.dart:44`/`equipment_form_card.dart:39` — though see F-414 for the broader `siteId`-is-really-`tenantId` naming concern, which doesn't block this fix). Keep `UIUtils.showToast` for the success/error feedback, following the exact defensive `isLoading`/try-catch pattern this module's own `DrillFormCard`/`EquipmentFormCard` already use correctly (`drill_form_card.dart:35-69`) — call the real service inside the try block, not just show a toast unconditionally.

**Verification:** From the Emergency Broadcast tab, enter a real message, select a type, tap send, and confirm (a) a push notification is actually dispatched (check via a subscribed test device/emulator, or Firebase console delivery logs) and (b) a new document appears in `emergency_broadcasts` with the correct `siteId`/`message`/`emergencyType`/`sentBy`/`sentAt`. Confirm an error (e.g. simulated network failure) surfaces via the error-styled toast rather than silently succeeding.

---

### System Admin Cluster

### [DONE] F-501: Remove or gate the live "Bypass Login (Dev)" button on the production login screen
**Severity:** Critical
**Module(s) / File(s):** `lib/features/auth/widgets/login_card.dart`, `lib/features/auth/screens/login_screen.dart`, `lib/core/services/auth_service.dart` (`devBypassLogin()`)
**Depends on:** none (independent of F-003, though F-003's claims work is what would make a real dev-bypass path meaningful once claims exist)
**Source:** `docs/modules/auth.md` §7

**Current behavior:** `LoginCard` (`login_card.dart:71-93`) renders a "Bypass Login (Dev)" `ElevatedButton` unconditionally — no `kDebugMode` check, no build-flavor check, no feature flag anywhere in the widget tree between it and the screen. Tapping it calls `LoginScreen._devBypassLogin()` (`login_screen.dart:59-79`), whose entire effective body is:
```dart
ref.read(isMockLoggedInProvider.notifier).state = true;
```
This sets a client-side Riverpod flag directly — it never calls Firebase Auth in any form. Confirmed by tracing `isMockLoggedInProvider` through `app_providers.dart`: `isAuthenticatedProvider` (lines 134-139), `userProfileProvider` (lines 58-84), `currentTenantIdProvider` (lines 109-121), and `userRoleProvider` (lines 142-154) all short-circuit to hardcoded mock values (`dev-admin-123` / `admin` / `sentinel-dev`) whenever this flag is true, entirely independent of `request.auth`. Separately, and confirmed by repo-wide grep, `AuthService.devBypassLogin()` (`auth_service.dart:85-98`) — the method that actually calls `_auth.signInAnonymously()` and would obtain a real (if anonymous) Firebase Auth token — has **zero call sites anywhere in `lib/`**. It is unused dead code; `LoginScreen._devBypassLogin()` is a different, similarly-named method that does not call it. Net effect: anyone with access to a release build of this app can tap one button on the login screen and have the UI render as a fully authenticated `admin` user, while every real Firestore read/write they attempt fails server-side (`firestore.rules`' `isAuthenticated()` requires `request.auth != null`, which remains null throughout this bypassed session) — a client-side security-theatre bypass rather than a working backdoor, but still an unguarded, unauthenticated-looking-authenticated state reachable in production.

**Required fix:** Wrap the button in `login_card.dart` in a `kDebugMode` check (import `flutter/foundation.dart`) so it does not render at all in release builds — the minimal, lowest-risk fix. If local/dev sign-in convenience is still wanted beyond `kDebugMode`, additionally rewire `LoginScreen._devBypassLogin()` to call `ref.read(authServiceProvider).devBypassLogin()` (the real anonymous-auth method) instead of setting `isMockLoggedInProvider` directly — this at least produces a genuine `request.auth` token from Firebase so server-side rule checks are exercised during dev testing, rather than silently no-oping. This second change does not by itself make bypassed sessions fully functional against real tenant-scoped data — that still requires F-003's custom-claims work, since an anonymous Firebase user has no `role`/`tenantId` claims either. At minimum, ship the `kDebugMode` gate; treat the `devBypassLogin()` rewire as a secondary improvement.

**Verification:** Build a release build (`flutter build apk --release` or the equivalent for the target platform) and confirm the "Bypass Login (Dev)" button is not present on `/login`. Run a debug build and confirm it still is. If `devBypassLogin()` is rewired, confirm tapping the button now produces a real anonymous `FirebaseAuth.instance.currentUser` (non-null `uid`) rather than only flipping `isMockLoggedInProvider`.

---

### [DONE] F-507: `OfflineSyncService.initialize()` is never called — the offline write queue throws on first use
**Severity:** Critical
**Module(s) / File(s):** `lib/core/services/offline_sync_service.dart`, `lib/main.dart`, `lib/core/providers/app_providers.dart:20-24`
**Depends on:** none
**Source:** `docs/modules/settings.md` §5, §7

**Current behavior:** `OfflineSyncService._queueBox`/`_cacheBox` (`offline_sync_service.dart:14-15`) are declared `late Box<String>` and assigned only inside `initialize()` (lines 30-46, via `Hive.openBox<String>(...)`). Confirmed by repo-wide grep: `OfflineSyncService.initialize()` has **zero call sites anywhere in `lib/`**. `main.dart` calls `Hive.initFlutter()` (line 83), which only bootstraps the Hive package itself — it never opens these two specific boxes. `offlineSyncServiceProvider` (`app_providers.dart:20-24`) constructs an `OfflineSyncService` instance, but its own doc comment (`/// Offline sync service (initialized in main.dart)`) is false as currently written — nothing in `main.dart` initializes it. Consequence, per Dart's `late` semantics: any code that reaches `_queueBox` before assignment throws `LateInitializationError`. `FirestoreService.createDocument()`/`updateDocument()`/`deleteDocument()` (`firestore_service.dart:122-180`) each call `_offlineSync.queueOperation(...)` → `_queueBox.put(...)` with no guard — confirmed via `grep -rn "\.createDocument("` that this is called from **28 files** across the codebase, meaning every form submission going through the app's officially-documented standard write path throws at the moment of submission, before ever reaching Firestore. Separately, `pendingSyncCountProvider`/`syncStatusProvider` (`app_providers.dart:165-174`) only ever emit from inside `_updateStatus()`, which itself is only invoked by `initialize()`/`queueOperation()`/`retryOperation()`/`removeOperation()` — since `initialize()` never runs, `OfflineQueueScreen`'s `pendingCount.when(...)` (`offline_queue_screen.dart:25`) never leaves its `loading:` branch, so this module's own queue-viewer screen spins forever instead of crashing (the crash only happens once a write is actually attempted elsewhere in the app).

**Required fix:** Call `await ref.read(offlineSyncServiceProvider).initialize()` during app startup in `main.dart`, before `runApp(...)`. The simplest correct approach: build a `ProviderContainer` with the same `firestoreProvider` override already used (`main.dart:110-113`), call `await container.read(offlineSyncServiceProvider).initialize()` on it, then pass that same container into `UncontrolledProviderScope(container: container, child: const XMSystemApp())` instead of a fresh `ProviderScope`, so the initialized instance is the one the rest of the app actually reads. Update `app_providers.dart:20`'s doc comment once this is true. If F-520 (`notifications` cluster) wires `NotificationService` initialization at the same startup point, sequence both initializations together on the same container rather than restructuring `main.dart` twice.

**Verification:** Submit any form that goes through `FirestoreService.createDocument()` (e.g., a Training "Allocate Course" form) and confirm it succeeds instead of throwing `LateInitializationError`. Open `OfflineQueueScreen` (`/offline-queue`) with no pending operations and confirm it shows the real empty state (`EmptyQueueView`) rather than spinning indefinitely. Turn off network connectivity, submit a form, confirm it appears in the offline queue, then restore connectivity and confirm it syncs and disappears from the queue automatically.

---

### [DONE] F-521: Add routing, an auth-redirect exemption, and a tenant-resolution scheme so the public careers portal is actually reachable
**Severity:** Critical
**Module(s) / File(s):** `lib/config/router.dart`, `lib/features/public/screens/public_careers_screen.dart`
**Depends on:** F-001 (rules exemption for `job_requisitions`/`job_applications`), F-002 (tenant-ID handling in `job_application_form.dart`'s write) — this item is the remaining routing/reachability half neither of those touches
**Source:** `docs/modules/public.md` §5, §7, §8

**Current behavior:** `public.md`'s reachability audit confirms this module is blocked at every layer simultaneously; this item addresses the layers F-001 (Firestore rules) and F-002 (the hardcoded tenant ID in `JobApplicationForm._submit()`) don't touch:
1. **No route.** Confirmed by reading `router.dart`'s full import and route list: there is no `import` for `public_careers_screen.dart` and no `GoRoute` for it anywhere in the file. There is no way to navigate to `PublicCareersScreen` from inside the app, and no way to deep-link to it either.
2. **The redirect would block it even if routed.** `router.dart`'s top-level `redirect` callback (lines 82-92) is unconditional: `if (!isAuthenticated && !loggingIn) return '/login';`. The only two routes exempted from this check are `/login` and `/lock` (via the `loggingIn`/`locking` booleans on lines 83-84). Adding a `GoRoute` for the careers screen without also touching this callback would still bounce an unauthenticated visitor straight to `/login` before the screen ever rendered — the opposite of "public."
3. **Tenant resolution has no meaning for a pre-auth visitor.** `PublicCareersScreen` resolves its query target via `ref.watch(currentTenantIdProvider) ?? ""` (`public_careers_screen.dart:40`). `currentTenantIdProvider` (`app_providers.dart:109-121`) derives entirely from an authenticated user's custom claims or Firestore `users/{uid}` profile — a genuine anonymous visitor has neither, so this resolves to `null` → `""`, the same empty-tenant-bucket problem F-002 fixes on the write side, but here on the read side and not yet covered by that item. There is no tenant-slug URL parameter or public lookup mechanism anywhere in this module.

Note: a structurally similar, independently-built, equally-orphaned screen (`PublicCareersPortal`, `lib/features/people/screens/public_careers_portal.dart`) exists in the `people` module — out of scope for this item (belongs to the `people` cluster), but worth being aware of before building a second parallel fix; whoever picks this item up should confirm with the `people` cluster's fix owner whether both are being resolved or just this one.

**Required fix:** Three changes, needed together:
1. Add a `GoRoute` for `PublicCareersScreen` as a **top-level route**, outside the authenticated `ShellRoute` — parallel to `/login`/`/lock` (`router.dart:94-95`), e.g. `GoRoute(path: '/careers/:tenantSlug', builder: (context, state) => PublicCareersScreen(tenantSlug: state.pathParameters['tenantSlug']!))`. Placing it outside the `ShellRoute` matters — routes inside that shell render `AppShell`'s authenticated chrome (header bar, nav), which is wrong for a pre-login public page.
2. Add an exemption to the `redirect` callback (lines 82-92) for this new path, following the same shape as the existing `loggingIn`/`locking` checks: an `isPublicRoute = state.matchedLocation.startsWith('/careers')`-style boolean, short-circuiting before the `!isAuthenticated` check.
3. Resolve tenant scoping for a pre-login visitor. **Decision (resolved 2026-07-28): build proper multi-tenant routing**, not a single-tenant shortcut. Make the tenant identifier part of the URL itself (the `:tenantSlug` path parameter above), and change `PublicCareersScreen` to look up the tenant by that slug (this requires either a public, unauthenticated-readable field on `tenants/{tenantId}` holding a slug, or a small new public lookup collection mapping slug → tenant ID) rather than relying on `currentTenantIdProvider`, which is structurally an authenticated-user concept and cannot be repurposed for this. Coordinate this with F-001's rules work: the `allow read: if true` exemption F-001 adds for `job_requisitions` needs to be scoped per-tenant correctly once a real tenant ID is being resolved this way, not just opened globally.

**Verification:** As a signed-out user (fresh browser session / signed out in-app), navigate directly to the new public URL and confirm `PublicCareersScreen` renders without being redirected to `/login`. Confirm it shows job requisitions for the correct tenant (seed 2 different tenants with different published requisitions and confirm each tenant's slug shows only that tenant's postings). Submit a full application through `JobApplicationForm` (once F-002's fix lands) and confirm it succeeds end-to-end from a genuinely signed-out state.

---

## High

## Wave 2 — High

### Cross-cutting

### [DONE] F-011: Foreign-key fields rendered as plain text fields instead of lookups
**Severity:** High
**Module(s) / File(s):** `lib/features/crm/widgets/opportunity_form.dart`, `quote_form.dart`; `lib/features/finance/widgets/invoice_form.dart`, `journal_entry_form.dart`; `lib/features/field_service/widgets/work_order_form.dart`; `lib/features/supply_chain/widgets/purchase_order_form.dart`; `lib/features/people/widgets/employee_profile_form.dart`
**Depends on:** none
**Source:** `docs/modules/_known_gaps_rollup.md` §1.3; `crm.md`, `finance.md`, `field_service.md`, `supply_chain.md`, `people.md` §7 (DB-to-UI audit tables)

**Current behavior:** Foreign-key-shaped fields are rendered as plain `TextFormField`s a user must hand-type an ID into, instead of a proper lookup widget, in the following places (contrast: `EmployeeSelector` is already the correct, reusable pattern for person-references, used correctly elsewhere in the same codebase — e.g. `risk`'s 4 forms and `equipment`'s form get this right everywhere):
| File | Field(s) | FK target |
|---|---|---|
| `opportunity_form.dart` | `accountId`, `primaryContactId` | `accounts`, `contacts` |
| `quote_form.dart` | `opportunityId`, `accountId` | `opportunities`, `accounts` |
| `invoice_form.dart` | `vendorId`/`customerId`, `journalEntryId` | vendor/customer records, `fin_journal_headers` |
| `journal_entry_form.dart` (line items) | `accountId`, `costCenterId`, `projectId`, `taxCodeId` | `fin_chart_of_accounts`, `costCenters`, `projects`, `fin_tax_codes` |
| `work_order_form.dart` | `customerId`, `assetId`, `territoryId`, `billingAccountId`, `agreementId`, `incidentTypeId`, `serviceTypeId`, `substatusId` | various |
| `purchase_order_form.dart` | `vendorId`, `warehouseId` | vendor records, `warehouses` |
| `employee_profile_form.dart` | `departmentId`, `positionId` | **different sub-case** — already a `DropdownButtonFormField`, not free text, but populated from a hardcoded static item list (HR/IT/FIN/OPS/SALES/SHEQ; Manager/Officer/Technician/Engineer/Specialist/Director) rather than a real `Department`/`JobRole` collection — needs those collections to exist before a real lookup is possible, more than a widget swap |

**Required fix:** For every plain-`TextFormField` instance in the table, replace it with a proper lookup/autocomplete widget following the `EmployeeSelector` pattern (a type-ahead search over the target collection, storing the selected document's ID). If a generic `SearchableStringMultiSelect`-style widget already exists for non-employee lookups (check `lib/core/widgets/` first — `people`'s README mentions `SearchableStringMultiSelect` was used for contractor/asset allocation in `projects`), reuse it rather than building N bespoke widgets. For `employee_profile_form.dart`'s `departmentId`/`positionId`, this is a larger unit of work: decide whether to create real `Department`/`JobRole` Firestore collections (with an admin-facing management screen) before wiring a lookup, or accept the hardcoded list as an intentional simplification — flag as an Open Question if scope is unclear rather than guessing.

**Verification:** For each fixed field, confirm typing a partial name/label in the new widget surfaces matching real records from the target collection, and confirm the submitted document stores the correct ID (not a display string) by inspecting the written Firestore document.

---

### F-012: `Navigator.push`/`MaterialPageRoute` used from Hub screens instead of `UIUtils.showSideSheet`
**Severity:** High
**Module(s) / File(s):** `lib/features/safety/screens/safety_hub_screen.dart`, `lib/features/supply_chain/screens/supply_chain_hub_screen.dart`, `lib/features/projects/screens/project_operations_hub_screen.dart`, `lib/features/customer_service/screens/customer_service_hub_screen.dart`
**Depends on:** none
**Source:** `docs/modules/_known_gaps_rollup.md` §1.5; `.agents/AGENTS.md` §1 ("Deep Sub-Navigation")

**Current behavior:** AGENTS.md §1 mandates `UIUtils.showSideSheet` for opening sub-modules/forms from a Hub screen, specifically prohibiting `Navigator.push`. 4 confirmed violations: `safety_hub_screen.dart`'s "Scan Passport" button opens `QrScannerScreen` via `Navigator.push`; `supply_chain_hub_screen.dart` uses it broadly; `project_operations_hub_screen.dart`'s Gantt/Timesheet/Expense tiles; `customer_service_hub_screen.dart` opening `KnowledgeBaseScreen`.

**Required fix:** In each file, replace the `Navigator.push(context, MaterialPageRoute(builder: (ctx) => TargetScreen(...)))` call with `UIUtils.showSideSheet(context: context, title: '<Title>', builder: (ctx) => const TargetScreen())`, matching the pattern already used correctly by every other tile on the same hub screens (use a working tile on the same screen as the exact template).

**Verification:** Tap each fixed entry point; confirm it now opens as a side sheet sliding in over the current screen (preserving the hub's context/scroll position underneath) rather than replacing the whole screen via a full navigation push.

---

### [DONE] F-013: Raw `ScaffoldMessenger.showSnackBar` used instead of `UIUtils.showToast`
**Severity:** High
**Module(s) / File(s):** `lib/features/billing/screens/billing_portal_screen.dart`; `lib/features/supply_chain/screens/mrp_dashboard_screen.dart`, `production_order_screen.dart`; `lib/features/projects/screens/timesheet_entry_screen.dart`; `lib/features/customer_service/widgets/ticket_form.dart`, `knowledge_article_form.dart`; `lib/features/equipment/screens/loto_management_screen.dart`
**Depends on:** none
**Source:** `docs/modules/_known_gaps_rollup.md` §1.6; `.agents/AGENTS.md` §1

**Current behavior:** 7 files across 5 modules call `ScaffoldMessenger.of(context).showSnackBar(...)` directly instead of the mandated `UIUtils.showToast(context, 'msg', type: ToastType.success/error)`.

**Required fix:** In each file, replace the raw `ScaffoldMessenger`/`SnackBar` construction with the equivalent `UIUtils.showToast` call, picking `ToastType.success` or `ToastType.error` to match the message's intent (check `UIUtils.showToast`'s signature in `lib/core/utils/ui_utils.dart` for the exact parameters).

**Verification:** Trigger each replaced toast (submit the relevant form/action) and visually confirm it renders using the app's standard toast styling, not the default Material SnackBar look.

---

### [DONE] F-014: Navigation Entry Points (`lib/features/people/` and `lib/features/contractors/` missing entry points for QrPassport generation; `lib/features/auth/widgets/login_card.dart` missing `EnterpriseSSOScreen` alternate-auth button; `lib/features/supply_chain/` 3 detail screens + 3 forms orphaned)
**Severity:** High
**Module(s) / File(s):** `lib/features/safety/screens/contractor_qr_passport_screen.dart`, `employee_qr_passport_screen.dart`; `lib/features/auth/screens/enterprise_sso_screen.dart`; `lib/features/operations/screens/inventory_dashboard_screen.dart`; `lib/features/supply_chain/`
**Depends on:** none.
**Source:** `docs/modules/_known_gaps_rollup.md` §1.7; `safety.md`, `auth.md`, `operations.md`, `supply_chain.md` §7

**Current behavior:** Each screen/feature listed is fully implemented (real forms, real service calls, in most cases real BPF ribbon wiring) but has **zero confirmed entry point** anywhere in the app — no route in `router.dart`, no `UIUtils.showSideSheet` call, no button/menu item that opens it. Confirmed via repo-wide search for each class name.

**Required fix:** Add "Generate Passport" button in `employee_360_profile_screen.dart` opening `EmployeeQrPassportScreen`. Add same in `contractor_detail_screen.dart` opening `ContractorQrPassportScreen`. Add SSO entry point to `login_card.dart`. For `supply_chain`'s orphaned screens, determine the intended entry point from its module's persona journey and wire it up from `SupplyChainHubScreen` once F-012's `Navigator.push` fix lands there anyway (do both in the same pass).

**Verification:** From the app's normal navigation (launchpad → hub → sub-screen), reach each previously-orphaned screen without needing to hand-edit a route or call `Navigator.push` from a debug console.


### HR/SHEQ Cluster

### F-101: Reconcile `incident_report_form.dart`'s write shape with `core/models/incident.dart`'s `Incident` model

**Severity:** High
**Module(s) / File(s):** `lib/features/safety/screens/incident_report_form.dart`, `lib/features/safety/widgets/incident_type_severity_fields.dart`, `lib/core/models/incident.dart`
**Depends on:** F-019 (sequence this as part of the same pass that introduces `BaseIncident` and touches `Incident`, per F-019's own "Required fix" — which already commits to "fixing its known field-drift issues in the same pass, since you're already touching this model" — rather than two separate sessions modifying the same model file)
**Source:** `docs/modules/safety.md` §7 (DB-to-UI alignment audit)

**Current behavior:** `incident_report_form.dart`'s submitted document and `core/models/incident.dart`'s `Incident.fromFirestore`/`toFirestore` disagree on nearly every shared field:
- **Value-case mismatch on `type`/`severity`:** the form's dropdowns (`incident_type_severity_fields.dart` lines 18-25: `_types = ['Injury', 'Near Miss', 'Property Damage', 'Environmental', 'Hazard Observation']`, `_severities = ['Minor', 'Moderate', 'Major', 'Critical']`) write capitalized display strings straight to Firestore (`incident_report_form.dart:104-105`: `'type': _type, 'severity': _severity,`), while `Incident`'s documented enum is lowercase snake_case (`injury`/`near_miss`/`property_damage`/`environmental`/`fire`/`chemical` — `incident.dart:9-10`; `critical`/`major`/`moderate`/`minor`/`negligible` — `incident.dart:11`). Note the form's `'Hazard Observation'` type has no equivalent value in the model's enum at all — a sixth mismatch, not just a casing one.
- **`status` mismatch:** form hardcodes `'status': 'Open'` (`incident_report_form.dart:107`); model default is lowercase `'open'` (`incident.dart:33`).
- **`area` never collected:** the form writes `location` (`incident_report_form.dart:106`) but has no field anywhere for `area`, which `Incident` declares as a distinct property (`incident.dart:14, 35, 59, 81, 105, 122`).
- **`lostTimeInjury`/`daysLost` never collected:** absent from the form's data map entirely (`incident_report_form.dart:101-119`) — these are exactly the two fields an LTIFR (Lost Time Injury Frequency Rate) calculation needs, and LTIFR is a named KPI in this module's own analytics screens and the main dashboard.
- **`rootCause`/`immediateAction`/`correctiveAction`/`assigneeId` never written back:** absent from the form; no other screen in `safety` writes them onto the incident document either — `capa_form.dart`'s free-text `rca` field goes to the separate `capas` collection instead.
- **`dateOfIncident`/`createdAt` wrong type:** form writes ISO date strings (`incident_report_form.dart:112-113`: `_dateOfIncident.toIso8601String()`, `DateTime.now().toIso8601String()`); `Incident.fromFirestore` casts both as `Timestamp?` (`incident.dart:60, 68`) — `(data['dateOfIncident'] as Timestamp?)?.toDate()` would throw a type-cast error against a real document this form writes.
- **Orphan fields** present in every real document this form writes but absent from the `Incident` model entirely: `photoUrl`, `isAnonymous`, `directCosts`, `indirectCosts`, `totalCost`, `contractorId`, `reporterName`, `injuryDetails`/`environmentalDetails`/`propertyDamageDetails` (`incident_report_form.dart:109-137`).

None of this has ever crashed anything because, per `safety.md` §5, a repo-wide search found **zero importers of `core/models/incident.dart`** anywhere in `lib/` — nothing currently parses a real document through `Incident.fromFirestore`. Every screen in `safety` (register, detail sheet, analytics) reads the same documents as raw `Map<String, dynamic>` instead, which is precisely why this drift has never surfaced as a runtime error.

**Required fix:** Land this as part of F-019's work on `Incident`, not as a separate pass. When that happens: (1) decide the canonical value set for `type`/`severity`/`status` — either normalize the form's dropdown values to the model's lowercase snake_case enum at write time (change `_types`/`_severities` in `incident_type_severity_fields.dart` and the `'Open'` literal at `incident_report_form.dart:107`), or change the model to match the form's capitalized strings; normalizing the form is the more consistent direction, since lowercase snake_case matches this codebase's other enum conventions (e.g. `EmployeeProfile.employmentStatus`). Also reconcile `'Hazard Observation'` — either add it to the model's `type` enum or fold it into `near_miss`. (2) Add UI fields for `area` (or confirm it's redundant with `location` and drop it from the model) and for `lostTimeInjury`/`daysLost` (a checkbox + number field is enough — these directly feed the LTIFR KPI already displayed elsewhere). (3) Change `_dateOfIncident`/`createdAt` to write `Timestamp` objects instead of ISO strings. (4) Either add the orphan fields (`photoUrl`, `directCosts`, etc.) to `Incident`/`toFirestore`, or explicitly note them as intentionally UI-only/model-excluded. (5) Once shapes agree, migrate at least the Incident Register/Detail screens to parse through `Incident.fromFirestore` instead of raw `Map` access, so future drift throws a compile error instead of silently reappearing.

**Verification:** After normalizing, submit a new incident through `incident_report_form.dart` and confirm `Incident.fromFirestore(doc)` parses the resulting document without throwing (a temporary debug call or a unit test constructing `Incident.fromFirestore` from the write path's output is sufficient). If step 5 is done, confirm the Incident Register/Detail screens still render existing and newly-created incidents correctly — regression-test `safety_analytics_screen.dart`'s KPI cards, which should be able to compute a real LTIFR once `lostTimeInjury`/`daysLost` are populated for the first time.

---

### F-102: `reporterName` hardcoded to the literal string `'Selected Employee'`

**Severity:** High
**Module(s) / File(s):** `lib/features/safety/screens/incident_report_form.dart` (line 109)
**Depends on:** none
**Source:** `docs/modules/safety.md` §7 ("Other" — `reporterName` hardcoded bug); `docs/modules/_known_gaps_rollup.md` §2 (High severity table)

**Current behavior:** `_submitIncident()`'s data map sets `'reporterName': 'Selected Employee'` unconditionally (`incident_report_form.dart:109`) — a literal placeholder string, not the display name of whoever was actually picked via the `EmployeeSelector` bound to `_selectedReporterId` (`incident_basic_info_fields.dart:24-28`, label "Reported By (Optional)"). Every incident document's stored `reporterName` is this same literal text regardless of who reported it, or whether anyone was explicitly selected at all — the field is optional, and `reportedBy` itself correctly falls back to `profile.uid` when `_selectedReporterId` is null (`incident_report_form.dart:108`), but `reporterName` has no equivalent fallback logic; it's just the constant string either way.

One correction worth flagging against already-drafted content: `EmployeeSelector`'s `onChanged` callback (`lib/features/people/widgets/employee_selector.dart:7, 44`) is typed `ValueChanged<String?>` — verified directly against the widget source, it only ever surfaces the selected employee's **ID** to the caller, never a name or full record. F-009 (already drafted, not modified by this item) describes `EmployeeSelector` as "already returns the selected employee's full record, not just an ID — use its `.name`/`.displayName` field rather than a second lookup." That description does not match the widget's actual public API as it exists in source today — there is no such field exposed on the callback. Whoever implements F-009's 3 forms (and this item) will need a real secondary lookup by ID, not a field read off the callback value.

**Required fix:** In `_submitIncident()`, before building `data`, resolve the reporter's display name: if `_selectedReporterId` is non-null, look it up from `ref.read(employeesProvider).valueOrNull` (the same data source `EmployeeSelector` itself renders from — import `lib/features/people/providers/employee_providers.dart` if not already present in this file) and use the matching employee's `.fullName`; if `_selectedReporterId` is null (self-report), fall back to `profile.displayName` (`UserProfile.displayName`, already in scope via the existing `profile` variable at `incident_report_form.dart:86`). Set `reporterName` to that resolved value instead of the literal string.

**Verification:** Submit the form twice — once with a reporter explicitly selected via the dropdown, once leaving it blank (self-report) — and confirm the resulting `incidents` documents' `reporterName` field shows the real selected employee's name in the first case and the logged-in user's own display name in the second, never the literal `'Selected Employee'` string.

---

### F-107: `claims_tab.dart`'s employee field is free text with no `employeeId` captured at all

**Severity:** High
**Module(s) / File(s):** `lib/features/workers_comp/widgets/claims_tab.dart`
**Depends on:** none
**Source:** `docs/modules/workers_comp.md` §7 (DB-to-UI alignment audit)

**Current behavior:** `claims_tab.dart`'s inline claim-creation form binds the employee field to a plain `TextEditingController` (`_empCtrl`, declared at line 22) rendered as a `TextFormField` labeled `'Employee Name *'` (lines 129-134), and writes its raw text directly as `'employeeName': _empCtrl.text.trim()` (line 49). No `employeeId` field is captured or written anywhere in this form — confirmed by inspecting the full `data` map at lines 48-59, and by the file's import list, which (unlike every other create form surveyed in this batch — `bbs_observation_form.dart`, `medical_form.dart`, `first_aid_form.dart`, `record_form_sheet.dart`, `register_doc_form.dart`) does not import `lib/features/people/widgets/employee_selector.dart` at all. A COIDA claim therefore can never be reliably linked back to a real `EmployeeProfile` document — only a free-typed name string exists, with the standard risks of free text (typos, "John Smith" vs. "J. Smith" being treated as different people, no way to programmatically join a claim to that employee's other records, e.g. their `medical_records` or `training_records`).

This is the same "FK rendered as plain `TextFormField`" pattern F-011 fixes elsewhere (`opportunity_form.dart`, `quote_form.dart`, `invoice_form.dart`, `journal_entry_form.dart`, `work_order_form.dart`, `purchase_order_form.dart`, `employee_profile_form.dart`) — `workers_comp` was not included in F-011's file list and needs its own fix here. It is also a categorically different bug from F-009's `employeeName`-missing-on-write pattern elsewhere in this batch: F-009's shape is "ID captured, display name not written back"; this module's shape is "no ID ever captured in the first place," so F-009's fix template (derive `employeeName` from an already-captured `employeeId` at submit time) doesn't directly apply — the input widget itself has to change, not just the submit payload.

**Required fix:** Replace the `TextFormField`/`_empCtrl` pair (lines 129-134) with an `EmployeeSelector` bound to a new `String? _employeeId` state field, following the same pattern already used correctly elsewhere in this codebase (e.g. `first_aid_form.dart`'s `_patientId`/`EmployeeSelector` pairing). In `_submitClaim()` (lines 37-76), write both `'employeeId': _employeeId` and `'employeeName': <resolved fullName>` — look up the name from `ref.read(employeesProvider).valueOrNull` by `_employeeId` (the same lookup pattern F-102 needs for `reporterName`) — instead of the raw controller text. Keep the separate `idNumber` field (lines 138-144) as free text; that's a government ID number, not an employee foreign key, and is already correctly typed. Check `rtw_tab.dart` for any employee-name display logic that assumed free text and update if needed.

**Verification:** Submit a new COIDA claim via the updated form, selecting a real employee from the dropdown; confirm the resulting `coida_claims` document has both a populated `employeeId` matching a real `employees` document and an `employeeName` matching that employee's `fullName`. Confirm `rtw_tab.dart` and the existing claims list in `claims_tab.dart` itself still display the claim correctly after the field change.

---

### SCM Cluster

### F-203: `inventory_item_form.dart` is missing all 4 bin-location fields
**Severity:** High
**Module(s) / File(s):** `lib/features/supply_chain/widgets/inventory_item_form.dart`
**Depends on:** F-001 (`inventory_items` writes are rules-blocked until then; the form edit itself is independent of rules)
**Source:** `docs/modules/supply_chain.md` §7 (DB-to-UI alignment audit: "warehouseId / aisle / rack / bin | Missing")

**Current behavior:** `InventoryItem` has 4 bin-location fields — `warehouseId`, `aisle`, `rack`, `bin` (all nullable strings, `scm_models.dart:35-38`, read at `scm_models.dart:96-99`, written at `scm_models.dart:123-126`) — but none of them appear anywhere in `InventoryItemForm`. The form declares controllers for every other field on the model (`_skuController` through `_stockLevelController`, `inventory_item_form.dart:20-37`) but has no `_warehouseIdController`/`_aisleController`/`_rackController`/`_binController` at all, and its `_submit()` method constructs the `InventoryItem` it saves (`inventory_item_form.dart:132-163`) without ever setting these 4 fields — meaning every item created or edited through this form silently gets `null` for all 4, regardless of prior values on edit. An item can never be assigned a physical storage location through this form.

**Required fix:** Add 4 new fields to the form: a `warehouseId` lookup (following the pattern F-011 already prescribes for FK-as-textfield fields elsewhere in this module — a searchable selector over `ScmService.streamWarehouses()`/`getWarehouses()`, not a plain `TextFormField`) plus plain `TextFormField`s for `aisle`/`rack`/`bin` (these are free-text location codes on the model itself, not foreign keys, so plain text fields are appropriate here — see `docs/schema_scm.md:92-97`'s `locations` sub-collection design for the same free-text convention). Wire all 4 into `_submit()`'s `InventoryItem(...)` construction (`inventory_item_form.dart:132-163`) and into `initState()`'s controller initialization from `widget.initialData` (`inventory_item_form.dart:44-102`), following the exact pattern already used for every other field in this form.

**Verification:** Create or edit an inventory item through this form (directly instantiate it in a debug harness or side sheet if F-014 hasn't yet made it reachable through normal navigation), set a warehouse and bin/aisle/rack values, save, and confirm the resulting Firestore document has all 4 fields populated — re-open the form against that same item and confirm the values round-trip correctly instead of showing blank.

---

### F-204: `itemType`/`valuationMethod` rendered as free text instead of the schema's closed enums
**Severity:** High
**Module(s) / File(s):** `lib/features/supply_chain/widgets/inventory_item_form.dart`
**Depends on:** F-001 (same collection as F-203 — implement together if both are being fixed in the same pass)
**Source:** `docs/modules/supply_chain.md` §7 (DB-to-UI alignment audit: "itemType | Wrong widget", "valuationMethod | Wrong widget"); `docs/schema_scm.md:17,21`

**Current behavior:** `itemType` (`_itemTypeController`, `inventory_item_form.dart:241-246`) and `valuationMethod` (`_valuationMethodController`, `inventory_item_form.dart:278-283`) are both plain `TextFormField`s a user must hand-type into, even though `docs/schema_scm.md` specifies both as closed enums: `item_type` is `RAW_MATERIAL`/`COMPONENT`/`SUB_ASSEMBLY`/`FINISHED_GOOD`/`CONSUMABLE`/`ASSET` (`docs/schema_scm.md:17`) and `valuation_method` is `FIFO`/`LIFO`/`AVERAGE_COST`/`STANDARD_COST` (`docs/schema_scm.md:21`). This is inconsistent with the same form's own `lifecycleStatus` field, which correctly uses a `DropdownButtonFormField` (`inventory_item_form.dart:436-448`) — so the correct pattern already exists one field away in the same file. Free text here risks values downstream code can't classify, and offers no guardrail against typos in a field meant to drive costing logic.

**Required fix:** Replace both `TextFormField`s with `DropdownButtonFormField<String>`s, mirroring `_lifecycleStatus`'s existing implementation exactly (`inventory_item_form.dart:436-448`): a `String _itemType`/`String _valuationMethod` state variable initialized from `widget.initialData` (falling back to a sensible default, e.g. `'FINISHED_GOOD'`/`'FIFO'`), a fixed `items` list built from the enum values above, and an `onChanged` callback calling `setState`. Remove the now-unused `_itemTypeController`/`_valuationMethodController` and their `dispose()` calls.

**Verification:** Open the form, confirm both fields render as dropdowns offering exactly the schema doc's enum values, save an item, and confirm the stored `item_type`/`valuation_method` values match one of the enum options rather than arbitrary typed text.

---

### F-205: Supply Chain hub's 3 sub-screens are hardcoded `ListTile`s with no `onTap` handlers
**Severity:** High
**Module(s) / File(s):** `lib/features/supply_chain/screens/inventory_dashboard.dart`, `warehouse_management_screen.dart`, `asset_management_screen.dart`
**Depends on:** none
**Source:** `docs/modules/_known_gaps_rollup.md` §2 (High table: "supply_chain | Hub screen (InventoryDashboard, WarehouseManagementScreen, AssetManagementScreen) is hardcoded ListTiles with no onTap handlers — the first screens reached from the Supply Chain tile"); `docs/modules/supply_chain.md` §4, §7

**Current behavior:** All three screens reached from `SupplyChainHubScreen`'s first three cards are `StatelessWidget`s built entirely from literal `ListView`/`Card`/`ListTile` trees with no Firestore access and no `onTap` at all (confirmed by reading each file in full): `InventoryDashboard` (`inventory_dashboard.dart:1-38`) shows fake "3 items below minimum threshold" and "5 pending approval" subtitles; `WarehouseManagementScreen` (`warehouse_management_screen.dart:1-38`) shows 3 static tiles ("Bin Locations," "Stock Movements," "Barcode Scanning"); `AssetManagementScreen` (`asset_management_screen.dart:1-45`) shows 4 static tiles ("Property Management," "Equipment Tracking," "Preventative Maintenance," "Asset Lifecycle"). These are the very first screens a user reaches after tapping the "Supply Chain" launchpad tile — an AGENTS.md §2 "No Hardcoded Data" violation on the module's main landing surface.

**Required fix:** Make each tile real, using data and destinations that already exist elsewhere in the app rather than inventing new backing concepts:
- `InventoryDashboard`: "Low Stock Alerts" → stream `inventory_items` and compute a real count where `stockLevel <= reorderPoint`; "Material Requirements Planning" → either stream real `mrp_suggestions` counts or simply deep-link to the already-real, already-routed `MrpDashboardScreen` (`/mrp-dashboard`) — per `supply_chain.md` §8's own open question, this card arguably shouldn't exist as a separate static surface once `MrpDashboardScreen` covers the same ground; "Purchase Orders" → stream a real count from `purchase_orders` where `status` indicates pending approval, `onTap` opening `PurchaseOrderDetailScreen`/a list (coordinate with F-014, which is what makes that screen reachable).
- `WarehouseManagementScreen`: "Bin Locations" → tie to F-206's new Bin Locations screen once built; "Stock Movements" → stream real `transfer_orders`, `onTap` into `TransferOrderDetailScreen`/`TransferOrderForm` (coordinate with F-014); "Barcode Scanning" → deep-link to the already-real, already-routed `WmsScannerScreen` (`/wms-scanner`).
- `AssetManagementScreen`: "Property Management" → deep-link to the already-real, fully-working `/properties` route; "Equipment Tracking" → deep-link to `/equipment` (coordinate with F-214, which adds this route); "Preventative Maintenance"/"Asset Lifecycle" → these don't have an obvious existing real backing surface in this module — either stream real counts from `assets`/`ScmService.streamAssets()` if a reasonable interpretation exists, or flag as an Open Question rather than inventing fake functionality to fill the tile.

Since `SupplyChainHubScreen`'s cards currently open via `Navigator.push` (a separate AGENTS.md §1 violation fixed by F-012), whichever of F-012 or this item lands first should leave the other's `onTap`/navigation call in the correct `UIUtils.showSideSheet` shape — don't reintroduce `Navigator.push` if F-012 has already landed.

**Verification:** From each of the 3 screens, confirm every tile's subtitle reflects a real, seeded number (not a literal string) and confirm tapping each tile navigates somewhere real, not nothing.

---

### F-206: Wire "Vendor Performance" and "Bin Locations" hub cards to the existing, unused `ScmService` CRUD
**Severity:** High
**Module(s) / File(s):** `lib/features/supply_chain/screens/supply_chain_hub_screen.dart`; new screen files (e.g. `vendor_performance_screen.dart`, `bin_locations_screen.dart`) under `lib/features/supply_chain/screens/`
**Depends on:** F-001 (`warehouseBinLocations`/`vendorPerformanceMetrics` writes are rules-blocked until then; reads already work via the tenant catch-all)
**Source:** `docs/modules/_known_gaps_rollup.md` §2 (High table: "supply_chain | 2 literal 'Coming Soon' stub cards sit next to fully-written, unused ScmService CRUD for the same features"); `docs/modules/supply_chain.md` §4, §5, §7

**Current behavior:** Two of `SupplyChainHubScreen`'s five cards open literal placeholder scaffolds: `Center(child: Text('Vendor Performance — Coming Soon'))` (`supply_chain_hub_screen.dart:37-44`) and `Center(child: Text('Bin Locations — Coming Soon'))` (`supply_chain_hub_screen.dart:45-52`) — an AGENTS.md §3 banned-stub pattern. Both have complete, working CRUD already implemented and completely unused: `ScmService.streamVendorPerformanceMetrics`/`getVendorPerformanceMetrics`/`createVendorPerformanceMetric`/`updateVendorPerformanceMetric`/`deleteVendorPerformanceMetric` (`scm_service.dart:340-378`) over the `VendorPerformanceMetric` model (`scm_models.dart:478-538`), and `ScmService.streamBinLocations`/`getBinLocations`/`createBinLocation`/`updateBinLocation`/`deleteBinLocation` (`scm_service.dart:300-332`) over the `WarehouseBinLocation` model (`scm_models.dart:411-476`). Neither has a single caller anywhere outside `scm_service.dart` itself (confirmed by grep, per `supply_chain.md` §5).

**Required fix:** Build two real screens — following the same file-per-card pattern the hub already uses for its other three cards (`inventory_dashboard.dart`, `warehouse_management_screen.dart`, `asset_management_screen.dart`), not inline widgets in the hub file itself, per AGENTS.md §4's 200-line/micro-widget rules. Each should be a real list view streaming its respective collection (`streamVendorPerformanceMetrics()`/`streamBinLocations()`) with a create/edit form using the service's existing `create`/`update` methods (no new backend work needed, only UI). Replace the two `Center(child: Text(...))` placeholders at `supply_chain_hub_screen.dart:37-52` with these new screens.

**Verification:** Tap "Vendor Performance" and "Bin Locations" from the hub; confirm both now show real (possibly empty) lists backed by live streams instead of static text, and confirm a record created through each new form appears in the list immediately and persists in Firestore under the correct collection.

---

### F-209: `constructionDate` is tracked in form state but never rendered in the Property form UI
**Severity:** High
**Module(s) / File(s):** `lib/features/property/widgets/property_form_sheet.dart`
**Depends on:** F-001 (`properties` writes are rules-blocked until then; the form edit itself is independent of rules)
**Source:** `docs/modules/property.md` §7 (DB-to-UI alignment audit: "constructionDate | Missing"), §8

**Current behavior:** `_PropertyFormSheetState` declares `DateTime? _constructionDate` (`property_form_sheet.dart:33`), initializes it from the existing property or `DateTime.now()` (`property_form_sheet.dart:53`), and writes it into the submitted document (`'constructionDate': _constructionDate?.toIso8601String()`, `property_form_sheet.dart:92`) — but no widget anywhere in `build()` (`property_form_sheet.dart:108-245`) ever reads or renders `_constructionDate`: no `ListTile`/`showDatePicker` exists for it, unlike the correctly-implemented date pickers used elsewhere (e.g. `supply_chain`'s `PurchaseOrderForm`, `purchase_order_form.dart:186-201`). Unlike `supply_chain`'s equivalent orphaned-form gaps, this form is live and reachable (`PropertyHubScreen`/`PropertyDetailsScreen` both open it correctly today) — every new property silently gets today's date baked in with no way for the user to set anything else, and an existing property's construction date can never be changed through the UI.

**Required fix:** Add a `ListTile`+`showDatePicker` control for `_constructionDate` to the form, following the exact pattern already used correctly in this codebase (e.g. `purchase_order_form.dart:186-201`'s "Order Date" `ListTile`) — place it near the other property-attribute fields (after `status`, `property_form_sheet.dart:196-200`, is a reasonable spot). No model or write-path change is needed; `constructionDate` is already read, stored, and typed correctly (`property_models.dart:15,52-54`) — only the missing UI control needs to be added.

**Verification:** Open "Add Property" and "Edit Property," confirm a construction-date picker is now visible and interactive, set/change it, save, and confirm the persisted value reflects the chosen date rather than always being today's date.

---

### F-210: `Property.status` is a free-text field despite being treated as a closed set everywhere it's read
**Severity:** High
**Module(s) / File(s):** `lib/features/property/widgets/property_form_sheet.dart`
**Depends on:** F-001 (same collection as F-209 — implement together if both are being fixed in the same pass)
**Source:** `docs/modules/property.md` §7 (DB-to-UI alignment audit: "status | Wrong widget")

**Current behavior:** `status` is a plain `TextFormField` (`property_form_sheet.dart:197-200`), but every downstream reader treats it as a fixed set of known values: `PropertyCard` does `property.status == 'Optimal'` and `.contains('Critical')` for status-color logic (`property_card.dart:16,18`), `PropertyHeroHeader` passes it into similar status-driven styling (`property_hero_header.dart:63`), and `PropertyHubScreen`'s own "Critical Alerts" dashboard stat is computed as `properties.where((p) => p.status.contains('Critical')).length` (`property_hub_screen.dart:117-118`) — a case-sensitive substring match. Because entry is unconstrained free text, any deviation in case or wording (e.g. a manager typing "critical issue" instead of the expected "Critical") would silently fail to match, undercounting the portfolio's own "Critical Alerts" KPI on its primary dashboard without any error or indication that it happened.

**Required fix:** Replace the `TextFormField` at `property_form_sheet.dart:197-200` with a `DropdownButtonFormField<String>` over the values the codebase's own read-side logic already implies are meaningful — at minimum `'Optimal'` and a `'Critical'`-containing value (e.g. `'Critical'`, plus whatever intermediate states the product intends, such as `'Warning'`/`'Under Review'`); confirm the full intended set with whoever owns the product decision if it's not obvious from the read-side code alone, rather than guessing a complete enum. Follow the same `String _status` state-variable + fixed `items` list pattern used correctly elsewhere in this codebase (e.g. `inventory_item_form.dart:436-448`'s `_lifecycleStatus` dropdown).

**Verification:** Open the form, confirm `status` now renders as a dropdown constrained to the agreed value set, and confirm `PropertyHubScreen`'s "Critical Alerts" count and `PropertyCard`'s status color both respond correctly and consistently to every property's status after the change.

---

### [DONE] F-212: Build write UIs for Property's 5 read-only child sub-collections
**Severity:** High
**Module(s) / File(s):** `lib/features/property/widgets/property_facility_tab.dart` (2 sub-collections), `property_assets_tab.dart`, `property_leases_tab.dart`, `property_esg_tab.dart`; new form widgets for each
**Depends on:** F-001 (all 5 target collections — `property_projects`, `legal_appointments`, `property_assets`, `property_leases`, `property_utilities` — are rules-blocked until then)
**Source:** `docs/modules/property.md` §4, §7 ("Five child sub-collections have real read UIs but zero write UIs anywhere")

**Current behavior:** `PropertyFacilityTab`, `PropertyAssetsTab`, `PropertyLeasesTab`, and `PropertyEsgTab` all stream real, live, correctly-typed data — `propertyProjectsProvider`, `propertyAppointmentsProvider`, `propertyAssetsProvider`, `propertyLeasesProvider`, `propertyUtilitiesProvider` (all family providers in `property_providers.dart:22-110`) — and render it correctly (confirmed by reading each tab file in full). But none of the 5 models these tabs display — `PropertyProject`, `LegalAppointment`, `AssetInfo`, `LeaseInfo`, `UtilityUsage` (all in `property_models.dart`) — has any corresponding create/edit form anywhere in the module (confirmed by grep: no `Form`/`showModalBottomSheet`/`showDialog` construction referencing any of these 5 types exists anywhere in `lib/features/property/`). Every one of these 5 tabs can only ever show real data if it's seeded out-of-band (Firestore console or a script) — never through the shipped app, for any tenant.

**Required fix:** Build one create form per sub-collection (5 total), each following `PropertyFormSheet`'s existing direct-Firestore-write pattern (`firestore.tenantCollection(tenantId, '<collection>').add(data)` — this module has no dedicated service layer and none is required to stay consistent, per `property.md` §5) and opened via `UIUtils.showSideSheet` (not `showModalBottomSheet` — build these new forms using the correct pattern from the start rather than copying `PropertyFormSheet`'s current incorrect call shape; see F-213 for that separate fix). Checklist, one add-entry-point per tab:
- [ ] `PropertyProject` create form (fields: `title`, `type`, `description`, `status`, `assigneeId` [use `EmployeeSelector`], `dueDate`, `progress`) → add button on `PropertyFacilityTab`'s "Facility Projects & Maintenance" section (`property_facility_tab.dart:166-177`)
- [ ] `LegalAppointment` create form (fields: `role`, `personId` [use `EmployeeSelector`, matching `PropertyFormSheet`'s existing `managerId` pattern], `status`, `expiry`) → add button on `PropertyFacilityTab`'s "Legal Appointments" section (`property_facility_tab.dart:179-198`)
- [ ] `AssetInfo` create form (fields: `name`, `category`, `condition`, `lastInspected`) → add button on `PropertyAssetsTab` (`property_assets_tab.dart`)
- [ ] `LeaseInfo` create form (fields: `tenantId`, `monthlyRent`, `startDate`, `endDate`, `status`) → add button on `PropertyLeasesTab` (`property_leases_tab.dart`)
- [ ] `UtilityUsage` create form (fields: `month`, `electricity`, `water`, `waste`, `carbon`) → add button on `PropertyEsgTab` (`property_esg_tab.dart`)

Every write must set `propertyId` to the parent property's ID (the pattern each provider already filters on, e.g. `property_providers.dart:30,48,66,86,104`).

**Verification:** For each of the 5, create one real record through its new form from a property's detail screen and confirm it immediately appears on the corresponding tab (real-time, no manual refresh), and confirm the Firestore document exists under the correct tenant-scoped collection with `propertyId` correctly set.

---

### F-213: Property Hub/Details screens use `showModalBottomSheet` instead of `UIUtils.showSideSheet`
**Severity:** High
**Module(s) / File(s):** `lib/features/property/screens/property_hub_screen.dart`, `property_details_screen.dart`
**Depends on:** none
**Source:** `docs/modules/property.md` §4, §7 ("showModalBottomSheet used directly instead of UIUtils.showSideSheet for both Add and Edit")

**Current behavior:** `PropertyHubScreen`'s "Add Property" button calls `showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => const PropertyFormSheet())` directly (`property_hub_screen.dart:36-42`), and `PropertyDetailsScreen`'s edit icon does the same with `PropertyFormSheet(property: property)` (`property_details_screen.dart:58-64`) — both bypass `UIUtils.showSideSheet`. This is confirmed against the actual `showSideSheet` implementation in `lib/core/utils/ui_utils.dart`, which adds responsive wide-screen side-sheet behavior these calls skip entirely. `property` is not among the 4 files F-012 already covers (`safety_hub_screen.dart`, `supply_chain_hub_screen.dart`, `project_operations_hub_screen.dart`, `customer_service_hub_screen.dart`) — this is the same AGENTS.md §1 rule violated through a different Flutter API (`showModalBottomSheet` vs. `Navigator.push`/`MaterialPageRoute`), so it needs its own fix rather than being picked up incidentally by F-012.

**Required fix:** Replace both calls with `UIUtils.showSideSheet(context: context, title: 'Add Property', builder: (ctx) => const PropertyFormSheet())` and `UIUtils.showSideSheet(context: context, title: 'Edit Property', builder: (ctx) => PropertyFormSheet(property: property))` respectively, matching the exact call shape F-012 already prescribes for its own Navigator.push fixes. `PropertyFormSheet`'s `build()` currently wraps its content in bottom-sheet-shaped padding assumptions (`Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, ...))`, `property_form_sheet.dart:109-115`) and calls `Navigator.pop(context)` on submit (`property_form_sheet.dart:104`) — confirm this still renders and dismisses correctly inside a side sheet's container once the call site changes; adjust if `showSideSheet`'s content-widget conventions differ (check a corrected F-012 call site as the reference for expected shape).

**Verification:** Tap "Add Property" and the edit icon; confirm both now open as a side sheet (sliding in over the current screen, preserving context underneath) rather than a bottom sheet, consistent with every other correctly-implemented hub screen, and confirm the form still submits and dismisses correctly from inside it.

---

### F-216: `AssetDetailScreen`'s edit button is a literal no-op
**Severity:** High
**Module(s) / File(s):** `lib/features/equipment/screens/asset_detail_screen.dart`; `lib/features/equipment/widgets/equipment_asset_tab.dart` (form fields to reuse)
**Depends on:** none
**Source:** `docs/modules/_known_gaps_rollup.md` §1.7 (context); `docs/modules/equipment.md` §4, §7 ("AssetDetailScreen's edit button is a literal no-op — a banned stub more blatant than the 'coming soon' toast pattern seen elsewhere, since it gives no feedback at all")

**Current behavior:** `AssetDetailScreen`'s AppBar edit action is `IconButton(icon: const Icon(Icons.edit), onPressed: () {})` (`asset_detail_screen.dart:34-39`) — a literal empty callback giving no feedback at all, not even a toast. This is confirmed as the single most blatant AGENTS.md §3 "unconfigured onPressed callback" violation found across this session's 4-module scope. Equipment items can be created through `EquipmentAssetTab`'s real inline form (`equipment_asset_tab.dart`) but never subsequently edited anywhere in the app — creation is the only write path that exists.

**Required fix:** Wire this button to a real edit flow. The cleanest reuse is `EquipmentAssetTab`'s own inline create-form fields (`equipment_asset_tab.dart:157-301`) — factor them into a reusable form widget parameterized by an optional `EquipmentModel? initialData` (mirroring the `initialData`-constructor pattern already used correctly by `supply_chain`'s `InventoryItemForm`/`PurchaseOrderForm`), and open it from this button via `UIUtils.showSideSheet` (per AGENTS.md §1 — not `showDialog`/`Navigator.push`), pre-filled from the `asset` (`EquipmentModel`) this screen already has loaded, writing via `.doc(assetId).update(asset.toMap())` on submit with the standard defensive `isLoading`/try-catch pattern.

**Verification:** Open an existing equipment item's detail screen, tap Edit, change a field (e.g. `location`), submit, and confirm the detail screen reflects the change immediately without needing to leave and re-enter the screen manually.

---

### F-217: `MaintenanceLogDialog` is a fully static placeholder
**Severity:** High
**Module(s) / File(s):** `lib/features/equipment/widgets/maintenance_log_dialog.dart`
**Depends on:** none
**Source:** `docs/modules/equipment.md` §4, §7, §8

**Current behavior:** `MaintenanceLogDialog` (`maintenance_log_dialog.dart`, all 63 lines) performs no Firestore query at all — it's a static icon-and-text placeholder regardless of which equipment item or tenant is viewing it, despite occupying the "Maintenance" tab of `EquipmentManagementScreen` as if it were functional. Its "Open Work Orders" button (`maintenance_log_dialog.dart:44-56`) calls `UIUtils.showToast(context, 'Connecting to Work Order Management...')` — correctly uses the mandated toast utility (unlike several other stubs found in this scope), but performs no real navigation or query. There is a real, working collection and model to build against: `field_service`'s `work_orders` is already correctly declared in `firestore.rules` (`equipment.md` §5 confirms this directly), and this same module's own `LotoAutomation.lockoutFailedEquipment()` (`loto_automation.dart`) already successfully constructs and writes real `WorkOrder` documents to it — so a working reference implementation for the write shape already exists one file away.

**Required fix:** Replace the static content with a real query against `work_orders`, filtered to whatever field associates a work order with a specific equipment item (check `field_service`'s `WorkOrder` model, `lib/features/field_service/models/work_order.dart`, and `LotoAutomation.lockoutFailedEquipment()`'s own construction of a `WorkOrder` for the correct linking field to query on) and render real open work orders for the asset as a list. The "Open Work Orders" button's real job should become either navigating into `field_service`'s own work order detail screen, or simply becoming redundant once the tab itself shows real data live — check whether `field_service`'s detail screen is reachable and correctly fed a real ID before wiring a deep link into it (per `field_service.md`'s own findings, that screen has separately been fed a hardcoded fake ID elsewhere in the app, which is out of scope for this fix but worth confirming isn't also broken before depending on it).

**Verification:** Create a real `WorkOrder` linked to a specific equipment item, open that equipment's Maintenance tab, and confirm the real work order appears instead of the static placeholder text.

---

### F-219: Contractor status filter is permanently broken by a case-sensitivity mismatch
**Severity:** High
**Module(s) / File(s):** `lib/features/contractors/widgets/add_contractor_form.dart`
**Depends on:** none
**Source:** `docs/modules/contractors.md` §5, §7 (DB-to-UI alignment audit note: "the status/complianceStatus bug is a case-mismatch with the reader, not a form defect")

**Current behavior:** `AddContractorForm._submit()` writes `'status': _status.toLowerCase()` and `'complianceStatus': _complianceStatus.toLowerCase()` (`add_contractor_form.dart:61-62`), even though both are selected from capitalized-value dropdowns (`['Active', 'Inactive', 'Suspended']`, `add_contractor_form.dart:180-184`; `['Compliant', 'Non-compliant', 'Pending']`, `add_contractor_form.dart:196-201`). `ContractorManagementScreen`'s status filter dropdown independently offers capitalized values (`['All', 'Active', 'Inactive', 'Suspended']`, `contractor_management_screen.dart:113`), and `ContractorList` filters via case-sensitive equality (`data['status'] == widget.statusFilter`, `contractor_list.dart:58`) — since stored values are always lowercase and the filter is always capitalized, this equality can never be true. Selecting any specific status filter always returns zero results, regardless of how many contractors actually have that status. A second, previously undocumented consequence of the same lowercasing: `ContractorList`'s own status chip performs the identical case-sensitive comparison for its color (`GStatusTag(label: status, color: status == 'Active' ? XMTheme.success : XMTheme.error)`, `contractor_list.dart:125-131`) — so every contractor's status chip, active or not, always renders in the error color, and its label text always displays in lowercase (`'active'`) instead of the capitalized form used everywhere else in the UI. (`riskRating` has no equivalent mismatch — written and read with matching case, per `contractors.md` §5/§7.)

**Required fix:** Remove `.toLowerCase()` from both writes at `add_contractor_form.dart:61-62`, storing `_status`/`_complianceStatus` exactly as selected from their dropdowns. This single-point fix corrects both the filter comparison (`contractor_list.dart:58`) and the status chip's color/label display (`contractor_list.dart:125-131`) simultaneously, since both already expect capitalized values. Do not instead lowercase the filter/comparison side — that would only fix the filter and leave the status-chip color bug unfixed. Existing contractor documents already written with lowercase values will need either a one-time data backfill or a defensive case-insensitive comparison at read time as a stopgap, to remain correctly filterable/colored after this fix — flag this to whoever implements it.

**Verification:** Add a contractor with status "Active," confirm its status chip renders in the success color with label "Active" (not lowercase "active"). Apply the "Active" filter in `ContractorManagementScreen` and confirm this contractor (and only contractors with that exact status) now appears, where previously the filter always returned zero results regardless of selection.

---

### F-221: Wire up `AiComplianceService.triggerPreScreen()` — AI pre-screen can never be triggered from the UI
**Severity:** High
**Module(s) / File(s):** `lib/features/contractors/widgets/safety_file_submission_view.dart`; `lib/features/contractors/services/ai_compliance_service.dart` (no changes needed — already correct)
**Depends on:** none
**Source:** `docs/modules/contractors.md` §5, §7 ("AI pre-screen trigger path (triggerPreScreen) unreachable — only the display side works")

**Current behavior:** `AiComplianceService.triggerPreScreen(documentId, documentUrl)` (`ai_compliance_service.dart:30-45`) is a real, working implementation calling the deployed `preScreenComplianceDocument` Cloud Function (confirmed to exist at `functions/src/prescreen_compliance.ts`, exported from that codebase's `index.ts`, per `contractors.md` §5). But `triggerPreScreen` has exactly one match anywhere in `lib/` — its own definition — confirmed by grep, zero callers. Only the read/display side works: `AiPreScreenBadge` (instantiated per document at `safety_file_submission_view.dart:224`) streams any pre-existing `compliance_prescreens` result via `compliancePreScreenProvider`/`streamPreScreenResult()` (`ai_compliance_service.dart:18-21,47-59`), but nothing in the shipped UI ever creates a *new* one — a document uploaded today shows `AiPreScreenBadge`'s empty/no-result state forever, not because the AI check failed, but because it was never asked to run.

**Required fix:** Add a UI trigger calling `ref.read(aiComplianceServiceProvider).triggerPreScreen(documentId, documentUrl)`. The natural entry point is next to each document row in `SafetyFileSubmissionView`'s document list (`safety_file_submission_view.dart:208-234`, alongside the existing "Review" button and `AiPreScreenBadge`) — e.g. an "AI Pre-Screen" icon button that calls it on tap and drives `AiPreScreenBadge` into a loading state until the stream resolves. `documentUrl` is already available on `ContractorDocument.url` (`safety_file_models.dart:148`). Wrap the call in the standard defensive try/catch + `isLoading` pattern per AGENTS.md §1, surfacing failures via `UIUtils.showToast`.

**Verification:** Upload a contractor document, tap the new "AI Pre-Screen" trigger, and confirm `AiPreScreenBadge` transitions from empty/loading to a real result once the Cloud Function completes and writes to `compliance_prescreens`, without needing to seed that result manually.

---

### F-222: Wire `FindingListItem`/`FindingUpdateDialog` into the UI — findings are currently write-only
**Severity:** High
**Module(s) / File(s):** `lib/features/contractors/widgets/safety_file_submission_view.dart`; `lib/features/contractors/widgets/finding_list_item.dart`, `finding_update_dialog.dart` (no changes needed); `lib/features/contractors/widgets/document_review_dialog.dart` (related fix, see below)
**Depends on:** none
**Source:** `docs/modules/contractors.md` §5, §7 ("Finding/FindingListItem/FindingUpdateDialog form a write-only pipeline — created findings are never displayed or updatable anywhere")

**Current behavior:** `DocumentReviewDialog._submitReview()` (`document_review_dialog.dart:43-94`) does write real documents to the `findings` collection (lines 67-89), matching the rules-declared collection name exactly — but omits `Finding`'s own `requirementId`/`siteId` fields entirely (both `required` on the `Finding` constructor, `safety_file_models.dart:13,24,30,32`), which are defensively defaulted to `0`/`''` by `Finding.fromFirestore` (`safety_file_models.dart:50-51`) rather than throwing, so this doesn't crash — it just silently produces findings with meaningless `requirementId`/`siteId` values. More significantly: `FindingListItem` (`finding_list_item.dart`) and `FindingUpdateDialog` (`finding_update_dialog.dart`) — real, purpose-built list-display and status-update widgets for exactly this `findings` data — have zero callers anywhere in the app outside their own files (confirmed by grep for both class names). A finding can be created through `DocumentReviewDialog`'s review flow but never subsequently viewed as a list or have its status updated through any screen.

**Required fix:** Wire `FindingListItem`/`FindingUpdateDialog` into `SafetyFileSubmissionView` — e.g. a findings list per document (or per submission), rendered below/alongside the existing document list (`safety_file_submission_view.dart`'s `ListView.builder`, lines 208-234), streaming `findings` filtered by `documentId`/`submissionId`, each row using `FindingListItem` and opening `FindingUpdateDialog` on tap for status changes. While touching this area, also fix `DocumentReviewDialog._submitReview()` to populate `requirementId`/`siteId` on the `findings` write — `siteId` is already available via `ref.read(currentTenantIdProvider)` (the same tenant-scoping value used elsewhere in this file); `requirementId` needs a real source — check whether `ContractorDocument` or its parent submission carries a requirement reference anywhere in the model, and if not, treat as an Open Question rather than inventing a value.

**Verification:** Submit a document review with feedback (creating a `Finding`), confirm it now appears in a findings list somewhere in the UI (not only in Firestore), and confirm `FindingUpdateDialog` can change its status and that the change persists and is reflected back in the list.

---

### F-223: Build real Compliance and Inductions tabs (currently static placeholders)
**Severity:** High
**Module(s) / File(s):** `lib/features/contractors/screens/contractor_management_screen.dart`; `lib/features/contractors/widgets/contractor_compliance_card.dart`; `firestore.rules` (new collection needed for Inductions — see Required fix)
**Depends on:** none (the Inductions half requires adding its own new firestore.rules entry as part of this item, since no such collection exists yet for F-001 to have enumerated)
**Source:** `docs/modules/contractors.md` §4, §7 ("Two of the screen's three tabs (Compliance, Inductions) are static placeholders")

**Current behavior:** `ContractorManagementScreen`'s Compliance tab renders `const ContractorComplianceCard()` (`contractor_management_screen.dart:79`), a fully static `StatelessWidget` (`contractor_compliance_card.dart`, all 34 lines) — an icon, a heading, and the caption "Insurance certificates, tax clearance, safety files," no query, no data — despite the real underlying data (`SafetyFileSubmissionView`/`contractor_documents`/`safety_file_submissions`) already existing and working correctly one tap further into `ContractorList` → `ContractorProjectsSheet`. The Inductions tab (`_inductionsTab()`, `contractor_management_screen.dart:146-167`) is equally static — an icon and the caption "Site induction completion tracking per contractor," no query, no data — and unlike Compliance, no backing collection or model exists anywhere in the codebase for contractor-specific inductions (a *different*, employee-focused induction check exists in `safety`'s `passport_compliance_checker.dart:106-115`, querying `training_records` where `type == 'induction'` — but that's employee training-record data, not a contractor induction schema, and `safety` is out of this cluster's scope). Both tabs are AGENTS.md §3 banned-stub violations.

**Required fix:** For Compliance — replace `ContractorComplianceCard` with a real cross-contractor overview, e.g. a `StreamBuilder`/aggregation over `contractors` joined against each contractor's latest `safety_file_submissions`/`contractor_documents` status (the same collections `SafetyFileSubmissionView` already queries correctly — reuse its query shape as the reference), surfacing counts/lists of expiring insurance, outstanding tax clearance, and pending safety files across the whole register, rather than requiring a manager to drill into each contractor individually. For Inductions — this needs new schema first: define fields (at minimum `contractorId`, an attendee reference, `date`, `site`/`projectId`, `status`), add a corresponding `firestore.rules` entry (following the pattern already used for this module's other 6 collections, `contractors.md` §5), add a model + provider following this module's existing conventions, then build both a real read view and a create form (this tab currently has neither). Confirm the schema shape with whoever owns the requirement before implementing rather than guessing silently, per AGENTS.md §7's "never guess ambiguous requirements" rule.

**Verification:** Compliance tab: seed a contractor with an expiring or missing document, confirm it surfaces in the new overview. Inductions tab: once schema is defined and rules deployed, create a real induction record through its new form and confirm it appears in the tab's list.

---

### F-224: Add the missing `/contractors` route on the launchpad tile
**Severity:** High
**Module(s) / File(s):** `lib/config/router.dart`
**Depends on:** none
**Source:** `docs/modules/contractors.md` §2, §7 ("Launchpad's 'Contractors' tile points at a nonexistent route (/contractors), though the module remains reachable via projects/operations")

**Current behavior:** `business_os_launchpad.dart`'s "Contractors" tile (`business_os_launchpad.dart:192-197`) sets `route: '/contractors'`. Reading the complete `router.dart` (281 lines) and confirmed by grep, no `GoRoute` exists for `path: '/contractors'` — the identical defect shape as F-214's `/equipment` case. Unlike `equipment`, however, `ContractorManagementScreen` is not an orphan: it is correctly constructed via `UIUtils.showSideSheet` from `lib/features/projects/screens/project_details_screen.dart` and `lib/features/projects/widgets/project_tabs/contractor_card.dart` (2 call sites), and via a module-card tap in `lib/features/operations/widgets/operations_hub_modules.dart` — so the module remains genuinely reachable in practice, just not from the tile that specifically advertises it on the launchpad. Tapping the launchpad tile itself still lands on `router.dart`'s generic "Page Not Found" error screen, same as F-214 — this is why this item is rated one severity level below F-214's Critical rather than matching it: the launchpad entry point is broken in the same way, but there is no total lockout of the module the way there is for `equipment`.

**Required fix:** Add `GoRoute(path: '/contractors', pageBuilder: (c, s) => const NoTransitionPage(child: ContractorManagementScreen()))` inside the `ShellRoute`'s `routes` list in `router.dart`, plus the corresponding import (`import '../features/contractors/screens/contractor_management_screen.dart';`), matching F-214's fix shape exactly.

**Verification:** From the launchpad, tap the "Contractors" tile; confirm it now opens `ContractorManagementScreen` directly instead of the "Page Not Found" screen.

---
### Project Ops + Finance Cluster

### F-305: `projects`' two safety-file read sites use a collection name that may not match what's actually written
**Severity:** High
**Module(s) / File(s):** `lib/features/projects/widgets/project_tabs/contractor_card.dart` (line 262), `lib/features/projects/widgets/project_tabs/ohs_file_content.dart` (line 329)
**Depends on:** the SCM cluster's `contractors` module fix for the identical `safetyFileSubmissions`/`safety_file_submissions` naming split (`contractors` owns the write side of this collection) — resolve that decision first, then apply whichever direction it lands in here; do not change these two files unilaterally, since fixing only the read side to match the *rules-declared* name would actively break these two screens if `contractors`' write is instead kept on (or fixed to use) the camelCase name
**Source:** `docs/modules/projects.md` §5, §7; `docs/modules/_known_gaps_rollup.md` §1.1, §2 Critical table (`contractors` | camelCase/snake_case collection typo hides real safety-file approvals one screen away)

**Current behavior:** Both `contractor_card.dart` and `ohs_file_content.dart` — the live implementation of the Safety File & Resource Audit subprocess's *viewing* side (`projects.md` §6) — query the same camelCase collection name:
```
contractor_card.dart:260-266
    final submissionQuery = await fs
        .tenantCollection(tenantId, 'safetyFileSubmissions')
        .where('contractorId', isEqualTo: contractorId)
        .where('projectId', isEqualTo: projectId)
        .limit(1)
        .get();

ohs_file_content.dart:326-333
  Future<Map<String, dynamic>> _loadOHSData(dynamic fs, String tenantId) async {
    final subQ = await fs
        .tenantCollection(tenantId, 'safetyFileSubmissions')
        .where('contractorId', isEqualTo: contractorId)
        .where('projectId', isEqualTo: projectId)
        .limit(1)
        .get();
```
`firestore.rules` declares a rule for `safety_file_submissions` (snake_case, line 206) — a differently-cased name than what these two reads actually query. Tenant-scoped reads in this app succeed via the catch-all regardless of whether the exact collection name is declared (`allow read: if belongsToTenant(tenantId)` applies to reads on *any* subcollection name under a tenant), so these two reads aren't rules-blocked today — but they only ever return real data if whatever writes contractor safety-file submissions also targets the identical camelCase `safetyFileSubmissions` name. `projects.md` confirms no code inside this module ever writes to this collection (§6: "no code in this module *writes* a safety file submission — that's `contractors`' side"), and this batch's shared context identifies the identical camelCase-vs-snake_case split on `contractors`' own write side. Whether these two reads currently find real data, or always come back empty, depends entirely on which name `contractors` actually writes to today — not something confirmable from this module alone.

**Required fix:** Once the `contractors`-side item resolves which name is canonical (either `contractors`' write is changed to match the rules-declared `safety_file_submissions`, or the rule/collection name is changed to the camelCase `safetyFileSubmissions` these two reads — and presumably `contractors`' write — already use), update these two `tenantCollection(tenantId, 'safetyFileSubmissions')` calls to match: a one-line change per file if the canonical name changes, or no change at all if camelCase is kept. Do not resolve this file's naming in isolation from the `contractors` write-side decision — the two must agree.

**Verification:** After the naming decision lands end-to-end (`contractors`' write + `firestore.rules` + these two reads all agree on one name), submit a real contractor safety file through `contractors`' submission flow, then open that contractor's card and the OHS File tab on a linked Project and confirm the real submission's status/score/findings render — not an empty/not-found state.

---

### Sales / Customer Service / Field Service Cluster

### F-405: AGENTS.md §3 banned-stub violations across customer_service's reachable and real screens
**Severity:** High
**Module(s) / File(s):** `lib/features/customer_service/screens/omnichannel_ticket_screen.dart`, `knowledge_base_screen.dart`, `ticket_detail_screen.dart`, `knowledge_article_detail_screen.dart`
**Depends on:** none (independent of F-403, though F-403's real-vs-mock decision determines whether some of these lines survive at all — see note below)
**Source:** `docs/modules/customer_service.md` §7 ("AGENTS.md §3 Banned Stubs")

**Current behavior:** Four screens contain unconfigured `onPressed`/`onTap`/`onSubmitted` callbacks — AGENTS.md §3's banned-stub pattern — confirmed by direct read of each file. `omnichannel_ticket_screen.dart`: "Resolve" (`onPressed: () {}`, line 94), "Transfer" (`onPressed: () {}`, line 100), the attachment icon (`onPressed: () {}`, line 149), the reply `TextField`'s `onSubmitted: (_) {}` (line 161), and the send `IconButton` (`onPressed: () {}`, line 167) — none of these 5 callbacks do anything. This screen is also currently dead code (see F-403), so these stubs are invisible to any real user today, but would become live bugs the moment anything links to this screen. `knowledge_base_screen.dart`: all 5 sidebar category `ListTile`s (`onTap: () {}`, lines 28/33/38/43/48) and all 6 article-card `InkWell`s (`onTap: () {}`, line 90, inside a `GridView.builder(itemCount: 6, ...)`) — this screen **is** reachable today via the hub's icon button, so these 11 stubs are live, user-facing dead buttons right now, not latent ones. `ticket_detail_screen.dart`: the message-send `IconButton` (`onPressed: () { /* Send message action */ }`, lines 326-331) — worse than a simple no-op, since the adjacent reply `TextField` (lines 310-321) also has no `controller` at all, so wiring the button alone isn't sufficient; the typed text isn't captured anywhere yet. `knowledge_article_detail_screen.dart`: the Edit `IconButton` (`onPressed: () { /* Edit action */ }`, lines 34-39).

**Required fix:** Wire each to real behavior, sequenced against F-403's outcome. For `knowledge_base_screen.dart`'s 11 stubs: once its hardcoded cards are replaced with real `KnowledgeArticle` data (per F-403), each card's `onTap` should open `KnowledgeArticleDetailScreen(articleId: ...)` and each sidebar category should filter the article stream by category — these mostly resolve as a side effect of that larger fix rather than needing independent wiring, so sequence this after F-403 lands for this screen specifically. For `ticket_detail_screen.dart`: add a `TextEditingController` to the reply field, and wire the send button to construct a `TicketMessage` and call a new `CustomerServiceService.addMessage(ticketId, message)` (or equivalent, following the existing CRUD pattern) — the `ticketMessagesStreamProvider` already watching this ticket's messages (`ticket_detail_screen.dart:7-11`) will pick up the new message automatically once written, no further UI change needed. For `knowledge_article_detail_screen.dart`: wire the Edit button to open `KnowledgeArticleForm(initialArticle: article)` via `UIUtils.showSideSheet`. For `omnichannel_ticket_screen.dart`: per F-403, this screen is a candidate for deletion as dead/duplicate code — if it survives that decision, wire Resolve/Transfer to real `CustomerServiceService.updateTicket()` calls changing `status`, and the message composer to the same `addMessage()` path as `ticket_detail_screen.dart`; if it's deleted instead, these 5 stubs are moot and should not be fixed in isolation first.

**Verification:** For `knowledge_base_screen.dart`: tap a sidebar category and confirm the article grid filters; tap an article card and confirm it opens the real article's detail screen. For `ticket_detail_screen.dart`: type a message, tap send, confirm it appears in the messages panel in real time. For `knowledge_article_detail_screen.dart`: tap Edit, confirm `KnowledgeArticleForm` opens pre-filled with the article's current data. For `omnichannel_ticket_screen.dart`: verify per whichever fate F-403 assigns it (wired, or removed from the codebase entirely).

**Partially resolved 2026-07-30:** `knowledge_base_screen.dart`'s 11 stubs are fixed — the 5 sidebar categories now filter the real article stream by `KnowledgeArticle.categories`, and all article cards open `KnowledgeArticleDetailScreen` via `UIUtils.showSideSheet` (was `Navigator.push`, itself an AGENTS.md §1 violation caught in the same pass). `knowledge_article_detail_screen.dart`'s Edit button now opens `KnowledgeArticleForm(initialArticle: article)` via `UIUtils.showSideSheet`, invalidating `articleFutureProvider` on save. Still outstanding: `ticket_detail_screen.dart`'s send button/missing controller, and `omnichannel_ticket_screen.dart`'s 5 stubs (pending F-403's dead-code decision for that screen) — not marked `[DONE]` until those land.

---

### F-409: `RouteOptimizationScreen`'s client-side "Optimize Route" and the `optimizeRoute` Cloud Function independently implement the identical fake behavior, disconnected from each other
**Severity:** High
**Module(s) / File(s):** `lib/features/field_service/screens/route_optimization_screen.dart`, `firebase/functions/src/routingEngine.ts` (`optimizeRoute`)
**Depends on:** none
**Source:** `docs/modules/field_service.md` §5, §7, §8; `docs/schema_field_service.md` (route optimization described as a first-class capability)

**Current behavior:** Two independent, unconnected implementations of "route optimization" exist, and both are the same fake behavior. Client-side: `RouteOptimizationScreen`'s `_WorkOrdersNotifier.optimizeRoute()` (`route_optimization_screen.dart:83-85`) is `state = state.reversed.toList();` — a literal list reversal of the screen's own hardcoded 5-entry `_WorkOrder` list (lines 36-73, fabricated Johannesburg addresses). The "Optimize Route" button (`_buildOptimizeButton`, lines 253-297) calls this method directly (line 260) then shows a "Route optimized!" success toast (lines 261-277) regardless of what happened. Backend: `routingEngine.ts`'s `optimizeRoute` callable function (`firebase/functions/src/routingEngine.ts:15-37`) is, per its own code comment, built to "Simulate a TSP solver by reversing the order of workOrderIds" (line 24) — its entire implementation is `const optimizedOrder = [...workOrderIds].reverse();` (line 25), returning a canned `estimatedDuration: "4h 30m"` (line 29) regardless of input. Confirmed by grep: `optimizeRoute`/`routingEngine`/`httpsCallable`/`FirebaseFunctions` under `lib/features/field_service/` matches only the screen's own unrelated local method of the same name — the Cloud Function is never called from anywhere in the Dart codebase. Two independently-built implementations produce the identical placeholder behavior without either being aware of the other, and neither is a real optimizer — both exist purely to make the button feel functional.

**Required fix:** Pick one real implementation rather than fixing both independently — per the persona journey's stated need (`field_service.md` §2's "Optimize Dispatcher Route" step) and `docs/schema_field_service.md`'s explicit framing of route optimization as a first-class capability, the backend `optimizeRoute` Cloud Function is the right place for a real solver (a proper TSP heuristic — nearest-neighbor or 2-opt is a reasonable, tractable starting point for a field-service-sized route rather than an exact solver) since it can incorporate real distance/travel-time data unavailable client-side. Implement a real heuristic in `routingEngine.ts` in place of the `.reverse()` placeholder, taking `locations` (already part of `OptimizeRouteRequest`, line 6) into account rather than ignoring it. Then rewire `RouteOptimizationScreen`'s `_buildOptimizeButton` (and by extension `_WorkOrdersNotifier`) to call the Cloud Function via `FirebaseFunctions.instance.httpsCallable('optimizeRoute')` with the real `workOrderIds`/`locations` for the current work order list, apply the returned `optimizedOrder` to reorder the on-screen list, and surface the real `estimatedDuration`/`stops` in the day-summary card (`_buildDaySummaryCard`, lines 198-230, which currently shows further hardcoded values — `'42 km'`/`'~8.5 h'`, lines 224-226 — beyond just the reversal bug) instead of the canned strings. Sequence this alongside whatever replaces this screen's hardcoded `_WorkOrder` list with real `WorkOrder` data — F-408 fixes the sibling `work_order_list_screen.dart`'s identical dummy-data pattern; apply the same real-data fix here if this screen is kept as a distinct view rather than merged into that one.

**Verification:** Deploy the corrected `optimizeRoute` function to the emulator. From `RouteOptimizationScreen`, tap "Optimize Route" against a real (non-hardcoded) set of work orders with distinct locations, and confirm the resulting order reflects a real distance/time-based optimization rather than a simple reversal — verify by checking that the total route distance the heuristic reports is shorter than (or equal to, in a worst case) the un-optimized order's distance, not merely different from it.

---

### [DONE] F-410: `status`/`priority` are free-text fields on `work_order_form.dart` despite being documented fixed enums
**Severity:** High
**Module(s) / File(s):** `lib/features/field_service/widgets/work_order_form.dart`
**Depends on:** none
**Source:** `docs/modules/field_service.md` §7 (DB-to-UI alignment audit); `docs/modules/customer_service.md` §7 (contrast reference)

**Current behavior:** `status` and `priority` are plain `TextFormField`s bound to `_statusController`/`_priorityController` (`work_order_form.dart:22-23`, rendered at lines 222-234), even though `field_service_models.dart`'s `WorkOrder` documents both as fixed enums — `status` defaults to `'DRAFT'` and, per `field_service.md` §5's Cloud Functions section, has 8 real documented values (`DRAFT`/`SCHEDULED`/`DISPATCHED`/`TRAVELING`/`IN_PROGRESS`/`ON_HOLD`/`COMPLETED`/`CANCELED`); `priority` defaults to `'LOW'` with 4 documented values, referenced directly by `work_order_details_screen.dart`'s own `_getPriorityColor()` switch (`work_order_details_screen.dart:128-139`), which handles `'HIGH'`/`'MEDIUM'`/`'LOW'` explicitly and falls through to grey for anything else — including any free-text value a user might type that doesn't exactly match. A user creating or editing a work order through this form can type anything into either field — `'in progres'`, `'urgent'`, trailing whitespace — since the form's only validation is non-empty (`work_order_form.dart:224-227,231-234`), not membership in the real enum. This is inconsistent with this same codebase's `customer_service/widgets/ticket_form.dart`, which correctly uses `DropdownButtonFormField`s constrained to fixed option lists for its own analogous `status`/`priority` fields (`ticket_form.dart:127-144,149-162`) — `ticket_form.dart` is part of `customer_service`'s real, Firestore-backed implementation (see that module's F-403), so it remains a valid same-codebase template despite currently being unreachable from navigation itself.

**Required fix:** Replace both `TextFormField`s with `DropdownButtonFormField<String>`s, following `ticket_form.dart`'s exact pattern (a `String _status`/`String _priority` state variable, a fixed `items` list mapped to `DropdownMenuItem`s, `onChanged` calling `setState`) — use the 8 real `status` values and 4 real `priority` values enumerated above as the fixed option lists, cross-checking against `docs/schema_field_service.md` for the canonical list if any ambiguity remains. Remove `_statusController`/`_priorityController` and their `dispose()` calls, replacing them with the plain state variables the dropdown pattern uses instead.

**Verification:** Open the form, confirm `status` and `priority` render as dropdowns offering exactly the documented enum values, save a work order, and confirm `work_order_details_screen.dart`'s `_getPriorityColor()` correctly colors the result (no more silent grey-fallback from a mistyped value) and the Details tab's status text always matches one of the 8 real values.

**Resolved 2026-07-30:** dropdowns already existed (`work_order_form.dart:252-268`) but with a deviating, non-canonical value set (status: `DRAFT/UNSCHEDULED/SCHEDULED/IN_PROGRESS/COMPLETED/CANCELLED` — missing `DISPATCHED`/`TRAVELING`/`ON_HOLD`, extra non-canonical `UNSCHEDULED`, double-L `CANCELLED`; priority: `LOW/MEDIUM/HIGH/EMERGENCY` — `EMERGENCY` isn't a real value, missing `CRITICAL`). Corrected against `docs/schema_field_service.md`'s canonical lists, hoisted into shared `kWorkOrderStatuses`/`kWorkOrderPriorities` constants in `field_service_models.dart` (single source of truth, reusable anywhere else in the module that needs the enum) rather than inlined literals.

---

### [DONE] F-411: `address`/`scheduling`/`safetyRequirements`/`iotContext`/`financials` are raw hand-typed JSON text fields — a malformed entry throws an uncaught `FormatException` at save time
**Severity:** High
**Module(s) / File(s):** `lib/features/field_service/widgets/work_order_form.dart`
**Depends on:** none
**Source:** `docs/modules/field_service.md` §7 (DB-to-UI alignment audit); `docs/modules/_known_gaps_rollup.md` §2 (High table: "`field_service` | 4 structured `Map` fields... rendered as raw hand-typed JSON text fields; malformed input throws an uncaught `FormatException`" — the rollup's own count of 4 undercounts by one; there are 5 such fields on the model)

**Current behavior:** 5 of `WorkOrder`'s fields are structured `Map<String, dynamic>` on the model — `address`, `scheduling`, `safetyRequirements`, `iotContext`, `financials` — and all 5 are rendered identically on this form: a multi-line `TextFormField` labeled `'<Field> (JSON)'` (lines 322-350), pre-filled via `jsonEncode()` on load (`initState`, lines 99-113) and parsed back via `jsonDecode()` on save (`_submit()`, lines 176-180). A user must hand-type valid JSON syntax into a plain text box to edit any of these 5 fields — there is no structured sub-form for any of them. This is worse than a UX inconvenience: `_submit()`'s `try`/`catch` block (`work_order_form.dart:186-204`) wraps only the `service.createWorkOrder(workOrder)`/`updateWorkOrder(workOrder)` calls — the `WorkOrder(...)` construction itself, including all 5 `jsonDecode()` calls, happens at lines 148-184, **entirely outside the try block**. A single malformed entry in any of the 5 fields (a trailing comma, an unescaped quote, unbalanced braces) throws a `FormatException` synchronously during `_submit()`, uncaught by the surrounding error handling that was clearly built to cover exactly this kind of save-time failure — the user hits an unhandled exception rather than the "Error saving Work Order" toast the catch block shows for every other kind of save failure.

**Required fix:** Build a proper structured sub-form for each of the 5 fields in place of its raw-JSON `TextFormField`, matching each field's real shape: `address` (street/city/postal-code-style fields, or reuse a map/geocoding pattern if one exists elsewhere in the app), `scheduling` (date/time pickers for window start/end, following `showDatePicker` usage already correct elsewhere in this codebase, e.g. `opportunity_form.dart`'s Expected Close Date picker), `safetyRequirements` (likely a set of checkboxes/toggles once the schema's PTW/HIRA fields are pinned down — coordinate with whoever resolves `field_service.md` §5's note that this concept is currently aspirational-only), `iotContext` (likely read-only/system-populated rather than user-editable at all, since `work_order_details_screen.dart`'s own IoT Context tab treats it as informational output, not input — confirm before building an editable form for data that may only ever be system-written), `financials` (numeric fields for whatever cost/billing breakdown the schema defines). Given the differing shapes and confirmation needed per field (especially `safetyRequirements`/`iotContext`), this is real, multi-part scope — implementing as up to 5 smaller, independently-shippable sub-tasks (one structured sub-form per field) is likely more actionable than one combined change, particularly since `iotContext`/`safetyRequirements` need a product decision first while `address`/`scheduling`/`financials` do not. Regardless of how the structured-input work is sequenced, fix the try-catch scoping immediately and independently of the larger sub-form work: move the `WorkOrder(...)` construction (lines 148-184) inside the existing `try` block (currently starting at line 186), so a `FormatException` from any remaining raw-JSON field surfaces as the intended "Error saving Work Order" toast rather than an uncaught exception — this alone removes the crash risk even before any individual field gets its real structured widget.

**Verification:** Immediate fix: enter deliberately malformed JSON into any one of the 5 fields (e.g. `{invalid`), tap save, and confirm the app shows the "Error saving Work Order" toast rather than crashing or showing an unhandled-exception overlay. Per-field fix: once a field's structured sub-form ships, confirm it's no longer possible to enter free-text JSON for that field at all, and confirm a work order saved through the new sub-form round-trips correctly (re-opening the form shows the same structured values, not a raw JSON blob).

---

### F-413: `emergency_contacts_tab.dart` is entirely hardcoded and its "call" buttons don't actually dial
**Severity:** High
**Module(s) / File(s):** `lib/features/emergency/widgets/emergency_contacts_tab.dart`
**Depends on:** none
**Source:** `docs/modules/emergency.md` §4, §7

**Current behavior:** `EmergencyContactsTab`'s entire content is 6 hardcoded `_ContactCard` widgets (lines 21-56): Fire Department (10111), Ambulance/EMS (10177), Police/SAPS (10111), Poison Information (0800 111 990), SHE Manager (On-site ext. 201), Environmental Officer (On-site ext. 205) — literal `const` widgets with no Firestore read, an AGENTS.md §2 "No Hardcoded Data" violation (unlike this module's Drills/Equipment tabs, which are real). Each card's phone `IconButton.filledTonal` (`_ContactCard`, lines 96-102) calls `onPressed: () { UIUtils.showToast(context, 'Dialing $number...'); }` (lines 97-99) — it correctly uses the toast utility but never actually dials; the file has no `url_launcher` import and no `tel:` URI construction anywhere, despite `url_launcher` already being a project dependency (`pubspec.yaml:52`) used correctly elsewhere in this same app (`billing_service.dart:4,19`: `import 'package:url_launcher/url_launcher.dart'` / `await launchUrl(uri)`). Tapping "call" in a real emergency does nothing but show a toast claiming it's dialing.

**Required fix:** Two independent parts. (1) Replace the hardcoded contact list with a real one: add a Dart model plus a small tenant-scoped collection (e.g. `emergency_contacts`, matching the naming convention of this module's other 2 real collections) with a create/edit form, following `DrillFormCard`/`EquipmentFormCard`'s existing pattern in the same module (inline toggle-to-form card, defensive `isLoading`/try-catch, `firestoreServiceProvider.createDocument`) — so the SHE Manager/Environmental Officer entries (and any other site-specific numbers) can actually be maintained per tenant rather than hardcoded once for every deployment of the app; the 4 universal emergency-service numbers (Fire/Ambulance/Police/Poison) can reasonably ship as seeded defaults rather than requiring every tenant to re-enter them, but should still come from the same real collection rather than being compiled into the widget. (2) Wire the phone button to actually dial: replace the `UIUtils.showToast` call with `launchUrl(Uri(scheme: 'tel', path: number))`, following `billing_service.dart`'s existing `url_launcher` usage as the direct template, keeping a toast only for the error path if the launch fails (e.g. no telephony capability on the current device/platform).

**Verification:** Confirm the contacts list now reflects real, tenant-editable data (add a contact through the new form, confirm it appears without a code change/redeploy). On a device with telephony (or web's `tel:` handoff), tap a contact's phone button and confirm it opens the native dialer pre-filled with the correct number, rather than showing a toast.

---

### System Admin Cluster

### F-502: Remove hardcoded Firebase and Gemini API keys from `firebase_config.dart`
**Severity:** High
**Module(s) / File(s):** `lib/config/firebase_config.dart`, `lib/core/services/auth_service.dart:160`
**Depends on:** none
**Source:** `docs/modules/auth.md` §7

**Current behavior:** `firebase_config.dart` hardcodes a real-looking Firebase Web API key (`apiKey = 'AIzaSyCqAZ_Vkmbqqp6z_JlsCVnVGEskNDWLI7Q'`, line 6) and a separate Gemini API key (`geminiApiKey = 'AIzaSyDj7ABaHG6_jU4T8NVelw5dQ4EGxReHY8w'`, line 14), both committed to source control. Confirmed by repo-wide grep, `FirebaseConfig` is referenced exactly once anywhere in `lib/` — `auth_service.dart:160`, `FirebaseConfig.defaultSiteId` only. Neither `apiKey` nor `geminiApiKey` is read by any real initialization path: `main.dart` builds its actual `FirebaseOptions` from `dotenv.env['FIREBASE_API_KEY']` (a git-ignored `.env`, confirmed untracked), and `gemini_provider.dart` builds its `GenerativeModel` from `String.fromEnvironment('GEMINI_API_KEY', ...)` (a compile-time `--dart-define`, see F-513) — neither touches `FirebaseConfig` at all. Both key fields are dead code from a consumption standpoint, but the literal credential values remain live secrets sitting in version control regardless of whether anything currently reads them.

**Required fix:** Delete the `apiKey`, `authDomain`, `firestoreDatabaseId`, `storageBucket`, `messagingSenderId`, and `projectId`, and `geminiApiKey` fields from `firebase_config.dart`, keeping only `defaultSiteId` (`auth_service.dart:160`'s one live consumer) — rename the class or leave it as a single-field config holder, whichever keeps the diff smaller. Do not route real Firebase/Gemini initialization through this class instead — `.env`/`--dart-define` are already the working, intentional pattern for both, and consolidating onto this hardcoded class would reintroduce the exact problem being fixed. **Caveat, explicitly outside a normal code-fix's scope but worth stating so it isn't silently assumed-resolved:** both key values are already present in this repository's git history even after being deleted from the working tree — removing the literal from the file does not revoke or invalidate it. Closing this finding fully requires rotating both keys (regenerating the Firebase Web API key in the Firebase console and the Gemini key in Google AI Studio / Cloud console) and updating `.env`/the `--dart-define` build input with the new values; that rotation step is an infrastructure action, not a file edit, and should be tracked separately from this code change.

**Verification:** `grep -rn "FirebaseConfig" lib/` after the edit — confirm the only remaining reference is `auth_service.dart`'s `defaultSiteId` usage, and confirm `flutter analyze` reports no broken references. Confirm the app still builds and signs in successfully (`.env`-sourced Firebase config is unaffected by this change). Separately, and outside this repo, confirm with whoever owns the Firebase/Google Cloud project that both leaked keys have been rotated.

---

### F-503: No create/edit form exists anywhere for `UserProfile`'s optional fields
**Severity:** High
**Module(s) / File(s):** `lib/core/widgets/app_header_bar.dart:147-154`, `lib/core/models/user_profile.dart`, `lib/core/services/auth_service.dart` (`_getOrCreateProfile`, `updateProfile`)
**Depends on:** none
**Source:** `docs/modules/auth.md` §6, §7

**Current behavior:** `UserProfile` (`user_profile.dart`) has `department`, `jobTitle`, `phone`, and `preferences` fields, all nullable. `AuthService._getOrCreateProfile()` (`auth_service.dart:143-168`) sets only `uid`/`email`/`displayName`/`photoURL`/`role`/`tenantId` on first sign-in — the four fields above are never set and stay `null` permanently, since no other write path exists. The only "Edit Profile" entry point anywhere in the app is `app_header_bar.dart`'s profile menu (`_showProfileMenu`, lines 138-175): the `ListTile` at lines 147-154 pops the dialog and calls `UIUtils.showToast(context, 'Edit profile opened')` — a stub that opens nothing. `AuthService.updateProfile()` (`auth_service.dart:184-190`), the one method that could plausibly power such a form (a generic `Map` update against `users/{uid}`), has zero callers anywhere in `lib/`, confirmed by grep. This is a full AGENTS.md §3 "Banned Stubs" instance: a menu item that visually looks actionable, reports a toast as if something happened, and does nothing.

**Required fix:** Build a real profile-edit screen or side-sheet (`UIUtils.showSideSheet`, per AGENTS.md §1 — this is a natural side-sheet from the header bar, not a full route) with form fields for `displayName`, `department`, `jobTitle`, and `phone` at minimum (`preferences` is a free-form `Map` and can be deferred to whatever specific preference toggles are actually needed elsewhere, rather than a generic key-value editor). Wire its submit action to `AuthService.updateProfile()` (already correctly implemented, just uncalled), following the standard defensive-write pattern (AGENTS.md §1: local `isLoading`, try/catch, `UIUtils.showToast` on success/error). Replace `app_header_bar.dart:150-153`'s stub `onTap` with a call to open this new form instead of the toast.

**Verification:** From any authenticated screen, open the header bar's profile menu → "Edit Profile," confirm a real form opens (not a toast), fill in department/job title/phone, submit, and confirm the values persist on `users/{uid}` in Firestore and reappear correctly if the form is reopened.

---

### F-505: `LockScreen`'s no-biometric-hardware fallback unlocks the session with no credential check at all
**Severity:** High
**Module(s) / File(s):** `lib/features/auth/screens/lock_screen.dart:40-56`
**Depends on:** none
**Source:** `docs/modules/auth.md` §4, §7

**Current behavior:** `_LockScreenState._authenticate()` (`lock_screen.dart:27-66`) first checks `canAuthenticate` (`canCheckBiometrics || isDeviceSupported()`, lines 35-38). When `canAuthenticate` is `true`, it correctly runs `_localAuth.authenticate(...)` and only unlocks on a genuine biometric success (lines 40-50). When `canAuthenticate` is `false` — a device that reports no biometric hardware/capability at all — the `else` branch (lines 51-56) is:
```dart
if (mounted && !auto) {
  ref.read(sessionManagerProvider).unlockSession();
}
```
This unlocks the session unconditionally, with no PIN, password, or any other credential prompt. `auto` is `true` only for the automatic check fired from `initState`'s post-frame callback (line 23); a manual tap of the "Unlock" button (line 92, calling `_authenticate` with default `auto: false`) reaches this branch and succeeds immediately, every time, on any device without biometric hardware. On such a device, the entire 30-minute-inactivity lock mechanism (`SessionManager`, see F-504) provides zero actual access control — the lock screen renders, but "unlocking" it is a single tap with no verification of who is tapping.

**Required fix:** Do not silently unlock in the no-biometric-hardware branch. At minimum, require the device's own lock-screen credential via `local_auth`'s `biometricOnly: false` path (already used correctly in `AuthService.authenticateWithBiometrics()`, `auth_service.dart:113-119` — `AuthenticationOptions(stickyAuth: true, biometricOnly: false)`, which allows PIN/pattern/password fallback through the OS's own authentication UI rather than Sentinel1 inventing its own). Route `LockScreen._authenticate()`'s `canAuthenticate` branch to always attempt `_localAuth.authenticate(...)` with `biometricOnly: false` regardless of `canCheckBiometrics`, and remove the auto-unlock `else` branch entirely — if `isDeviceSupported()` is also `false` (no device credential of any kind configured), fall back to `AuthService.signOut()` and return to `/login` rather than unlocking, since there is no credential on the device to verify against.

**Verification:** On a simulator/device configured with no biometric enrollment and no device PIN/passcode, trigger the lock screen and confirm "Unlock" no longer succeeds without any prompt — it should either present the OS credential prompt (if one exists) or force a full sign-out. On a device with a PIN but no biometrics enrolled, confirm the PIN prompt appears and unlock only succeeds after entering it correctly.

---

### F-512: Wire `ControlTowerScreen`'s KPIs and alerts to real data, and add drill-down navigation
**Severity:** High
**Module(s) / File(s):** `lib/features/executive/screens/control_tower_screen.dart`
**Depends on:** none (independent of F-017's dashboard/executive merge-or-differentiate decision — see "Required fix" for how this relates)
**Source:** `docs/modules/executive.md` §5, §7

**Current behavior:** `ControlTowerScreen` has no `cloud_firestore` or `flutter_riverpod` import anywhere in the file (confirmed by reading its full import list) — it is a plain `StatefulWidget` whose only real state is a live clock and animation controllers. Both of its data sets are `static const` literals:
- `_kpis` (`control_tower_screen.dart:70-113`, 6 entries): Cash Position `$12.4M` (Finance), Open Work Orders `47` (Field Service), Active Projects `23` (PMO), Open Cases `156` (Customer Service), Inventory Value `$8.2M` (SCM), Headcount `1,847` (HR) — every value is a compile-time string, none computed from `invoices`/`work_orders`/`projects`/`employees`/etc. This is an AGENTS.md §2 "No Hardcoded Data" violation on the one screen in the app explicitly branded (in its own header text, line 245) as the C-suite's "Global Control Tower."
- `_alerts` (lines 115-134, 3 entries) are likewise static. The third entry's description text (line 131) reads: *"SKU-4421 (Industrial Valves) has reached the minimum reorder threshold. **Auto-PO draft created.**"* — a factual claim that a purchase order was automatically drafted. No PO is ever created anywhere by this file (confirmed: no Firestore write of any kind exists in this module), and `lib/core/bpf/procure_to_pay_bpf.dart` has no connection to this screen — the claim is false regardless of what triggered the alert being shown.

Separately, `_KpiCard` (lines 364-493) and `_AlertTile` (lines 498-579) both have no `onTap`/`GestureDetector`/`InkWell` anywhere in either class (confirmed by reading both classes in full) — `_AlertTile` renders a trailing `Icons.arrow_forward_ios_rounded` chevron (lines 568-572) that visually implies tappable navigation but is purely decorative. This directly contradicts the Executive/C-Suite persona's own defining journey text (`_shared_personas_and_bpfs.md`): "View BI Dashboards → **Drill down via deep links** into specific Projects or High-Risk CAPAs → ..." — the one screen assigned to this persona as its primary journey step has neither the live data nor the navigation that journey describes.

**Required fix:** Replace `_kpis`/`_alerts`'s static lists with real Riverpod `StreamProvider`s, one per KPI/alert source, following AGENTS.md §2's real-time-first mandate. Before writing new queries, check what each pillar's own module already computes — `dashboard`'s `dashboard_providers.dart` is the direct reference pattern for this (`StreamProvider`s aggregating cross-module collections correctly), and several of the 6 KPIs likely already have an equivalent live aggregate elsewhere (e.g. Finance's cash position may already be computed somewhere in `finance`'s own dashboard-adjacent providers, PMO's active-project count is a simple `projects` collection count, SCM's inventory value likely already exists given `supply_chain`'s MRP engine) — reuse or extend an existing stream rather than inventing a parallel one where possible; only write a new query where no suitable one exists yet. Once each KPI/alert is backed by real data with a real underlying record/collection, add `onTap` to `_KpiCard` and `_AlertTile` that navigates to the relevant module hub or specific record (e.g. `context.go('/finance')` for the Cash Position card, a specific case's detail route for an SLA-breach alert) — this is naturally sequenced after the data-wiring half, since a real record/route is needed before a tap handler means anything. For the false "Auto-PO draft created" claim specifically: either remove that clause from the alert's description text now (the smaller, immediate fix), or make it real once F-008's Procure-to-Pay orchestrator wiring lands (that item adds the actual PO-creation stage hooks this claim would need to be true) — note that dependency in whichever direction is chosen. This item is independent of F-017's dashboard/executive merge-or-differentiate product decision — real data and working navigation are worth having on this screen regardless of whether it eventually merges with `DashboardScreen` or stays separate; if F-017 resolves toward a merge, this wiring work carries over rather than being wasted.

**Verification:** With seeded data present for at least 2-3 of the 6 KPI sources, open `/control-tower` and confirm those cards show real, non-static values matching what each source module's own screens report for the same metric. Confirm tapping a `_KpiCard`/`_AlertTile` navigates somewhere real rather than doing nothing. Confirm the SKU-4421 alert's copy no longer claims an action that didn't happen (either by removing the claim or by confirming a real PO document now exists when this alert fires).

---

### F-513: `GEMINI_API_KEY` resolves to an empty string as committed — no `--dart-define` supplied anywhere in the repo
**Severity:** High
**Module(s) / File(s):** `lib/features/ai_tools/providers/gemini_provider.dart`
**Depends on:** none
**Source:** `docs/modules/ai_tools.md` §5, §7, §8

**Current behavior:** `geminiProvider` (`gemini_provider.dart:4-7`, the entire file) builds its `GenerativeModel` from:
```dart
const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
```
This is a Flutter **compile-time** define, only ever populated via `--dart-define=GEMINI_API_KEY=...` (or `--dart-define-from-file`) passed to `flutter run`/`flutter build`. Checked directly as part of drafting this item: there is no `.vscode/launch.json` anywhere in the repo, no `.github/` CI workflow directory, and no `Makefile`. The root `README.md` does exist and has a "Getting Started" section (lines 33-67) with explicit `Run Locally` instructions:
```bash
flutter pub get
flutter run -d chrome   # Web
flutter run              # Mobile
```
— no `--dart-define` flag anywhere in it, and its "Environment Setup" section (lines 40-53) documents only the `.env` Firebase variables (`FIREBASE_API_KEY` etc.), never `GEMINI_API_KEY`. `scripts/sync_and_reload.sh` (the only file under `scripts/`) contains no reference to either `dart-define` or `GEMINI_API_KEY` either. A repo-wide grep for `dart-define` returns only a generic, unrelated mention in `.agents/skills/saas-production-readiness/SKILL.md`. **No build script, CI config, or documentation anywhere in this repository supplies `--dart-define=GEMINI_API_KEY=...`.** As committed, every one of `AIChatScreen`'s 4 tabs (`SheqChatTab`, `HazardPhotoTab`, `RcaAssistantTab`, `SafetyFlashTab`) constructs its `GenerativeModel` with an empty-string API key and would fail its first real Gemini call — each tab's own `try/catch` catches this (surfaced as an inline `"Error: ..."`/`"Analysis error: ..."` message rather than a crash — though see F-516, which can turn that error display itself into a crash for short error messages). Note `firebase_config.dart` separately hardcodes a different, unused `geminiApiKey` value (see F-502) — that field is never read by `geminiProvider` or anywhere else, so it does not help here even though a real-looking key sits nearby in source.

**Required fix:** Supply `GEMINI_API_KEY` via `--dart-define` at build/run time from a source that isn't committed to git — mirroring the `.env`/`flutter_dotenv` pattern already used correctly for Firebase config in `main.dart`, or a `--dart-define-from-file=secrets.json` pointing at a git-ignored file. Add whatever run/build tooling this repo is currently missing: a `.vscode/launch.json` with `--dart-define=GEMINI_API_KEY=...`-style args for local dev, an update to `README.md`'s `Run Locally` section documenting the required flag, and the equivalent flag in whatever CI/build pipeline actually ships this app (outside this repo — confirm with whoever owns that pipeline whether this is already handled there before assuming it's fully broken end-to-end in production). If a git-ignored `.env`-based approach is preferred instead (consistent with how Firebase config is already handled), switch `gemini_provider.dart` from `String.fromEnvironment` to `dotenv.env['GEMINI_API_KEY']`, matching `main.dart`'s existing `flutter_dotenv` usage exactly — this avoids needing new run-configuration tooling at all.

**Verification:** Run the app with the chosen mechanism supplying a real key, exercise any of the 4 `AIChatScreen` tabs, and confirm a real Gemini response is returned instead of an inline error message. Run the app without the key supplied and confirm the failure mode is a clean, catchable error rather than a crash (this should already be true given each tab's `try/catch`, but re-verify after any change to how the key is sourced).

---

### F-514: None of `AIChatScreen`'s 4 tabs persists its AI-generated output anywhere
**Severity:** High
**Module(s) / File(s):** `lib/features/ai_tools/widgets/sheq_chat_tab.dart`, `hazard_photo_tab.dart`, `rca_assistant_tab.dart`, `safety_flash_tab.dart`
**Depends on:** none
**Source:** `docs/modules/ai_tools.md` §7, §8

**Current behavior:** Confirmed by reading all 4 tab files in full: none contains a `cloud_firestore` import or any write call. `HazardPhotoTab._analyze()` (`hazard_photo_tab.dart:31-53`) generates a hazard/PPE/non-compliance report into local `_result` state, displayed via `AIHazardReport` (line 121) — no "Save as Hazard" or "Attach to Incident" action anywhere in the file. `RcaAssistantTab._analyze()` (`rca_assistant_tab.dart:28-60`) generates a 5-Why RCA report the same way, displayed inline (lines 154-190) — no "Save to CAPA"/"Attach to Incident" action. `SafetyFlashTab._generate()` (`safety_flash_tab.dart:18-43`) generates a bulletin displayed inline (lines 117-157) with only a non-functional "copy" button (see F-515) — no "Post to Safety Board" or equivalent. `SheqChatTab` (the 4th tab) holds its entire conversation in an in-memory `_messages` list (line 17) with no persistence at all — navigating away loses the conversation history permanently. In every case, the pattern is identical: generate → display → lose on navigation away. This is an AGENTS.md §3 "End-to-End Vertical Slices" gap distinct from any single stub — the AI generation itself genuinely works (subject to F-513's API key issue), but no output is ever captured into the system of record it's ostensibly helping populate.

**Required fix:** This is scoped per-tab since each output type has a different natural destination, not one shared fix. For `HazardPhotoTab`: add a "Save as Hazard" action that writes the analysis (plus the captured image — `firebase_storage` is already a used dependency elsewhere in the app, see F-522 for the other place this same gap shows up) into the `hazards` collection, following whatever form/service `safety`'s own hazard-creation flow already uses as the target shape. For `RcaAssistantTab`: add a "Save as CAPA" or "Attach to Incident" action targeting `capas` (coordinate with F-006, which needs a real CAPA-creation path for the same collection — reuse whatever service method that work introduces rather than writing a second one). For `SafetyFlashTab`: add a "Post to Safety Board" action (confirm whether a "Safety Board" concept/collection already exists elsewhere in the app before inventing one — if not, this may need a small new collection). For `SheqChatTab`: lower priority than the other three since it's a conversational aid rather than a report generator, but at minimum consider whether conversation history should survive tab navigation within the same session (in-memory is acceptable; losing it entirely on every rebuild is not). Each new save action should follow the standard defensive-write pattern (AGENTS.md §1: `isLoading`, try/catch, `UIUtils.showToast`).

**Verification:** For each of the first three tabs, generate an AI output, tap the new save action, and confirm a real document appears in the target collection with the AI-generated content intact. Navigate away and back, and confirm the saved record is independently visible from wherever that collection is normally viewed (e.g. the Hazards list, CAPA list, Safety Board), not just from the AI tab itself.

---

### F-520: `NotificationService` is fully implemented with zero callers — wire it up and back `NotificationsScreen` with real data
**Severity:** High
**Module(s) / File(s):** `lib/core/services/notification_service.dart`, `lib/features/notifications/screens/notifications_screen.dart`, `lib/core/services/auth_service.dart`
**Depends on:** F-001 (declares rules for the `notifications`/`fcm_tokens` collections this item needs)
**Source:** `docs/modules/notifications.md` §5, §7, §8

**Current behavior:** `NotificationService` (`notification_service.dart`, entire file, core-level, not part of the `notifications` feature folder) implements real FCM permission request + token fetch + registration (`init()`, lines 23-60, with a Firestore direct-write fallback to `tenants/{siteId}/fcm_tokens/{uid}` if the `registerDeviceToken` callable fails — lines 71-83), token-refresh re-registration (lines 51-53), foreground/background message stream wrappers (lines 86-104), and three working Cloud Function wrappers — `sendEmail` (lines 108-121), `sendPush` (lines 124-141), `sendEmergencyBroadcast` (lines 144-155, the same function `emergency.md` documents as real-but-uncalled from its own module — two independent modules each hold one half of the same dead call chain). Confirmed by repo-wide grep: this file is referenced nowhere else in `lib/` — `NotificationService.provider`, `.init(`, `.sendPush(`, and its message streams have zero external callers. `main.dart` separately registers `FirebaseMessaging.onBackgroundMessage` directly (not through this service), so the app could technically receive a background push at the OS level, but since `registerDeviceToken` only fires from inside this unused service, no device token is ever actually registered — nothing is addressed to this app's install.

Separately, `NotificationsScreen` (`notifications_screen.dart`) builds a local `List<Map<String, dynamic>>` literal inline in `build()` (lines 12-35) — three fixed entries — with an explicit code comment admitting it (line 11: `// In a real app, this would use a StreamProvider over a 'notifications' Firestore collection`). No `notifications` collection is declared in `firestore.rules`, and the app never queries one anywhere (confirmed by grep). "Mark all read" (lines 41-44) and per-item tap (lines 89-91) both call `UIUtils.showToast` only, with no state mutation or navigation — non-functional stubs, but ones that only make sense to fix once the screen has real data to act on; not drafted as a separate item.

**Required fix:** Initialize `NotificationService` at login — the natural call site is inside `AuthService`, immediately after `_getOrCreateProfile()` returns in `signInWithGoogle()` (`auth_service.dart:53`) and `signInWithSAML()` (`auth_service.dart:75`), where `profile.uid`/`profile.tenantId` are both freshly available: `await ref.read(NotificationService.provider).init(uid: profile.uid, siteId: profile.tenantId ?? '')`. If F-507's `OfflineSyncService.initialize()` fix restructures `main.dart` around a `ProviderContainer` for startup initialization, consider whether device-token registration belongs at that same startup point instead of per-sign-in — either is defensible, but pick one rather than leaving it uncalled. Then convert `NotificationsScreen` to a real `StreamProvider` over a `notifications` (or per-user `users/{uid}/notifications`) collection — F-001 will have declared its rules by the time this is picked up — and wire "Mark all read" to a batch update of `isRead` across the visible documents, and per-item tap to navigate to whatever record the notification references (`type`/`collectionPath`-style fields, following `ApprovalItem`'s existing shape in `dashboard/providers/approvals_provider.dart` as a reference for how to carry a reference to the source document). Writing to this new collection from the actual source events (leave approval, training assignment, overdue action items — the three categories already shown in the mocked version) is a separate, larger effort across multiple other modules' write paths; scope this item to the notification-consumption side (the service + this screen) and treat cross-module notification-writing as follow-up work once the collection and screen are real.

**Verification:** Sign in and confirm (via `firebase auth:export` or the Firebase console) that a device token now appears under `tenants/{siteId}/fcm_tokens/{uid}` or via the `registerDeviceToken` callable's own success path. Seed a few documents directly into the `notifications` collection for the signed-in user and confirm `NotificationsScreen` renders them instead of the 3 hardcoded entries. Confirm "Mark all read" actually flips `isRead` on the real documents and the unread-dot indicators update accordingly.

---

## Medium

## Wave 3 — Medium

### Cross-cutting

### F-015: Remove remaining hardcoded/mocked data not already covered by a Critical/High item
**Severity:** Medium
**Module(s) / File(s):** `lib/features/people/screens/employee_activity_tab.dart`, `employee_hr_tab.dart`; `lib/features/health/screens/medical_tab.dart` (`OHStatChip` values); `lib/features/workers_comp/screens/compliance_tab.dart`; `lib/features/dashboard/screens/business_os_launchpad.dart` (RBAC filtering); `lib/features/property/screens/property_operations_tab.dart` ("Linked Incidents"/"Active Permits" panels)
**Depends on:** F-001 (several of these need working writes to real collections before they can be un-mocked)
**Source:** `docs/modules/_known_gaps_rollup.md` §1.8; `people.md`, `health.md`, `workers_comp.md`, `dashboard.md`, `property.md` §7

**Current behavior:** Each file renders static/hardcoded content where a live Firestore stream should be — e.g. `medical_tab.dart`'s `OHStatChip`s show literal `'Fit' 85%`/`'Restricted' 12%`/`'Unfit' 3%` regardless of the real `medical_records` stream queried a few lines below in the same file; `compliance_tab.dart`'s entire 10-item checklist and progress ring is a literal Dart list with no backing model; `business_os_launchpad.dart` shows all ~28 tiles to every user regardless of role (no RBAC filtering, despite an earlier plan's stated intent).

**Required fix:** For each file, replace the hardcoded values with a real computation over the module's existing live stream/provider (most of these modules already query the right collection nearby in the same file — the fix is deriving the displayed value from that data instead of a literal). For the Launchpad's RBAC gap specifically: filter the tile list by the current user's role (available via the custom claims from F-003) against each tile's minimum-required-role, which needs to be defined per tile — this is more design work than the other items in this group; consider scoping it separately if it stalls the rest.

**Verification:** For each fixed stat/checklist, seed data that should produce a non-default value and confirm the UI reflects it instead of the old hardcoded number. For the Launchpad, log in as 2 users with different roles and confirm they see different tile sets.

---

### F-016: Remove or migrate dead/legacy model classes
**Severity:** Medium
**Module(s) / File(s):** `lib/features/crm/models/crm_models.dart` (`Deal`/`DealStage`); `lib/features/finance/models/chart_of_accounts.dart`, `tax_model.dart` (`TaxRate`/`CurrencyExchange`); `lib/features/billing/models/subscription_models.dart` (plural); `lib/features/supply_chain/models/` (`BillOfMaterials`/`BomLine`/`ProductionOrder`); `lib/features/people/models/employee.dart`, `leave_request.dart` (possible duplication against `hr_models.dart`)
**Depends on:** none
**Source:** `docs/modules/_known_gaps_rollup.md` §1.10; `crm.md`, `finance.md`, `billing.md`, `supply_chain.md`, `people.md` §7

**Current behavior:** Each class listed has zero confirmed usage outside its own file (confirmed via grep during the original audit), superseded by a newer model (e.g. `Deal` by `Opportunity`) or never wired to a real service/provider/screen in the first place.

**Required fix:** For each, `grep -rn "<ClassName>"` across `lib/` to reconfirm zero external references still holds (code may have moved since the audit), then delete the file (or the class, if the file has other live content) and its provider if one exists. For `people`'s `employee.dart`/`leave_request.dart`, confirm first whether `EmployeeSelector` (which the README ties to `Employee`/`JobRole`) actually depends on `employee.dart` before deleting — if so, this is a rename/merge into `hr_models.dart`'s `EmployeeProfile`, not a straight deletion.

**Verification:** `flutter analyze` after each deletion — confirm no new "undefined class" errors appear, meaning nothing else silently depended on it.

---

### [DONE] F-017: Decide and implement dashboard/executive module boundary
**Severity:** Medium
**Module(s) / File(s):** `lib/features/dashboard/`, `lib/features/executive/`
**Depends on:** none
**Source:** `docs/modules/dashboard.md` §7, `docs/modules/executive.md` §7

**Current behavior:** `DashboardScreen`/`BusinessOsLaunchpad` (`dashboard`) and `ControlTowerScreen` (`executive`) are two independently-built "landing/exec surface" screens serving overlapping purposes (both are metrics/oversight surfaces primarily for the Executive persona) with zero shared code, models, or providers.

**Required fix:** This is a product decision first, code change second — options are (a) merge `executive` into `dashboard` as a tab/view, (b) keep both but clearly differentiate their purpose (e.g. `dashboard` = operational SHEQ metrics, `executive` = cross-pillar financial/strategic KPIs) and cross-link them, or (c) leave as-is and just document the boundary (already done in both docs). Once decided, if (a) or (b): migrate `ControlTowerScreen`'s hardcoded `_KpiData`/`_AlertData` to real Firestore-backed providers as part of the same pass (this overlaps with F-015's hardcoded-data cleanup for `executive` specifically — do together).

**Verification:** N/A until the product decision is made — log the decision as resolved in this item's "Required fix" section when implementation happens, and update `docs/modules/dashboard.md`/`executive.md`'s "Open Questions" sections to reflect the resolution.

---

### [DONE] F-018: Delete the dead CopilotScreen/CopilotChatWidget/RagService trio
**Severity:** Medium
**Module(s) / File(s):** `lib/features/ai_tools/screens/copilot_screen.dart`, `lib/features/ai_tools/widgets/copilot_chat_widget.dart`, `lib/features/ai_tools/services/rag_service.dart` (confirm exact filenames before deleting — verify zero remaining references first)
**Depends on:** none. **Supersedes F-014's `copilot_screen.dart` entry-point item** — do not add an entry point to a screen this item deletes; F-014 should be marked resolved-by-deletion once this lands.
**Source:** `docs/modules/copilot.md` §7, `docs/modules/ai_tools.md` §7, `docs/modules/billing.md` §7

**Current behavior:** 3 distinct AI-chat implementations exist: `CopilotPanel` (`copilot` module, routed at `/copilot`, backed by a real `askCopilot` Cloud Function, reachable), `AIChatScreen` (`ai_tools` module, routed at `/ai`, reachable, generates content that's never saved per F-015-adjacent findings), and `CopilotScreen`/`CopilotChatWidget`/`RagService` (`ai_tools` module, billing-gated behind the broken "Upgrade Now" button from the billing cluster's fix item, zero instantiation sites anywhere).

**Decision (resolved 2026-07-28): keep the 2 working implementations, delete the dead trio.** `CopilotPanel` and `AIChatScreen` are both reachable and serve distinct purposes (contextual assistant vs. a dedicated hazard/RCA/safety-flash tool). `CopilotScreen`/`CopilotChatWidget`/`RagService` have zero entry points anywhere and sit behind a paywall button that calls a Cloud Function that doesn't exist (the billing cluster's fix item) — not worth fixing/routing dead code when nothing depends on it.

**Required fix:** `grep -rn "CopilotScreen\|CopilotChatWidget\|RagService"` across `lib/` to reconfirm zero external references still hold (code may have moved since the audit), then delete all 3 files. Remove any now-unused imports in files that referenced them (check `ai_tools`' route/screen index if one exists).

**Verification:** `flutter analyze` after deletion — confirm no new "undefined class"/"unused import" errors, meaning nothing else silently depended on these files.

---

### F-019: Introduce a `BaseIncident` polymorphic base class
**Severity:** Medium
**Module(s) / File(s):** `lib/core/models/` (new `base_incident.dart`); `lib/core/models/safety_models.dart` (`Incident`); `lib/features/environment/` (spill records); `lib/features/health/` (first-aid records); `lib/features/workers_comp/` (COIDA claims) — candidates to extend it, not all mandatory in the first pass
**Depends on:** none
**Source:** `.agents/AGENTS.md` §5 (the original mandate); `docs/modules/_shared_personas_and_bpfs.md`'s rules-vs-code gap note; referenced in `safety.md`, `health.md`, `environment.md`, `workers_comp.md`, `risk.md`, `emergency.md`, `field_service.md` §7

**Current behavior:** `.agents/AGENTS.md` §5 mandates "Polymorphism for Shared Concepts... e.g. `BaseIncident` for Safety and Environmental incidents" — this class does not exist anywhere in the codebase, confirmed by repo-wide search. `safety`'s `Incident` model is the only real incident-shaped model that exists today, and per `safety.md`'s own audit, nothing currently parses documents through it anyway (the form's write shape and the model's expected shape have already drifted — see the safety cluster's own fix item for that separate bug). `environment`'s `spill_form.dart` is the clearest second candidate (substance, volume, location, containment, authority-notification — structurally an incident report in substance) that AGENTS.md's own example names explicitly.

**Required fix:** This is a scoped architecture task, not a bug fix — create `BaseIncident` with the fields genuinely common across candidates (location, dateTime, severity/status, reportedBy, description, at minimum), have `Incident` extend or compose it first (fixing its known field-drift issues in the same pass, since you're already touching this model), then evaluate `environment`'s spill records as the second real adopter. Don't force-fit `health`/`workers_comp`/`emergency`'s models into this hierarchy if their shape doesn't genuinely share fields with `Incident` — each module doc already flagged this class's relevance to their domain as "plausible" or "a candidate," not confirmed-necessary; use judgment per candidate rather than mechanically extending all of them.

**Verification:** `flutter analyze` after introducing the base class and migrating `Incident`; confirm `incident_report_form.dart` still compiles and existing incident-reading screens still render real data correctly (this touches a model with live, if drifted, data — regression-test the Safety Hub's incident list before/after).

---


### HR/SHEQ Cluster

### F-103: `qr_scanner_screen.dart` duplicates `passport_compliance_checker.dart`'s compliance-check logic instead of calling it

**Severity:** Medium
**Module(s) / File(s):** `lib/features/safety/screens/qr_scanner_screen.dart`, `lib/features/safety/services/passport_compliance_checker.dart`
**Depends on:** none
**Source:** `docs/modules/safety.md` §6, §7 ("Duplicated compliance-check logic")

**Current behavior:** `qr_scanner_screen.dart`'s `_handleEmployeeScan()` (lines 61-167) and `_handleContractorScan()` (lines 169-261) re-implement medical-certificate/training/induction/PTW compliance checks inline — querying `training_records` filtered by `type == 'medical_certificate'`/`type == 'induction'` (lines 110-115), counting valid vs. expired training records, and counting active permits by worker match (lines 117-137) — duplicating what `services/passport_compliance_checker.dart`'s `checkEmployeeCompliance()`/`checkContractorCompliance()` already do (lines 48-153, 155-211 of that file), against the same collections and the same `type` filters. The two implementations don't even agree with each other: `qr_scanner_screen.dart` derives `isCompliant` from `status == 'Active'` alone (line 149) with no reference to training/medical/PTW state at all, while `PassportComplianceChecker` derives a 3-tier `ComplianceLevel` (compliant/warning/nonCompliant) from an actual accumulated issues list (lines 132-140 of that file). This means the gate-scan screen and the (currently orphaned — see F-014, which covers those screens' unreachability, a separate issue from this one) QR passport-generation screens that depend on `PassportComplianceChecker` would show two different compliance verdicts for the same employee, computed by two different code paths, if both were ever reachable side-by-side.

**Required fix:** Replace `_handleEmployeeScan()`'s and `_handleContractorScan()`'s inline Firestore queries and manual compliance derivation with calls to `ref.read(passportComplianceCheckerProvider).checkEmployeeCompliance(employeeId)` / `.checkContractorCompliance(contractorId)`. Keep the surrounding profile/company/project-allocation lookups (name, department, job title, supervisor, project list — lines 72-146, not covered by `PassportComplianceChecker`) in `qr_scanner_screen.dart`; only replace the compliance-verdict portion. Update `_showEmployeeResult()`/`_showContractorResult()`'s `isCompliant` parameter and issue list to be driven by the returned `ComplianceCheckResult.level`/`.issues` instead of the current ad hoc booleans.

**Verification:** Scan an employee/contractor QR whose training records include an expired certificate or a missing induction; confirm the gate-scan result sheet's compliance verdict and listed issues match what `PassportComplianceChecker.checkEmployeeCompliance()`/`checkContractorCompliance()` independently compute for the same ID.

---

### F-106: `business_os_launchpad.dart`'s "Training" tile routes to a `/training` path that doesn't exist in `router.dart`

**Severity:** Medium
**Module(s) / File(s):** `lib/features/dashboard/screens/business_os_launchpad.dart` (line 129), `lib/config/router.dart`
**Depends on:** none
**Source:** `docs/modules/training.md` §4, §7 ("Broken Launchpad tile")

**Current behavior:** `business_os_launchpad.dart`'s "Training" `_LaunchpadCard` is declared with `route: '/training'` (`business_os_launchpad.dart:125-130`), and `_LaunchpadCard`'s `onTap` calls `context.go(route)` (`business_os_launchpad.dart:325`). `router.dart` defines no `/training` `GoRoute` anywhere — confirmed by checking every `path:` declaration in the file; `/hr`, `/people`, `/health`, `/workers-comp`, `/safety` all exist as real routes, `/training` does not. Tapping this tile hits the app's global `errorBuilder` — a plain "Page Not Found" `Scaffold` (`router.dart:64-65`) — instead of opening the Training module. Unlike `compliance`'s equivalent bug (F-109), this module is not fully unreachable: `training_screen.dart` is correctly reachable via a side-sheet from `people/screens/employee_hub_screen.dart` and `people/widgets/people_hub/people_hub_modules_grid.dart`, so this is a broken shortcut on the main Launchpad, not the module's only entry point — hence the lower severity than F-109's identical-shaped bug in `compliance`.

**Required fix:** Either (a) add a `/training` `GoRoute` in `router.dart` pointing at `TrainingScreen`, mirroring the existing `/health`/`/workers-comp` pattern (both of those modules have a working top-level route *alongside* a side-sheet entry point — use either as the template), or (b) change the Launchpad tile's behavior to open the existing People Hub side-sheet instead of a bare `context.go()`. Option (a) is the smaller, more consistent change relative to this module's siblings — recommend it unless there's a deliberate reason `training` was excluded from top-level routing.

**Verification:** Tap the "Training" tile from the main Business OS Launchpad; confirm it opens `TrainingScreen` instead of the "Page Not Found" screen.

---

### F-110: `daysUntilExpiry` computed once at document-creation time, never refreshed

**Severity:** Medium
**Module(s) / File(s):** `lib/features/compliance/widgets/register_doc_form.dart` (line 58), `lib/features/compliance/widgets/expiring_tab.dart` (lines 26-30), `lib/features/compliance/widgets/doc_list_item.dart`
**Depends on:** F-108 (fix the collection-name mismatch first — verifying this item requires the Expiring tab to actually be reading the same collection the form writes to, which isn't true until F-108 lands)
**Source:** `docs/modules/compliance.md` §5, §7 ("Stale computed field")

**Current behavior:** `register_doc_form.dart` computes `daysUntilExpiry` once, at write time — `'daysUntilExpiry': _expiry.difference(DateTime.now()).inDays` (line 58) — and stores it as a static integer rather than deriving it from `expiryDate` at read/query time. `expiring_tab.dart` then filters and sorts directly on this stored, never-updated value: `.where('daysUntilExpiry', isLessThanOrEqualTo: 90).orderBy('daysUntilExpiry')` (lines 29-30). A document registered today with a 1-year expiry stores `daysUntilExpiry: 365` permanently — that number never counts down as real time passes. Both the Expiring tab's 90-day filter and `doc_list_item.dart`'s day-count badge silently drift out of sync with the document's actual `expiryDate` the longer the record exists: a document that's now genuinely 60 days from expiry could still read `daysUntilExpiry: 200` and never appear in the Expiring tab, or an already-expired document could still display a stale positive number.

**Required fix:** Stop persisting `daysUntilExpiry` as a stored field and compute it at render/query time instead — `safety.md` notes `ppe_compliance_screen.dart` already does this correctly for its own expiry countdown; use that screen as the reference pattern. Concretely: remove the `daysUntilExpiry` write from `register_doc_form.dart:58`; change `expiring_tab.dart`'s query to filter/sort on `expiryDate` directly (Firestore supports range queries and `orderBy` on a `Timestamp` field the same way it does on an integer — e.g. `.where('expiryDate', isLessThanOrEqualTo: Timestamp.fromDate(DateTime.now().add(const Duration(days: 90)))).orderBy('expiryDate')`); update `doc_list_item.dart`'s day-count badge to compute `expiryDate.difference(DateTime.now()).inDays` inline at build time instead of reading a stored field. If a stored field is preferred for query-performance reasons over switching to a range query on `expiryDate`, the alternative is a daily scheduled Cloud Function that recomputes `daysUntilExpiry` across all documents — but computing at read time is simpler and avoids adding a new scheduled function for a module this small.

**Verification:** Register a document with an expiry date roughly 85 days out; confirm it appears in the Expiring tab immediately (once F-108's collection fix has landed) with a correct, live day count. Adjust `expiryDate` on an existing test document directly in Firestore and reload the tab; confirm the displayed day count changes accordingly rather than staying frozen at its original value.

---

### F-111: `legal_tab.dart`'s 9 framework cards render a dead external-link affordance

**Severity:** Medium
**Module(s) / File(s):** `lib/features/compliance/widgets/legal_tab.dart` (lines 11-66, 73, 108-112)
**Depends on:** none
**Source:** `docs/modules/compliance.md` §7 ("Dead external-link affordance")

**Current behavior:** Each of the 9 legal/standards framework cards in `LegalTab` (Occupational Health and Safety Act, COIDA, GSR, Hazardous Chemical Substances Regulations, Construction Regulations 2014, NEMA, ISO 45001/14001/9001 — the `reqs` record-tuple list at lines 11-66) renders a trailing `Icon(Icons.open_in_new_rounded, ...)` (lines 108-112) inside a `GCard` (line 73) — visually implying a tap-through to the actual regulation text or an external reference. `GCard` (`lib/core/widgets/g_card.dart`) already supports an `onTap: VoidCallback?` parameter that, when non-null, automatically wraps its content in an `InkWell` (`g_card.dart:10, 41-47`) — but `legal_tab.dart:73`'s `GCard(...)` call never passes one, so the affordance is purely decorative today. This is a small but real instance of AGENTS.md's "Banned Stubs" principle — an affordance implying functionality that doesn't exist — even though it isn't a literal `// TODO` or `onPressed: null`.

**Required fix:** Add a URL to each of the 9 entries in the `reqs` list (extend the existing 4-element records — title, description, icon, color — to a 5th element, or restructure to a record with named fields for clarity) pointing at the real public text of each Act/standard (e.g. the South African Government Gazette page for the OHS Act, the relevant ISO standard's public landing page). Pass `onTap: () => launchUrl(Uri.parse(url))` to the `GCard` at line 73 — no need to add a separate `InkWell`, since `GCard` already handles that internally once `onTap` is non-null. `url_launcher` (`^6.3.2`) is already a dependency (`pubspec.yaml:52`) and already used correctly elsewhere in this codebase — `lib/features/billing/services/billing_service.dart:17-19` (`Uri.parse(url)` / `await launchUrl(uri)`) is a ready-made reference pattern for the exact call shape needed here. If no real external link target is wanted for this release instead, the lower-effort alternative is removing the `open_in_new_rounded` icon entirely so the card stops implying tap-through functionality it doesn't have — but given this is static reference content with genuinely stable real-world URLs, wiring the real links is the more useful fix.

**Verification:** Tap each of the 9 framework cards; confirm it opens the real regulation/standard reference in an external browser via `launchUrl`, or — if the removal alternative was chosen instead — confirm the icon no longer appears and the card is honestly non-interactive.
### SCM Cluster

### F-207: Remove the dead `inventory` Firestore rule (superseded by `inventory_items`)
**Severity:** Medium
**Module(s) / File(s):** `firestore.rules`
**Depends on:** F-001 (remove this dead entry only after F-001's `inventory_items` rule has landed — ideally in the same pass, so there's never a gap where inventory writes have zero matching rule at all)
**Source:** `docs/modules/supply_chain.md` §5, §7, §8 (Open Questions: "Is the `inventory_items`/`inventory` naming drift a rules bug... or a code bug...?")

**Current behavior:** `firestore.rules:199-203` declares `match /inventory/{itemId} { ... }` (singular, no `_items` suffix). Every real code path — the Dart client (`ScmService._inventoryRef`, `scm_service.dart:18-19`; `scm_streams_provider.dart:9`) and the deployed Cloud Function (`mrpEngine.ts:20`) — consistently reads/writes `inventory_items` instead, and nothing anywhere in the codebase ever queries `.collection('inventory')` (confirmed by grep). This is a judgment call worth recording explicitly: the drift is not an unresolved naming disagreement in the code (Dart and the Cloud Function already agree with each other on `inventory_items`) — it's a single leftover rules entry that matches zero real writes and simply sits there as dead, misleading configuration. F-001 already adds the correct `inventory_items` rule as part of its own fix (see F-001's `Current behavior`, which lists `supply_chain: inventory_items` explicitly), so this item's scope is narrower: cleaning up the now-fully-redundant `inventory` block afterward so a future reader doesn't mistake it for the real, protected collection.

**Required fix:** Delete the `match /inventory/{itemId} { ... }` block at `firestore.rules:199-203`, after confirming F-001's `inventory_items` rule is present and deployed (do not remove `inventory` before `inventory_items` exists, or inventory writes would have zero matching explicit rule for the gap between the two changes).

**Verification:** `grep -n "match /inventory/" firestore.rules` returns only the `inventory_items` block, not `inventory`. Re-run F-001's own verification sweep for this collection specifically (submit a real inventory item write) to confirm nothing regressed.

---

### F-208: Delete dead `LeadToCashAutomation` — an unreachable, duplicate "Won Opportunity" handler
**Severity:** Medium
**Module(s) / File(s):** `lib/core/automation/lead_to_cash_automation.dart`
**Depends on:** none
**Source:** `docs/modules/supply_chain.md` §6, §7

**Current behavior:** `LeadToCashAutomation.triggerOpportunityWon(Opportunity opp)` (`lead_to_cash_automation.dart:24-51`) is a third, independently-built "Won Opportunity" handler, distinct from both the real `BpfOrchestrator` (wired by F-004) and whatever `crm`'s own service does — it calls `ScmService.createSalesOrder()` and `FinanceService.createInvoice()` directly. Confirmed by grep: `triggerOpportunityWon`/`leadToCashAutomationProvider` have zero call sites anywhere in `lib/` outside their own file — no "Mark Opportunity as Won" button or any other UI action calls it. This is distinct from F-004, which wires the real `bpfOrchestratorProvider`/`BpfOrchestrator` methods into the UI — that is the correct, intended Lead-to-Cash implementation. This file is a separate, parallel, never-invoked implementation of the same conceptual event that should not also be wired up alongside F-004; it should simply be deleted as dead code once F-004 confirms `BpfOrchestrator` is the surviving implementation.

**Required fix:** `grep -rn "LeadToCashAutomation\|leadToCashAutomationProvider\|triggerOpportunityWon"` across `lib/` to reconfirm zero external references still holds (code may have moved since this was drafted), then delete `lib/core/automation/lead_to_cash_automation.dart` entirely. Do not attempt to merge its logic into `BpfOrchestrator` — F-004's `convertLeadToOpportunity`/`createQuoteFromOpportunity`/`createProjectFromQuote`/`createInvoiceFromProject` already cover the equivalent Lead-to-Cash flow with real, tested-by-inspection Firestore writes; this file's `createSalesOrder`+`createInvoice`-only shortcut is a narrower, redundant duplicate, not a superset worth preserving.

**Verification:** `flutter analyze` after deletion — confirm no new "undefined class"/"undefined identifier" errors appear, meaning nothing else silently depended on it.

---

### F-211: `complianceScore`/`totalAssets` are manually-typed instead of derived from live data
**Severity:** Medium
**Module(s) / File(s):** `lib/features/property/widgets/property_form_sheet.dart`; `lib/features/property/screens/property_hub_screen.dart` (`_buildStatsRow`)
**Depends on:** F-001 (only if `totalAssets`/`complianceScore` remain writable fields on `Property`; moot for `totalAssets` if it is instead fully derived client-side per the Required fix below, since that removes the write path for this field entirely)
**Source:** `docs/modules/property.md` §7 (DB-to-UI alignment audit: "complianceScore / totalAssets | Wrong widget (architectural)"), §8

**Current behavior:** Both fields are plain numeric `TextFormField`s a human types directly (`_complianceScoreController`/`_totalAssetsController`, `property_form_sheet.dart:205-218`), despite the `Property` model's own inline comments marking them `// Added for traceability` (`property_models.dart:17-18`) — language that reads as "meant to be derived," not manually maintained. `totalAssets` in particular has an exact, already-live source of truth elsewhere in the same app: `propertyAssetsProvider` (`property_providers.dart:94-110`), a family stream over the real `property_assets` collection filtered by `propertyId`, already consumed directly by `PropertyAssetsTab` (`property_assets_tab.dart:142`) to render the literal list of assets for that property. Nothing keeps a manually-typed `totalAssets` number in sync with that real count — an admin can type any value, and `PropertyHubScreen`'s own "Total Assets"/"Avg. Compliance" portfolio stats (`property_hub_screen.dart:116-129`) are built directly from these potentially-stale, hand-entered fields. No equivalent live source for `complianceScore` was found anywhere in this session's 4-module scope.

**Required fix:** For `totalAssets` — remove the manual entry field and its write (`property_form_sheet.dart:95,213-218`) from the form entirely, and instead compute it at render time from `propertyAssetsProvider(property.id).valueOrNull?.length` wherever it's displayed (`PropertyHubScreen._buildStatsRow`, `property_hub_screen.dart:116-129`, and anywhere else `property.totalAssets` is read) — no new backend work is required since the source stream already exists and is already live. For `complianceScore` — no existing data source to derive it from was found; treat this as an Open Question (matching `property.md` §8's own framing) rather than guessing a formula. If left as manual entry in the interim, this should not be silently presented as a computed metric on the portfolio dashboard — consider a UI label change (e.g. "Compliance Score (manual)") until a real computation source is defined.

**Verification:** Seed a property with a known number of `property_assets` documents; confirm `PropertyHubScreen`'s "Total Assets" stat (and any other place `totalAssets` is displayed) reflects the real, current count without anyone manually entering it, including immediately after adding/removing an asset. `complianceScore` verification is deferred until its computation source is defined, per F-017/F-018's convention for items blocked on a product decision.

---

### F-218: `ContractorList` reads the wrong field name for contact person (`contactPerson` vs. written `contactPersonId`)
**Severity:** Medium
**Module(s) / File(s):** `lib/features/contractors/widgets/contractor_list.dart`
**Depends on:** none
**Source:** `docs/modules/contractors.md` §5, §7 (DB-to-UI alignment audit: "contactPersonId | Correct widget, broken downstream")

**Current behavior:** `AddContractorForm._submit()` writes the selected contact person as `'contactPersonId': _selectedContactPersonId ?? ''` (`add_contractor_form.dart:55`), correctly sourced from `EmployeeSelector` (`add_contractor_form.dart:109-114`). `ContractorList`'s card subtitle instead reads `d['contactPerson']` — no `Id` suffix (`contractor_list.dart:98`: `'${d['contactPerson'] ?? ''} • ${d['scopeOfWork'] ?? ''}'`) — a key that is never written anywhere in this module (confirmed by grep for `'contactPerson'` vs. `'contactPersonId'` across `lib/features/contractors/`). Every contractor's card subtitle silently renders with a blank leading segment (just `' • <scope>'`) regardless of who was actually selected as contact person.

**Required fix:** Change `contractor_list.dart:98` to read `d['contactPersonId']` and resolve it to a display name rather than the raw ID, using the same `employeesProvider` (`lib/features/people/providers/employee_providers.dart`) that `EmployeeSelector` itself already watches internally (`employee_selector.dart:21`) and displays via `emp.fullName` (`employee_selector.dart:41`) — e.g. look up the matching employee in `ref.watch(employeesProvider).valueOrNull` by `.id == d['contactPersonId']` and display its `.fullName`, falling back to a placeholder if not found or still loading.

**Verification:** Add a contractor with a real contact person selected; confirm the resulting card in `ContractorList` shows that person's actual full name in the subtitle instead of a blank segment.

---

### Project Ops + Finance Cluster

### F-304: `new_project_dialog_content.dart` hardcodes every new project's `propertyId` to a literal placeholder
**Severity:** Medium
**Module(s) / File(s):** `lib/features/projects/widgets/new_project_dialog/new_project_dialog_content.dart` (line 104)
**Depends on:** none (a real property lookup needs `property`'s collections declared in rules first — see F-001, which already lists all 6 of `property`'s collections)
**Source:** `docs/modules/projects.md` §7 (DB-to-UI alignment audit); `docs/modules/_known_gaps_rollup.md` §1.8

**Current behavior:** `_save()` constructs every new `Project` with `propertyId` hardcoded to a literal string (`new_project_dialog_content.dart:101-105`):
```
101:      final project = Project(
102:        id: '',
103:        tenantId: siteId,
104:        propertyId: 'default-property',
105:        name: _nameCtrl.text.trim(),
```
`Project.propertyId` is a real model field (`project_models.dart`), and the module's own README describes it as "Linked Property" — but the create form exposes no control for it at all: no dropdown, no selector, not even a free-text field. Every project created through this dialog, regardless of which real property it actually belongs to, receives the identical placeholder value. This is an AGENTS.md §2 "No Hardcoded Data" violation on write, not merely on display: the bad value is persisted permanently into every project's own record, not just shown incorrectly during one render pass.

**Required fix:** Add a property selector to the form, following the same lookup-widget pattern already used correctly elsewhere in this exact form for other FK-shaped fields (`EmployeeSelector` for `projectLead`/`fallbackContact`, `SearchableStringMultiSelect` for `allocatedContractorIds`) rather than a plain `TextFormField` — source the options from `property`'s `properties` collection. Note `property`'s collections are currently undeclared in `firestore.rules` (F-001 covers this), so a real property list can't round-trip end-to-end until that lands. If a project can genuinely have no linked property in some cases (e.g. non-site-based work), make the field explicitly optional with a real "No linked property" state rather than a silent fake default standing in for "none."

**Verification:** Create a new project through the dialog, selecting a real property; confirm the resulting document's `propertyId` matches the selected property's real ID. Create a second project with a different property selected and confirm the two projects end up with two different `propertyId` values, not both `'default-property'`.

---

### F-307: `risk_matrix_widget.dart` is captioned as a live risk-distribution heat map but is entirely decorative
**Severity:** Medium
**Module(s) / File(s):** `lib/features/risk/widgets/risk_matrix_widget.dart`; `lib/features/risk/screens/risk_command_center_screen.dart` (caption/usage site)
**Depends on:** none
**Source:** `docs/modules/risk.md` §7 ("Other")

**Current behavior:** `risk_command_center_screen.dart` captions this widget as a "Risk Distribution Matrix... Likelihood vs Impact assessment heat map" — language that reads as a live analytics view. The widget itself (`risk_matrix_widget.dart`, 102 lines total) is a `StatelessWidget` with **no constructor parameters, no `ref`, and no query of any kind**. Its 4×5 grid is generated purely from static inputs: fixed `levels`/`colors` arrays (lines 11-17), fixed axis labels (`'Rare'`/`'Unlikely'`/`'Possible'`/`'Likely'`/`'Almost Certain'`, lines 27-31), a gradient computed from cell position only (`intensity = (4 - row + col) / 8`, line 65), and cell numbers that are simply `row + col + 1` (line 83) — an arithmetic sequence, not a count of anything. Regardless of how many real HIRA/DRA/Bow-Tie/Strategic assessments exist for the tenant, or what their actual likelihood/impact ratings are, this grid renders identically every time. A user reading the Command Center screen has no way to tell this apart from a real distribution chart from the UI alone.

**Required fix:** Wire the widget to real data: accept a list of (likelihood, severity) pairs — or a pre-bucketed count map — as a constructor parameter, sourced from a live aggregation over `risk_assessments`/`strategic_risks` (the collections whose forms, `hira_form.dart`/`strategic_risk_form.dart`, already write comparable `likelihood`/severity-rated fields). Note `dynamic_risk_assessments` records shouldn't feed this matrix until F-306 (this cluster's DRA field-mismatch item) lands, since `dra_form.dart` currently produces no comparable rating at all. Replace the `row + col + 1` placeholder cell numbers with real per-cell counts, and drive the gradient intensity from those counts (e.g. relative density) instead of the fixed position-based formula.

**Verification:** Seed several HIRA/Strategic risk records with known likelihood/severity combinations; open the Command Center screen and confirm the matrix's cell counts match the seeded data's actual distribution, and confirm the counts update when a new assessment is added.

---

### F-308: `risk` module README documents an architecture that doesn't exist
**Severity:** Medium
**Module(s) / File(s):** `lib/features/risk/README.md`
**Depends on:** none
**Source:** `docs/modules/risk.md` §1, §5, §7, §8

**Current behavior:** `lib/features/risk/README.md` states (lines 7-8): "**State Management:** Riverpod (`risk_providers.dart`)" and "**Data Model:** `RiskEntry` (used for both HIRA and strategic risks)." Both claims are false: repo-wide grep finds no file named `risk_providers.dart` anywhere in the codebase, and the string `RiskEntry` appears nowhere except inside the README's own text. Directory listing confirms `lib/features/risk/` contains only `screens/` and `widgets/` — no `models/`, `providers/`, or `services/` directory exists at all. Every one of the module's 4 sub-features (HIRA, DRA, Bow-Tie, Strategic Register) writes and reads raw `Map<String, dynamic>` directly inside screen/widget `build()` methods via `firestoreServiceProvider.createDocument()` and inline `StreamBuilder<QuerySnapshot>` calls — a real, working pattern, just not the one the README describes. Per AGENTS.md §4, this manifest exists specifically so an agent can "read this manifest instead of parsing thousands of lines of Dart code" — an agent trusting it today would go looking for files that don't exist and a model that was never built, for a 17-file module that is architecturally central to Project Operations.

**Required fix:** Two options, not mutually exclusive in sequence:
1. **Minimum, do this now:** rewrite the README's Architecture section to describe what's actually there — no dedicated state-management layer; each screen owns its own `StreamBuilder`/`firestoreServiceProvider` calls; no `RiskEntry` model, raw maps throughout; list the 5 real collections (`risk_assessments`, `dynamic_risk_assessments`, `strategic_risks`, `bowtie_analyses`, `hazards`) in place of the fictitious model reference.
2. **Larger follow-up, separate effort, not required to close this item:** actually build the claimed layer — a real `RiskEntry`-family model set (or reuse `core/models/safety_models.dart`'s existing, currently-unused `RiskAssessment` class, which `risk.md` §1/§8 flags as a plausible but unconfirmed candidate), a `risk_providers.dart` with proper `StreamProvider`s per collection, and a `RiskService` — migrating all 4 forms/screens off inline raw-map CRUD. This is a substantially larger unit of work than the README correction and should not block it.

**Verification:** For option 1, confirm the README's Architecture section no longer names any file or class that returns zero grep hits under `lib/features/risk/` or `lib/core/models/`. For option 2 (if undertaken), run `flutter analyze` after migration and regression-test all 4 create/read flows to confirm they behave identically from a user's perspective after moving off raw maps.

---

### F-313: Decide which of finance's 3 non-intersecting collection-naming schemes is canonical
**Severity:** Medium
**Module(s) / File(s):** `lib/features/finance/services/finance_service.dart`, `firestore.rules`, `firebase/functions/src/index.ts` (`postJournalEntry`, `onInvoiceStatusChanged`, `revRecEngine`)
**Depends on:** none (this decision should ideally land before or alongside F-001's rules fix for finance's `fin_*` collections, so F-001 doesn't lock in a name this item would then have to migrate away from — a sequencing preference, not a hard blocker, since F-001 can proceed independently if this decision takes longer)
**Source:** `docs/modules/finance.md` §5, §8 (Open Questions)

**Current behavior:** Three separate, non-intersecting naming schemes exist for what should be one coherent GL/invoicing data model, confirmed by direct code read:
1. **`firestore.rules`** (lines 140-150) declares purpose-built rules for collections named `invoices` and `journal_entries`.
2. **`FinanceService`** — the only Dart code that performs client-side writes for this domain — writes to `fin_ap_invoices`, `fin_ar_invoices`, `fin_journal_headers`, `fin_chart_of_accounts`, `fin_tax_codes`, `budgetPlans`, `costCenters`, none of which match scheme 1's names.
3. **Cloud Functions** `postJournalEntry` (real, called by `LedgerPostingService` — see F-317, this cluster's item on that function's own zero-call-site problem) and `onInvoiceStatusChanged` (a Firestore-update trigger), plus `revRecEngine.revenueRecognition`, operate on a *third* scheme: `tenants/{t}/finance_journals`, `tenants/{t}/finance_accounts`, `tenants/{t}/finance_invoices`.

Zero code anywhere in the repo (`lib/` or either Functions codebase) writes to a collection literally named `invoices` or `journal_entries` — scheme 1's rules currently protect collections nothing uses. Scheme 2's collections are undeclared in rules and blocked by the catch-all (F-001's job to patch mechanically, without resolving *which* name should have won). Scheme 3 means even after F-001 adds rules for scheme 2's names, `postJournalEntry`/`onInvoiceStatusChanged`/`revRecEngine` would still operate on a location neither the rules nor `FinanceService` ever reads or writes — these real, correctly-coded Cloud Functions have no confirmed path to ever interact with data a user can see, regardless of the rules fix. This decision also affects F-302 (this cluster's `revenue_recognition_screen.dart` item, in `projects`) — if that screen is ever wired to real data, it needs to read whichever scheme wins here, since `revRecEngine` is scheme 3's writer.

**Required fix:** A product/architecture decision first, mechanical migration second — the same shape as F-017/F-018 elsewhere in this fix list. Options: (a) standardize on scheme 2 (`fin_*` + `budgetPlans`/`costCenters`) since it's what the actual, most fully-built service (`FinanceService`, 341 lines of real CRUD) already uses — update `firestore.rules` to match (what F-001 will do by default if this decision isn't made first) and migrate the Cloud Functions off scheme 3 onto scheme 2's names; (b) standardize on scheme 1 (`invoices`/`journal_entries`) since it's already declared in rules — re-point `FinanceService` at these names instead, and still migrate the Cloud Functions; (c) standardize on scheme 3 since it's what the only server-side, transactionally-safe write path (`postJournalEntry`) already uses — re-point both `FinanceService` and the rules, and treat `LedgerPostingService.postJournalEntry()` (not `FinanceService.createJournalEntry()`'s direct client write) as the intended primary write path going forward, which also resolves `finance.md` §8's separate open question about whether the Cloud Function should replace the direct-write path (it has server-side balance validation; the direct client write doesn't). Whichever direction, this must land as one coordinated change across all 3 locations, not 3 independent ones.

**Verification:** N/A until the product decision is made — log the decision as resolved in this item when implementation happens, per the same pattern F-017/F-018 use. Once implemented: create a journal entry through whichever path is now canonical, confirm it's readable from `FinanceHubScreen`/`JournalEntryDetailScreen`, and confirm `postJournalEntry`'s Cloud Function (if scheme 3 or a migrated equivalent is kept as the posting path) can find and act on it.

---

### F-314: Banned-stub sweep — Budget Plan / Cost Center FABs and Invoice Detail's "Linked Journal Entry" tile
**Severity:** Medium
**Module(s) / File(s):** `lib/features/finance/screens/budget_plan_list_screen.dart` (line 53), `lib/features/finance/screens/cost_center_list_screen.dart` (line 54), `lib/features/finance/screens/invoice_detail_screen.dart` (lines 182-184)
**Depends on:** none
**Source:** `docs/modules/finance.md` §7 (AGENTS.md §3 banned-stubs rule); `docs/modules/_known_gaps_rollup.md` §1.1 pattern context

**Current behavior:** Three AGENTS.md §3 ("Banned Stubs... Never use `// TODO`, unconfigured `onPressed` callbacks") violations in the same module, all sharing the identical shape — a tappable control that visibly exists but silently does nothing:
```
budget_plan_list_screen.dart:51-56
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement Create Budget Plan
        },
        child: const Icon(Icons.add),
      ),

cost_center_list_screen.dart:52-57
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement Create Cost Center
        },
        child: const Icon(Icons.add),
      ),

invoice_detail_screen.dart:174-186
    return Card(
      ...
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: Colors.blue),
        title: const Text('Linked Journal Entry'),
        subtitle: Text('ID: ${invoice.journalEntryId}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Typically navigation to Journal Entry Detail Screen
        },
      ),
    );
```
`budget_plan_list_screen.dart`/`cost_center_list_screen.dart` each already have a real, working list view (`StreamBuilder` over `FinanceService.streamBudgetPlans()`/`streamCostCenters()`) and a real detail screen reachable via each row's own `onTap` (`BudgetPlanDetailScreen`/`CostCenterDetailScreen`) — only the create path is missing. `invoice_detail_screen.dart`'s tile renders a real `journalEntryId` value with a forward-navigation chevron affixed, visually promising drill-down that the `onTap` doesn't deliver — a literal comment stands in for the navigation call.

**Required fix:** For the 2 FABs: wire each `onPressed` to open a create form as a side-sheet (`UIUtils.showSideSheet`, per AGENTS.md §1) calling `FinanceService.createBudgetPlan()`/`createCostCenter()` — both already exist and are real; this is a missing form, not a missing service method (note neither list screen is itself reachable from a Hub screen today per `finance.md` §4's separate reachability finding, which this item does not fix). For `invoice_detail_screen.dart`'s tile: replace the empty `onTap` with real navigation to `JournalEntryDetailScreen(journalEntryId: invoice.journalEntryId!)`, using `budget_plan_list_screen.dart`'s or `cost_center_list_screen.dart`'s own row `onTap` (in this same module) as the direct template for the navigation call shape.

**Verification:** Tap each FAB; confirm a real create form opens and a new Budget Plan/Cost Center document appears in Firestore and in the list after submission. Open an Invoice with a non-null `journalEntryId` and tap the "Linked Journal Entry" tile; confirm it navigates to that journal entry's real detail screen instead of doing nothing.

---

### F-315: GL account IDs use a bare timestamp instead of a human-readable prefix
**Severity:** Medium
**Module(s) / File(s):** `lib/features/finance/screens/chart_of_accounts_view.dart` (`_addAccount()`, line 55)
**Depends on:** none
**Source:** `docs/schema_finance.md` line 15; `docs/modules/finance.md` §7 (AGENTS.md §2 "Human Readable IDs")

**Current behavior:** AGENTS.md §2 mandates: "When creating new master records..., generate a concise, human-readable ID (e.g., `PRJ-001`, `INC-045`) and use it explicitly as the Firestore document ID." `docs/schema_finance.md:15` gives the worked example for this exact model: "**Document ID:** `{account_id}` (e.g., `1000-Cash`)." `chart_of_accounts_view.dart`'s `_addAccount()` ignores both and generates the ID as a bare millisecond timestamp:
```
54:                final newAccount = GeneralLedgerAccount(
55:                  id: DateTime.now().millisecondsSinceEpoch.toString(),
56:                  accountNumber: codeCtrl.text,
57:                  name: nameCtrl.text,
```
The raw material for a readable ID already exists in the same method — `codeCtrl.text` ("Account Code (e.g. 1000)") and `nameCtrl.text` are both captured, just not used to construct `id`. This is inconsistent with the rest of the module: `Invoice`/`JournalEntry`/`JournalLine` IDs already use readable prefixes (`INV-`, `AP-INV-`, `JE-`, `LINE-`) elsewhere in `FinanceService`.

**Required fix:** In `_addAccount()`, construct `id` from `codeCtrl.text` and `nameCtrl.text` following `schema_finance.md`'s own example shape — e.g. `'${codeCtrl.text.trim()}-${nameCtrl.text.trim().replaceAll(' ', '')}'` (yielding `1000-Cash` for code `1000`/name `Cash`) — with an explicit collision check (a `.get()` against the target doc ID before `.set()`, surfacing an error via `UIUtils.showToast` if it already exists) rather than silently overwriting an existing account that happens to produce the same ID.

**Verification:** Create a new GL account with code `1000` and name `Cash`; confirm the resulting Firestore document ID is `1000-Cash` (or an equivalent readable scheme), not a 13-digit timestamp. Attempt to create a second account that would produce the same ID and confirm it's rejected with a clear error, not silently overwritten.

---

### F-316: Chart of Accounts' Balance column and "Multi-Entity Consolidation" toggle are non-functional placeholders
**Severity:** Medium
**Module(s) / File(s):** `lib/features/finance/screens/chart_of_accounts_view.dart` (lines 17, 86-94, 129)
**Depends on:** F-311 (this cluster's immutability item) if balance is computed by summing posted `JournalLine`s against a posting-status guard — sequencing preference, not a hard requirement
**Source:** `docs/modules/finance.md` §7 (AGENTS.md §2 "No Hardcoded Data")

**Current behavior:** Every row's Balance column renders a literal `'\$0.00'` regardless of the account's real balance, and the "Multi-Entity Consolidation" switch toggles local state nothing else reads:
```
17:  bool _isConsolidated = false;
...
86:                const Text('Multi-Entity Consolidation'),
87:                Switch(
88:                  value: _isConsolidated,
89:                  onChanged: (val) {
90:                    setState(() {
91:                      _isConsolidated = val;
92:                    });
93:                  },
94:                ),
...
129:                          DataCell(Text('\$0.00')),
```
This screen was touched earlier in this same effort specifically to fix a `GeneralLedgerAccount` model/field-name drift (commit `36279ed`, "Fix GL account model drift and WMS scanner overlay API"); that commit's own message states the balance display was left this way deliberately: *"balance display is temporarily hardcoded to \$0.00 pending real balance wiring (tracked in docs/modules/finance.md)."* That same commit also **removed** a `currentBalance` field the account model previously carried (the pre-commit code read `acc.currentBalance.toStringAsFixed(2)`) in favor of the current `GeneralLedgerAccount` shape, which has no stored balance field at all — consistent with `schema_finance.md`'s "true dual-entry"/immutability design, where an account's balance is properly a *derived* value summed from posted journal lines, not a mutable stored total that could drift from the ledger's own truth. This item is the proper follow-up now that the model itself is stable: the fix is to compute a real balance, not to reintroduce a stored `currentBalance` field, which would be a step backward from the model's own corrected design.

**Required fix:** Replace the hardcoded `'\$0.00'` with a balance computed on read by summing `JournalLine.debitAmount`/`creditAmount` across all `POSTED` `JournalEntry` documents whose lines reference that `accountId` (net debit minus credit, or the reverse depending on account type, per standard GL sign conventions) — do not add a stored `currentBalance` field back onto `GeneralLedgerAccount`. This is naturally sequenced alongside F-311 (this cluster's immutability item) since both concern what "posted" means for a journal entry; not a hard dependency, since a read-time sum works regardless of whether the mutation guard from F-311 has landed yet. For "Multi-Entity Consolidation": either wire it to real filtering logic (first confirm whether a multi-entity/subsidiary concept exists anywhere in the data model — check `GeneralLedgerAccount.financialStatementGroup` and whether a tenant can have sub-entities — before assuming this toggle is meaningful) or remove it entirely if no such concept exists yet, rather than leaving a switch that visibly does nothing.

**Verification:** Post a real journal entry with debit/credit lines against a specific GL account and mark it `POSTED`; confirm that account's Balance column updates to reflect the real net amount, not `$0.00`, and confirm a still-`DRAFT` entry's lines are correctly excluded from the sum. For the consolidation toggle: either confirm switching it produces a visibly different (correctly filtered/aggregated) account list, or confirm it has been removed.

---

### F-317: `LedgerPostingService` — a correct, transactional journal-posting wrapper — has zero call sites
**Severity:** Medium
**Module(s) / File(s):** `lib/features/finance/services/ledger_posting_service.dart`
**Depends on:** none
**Source:** `docs/modules/finance.md` §5, §7; `docs/modules/_known_gaps_rollup.md` §2 Medium table

**Current behavior:** `LedgerPostingService.postJournalEntry()` (`ledger_posting_service.dart:13-30`) is a real, correctly-implemented wrapper around the `postJournalEntry` Cloud Function (`onCall`, `firebase/functions/src/index.ts`) — it takes `tenantId`/`date`/`description`/`lines` and calls `_functions.httpsCallable('postJournalEntry').call({...})`. `ledgerPostingServiceProvider` (lines 4-6) exposes it via Riverpod. Repo-wide grep for `ledgerPostingServiceProvider`/`LedgerPostingService` outside this file's own definition returns zero matches — no screen, form, or other service calls it. Meanwhile, `journal_entry_form.dart`'s actual submit path calls `FinanceService.createJournalEntry()` instead — a direct client-side Firestore write with no server-side balance validation (it doesn't check debits equal credits before writing) and, per F-313 (this cluster's naming-scheme item), a write target that doesn't intersect with what `postJournalEntry` itself operates on (`finance_journals`/`finance_accounts`, scheme 3, vs. `FinanceService`'s `fin_journal_headers`, scheme 2). This is the same "correct code, never called" shape F-004 documents for `bpfOrchestratorProvider` app-wide — worth noting as a related precedent even though it isn't a strict dependency — here scoped to one specific Cloud Function wrapper rather than the whole BPF engine.

**Required fix:** Decide, as part of or informed by F-313, whether `journal_entry_form.dart` should call `LedgerPostingService.postJournalEntry()` instead of `FinanceService.createJournalEntry()` as its primary submit path — the Cloud Function path gets real server-side transactional posting and balance validation "for free," which the direct client write doesn't have and would otherwise need to reimplement client-side. If adopted: wire `journal_entry_form.dart`'s submit handler to `ref.read(ledgerPostingServiceProvider).postJournalEntry(...)`, and confirm the region hardcoded at `ledger_posting_service.dart:5` (`region: 'europe-west1'`) actually matches where this app's Cloud Functions deploy — don't assume it's correct, since a region mismatch would make every call fail with a not-found error even once wired.

**Verification:** Submit a journal entry through `journal_entry_form.dart` after rewiring; confirm the `postJournalEntry` Cloud Function actually invokes (check function logs in the emulator or deployed project) and that the resulting document appears wherever F-313's scheme resolution lands, with debits/credits validated server-side — submit an intentionally unbalanced entry and confirm it's rejected rather than written.

---

### F-318: `taxEngine.calculateTax` is a documented simulation with zero Dart-side callers
**Severity:** Medium
**Module(s) / File(s):** `firebase/functions/src/taxEngine.ts` (`calculateTax`)
**Depends on:** none
**Source:** `docs/modules/finance.md` §5, §7

**Current behavior:** `calculateTax` (`taxEngine.ts:3-24`) is a real, deployable `onCall` function that validates its `total`/`jurisdiction` arguments and returns a computed tax amount — but the computation itself is admittedly fake:
```
14:    // Simulate Stripe Tax call
15:    const simulatedTaxRate = 0.08; // 8% tax rate
16:    const taxAmount = total * simulatedTaxRate;
```
A flat, hardcoded 8% regardless of jurisdiction — `jurisdiction` is validated as required (the function throws if it's missing) but never actually used to look up a real rate. Repo-wide grep of `lib/` for `taxEngine`/`calculateTax` returns zero matches — nothing in the Flutter app calls this function at all, a separate gap from the simulation itself. This is lower urgency than this cluster's other items: unlike, say, `timesheet_entry_screen.dart`'s stub (F-303) or the immutability gap (F-311), this function's own code honestly labels itself a simulation rather than presenting fake output as if real — there is no user-facing screen currently claiming to show real tax calculations that's secretly wrong underneath. `TaxCode` (the real model — `code`, `jurisdictionId`, `taxType`, `rate`, GL liability/receivable account links, `finance_models.dart`) already exists and is a more plausible foundation for real jurisdiction-based tax than this function's flat rate.

**Required fix:** Two parts, sequence either way: (1) replace the simulated flat rate with a real lookup against `TaxCode` records (query the tax-codes collection — wherever F-313's naming decision lands — filtered by `jurisdictionId` matching the `jurisdiction` argument already being passed in), instead of or in addition to a real Stripe Tax API integration if that's still the intended long-term direction (the function's own comment suggests Stripe Tax was the original plan). (2) Wire a real Dart-side caller — most plausibly `invoice_form.dart`'s submit path, computing `taxAmount` server-side before constructing the `Invoice`, rather than leaving `taxAmount` as a value the form either computes client-side or leaves blank (check `invoice_form.dart`'s current handling of `taxAmount` before wiring this in — not confirmed one way or the other in this pass).

**Verification:** Call `calculateTax` with a real `total`/`jurisdiction` pair matching a seeded `TaxCode` record; confirm the returned `taxAmount` reflects that code's real `rate`, not a flat 8%. Confirm `invoice_form.dart` (once wired) populates `Invoice.taxAmount` from this function's output rather than leaving it at a default/zero.

---

### Sales / Customer Service / Field Service Cluster

### F-401: Delete crm's 4 dead `StateProvider` list caches; make `accountStreamProvider` a real live stream
**Severity:** Medium
**Module(s) / File(s):** `lib/features/crm/providers/crm_providers.dart`, `lib/features/crm/services/crm_service.dart`
**Depends on:** none
**Source:** `docs/modules/crm.md` §7; `docs/modules/_known_gaps_rollup.md` §2 (Medium table: "`crm` | `accountsProvider`/`contactsProvider`/`opportunitiesProvider`/`quotesProvider` are static `StateProvider`s, not streams — needs confirming whether any screen still binds to them")

**Current behavior:** `crm_providers.dart:5-8` declares `accountsProvider`, `contactsProvider`, `opportunitiesProvider`, `quotesProvider` as `StateProvider<List<T>>((ref) => [])` — a local cache seeded with an empty list and never fed by any stream, listener, or one-shot fetch anywhere in the file. Repo-wide grep for each of the 4 provider names returns exactly one match apiece — the declaration itself in `crm_providers.dart` — confirming zero screens anywhere in `lib/` call `ref.watch()`/`ref.read()` on any of them. This resolves the module doc's own open question: it is dead code, not a live real-time-first violation — every screen that needs this data already uses one of the module's real stream providers instead (`accountsStreamProvider`, `leadsStreamProvider`, `campaignsStreamProvider`, `opportunityQuotesStreamProvider.family`, etc.), which is presumably why nothing ever bound to the static 4. Separately, and requiring the opposite fix, `accountStreamProvider.family` (`crm_providers.dart:33-35`) — despite its `Stream`-suffixed name and `StreamProvider.family` type — wraps `CrmService.getAccount(id)`, a one-shot `Future<Account?>` (`crm_service.dart:74-78`), via `.asStream()` (`crm_providers.dart:34`). This one **is** live and load-bearing: `AccountDetailScreen` (`account_detail_screen.dart:11`) is its only consumer, and it's that screen's sole data source. Because `.asStream()` on a `Future` emits exactly one value and then closes, `AccountDetailScreen` never reflects a change to the account made elsewhere in the app (e.g. via `updateAccount()`, `crm_service.dart:56-60`) unless the user backs out and re-opens the screen — a genuine AGENTS.md §2 real-time-first violation, unlike the 4 dead providers sitting next to it in the same file.

**Required fix:** Delete `accountsProvider`, `contactsProvider`, `opportunitiesProvider`, `quotesProvider` (`crm_providers.dart:5-8`) entirely — reconfirm the zero-consumer grep still holds at implementation time, then remove the declarations; no screen changes are needed since nothing references them. For `accountStreamProvider`, add a real `Stream<Account?> streamAccount(String accountId)` method to `CrmService` following the exact pattern its sibling singular-record streams already use correctly (`streamOpportunity()`, `crm_service.dart:188-195`: `_tenantDoc.collection('accounts').doc(accountId).snapshots().map((doc) => doc.exists ? Account.fromJson(doc.data()!, doc.id) : null)`), then change `crm_providers.dart:33-35` to call `streamAccount(id)` instead of `getAccount(id).asStream()`. No change is needed in `AccountDetailScreen` itself — it already watches the provider by name, not by its underlying shape.

**Verification:** `flutter analyze` after deleting the 4 unused providers — confirm no new "undefined identifier" errors appear, meaning nothing else silently depended on them. For `accountStreamProvider`: open a real Account's detail screen, update that same account's data through another path while the screen stays open (directly in the Firestore console, or a second app session), and confirm the open detail screen updates live without navigating away and back — today it will not.

---

### F-402: crm has zero `AppEventBus` usage — a Won Opportunity notifies no other module
**Severity:** Medium
**Module(s) / File(s):** `lib/core/events/app_event_bus.dart`, `lib/features/crm/widgets/opportunity_form.dart`
**Depends on:** none (related to F-004, which wires the *direct* Lead-to-Cash orchestrator call chain — see note below on how this item differs)
**Source:** `docs/modules/crm.md` §6, §7, §8

**Current behavior:** Repo-wide grep for `AppEventBus` returns matches only in its own definition file, `lib/core/events/app_event_bus.dart` — the class (`AppEventBus`, `.fire()`, `.stream`) and its `appEventBusProvider` are fully implemented (a `StreamController<AppEvent>.broadcast()` wrapper, with 2 example event classes already modeled — `EmployeeTerminatedEvent`/`HighRiskIncidentReportedEvent`, `app_event_bus.dart:13-33`), but **nothing anywhere in `lib/`, in any module, ever calls `.fire()` or subscribes to `.stream`**. This isn't unique to `crm` — it's a repo-wide gap that happens to be most visible here, since `crm` has the clearest candidate trigger point AGENTS.md §5 itself gestures at. The natural fire point is `OpportunityForm._save()` (`opportunity_form.dart:52-104`): when a user changes `stage` to `'Closed Won'` via the Stage dropdown (one of 10 fixed options, `opportunity_form.dart:187-199`) and submits, `service.updateOpportunity(opp)` (`opportunity_form.dart:82`) writes the change straight to Firestore with no event of any kind fired. Per `crm.md` §6, `projects` is supposed to auto-create a Project on Won Opportunity, and `finance` is a plausible second listener — neither has any way to react to this specific transition except by independently polling/streaming the `opportunities` collection directly, which this session's cross-module pass did not find evidence of in either module. This is distinct from F-004: F-004 wires `BpfOrchestrator`'s direct, synchronous chain (`convertLeadToOpportunity()` → `createQuoteFromOpportunity()` → `createProjectFromQuote()` → `createInvoiceFromProject()`), which is the *primary*, already-coded path for Lead-to-Cash handoffs once wired to the UI. This item is about whether a *decoupled* notification should ALSO fire alongside that direct call chain, for any other module that might want to react to a Won Opportunity without being part of the direct orchestration chain (e.g. an activity-feed entry, a dashboard counter, a notification to the account owner). No concrete listener was found to exist anywhere in the codebase today, which is why this is Medium rather than High — the gap is real but nothing is currently broken by its absence, since F-004's direct chain is what actually carries the load-bearing handoff.

**Required fix:** Add a `WonOpportunityEvent` (or similarly named) class extending `AppEvent` to `app_event_bus.dart`, following the exact shape of the existing `EmployeeTerminatedEvent`/`HighRiskIncidentReportedEvent` examples (`app_event_bus.dart:13-33`) — carry at minimum `opportunityId`, `accountId`, and `amount`. Fire it from `OpportunityForm._save()` immediately after `service.updateOpportunity(opp)` succeeds, gated on `stage == 'Closed Won'` and, ideally, only on the *transition* into that stage rather than every re-save of an already-won Opportunity (compare against `widget.opportunity?.stage` before firing, since `widget.opportunity` already carries the pre-edit value). Do not add a listener anywhere as part of this item unless F-004's implementation surfaces a concrete need for one beyond the direct orchestrator chain it already wires — an event with no subscriber is a smaller, safer unit of dead-code risk than a speculative subscriber for a need that hasn't been confirmed; revisit once F-004 lands.

**Verification:** Change a real Opportunity's stage to "Closed Won" through the form; confirm (via a temporary debug listener on `appEventBusProvider.stream`, or a log statement) that the event fires exactly once with the correct `opportunityId`/`accountId`. Confirm it does not re-fire on a subsequent save of the same already-won Opportunity when the stage doesn't change.

---

### F-406: `customer_service_hub_screen.dart` imports `omnichannel_ticket_screen.dart` twice, never instantiates it
**Severity:** Medium
**Module(s) / File(s):** `lib/features/customer_service/screens/customer_service_hub_screen.dart`
**Depends on:** none
**Source:** `docs/modules/customer_service.md` §7

**Current behavior:** `customer_service_hub_screen.dart:2-3` imports `omnichannel_ticket_screen.dart` twice — a literal duplicate `import` statement (`import 'omnichannel_ticket_screen.dart';` on both line 2 and line 3). `OmnichannelTicketScreen` is never referenced anywhere else in the file — no constructor call, no route, no button. This is a small bug on its own (a harmless duplicate import; Dart tolerates it silently rather than erroring), but it's a concrete data point for F-403's real-vs-mock diagnosis: it's physical evidence the hub screen was edited with `OmnichannelTicketScreen` in mind and then never wired up, or wired up and later ripped back out, without the now-dead import being cleaned up either time — consistent with this module's broader pattern of real or intended pieces left disconnected from what's actually reachable.

**Required fix:** Delete one of the two duplicate `import 'omnichannel_ticket_screen.dart';` lines (`customer_service_hub_screen.dart:2` or `:3`). If F-403's real-vs-mock resolution results in `OmnichannelTicketScreen` being deleted entirely rather than wired up or repurposed, remove both import lines as part of that deletion instead of just deduplicating to one.

**Verification:** `flutter analyze` — confirm no unused-import warning remains for this file, and confirm the file still compiles with only one copy of the import (or zero, if `OmnichannelTicketScreen` was deleted as part of F-403).

---

### F-414: `siteId` is populated with the tenant ID, making both tabs' `.where('siteId', ...)` filter a redundant no-op
**Severity:** Medium
**Module(s) / File(s):** `lib/features/emergency/widgets/drill_form_card.dart`, `equipment_form_card.dart`, `emergency_drills_tab.dart`, `emergency_equipment_tab.dart`
**Depends on:** none
**Source:** `docs/modules/emergency.md` §5, §7, §8

**Current behavior:** Both of this module's write forms set `'siteId': p.tenantId` (`drill_form_card.dart:54`, `equipment_form_card.dart:47`) — the user's own tenant ID, not a distinct site identifier — and both read tabs filter on it: `emergency_drills_tab.dart:58` and `emergency_equipment_tab.dart:62` both run `.where('siteId', isEqualTo: siteId)` where `siteId = ref.watch(currentTenantIdProvider)` (the same tenant ID). Since both collections are already scoped to `tenants/{tenantId}/...` via `tenantCollection(tenantId, ...)` before the `.where()` is even applied, this filter is a redundant no-op: it always matches every document in the stream, because every document in a tenant's subcollection was written with that same tenant's ID as `siteId`. This is not unique to `emergency` — the identical `'siteId': tenantId` pattern is used in `property/widgets/property_form_sheet.dart:81` and `property/providers/property_providers.dart:14`, and in 3 places in `operations` (`action_tracker_screen.dart:87`, `action_form.dart:50`, and 4 separate `.where('siteId', ...)` calls inside `operations_hub_metrics.dart`) — all filtering on the same tenant-equals-tenant tautology. No genuine multi-site concept exists anywhere in the codebase to populate `siteId` with instead: `property`'s own `Property` model (`property_models.dart:3-19`) — the closest domain object that actually represents a physical location (it carries `address`/`lat`/`lng`) — has no `siteId` field and isn't referenced by any of these `.where('siteId', ...)` call sites at all. In other words, "site" as a field name exists in several places across the app, but "site" as a concept distinct from "tenant" does not exist anywhere yet.

**Required fix:** Given no real multi-site concept exists yet (confirmed above, not just for this module), remove the redundant filter rather than trying to make it meaningful: delete `.where('siteId', isEqualTo: siteId)` from both `emergency_drills_tab.dart:58` and `emergency_equipment_tab.dart:62` (the tenant-scoped collection path already provides correct scoping on its own), and stop writing `'siteId'` from `drill_form_card.dart:54`/`equipment_form_card.dart:47` unless a real future use is identified — if the field is kept for forward-compatibility with a future real multi-site feature, leave a short code comment stating it's currently synonymous with `tenantId` and not yet load-bearing, so a future reader doesn't assume it's already doing real work. This item is scoped to `emergency` only — do not modify `property`/`operations`' analogous instances as part of this fix, since they're outside this cluster's assignment, but the pattern is flagged here (and worth surfacing to whoever owns those modules) so a future multi-site effort knows to check all 3 modules, not just one. If multi-site scoping is genuinely on the near-term roadmap, the alternative fix is building a real `Site`/`Location` concept (`property`'s `Property` model is the natural foundation, given it already carries address/lat/lng) and migrating `siteId` to reference it for real — but per AGENTS.md §7, don't guess this is in scope; treat it as an Open Question for product to confirm rather than building speculatively.

**Verification:** Confirm the Drills/Equipment tabs show exactly the same documents after the filter is removed (since it was already a no-op, behavior should be visually identical — this is a code-cleanliness fix, not a behavior change). `flutter analyze` — confirm no new warnings from the removed `siteId` field if it's also dropped from the form submissions.

---
### System Admin Cluster

### F-508: `SettingsScreen`'s "Security" tiles show copy that doesn't match the real, code-enforced behavior
**Severity:** Medium
**Module(s) / File(s):** `lib/features/settings/screens/settings_screen.dart:52-77`, `lib/core/services/session_manager.dart:16`, `lib/main.dart:101-107`
**Depends on:** none
**Source:** `docs/modules/settings.md` §6, §7

**Current behavior:** Two static, non-interactive info tiles on `SettingsScreen` describe security behavior inaccurately:
- **Inactivity timeout:** `settings_screen.dart:55-57` states "Required to unlock session after **15m** of inactivity." `SessionManager._timeoutDuration` (`session_manager.dart:16`) is `Duration(minutes: 30)` — the real timeout is double what the UI claims. A user relying on this copy would believe their session locks twice as fast as it actually does, which is a mild security-messaging concern in the less-safe direction (the real session stays unlocked longer than documented).
- **Screen capture protection scope:** `settings_screen.dart:67-69` states protection is "Enabled on sensitive screens (Executive Dashboard, Action Tracker)" — implying two specific, named screens. `ScreenProtector.preventScreenshotOn()`/`protectDataLeakageWithBlur()` are called exactly once, unconditionally, in `main.dart:101-107` (`if (!kIsWeb) { ... }`), applying to the entire app on every non-web platform, not two named screens. The real behavior here is broader (and more protective) than the copy states, but the copy itself is simply wrong either way.

Both tiles have `trailing: Icon(Icons.check_circle)` and no `onTap` — they present as settled, accurate status displays, not aspirational copy, which is what makes the mismatch worth fixing rather than ignoring.

**Required fix:** Update the two subtitle strings in `settings_screen.dart` to match the real, code-enforced values: change "15m" to "30m" (line 56), and change "Enabled on sensitive screens (Executive Dashboard, Action Tracker)" to describe the real global, non-web scope (e.g., "Enabled app-wide on mobile and desktop platforms"), unless the intent is instead to make the *code* match the originally-stated narrower spec (per-screen scoping, 15-minute timeout) — that would be a larger change (screen-scoped `ScreenProtector` calls, a different `SessionManager` constant) and a product decision about which behavior is actually correct, not just a copy fix. Absent other direction, fixing the copy to match the code is the smaller, lower-risk direction and is the one assumed here.

**Verification:** Read `SettingsScreen`'s Security section after the change and confirm the displayed timeout and protection-scope text match `SessionManager._timeoutDuration` and `main.dart`'s `ScreenProtector` call site exactly.

---

### F-509: `isDarkModeProvider` is not persisted — dark mode resets to light on every app restart
**Severity:** Medium
**Module(s) / File(s):** `lib/core/providers/app_providers.dart:179`, `lib/features/settings/screens/settings_screen.dart:26-38`, `lib/main.dart:124`
**Depends on:** none
**Source:** `docs/modules/settings.md` §5, §7

**Current behavior:** `isDarkModeProvider` (`app_providers.dart:179`) is a bare `StateProvider<bool>((ref) => false)` — confirmed by grep, referenced only in `main.dart:124` (feeds `MaterialApp.router`'s `themeMode`), `app_providers.dart` itself, and `settings_screen.dart:28-36` (the toggle `Switch`). No Hive box write, no `shared_preferences` write, no persistence mechanism of any kind is attached to it. The toggle visibly works for the remainder of the current app session but silently reverts to light mode the next time the app is launched, with no indication to the user that their preference wasn't saved.

**Required fix:** Persist the value on change and restore it on startup. Given the app already depends on `hive_flutter` (used by `OfflineSyncService`, see F-507) and initializes Hive in `main.dart` before `runApp`, a small dedicated Hive box (e.g. `Hive.openBox<bool>('preferences')`, opened in `main.dart` alongside/after the `Hive.initFlutter()` call) is the most consistent choice given the rest of the app's offline-first posture — read the stored value when constructing `isDarkModeProvider`'s initial state, and write to it inside a listener (or convert `isDarkModeProvider` to a small `StateNotifier` that persists on every `state =` write) whenever `settings_screen.dart:34`'s `onChanged` fires.

**Verification:** Toggle dark mode on, fully close and relaunch the app (not just hot-reload/hot-restart, which retain in-memory Riverpod state), and confirm it opens in dark mode. Toggle back to light and repeat.

---

### F-511: Remove dead `pendingApprovalsProvider` stub
**Severity:** Medium
**Module(s) / File(s):** `lib/features/dashboard/providers/approvals_provider.dart:26-50`
**Depends on:** none
**Source:** `docs/modules/dashboard.md` §5, §7

**Current behavior:** `pendingApprovalsProvider` (`approvals_provider.dart:26-50`) is a `StreamProvider<List<ApprovalItem>>` built from an `async*` generator whose body, after an early `yield []` when `userProfile` is null, trails off into six lines of comments describing different ways one *could* combine multiple Firestore streams (RxDart, `StreamGroup`, a manual `StreamController`) without ever choosing one or emitting a second value — for a non-null profile, the generator never yields and the stream simply never completes or emits, hanging indefinitely. Confirmed by repo-wide grep on `pendingApprovalsProvider\b`: the only reference anywhere in `lib/` is this provider's own declaration — no screen watches or reads it. The actual approvals UI (`approvals_inbox_screen.dart`) confirmed instead uses `pendingApprovalsFutureProvider` (lines 38, 60, 68 — a separate, working `FutureProvider.autoDispose` a few lines below in the same file), consistent with `dashboard.md`'s assessment that this provider was superseded and left behind rather than ever finished.

**Required fix:** Delete `pendingApprovalsProvider` (lines 26-50) entirely, keeping `ApprovalItem` and `pendingApprovalsFutureProvider`. Re-run `grep -rn "pendingApprovalsProvider\b" lib/` immediately before deleting to reconfirm zero external references still holds (code may have moved since this was drafted) — do not delete on the strength of this doc alone. `dashboard.md`'s own open question about whether `pendingApprovalsFutureProvider` itself should become a real `StreamProvider` (matching the rest of `dashboard`'s real-time-first pattern) is a separate, larger change — out of scope for this dead-code-removal item.

**Verification:** `flutter analyze` after deletion — confirm no new "undefined identifier" errors. Open the Approvals Inbox side-sheet (from `dashboard_header.dart`) and confirm it still lists pending leave requests / job requisitions exactly as before, since it never depended on the deleted provider.

---

### F-516: Error-message truncation (`.substring(0, 120)`) throws `RangeError` on short error messages, in 2 files
**Severity:** Medium
**Module(s) / File(s):** `lib/features/ai_tools/widgets/sheq_chat_tab.dart:70`, `lib/features/ai_tools/widgets/copilot_chat_widget.dart:76`
**Depends on:** none (independent of F-014's entry-point fix for `copilot_chat_widget.dart` — that item makes this screen reachable, this item is a separate correctness bug found in the same file while reviewing it for F-014; the `sheq_chat_tab.dart` instance is already reachable today via the live `/ai` route, regardless of F-014)
**Source:** `docs/modules/ai_tools.md` (file-level finding, not separately called out in §7 prose — found via direct code review during this drafting pass)

**Current behavior:** Both files' chat-send error handlers build the displayed error message identically:
```dart
text: 'Error: ${e.toString().substring(0, 120)}',
```
(`sheq_chat_tab.dart:70`, inside `_send()`'s `catch` block; `copilot_chat_widget.dart:76`, inside `_send()`'s `catch` block — confirmed by grep, these are the only 2 occurrences of this exact pattern anywhere in `lib/`). `String.substring(0, 120)` throws a `RangeError` if the string is shorter than 120 characters. Many real Dart/Firebase exceptions produce short `toString()` output (e.g. a bare `Exception: No response received.` is 33 characters), so this is not an edge case — it is the common case for short, well-formed error messages. Because the `.substring()` call happens *inside* the `catch` block while constructing the very `ChatMessage` meant to display the error, a short exception message causes a second, unhandled `RangeError` at that point, which propagates up through `setState` uncaught — the intended graceful "show an error bubble" path instead crashes the widget. `sheq_chat_tab.dart` is part of the live, routed `/ai` screen (`AIChatScreen`'s first tab) — this is reachable and exercisable today, not gated behind any unreachability finding. `copilot_chat_widget.dart` is currently reachable only once F-014's entry-point fix for `CopilotScreen` lands, but the bug itself is independent of that reachability work.

**Required fix:** In both files, replace the unsafe truncation with a length-checked version, e.g.:
```dart
final msg = e.toString();
text: 'Error: ${msg.length > 120 ? msg.substring(0, 120) : msg}',
```
or equivalently `msg.substring(0, msg.length.clamp(0, 120))`. Apply the identical fix in both files since they're independent copies of the same logic, not shared code.

**Verification:** Force each chat send path to throw an exception with a short `toString()` (e.g., temporarily throw `Exception('short')` in place of the real call, or trigger a real short-message failure such as an invalid-argument error from the Gemini SDK) and confirm the error bubble renders with the short message instead of crashing. Confirm a genuinely long error message (over 120 characters) still truncates correctly.

---

### [DONE] F-517: `CopilotPanel` has no service/provider layer — the Cloud Function call sits directly inside the widget's `State` class
**Severity:** Medium
**Module(s) / File(s):** `lib/features/copilot/screens/copilot_panel.dart`
**Depends on:** none
**Source:** `docs/modules/copilot.md` §4, §7

**Current behavior:** `_CopilotPanelState._sendMessage()` (`copilot_panel.dart:87-138`) constructs the `FirebaseFunctions` callable and calls it directly (lines 99-105):
```dart
final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
    .httpsCallable('askCopilot');
final result = await callable.call<Map<dynamic, dynamic>>({...});
```
There is no `services/` or `providers/` subdirectory anywhere in `lib/features/copilot/` — confirmed, the module is a single file. This is an AGENTS.md §1 "Predictable Separation of Concerns" gap ("Keep UI files strictly visual. Business logic... must reside entirely within the State Management Layer") — a smaller-scale version of the same issue `emergency.md` documents for its whole module. Functionally the feature works today (the Cloud Function call succeeds), so this is an architectural-cleanliness finding, not a correctness bug.

**Required fix:** Extract the Cloud Function call into a dedicated service class (e.g. `lib/features/copilot/services/copilot_panel_service.dart` — note this is a different, new file from `ai_tools`'s existing `CopilotService`, which is a separate, unrelated implementation calling Gemini directly rather than this module's `askCopilot` Cloud Function; do not merge the two without a deliberate decision, see `ai_tools.md`'s and `copilot.md`'s shared open question on this) and a matching Riverpod provider, following the separation already used correctly elsewhere in the app (e.g. `crm_service.dart` + `crm_providers.dart`'s split between a plain service class holding the actual calls and a thin provider exposing it to widgets). `CopilotPanel`'s `_sendMessage()` should shrink to calling `ref.read(copilotPanelServiceProvider).ask(query, screenContext: widget.screenContext)` and handling only the returned result/error for display.

**Verification:** `flutter analyze` after the refactor. Confirm `CopilotPanel` still successfully round-trips a real question to the `askCopilot` Cloud Function and displays the answer/confidence exactly as before — this should be a pure refactor with no behavior change.

---

### [DONE] F-518: `screenContext` is never populated — `CopilotPanel` always answers with zero awareness of which screen it was opened from
**Severity:** Medium
**Module(s) / File(s):** `lib/features/copilot/screens/copilot_panel.dart:28-37, 104`, `lib/config/router.dart:273-276`
**Depends on:** none
**Source:** `docs/modules/copilot.md` §5, §7, §8

**Current behavior:** `CopilotPanel`'s constructor (`copilot_panel.dart:28-37`) accepts a `screenContext` parameter (default `''`, line 33), documented in its own code comment (lines 29-30) as existing specifically "so callers can pass the current screen / module so the Copilot can give more relevant answers." `_sendMessage()` forwards it to the Cloud Function verbatim (line 104: `'screenContext': widget.screenContext`). Its **only** instantiation site anywhere in the app is `router.dart:275`: `const CopilotPanel()` — no argument passed, so every real invocation sends `screenContext: ''`. Server-side, `copilotEngine.ts`'s `askCopilot` renders this into its prompt template as `"Context: ${screenContext.trim()}"`, which is simply an empty clause on every call today. The contextual-awareness feature is fully built on both the client (this parameter) and server (the prompt template that consumes it) but never actually wired through — the panel answers identically regardless of which screen the user opened it from.

**Required fix:** Since `CopilotPanel` is only ever reached via the `/copilot` route (a Launchpad tile tap, not a contextual push from within another screen — see F-519, which is related but distinct), there is no "previous screen" naturally available at the point `router.dart:275` constructs it today. The straightforward fix given the current routing shape: have `router.dart`'s `/copilot` `GoRoute` builder read a `from` query parameter (e.g. `/copilot?from=finance`) and pass that through as `screenContext`, with whichever screen/hub links to Copilot appending its own name to the URL when it does. This only produces a meaningful value once at least one real caller passes `from` — if F-519's overlay-conversion is implemented instead, wiring `screenContext` from the calling screen at that point is more natural and should be done together rather than twice.

**Verification:** From at least one screen that links to Copilot with a `from` value set, open the panel, ask a question, and confirm (via Cloud Function logs or a temporary debug print of the constructed prompt) that the context clause is non-empty and matches the screen navigated from.

---

## Low

### F-504: `SessionManager`'s inactivity auto-lock is fully disabled in debug builds — confirm intent and make it testable
**Severity:** Low
**Module(s) / File(s):** `lib/core/services/session_manager.dart:20-36`
**Depends on:** none
**Source:** `docs/modules/auth.md` §7

**Current behavior:** `SessionManager.startSession()` (`session_manager.dart:20-24`), `userInteracted()` (lines 26-30), and `_startTimer()` (lines 32-36) each early-return under `kDebugMode` before ever touching `_inactivityTimer`. The 30-minute inactivity auto-lock (`_timeoutDuration`, line 16) therefore cannot fire in a debug build under any circumstance — `LockScreen` can only ever be reached in a release or profile build. This may well be intentional (uninterrupted local development is a reasonable default), but as currently written there is also no way to opt back into exercising the lock flow during development — no flag, no debug menu action, no shortened timeout for testing — so a regression in the lock/unlock path (e.g. F-505) would not be caught by anyone running a debug build, only by manual release-build testing.

**Required fix:** This is a judgment call, not a clear bug — flagging for a decision rather than prescribing a fix. If the `kDebugMode` exemption is intentional and accepted, no code change is needed; consider adding a one-line comment at each of the three early-returns stating that explicitly, so a future reader doesn't mistake it for an oversight (it currently reads as one). If exercising the lock screen during development is actually needed, add a debug-only affordance instead of removing the exemption outright — e.g., a "Simulate Lock" action reachable only under `kDebugMode` (a debug menu entry, or a long-press on some existing debug-only UI element) that calls `_onTimeout()` directly, leaving the real 30-minute timer still disabled for normal day-to-day development.

**Verification:** N/A if the exemption is kept as-is (documentation-only change). If a debug-only trigger is added, confirm in a debug build that the new action locks the session and that `LockScreen`'s biometric/no-biometric flows both behave identically to a real release-build lock.

---

### F-506: Raw `ScaffoldMessenger.showSnackBar` used in `EnterpriseSSOScreen` instead of `UIUtils.showToast`
**Severity:** Low
**Module(s) / File(s):** `lib/features/auth/screens/enterprise_sso_screen.dart:21-23, 42-44`
**Depends on:** none (independent of F-014's entry-point fix for this same screen — this is a separate bug found while reviewing the file for F-014, not the reachability issue itself)
**Source:** `docs/modules/auth.md` §4

**Current behavior:** `_handleSAMLSignIn()` calls `ScaffoldMessenger.of(context).showSnackBar(...)` directly in two places — the empty-provider-ID validation message (lines 21-23) and the SAML-failure error message (lines 42-44) — instead of the AGENTS.md §1-mandated `UIUtils.showToast`. This is the same violation class as F-013, just not one of that item's enumerated files (confirmed: `docs/modules/_known_gaps_rollup.md` §1.6 caps its tally at 6 files across 5 modules, and `EnterpriseSSOScreen` is not among them) — an 8th instance of the same pattern, found independently while checking this file for other bugs alongside F-014's entry-point work.

**Required fix:** Replace both `ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(...)))` calls with `UIUtils.showToast(context, '...', type: ToastType.error)`, matching the pattern used correctly across the rest of the app (e.g. `job_application_form.dart`'s `_submit()` in the `public` cluster is a minimal correct template for both the success and error cases).

**Verification:** Trigger both code paths (submit with an empty Provider ID; submit with a Provider ID that causes `signInWithSAML` to throw) and visually confirm both now render as the app's standard toast rather than a default Material SnackBar.

---

### F-510: `OfflineQueueScreen` has no `BusinessOsLaunchpad` tile — reachable only by direct route
**Severity:** Low
**Module(s) / File(s):** `lib/features/dashboard/screens/business_os_launchpad.dart:256-298`, `lib/features/settings/screens/offline_queue_screen.dart`
**Depends on:** none
**Source:** `docs/modules/settings.md` §4, §7

**Current behavior:** `OfflineQueueScreen` is correctly routed (`/offline-queue`, `router.dart:235-239`), but `BusinessOsLaunchpad`'s "System Administration" section (`business_os_launchpad.dart:256-298`) lists only 5 tiles — Command Center (`/operations`), AI Chat (`/ai`), Global Settings (`/settings`), Global Control Tower (`/control-tower`), Sentinel Copilot (`/copilot`) — confirmed by reading the full tile list, there is no sixth tile for `/offline-queue`. This is distinct from F-014's "fully unreachable" pattern (`EnterpriseSSOScreen`, `CopilotScreen`, etc.): this screen genuinely is reachable, just not discoverable through the app's own navigation — a user would need to know the route string or reach it via an external deep link. This gap is notable specifically because the IT/Systems Administrator persona's own shared-doc journey text ("Monitor Background Sync Queues") names exactly this screen's purpose as a first-class task.

**Required fix:** Add a `_LaunchpadCard` entry for `OfflineQueueScreen` to the System Administration section in `business_os_launchpad.dart`, following the existing pattern (e.g. `title: 'Offline Sync Queue', icon: Icons.sync, color: Colors.blueGrey, route: '/offline-queue'`).

**Verification:** From `/launchpad`, confirm a new tile opens `OfflineQueueScreen` without needing to type the route directly.

---

### F-515: `SafetyFlashTab`'s "copy" button reports success without copying anything
**Severity:** Low
**Module(s) / File(s):** `lib/features/ai_tools/widgets/safety_flash_tab.dart:142-147`
**Depends on:** none
**Source:** `docs/modules/ai_tools.md` §4, §7

**Current behavior:** The `IconButton` at `safety_flash_tab.dart:142-147` (`Icons.copy`) has:
```dart
onPressed: () {
  UIUtils.showToast(context, 'Copied to clipboard');
},
```
No `Clipboard.setData` call exists anywhere in the file — confirmed by checking the import list (`material.dart`, `flutter_riverpod`, `google_generative_ai`, `app_providers.dart`, `ui_utils.dart`, `gemini_provider.dart` only; no `package:flutter/services.dart`, which is what `Clipboard` requires). The button shows a success toast unconditionally, regardless of whether anything was actually placed on the clipboard — a user who taps it and then pastes elsewhere gets nothing, with no indication anything went wrong, since the app told them it succeeded. This is the same "reports success without performing the action" shape as F-520's "Mark all read" stub.

**Required fix:** Add `import 'package:flutter/services.dart';` and call `await Clipboard.setData(ClipboardData(text: _result))` before showing the toast, so the button actually does what it claims.

**Verification:** Generate a Safety Flash bulletin, tap the copy button, then paste into any external text field and confirm the full bulletin text is present.

---

### [DONE] F-519: `CopilotPanel` is wired as a full routed screen, not the floating overlay its own design implies
**Severity:** Low
**Module(s) / File(s):** `lib/config/router.dart:273-276`, `lib/features/copilot/screens/copilot_panel.dart`
**Depends on:** none — likely superseded by F-018's ai_tools/copilot consolidation decision; keep any fix here minimal until that decision is made
**Source:** `docs/modules/copilot.md` §4, §7, §8

**Current behavior:** `CopilotPanel`'s own code comment (`copilot_panel.dart:26-27`) describes it as "A floating, glassmorphic side panel," and its build method (line 160: `width: 360`) constructs a fixed-width panel visually designed to sit over other content, with `BackdropFilter` blur (lines 157-158) intended to show whatever is behind it. Despite this, `router.dart:273-276` wires it as a normal `GoRoute` (`NoTransitionPage(child: CopilotPanel())`) — navigating to `/copilot` replaces the current screen entirely rather than floating above it, so the blur/glassmorphism effect has nothing behind it to blur, and the "side panel" framing doesn't match how it actually appears.

**Required fix:** Given this module's relationship to F-018's broader ai_tools/copilot consolidation decision is unresolved (three AI-chat implementations exist across the two modules; this one may be merged, replaced, or kept as-is depending on that decision), avoid a large investment here until F-018 resolves. If a minimal fix is wanted now regardless of that decision: convert the `/copilot` route to open `CopilotPanel` via `UIUtils.showSideSheet` from wherever it's launched (the Launchpad tile) instead of a `GoRoute`, matching the AGENTS.md §1-mandated pattern for exactly this kind of contextual panel — a small, self-contained change (remove the route, wrap the Launchpad tile's `onTap` in a `UIUtils.showSideSheet` call) that doesn't foreclose whatever F-018 eventually decides.

**Verification:** Tap the "Sentinel Copilot" Launchpad tile and confirm the panel now slides in as a side sheet over the Launchpad (with the blur effect visibly showing the Launchpad behind it) rather than navigating to a new full screen.

---

### F-522: `resumeLink` is a free-text URL field with no validation and no file upload
**Severity:** Low
**Module(s) / File(s):** `lib/features/public/widgets/job_application_form.dart:110-118`
**Depends on:** none
**Source:** `docs/modules/public.md` §7

**Current behavior:** `JobApplicationForm`'s résumé field (`job_application_form.dart:110-118`) is a plain `TextFormField` labeled "Resume Link (Google Drive, LinkedIn, etc.)" with only a required-non-empty validator (line 116: `val == null || val.isEmpty ? 'Required' : null`) — no URL-format validation, and no actual file-upload widget, despite `firebase_storage` being a real, used dependency elsewhere in the app (confirmed: `pubspec.yaml:17` declares it, and `incident_report_form.dart`/`feedback_overlay.dart` both use it for real uploads). Framed explicitly rather than asserting a verdict either way: this may be a deliberate scope choice (a link-based résumé submission is a legitimate, simpler design that avoids building file-upload infrastructure for a module that, per F-521, may not even be a priority destination yet) rather than an oversight — there is no evidence in the code or docs pointing definitively to one or the other.

**Required fix:** If a deliberate link-based design is confirmed (check with whoever owns the product decision before investing further), the minimal improvement is adding basic URL-format validation to the existing field (e.g. a regex or `Uri.tryParse(val)?.hasAbsolutePath` check) so obviously-malformed input is caught before submission, rather than accepting any non-empty string. If a real file upload is instead wanted, replace the field with a file picker (`file_picker` or a platform image/document picker) uploading to `firebase_storage` under a path like `tenants/{tenantId}/job_applications/{applicationId}/resume.pdf`, following the same upload pattern already used in `incident_report_form.dart`, and store the resulting download URL in `resumeLink` instead of a hand-typed one.

**Verification:** If validation-only: submit the form with a clearly invalid (non-URL) string in the résumé field and confirm it's now rejected client-side. If full upload: submit a real file and confirm it appears in the correct Firebase Storage path and the stored `resumeLink` field is a working download URL.

---
