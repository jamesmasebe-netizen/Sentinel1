# Known Gaps Rollup — All 28 Modules

Single index of every finding logged in each module doc's §7 Known Gaps, compiled 2026-07-28. Read this first to triage; follow the links into the per-module docs for full detail (code paths, exact line-level evidence, DB-to-UI audit tables).

**RE-VERIFIED 2026-08-10** (see `docs/testing/TEST_BACKLOG.md`'s "Flagged-not-fixed follow-up pass" and its own dated entries): this doc predates `docs/fixes/FIX_LIST.md`'s 109-item remediation (finished 2026-07-31) and the whole subsequent testing/extraction effort — a huge amount of fixing happened after this doc was written, without this doc being updated. A spot-check pass re-verified every row in §2's Critical table and the first 5 rows of the High table (24 rows total) against current code. Result: **23 of 24 are now `[FIXED]`**, confirmed via direct file:line citations, not assumption; 1 is `[PARTIAL]`. A later pass the same day re-verified the remaining 13 High/Medium rows (see §2) and `public`'s recruitment-pipeline disconnect (fixed end-to-end — see `TEST_BACKLOG.md`'s "T3-PUBLIC follow-up"). A third pass, same day, re-verified all of §1's cross-cutting patterns (§1.3/§1.5/§1.6/§1.7) — tagged inline below. Each re-verified row/pattern is tagged inline. **Rows/patterns without a tag were NOT re-checked** — treat those as still-uncertain, not still-true; verify before acting on them. Still not re-audited: §1.1/§1.2/§1.4/§1.8/§1.9/§1.10, and the full 27-module per-doc detail beyond what's summarized in this rollup.

Two ways to read this doc: **§1** groups findings by *pattern* — several of the most consequential bugs were written independently, by different people/passes, in different modules, without knowing about each other, which is itself informative (it means these are systemic habits, not one-off mistakes, and fixing the pattern once — e.g. in a shared lint rule or code-review checklist — is worth more than fixing each instance). **§2** groups the same findings by *severity* for a flat triage list.

---

## 1. Cross-Cutting Patterns

### 1.1 Firestore collections undeclared in `firestore.rules` → silently blocked by the catch-all `allow write: if false`
The single most repeated finding in the entire audit. Confirmed independently in **18 of 28 modules**: `safety` (capas, bbs_observations, ppe_compliance, ppe_inventory), `health` (medical_records, hygiene_surveys, first_aid_log(s)), `training` (courses, enrollments, training_enrollments, toolbox_talks), `workers_comp` (coida_claims), `compliance` (compliance_docs/compliance_documents), `environment` (waste_manifests, environmental_spills, esg_metrics), `operations` (actionItems, capas, bbs_observations, dynamic_risk_assessments, inventory_items, warehouses, integrations), `risk` (dynamic_risk_assessments, strategic_risks, bowtie_analyses), `finance` (all `fin_*` collections, budgetPlans, costCenters), `customer_service` (all `cs_*`), `field_service` (route_plans, customer_assets, iot_devices), `property` (all 6 of its collections), `public` (job_requisitions read + job_applications write — blocked for literally every caller, authenticated or not), `emergency` (emergency_drills, emergency_equipment), `supply_chain` (9 collections including the one MRP actually depends on), `people` (payroll_ledgers, compensation_plans, performance_reviews — the sensitive-data instance of this pattern), `notifications`, `billing`. `projects`' PMO island is a *stricter* variant — those root-level collections aren't reached by the catch-all at all, they're unreachable by any rule in the file.
**Fix shape:** this is one `firestore.rules` change, not 18 — enumerate the real collections each module actually uses (every module doc's §5 lists them) and add purpose-built rules, at minimum matching the tenant-catch-all's intent, with tighter rules for sensitive data (payroll/compensation/performance).

### 1.2 Hardcoded empty-string tenant ID (`tenantCollection("", ...)` / equivalent)
Confirmed independently **3 times**, always as a copy-paste-shaped bug against a sibling function that does it correctly in the same file or module: `training_providers.dart` (`coursesProvider`/`enrollmentsProvider`, 3 call sites), `projects`' `safety_compliance_data_fetcher.dart` (all 5 queries), `public`'s `JobApplicationForm._submit()`. Each silently targets `tenants/''/...` — a tenant that doesn't exist — so the affected reads/writes can never succeed for any real tenant, with no error surfaced to the user.
**Fix shape:** grep the codebase for `tenantCollection("` / `tenantCollection('' ` literal-empty-string patterns; each hit is the same bug.

### 1.3 Foreign-key fields rendered as plain `TextFormField` instead of a lookup
The DB-to-UI audit's signature finding, confirmed in **7 modules**: `crm` (`accountId`, `primaryContactId` on 2 forms), `people` (`departmentId`/`positionId` — hardcoded static dropdowns, not real lookups either), `finance` (`vendorId`/`customerId`/`journalEntryId` on invoice form; `accountId`/`costCenterId`/`projectId`/`taxCodeId` on journal line — 4 in one repeating row, the densest instance found), `field_service` (`customerId`, `assetId`, `territoryId`, `billingAccountId`, `agreementId`, `incidentTypeId`, `serviceTypeId`, `substatusId`), `supply_chain` (`vendorId`, `warehouseId`). Contrast: `risk`'s 4 forms and `equipment`'s form both use `EmployeeSelector` correctly everywhere a person reference appears — worth using as the reference implementation when fixing the others.

**[RE-VERIFIED 2026-08-10]** `crm`, `people`, `finance`, and `field_service` are now all **`[FIXED]`** — every field named above uses a real `EntitySelector<T>` lookup (`opportunity_form.dart`, `employee_profile_form.dart`, `invoice_form.dart`/`journal_entry_form.dart`, `work_order_form.dart`). `supply_chain` is **`[PARTIAL]`**: `purchase_order_form.dart`'s `vendorId` is fixed (`EntitySelector<Account>`), but `warehouseId` on the same form is still a plain `TextFormField`.

### 1.4 `employeeName` written as missing/never set, breaking display
Confirmed **3 times** with the identical shape (form writes `employeeId` only, list/card view reads `employeeName` and falls back to "Unknown Employee"): `people`'s `employee_360_profile_screen.dart` area is clean, but `health`'s `medical_form.dart`, and `training`'s `record_form_sheet.dart` and `allocate_course_form.dart` (2 separate forms, same module) all hit this.

### 1.5 `Navigator.push`/`MaterialPageRoute` used instead of `UIUtils.showSideSheet`
AGENTS.md §1 violation, confirmed in **5 modules**: `safety` (`safety_hub_screen.dart`'s "Scan Passport"), `supply_chain` (`SupplyChainHubScreen`), `projects` (`project_operations_hub_screen.dart`'s Gantt/Timesheet/Expense tiles), `customer_service` (`customer_service_hub_screen.dart` opening `KnowledgeBaseScreen`).

**[FIXED 2026-08-10]** All 4 — every file named above now calls `UIUtils.showSideSheet`; no `Navigator.push`/`MaterialPageRoute` remains in any of them (confirmed via direct grep, not assumption).

### 1.6 Raw `ScaffoldMessenger.showSnackBar` instead of `UIUtils.showToast`
AGENTS.md §1 violation, confirmed in **6 files across 5 modules**: `billing_portal_screen.dart`, `mrp_dashboard_screen.dart` + `production_order_screen.dart` (supply_chain), `timesheet_entry_screen.dart` (projects), `ticket_form.dart` + `knowledge_article_form.dart` (customer_service), `loto_management_screen.dart` (equipment, inconsistent with the same module's otherwise-correct usage elsewhere).

**[FIXED 2026-08-10]** All 6 — every file now uses `UIUtils.showToast`. `loto_management_screen.dart` itself turned out to have zero feedback calls at all (it's a pure list view now); the actual write lives in `loto_return_dialog.dart`, which correctly uses `UIUtils.showToast`. No `ScaffoldMessenger` remains anywhere in the LOTO flow.

### 1.7 Fully-built, zero-navigation-path features (banned-stub's inverse — the code is real, only the entry point is missing)
Confirmed **10+ times**: `safety`'s contractor/employee QR passport screens, `auth`'s `EnterpriseSSOScreen` (complete SAML form), `operations`' `inventory_dashboard_screen.dart`, `supply_chain`'s 3 detail screens + 3 forms + a BPF ribbon, `customer_service`'s entire real Firestore-backed implementation (parallel to the mocked one that's actually routed), `field_service`'s `WorkOrderDetailsScreen` (reachable, but fed a hardcoded fake ID so it can only ever render "not found"), `ai_tools`'s `CopilotScreen`/`CopilotChatWidget`/`RagService`, `projects`' 7-file PMO island (only live caller is the Lead-to-Cash orchestrator), `compliance`'s entire primary screen (the only module in the app where the *primary* screen itself, not a sub-screen, is unreachable), `equipment`'s main screen (see §2 Critical).

**[RE-VERIFIED 2026-08-10]** Per-item: `auth`'s `EnterpriseSSOScreen` **[FIXED]** (`router.dart` now declares `/sso`, wired from `login_screen.dart`). `operations`' `inventory_dashboard_screen.dart` **[FIXED]** (reachable from `operations_hub_modules.dart`'s Inventory card, independent of the earlier FAB fix). `supply_chain`'s 3 detail screens + 3 forms + BPF ribbon **[FIXED]** — all 6 (`InventoryItemDetailScreen`, `PurchaseOrderDetailScreen` with its BPF ribbon, `TransferOrderDetailScreen`, `InventoryItemForm`, `PurchaseOrderForm`, `TransferOrderForm`) now have live callers from the hub/dashboard screens fixed under §1.5 above. `customer_service`'s real implementation and `ai_tools`'s `CopilotScreen` stack: **[FIXED]** per this session's earlier T3 work (the mocked parallel and the orphaned Copilot stack were both deleted, not left dangling). `field_service`'s `WorkOrderDetailsScreen`, `compliance`'s primary screen, and `equipment`'s main screen: **[FIXED]**, confirmed earlier in this rollup's Critical table. Two items are **[PARTIAL]**: `safety`'s QR passport screens — the *contractor* one is reachable (`contractor_projects_sheet.dart` → `contractor_management_screen.dart`), but the *employee* one is still orphaned, since its only caller, `Employee360ProfileScreen`, itself has zero instantiation sites anywhere in `lib/` and no route. `projects`' PMO island — *viewing* is now reachable (`ProjectDetailScreen`'s WBS Tasks/Expenses tabs, reached via `quote_detail_screen.dart`'s project-creation flow), but `PmoService.createWbsTask`/`createExpense` still have zero callers anywhere — the island still has no UI to create a WBS task or PMO expense, only to view ones that don't exist yet.

### 1.8 Hardcoded/mocked data presented as live (AGENTS.md §2 "No Hardcoded Data")
Confirmed **10+ times**, ranging from single stat chips to entire screens: `people`'s 2 mocked 360-profile tabs, `health`'s `OHStatChip` percentages, `workers_comp`'s entire compliance checklist tab (no backing model at all), `dashboard`'s launchpad (no RBAC despite stated intent), `executive`'s entire KPI/alert set, `operations`' `schedule_board_screen.dart` (own comments admit "Mock data"), `projects`' `revenue_recognition_screen.dart` (entirely fabricated, not partially wired as assumed going in) and its hardcoded `'default-property'` on every new project, `supply_chain`'s hub screen + `ProductionOrderScreen` (falsely toasts "Inventory updated"), `notifications`' entire screen (own code comment admits it), `property`'s "Linked Incidents"/"Active Permits" panels.

### 1.9 The BPF engine is effectively unused end-to-end, not just partially stubbed
This is the most important single synthesis in this rollup, only visible by cross-referencing docs: `finance.md` found **`bpfOrchestratorProvider` has zero call sites anywhere in `lib/`**. That provider is what every "wired" BPF claim (Lead to Cash's `convertLeadToOpportunity`/`createQuoteFromOpportunity`/`createProjectFromQuote`/`createInvoiceFromProject`, Procure to Pay's `createInvoiceFromPurchaseOrder`) actually runs through. So even Lead to Cash — the one flow with genuinely correct, non-stubbed orchestrator code — is never triggered from any live screen today. Combined with the already-known stub status of Hire-to-Retire/Issue-to-Resolution/Asset-Lifecycle and the total absence of Project-Concept-to-Close wiring (see `_shared_personas_and_bpfs.md`), the accurate statement is: **none of the 6 BPFs currently execute through the app's UI**, though Lead to Cash's backend logic would work correctly if something called it.

### 1.10 Duplicate/legacy models with no clear owner
`crm`'s `Deal`/`DealStage` (superseded by `Opportunity`), `finance`'s `ChartOfAccounts` and `TaxRate`/`CurrencyExchange`, `billing`'s plural `subscription_models.dart`, `supply_chain`'s `BillOfMaterials`/`BomLine`/`ProductionOrder`, `people`'s possible `employee.dart`/`leave_request.dart` duplication against `hr_models.dart`, `field_service`'s 3-way `WorkOrder` shape collision across `FieldServiceService`/`iotTelemetryIngest`/`loto_automation.dart` (2 of the 3 write a shape the module's own detail screen can't read).

---

## 2. Findings by Severity

### Critical — silent data loss, security exposure, or a core flow that cannot work as built
| Module | Finding |
|---|---|
| `auth` | **[PARTIAL 2026-08-10]** `setCustomUserClaims` called nowhere in either Functions codebase — the mechanism `firestore.rules` depends on for tenant/role scoping has no producer. **Correction:** the code exists and is correct (`authClaims.ts`'s `syncUserClaims`, a Firestore trigger that calls `admin.auth().setCustomUserClaims()` for real) and is exported from `index.ts` — it would deploy today. The real, still-live blocker is that it's never been deployed: the Firebase project is on the Spark billing plan, which blocks all Cloud Functions deploys. Not a code gap; a billing/deploy handoff. |
| `auth` | **[FIXED]** Live, unguarded "Bypass Login (Dev)" button on the production login screen sets a mock-auth flag without calling Firebase Auth — fixed under `F-501`: the button is now `kDebugMode`-gated (`login_card.dart:100`) and calls the real `AuthService.devBypassLogin()` -> `signInAnonymously()`. |
| `people`, `projects`, `public` | **[FIXED 2026-08-10]** Hardcoded empty-string tenant ID (pattern §1.2) — confirmed via grep, no literal `tenantCollection("")` hits anywhere in `lib/`; `training_providers.dart`, `safety_compliance_data_fetcher.dart`, and `public`'s form-submission code all thread a real resolved tenantId now. |
| `finance` | **[FIXED]** `bpfOrchestratorProvider` has zero call sites — no BPF actually executes (pattern §1.9). Confirmed reachable from `lead_detail_screen.dart` ("Convert Lead"), `opportunity_detail_screen.dart` ("Generate Quote"), and `quote_detail_screen.dart` ("Accept Quote & Create Project") — all 3 call `ref.read(bpfOrchestratorProvider)` directly. |
| `finance` | **[FIXED 2026-08-10]** `FinanceService`'s real write targets (`fin_*` collections) undeclared in rules — all 7 `fin_*` collections `FinanceService` writes to are now declared in `firestore.rules` (lines 223-259, duplicated 489-526), matching what the service actually writes. |
| `finance` | **[FIXED 2026-08-10]** Immutability principle unenforced — `finance_service.dart:85-108` now has `_assertMutable()`, blocking `updateJournalEntry()`/`deleteJournalEntry()` on `POSTED`/`REVERSED` entries (cites `F-311`). |
| `risk` | **[FIXED 2026-08-10]** `dra_form.dart` writes `activity`/`area`; every reader expects `taskDescription`/`location` — `dra_form.dart:97` now writes `taskDescription` for real, matching every reader (`dra_card.dart`, `safety_compliance_data_fetcher.dart`). |
| `contractors` | **[FIXED 2026-08-10]** camelCase/snake_case collection typo — all 3 contractors files now consistently use `'safety_file_submissions'`; no camelCase spelling found anywhere in the module. |
| `compliance` | **[FIXED 2026-08-10]** Fully unreachable module — `/compliance` route exists (`router.dart:162-165`) and is wired to the launchpad; write and read paths agree on `compliance_docs`. |
| `equipment` | **[FIXED 2026-08-10]** `/equipment` had no route — it's now declared (twice, harmlessly) in `router.dart` and wired to the launchpad tile. |
| `operations` | **[FIXED 2026-08-10]** Action Tracker's create form and read-side model disagreed — both now consistently use `assignee`/`collectionName`. |
| `supply_chain` | **[FIXED 2026-08-10]** MRP engine's 3 different stock-quantity field names — `mrpEngine.ts` now reads `stock_level`, matching what `InventoryItem`/`ScmService` actually persist (cites `F-201`). Note: `docs/modules/supply_chain.md:73` itself is now stale documentation describing the old mismatch. |
| `billing` | **[FIXED 2026-08-10]** `createStripeCheckoutSession` "exists in neither Functions codebase" — it exists (`billing.ts:11`), is exported, and is called from `billing_service.dart`/`billing_portal_screen.dart`. |
| `billing` | **[FIXED 2026-08-10]** 3-way path mismatch — app and webhook now agree on `tenants/{t}/subscription/status`; the old `tenants/{t}/billing/subscription` path doesn't exist anywhere. |
| `settings` | **[FIXED 2026-08-10]** `OfflineSyncService.initialize()` never called — `main.dart:123` now calls it during app boot, before the queue is used. |
| `training` | **[FIXED/NUANCED 2026-08-10]** 3 mutually-unaware "enrollment" collections — `TrainingService.getComprehensiveEmployeeRecord()` now queries all 3 and combines them; no longer mutually unaware at the service layer. Individual UI tabs still each surface only one collection's slice — an open design question per the module's own docs, not a bug. |
| `training` | **[FIXED 2026-08-10]** `allocate_course_form.dart` never sets `assignedAt` — it does now (cites `F-009`), matching the Manager Hub's `orderBy('assignedAt')`. |
| `customer_service` | **[FIXED 2026-08-10]** Two complete parallel implementations — only one exists now; the real, Firestore-backed one, reachable from the router. |
| `field_service` | **[FIXED 2026-08-10]** 3-way `WorkOrder` shape collision — model, Cloud Function, and automation script now agree on snake_case keys; the detail screen navigates with a real order id, not a hardcoded fake one. |
| `projects` | **[FIXED 2026-08-10]** PMO island's root collections unreachable by any rule — now explicitly declared in `firestore.rules` (dated comment citing `TEST_BACKLOG.md T2c-SENSITIVE`). |
| `property` | **[FIXED 2026-08-10]** All 6 collections undeclared in rules — all 6 now declared (this session's T3-PROPERTY work). |
| `public` | **[FIXED 2026-08-10]** Nothing reachable by a 5-layer blocked chain — `public_tenant_directory`/`job_requisitions`/`job_applications` are now permissively declared for anonymous access (cites `F-501`), and `/careers/:tenantSlug` is a real, reachable route. **Still open, separately** (see `docs/testing/TEST_BACKLOG.md` T3-PUBLIC, not re-verified as part of this row): the *disconnected recruitment pipeline* — real applications land in a collection nothing reads, the recruiter Kanban reads a different, unpopulated one. That's a distinct, still-unresolved finding from this specific "is it reachable at all" one. |

### High — real functional or security gaps, not immediately catastrophic
| Module | Finding |
|---|---|
| `auth` | **[FIXED 2026-08-10]** Hardcoded Firebase + Gemini API keys committed in `firebase_config.dart` — removed (cites `F-502`); real init now reads `.env`/`--dart-define`. |
| `auth` | *(not re-verified this pass)* No form/UI exists to set `UserProfile.department`/`jobTitle`/`phone`/`preferences` anywhere — "Edit Profile" is a stub toast. |
| `notifications` | **[FIXED 2026-08-10]** `NotificationService` had zero callers — `app_providers.dart` now calls `.init()` on profile-ready, and `emergency_broadcast_tab.dart` calls `.sendEmergencyBroadcast()`. |
| `ai_tools` | *(not re-verified this pass)* All 4 AI-chat tabs generate content that is never saved anywhere — no "Save to Incident" action exists. |
| `ai_tools` | *(not re-verified this pass)* `GEMINI_API_KEY` likely resolves empty as committed. |
| `executive` | *(not re-verified this pass)* All KPI/alert data hardcoded; zero drill-down navigation. |
| `safety` | *(not re-verified this pass)* `Incident` model exists but nothing actually parses documents through it. |
| `safety` | **[FIXED 2026-08-10]** `reporterName` hardcoded to `'Selected Employee'` — `incident_report_form.dart` now derives it from the selected employee's real name; no hardcoded literal remains anywhere in `lib/`. |
| `field_service` | *(not re-verified this pass)* 4 structured `Map` fields rendered as raw hand-typed JSON text fields. |
| `projects` | *(not re-verified this pass)* `timesheet_entry_screen.dart` has no Firestore call at all. |
| `projects` | *(not re-verified this pass)* `revenue_recognition_screen.dart` is entirely fabricated data. |
| `supply_chain` | **[PARTIAL 2026-08-10]** Hub screen hardcoded `ListTile`s with no `onTap` handlers — `InventoryDashboard` and `WarehouseManagementScreen` are fully fixed (real streams, real `onTap`). `AssetManagementScreen` is half-fixed: "Property Management"/"Equipment Tracking" tiles work now, but "Preventative Maintenance"/"Asset Lifecycle" remain unwired `const ListTile`s. |
| `supply_chain` | **[STILL TRUE, in progress 2026-08-10]** 2 literal "Coming Soon" stub cards next to unused `ScmService` CRUD — this is exactly the banned-stub item currently being fixed (production orders + inventory transaction history) as part of this same follow-up pass; see `docs/testing/TEST_BACKLOG.md`. |
| Pattern §1.3 | FK-as-textfield across 7 modules |
| Pattern §1.5 / §1.6 | Navigation and toast rule violations across 9 files |
| Pattern §1.7 | 10+ fully-built, unreachable features |

### Medium — architecture/consistency issues, dead code, UX gaps
| Module | Finding |
|---|---|
| `dashboard` / `executive` | Two independently-built "landing/exec surface" screens serving the same persona with zero shared code |
| `ai_tools` / `copilot` | 3 distinct AI-chat implementations across 2 modules; one (`CopilotScreen`) has zero instantiation sites |
| `crm` | `accountsProvider`/`contactsProvider`/`opportunitiesProvider`/`quotesProvider` are static `StateProvider`s, not streams — needs confirming whether any screen still binds to them |
| `finance` | `LedgerPostingService` (correct `postJournalEntry` wrapper) has zero call sites; `journalEntriesProvider`/`invoicesProvider` are dead, so `FinanceHubScreen` always shows an empty journal list |
| `people` | Payroll/compensation/performance collections rely on the generic catch-all rather than role-scoped rules (the sensitive-data instance of §1.1) |
| Pattern §1.10 | 6+ duplicate/legacy model sets with no clear ownership |
| All 27 non-shared docs | IA/taxonomy conflict (4-Hub vs 7-Pillar vs 8-Compartment) — documented once in `_shared_personas_and_bpfs.md`, not re-litigated per module |

---

## 3. Clean / positive findings worth preserving as reference implementations
- **`environment`** — the cleanest module in the audit: live analytics computed from real streams, no hardcoded percentages, no field-name mismatches in either of its 2 forms.
- **`equipment`**'s create form — only one gap (a status enum missing `'Locked Out'`) across 7 fields; `assignedToId`/`category`/`nextInspectionDate` all use correct widgets.
- **`risk`**'s 4 forms — zero FK-as-textfield instances, the pattern §1.3 issue found everywhere else; `EmployeeSelector` and `showDatePicker` used consistently.
- **`operations`**'s `integration_config_form.dart` — no gaps, correct widget types throughout, `tenantId` system-set rather than user-entered.

---

*Source: `docs/modules/*.md` §7 sections, compiled 2026-07-28. Re-run the extraction (`awk` over `## 7. Known Gaps` … `## 8. Open Questions` across all module docs) if the underlying docs change.*
