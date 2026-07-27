# Known Gaps Rollup — All 28 Modules

Single index of every finding logged in each module doc's §7 Known Gaps, compiled 2026-07-28. Read this first to triage; follow the links into the per-module docs for full detail (code paths, exact line-level evidence, DB-to-UI audit tables).

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

### 1.4 `employeeName` written as missing/never set, breaking display
Confirmed **3 times** with the identical shape (form writes `employeeId` only, list/card view reads `employeeName` and falls back to "Unknown Employee"): `people`'s `employee_360_profile_screen.dart` area is clean, but `health`'s `medical_form.dart`, and `training`'s `record_form_sheet.dart` and `allocate_course_form.dart` (2 separate forms, same module) all hit this.

### 1.5 `Navigator.push`/`MaterialPageRoute` used instead of `UIUtils.showSideSheet`
AGENTS.md §1 violation, confirmed in **5 modules**: `safety` (`safety_hub_screen.dart`'s "Scan Passport"), `supply_chain` (`SupplyChainHubScreen`), `projects` (`project_operations_hub_screen.dart`'s Gantt/Timesheet/Expense tiles), `customer_service` (`customer_service_hub_screen.dart` opening `KnowledgeBaseScreen`).

### 1.6 Raw `ScaffoldMessenger.showSnackBar` instead of `UIUtils.showToast`
AGENTS.md §1 violation, confirmed in **6 files across 5 modules**: `billing_portal_screen.dart`, `mrp_dashboard_screen.dart` + `production_order_screen.dart` (supply_chain), `timesheet_entry_screen.dart` (projects), `ticket_form.dart` + `knowledge_article_form.dart` (customer_service), `loto_management_screen.dart` (equipment, inconsistent with the same module's otherwise-correct usage elsewhere).

### 1.7 Fully-built, zero-navigation-path features (banned-stub's inverse — the code is real, only the entry point is missing)
Confirmed **10+ times**: `safety`'s contractor/employee QR passport screens, `auth`'s `EnterpriseSSOScreen` (complete SAML form), `operations`' `inventory_dashboard_screen.dart`, `supply_chain`'s 3 detail screens + 3 forms + a BPF ribbon, `customer_service`'s entire real Firestore-backed implementation (parallel to the mocked one that's actually routed), `field_service`'s `WorkOrderDetailsScreen` (reachable, but fed a hardcoded fake ID so it can only ever render "not found"), `ai_tools`'s `CopilotScreen`/`CopilotChatWidget`/`RagService`, `projects`' 7-file PMO island (only live caller is the Lead-to-Cash orchestrator), `compliance`'s entire primary screen (the only module in the app where the *primary* screen itself, not a sub-screen, is unreachable), `equipment`'s main screen (see §2 Critical).

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
| `auth` | `setCustomUserClaims` called nowhere in either Functions codebase — the mechanism `firestore.rules` depends on for tenant/role scoping has no producer |
| `auth` | Live, unguarded "Bypass Login (Dev)" button on the production login screen sets a mock-auth flag without calling Firebase Auth |
| `people`, `projects`, `public` | Hardcoded empty-string tenant ID (pattern §1.2) |
| `finance` | `bpfOrchestratorProvider` has zero call sites — no BPF actually executes (pattern §1.9) |
| `finance` | `FinanceService`'s real write targets (`fin_*` collections) are undeclared in rules while the rules protect collections nothing writes to |
| `finance` | Immutability principle from `docs/schema_finance.md` unenforced — `updateJournalEntry()`/`deleteJournalEntry()` act unconditionally regardless of posted status |
| `risk` | `dra_form.dart` writes `activity`/`area`; every reader expects `taskDescription`/`location` — DRA cards permanently show "Untitled Assessment," 2 KPI dashboards show wrong/zero values |
| `contractors` | camelCase/snake_case collection typo (`safetyFileSubmissions` vs `safety_file_submissions`) hides real safety-file approvals one screen away |
| `compliance` | Fully unreachable module (no route) whose own form also writes to a different collection name than both its read tabs query |
| `equipment` | `/equipment` has no route anywhere in `router.dart` — the app's best-built screen (real form, real BPF ribbon) is disconnected from the launchpad tile that's supposed to open it |
| `operations` | Action Tracker's create form and its own read-side model disagree with each other (`assignee` vs `assigneeId`, missing `collectionName`), independent of the rules-blocking issue |
| `supply_chain` | MRP engine has 3 different field names for the same stock quantity across schema doc / Dart model / deployed Cloud Function |
| `billing` | Only real user action calls `createStripeCheckoutSession`, a Cloud Function that exists in neither Functions codebase |
| `billing` | 3-way path mismatch: app reads `tenants/{t}/subscription/status`, legacy webhook writes `tenants/{t}/billing/subscription` |
| `settings` | `OfflineSyncService.initialize()` never called — the write queue 27+ files depend on throws `LateInitializationError` on first real offline write |
| `training` | 3 mutually-unaware "enrollment" collections (`enrollments`/`training_enrollments`/`training_records`) with no cross-reference |
| `training` | `allocate_course_form.dart` never sets `assignedAt`; the Manager Hub's `orderBy('assignedAt')` silently excludes every allocation made through the form |
| `customer_service` | Two complete parallel implementations exist; only the 100%-mocked one is reachable from navigation |
| `field_service` | 3-way `WorkOrder` shape collision (pattern §1.10); the one reachable detail screen is fed a hardcoded fake ID so it can only show "not found" |
| `projects` | PMO island's root collections aren't reachable by any rule, including the catch-all — stricter failure than the usual pattern |
| `property` | All 6 of its collections undeclared in rules, and unlike most instances of §1.1, this one blocks a real, reachable, correctly-built form |
| `public` | Nothing in this module is reachable, pre-auth or otherwise, by a confirmed 5-layer blocked chain — and the one write path that exists is unconditionally denied for every caller |

### High — real functional or security gaps, not immediately catastrophic
| Module | Finding |
|---|---|
| `auth` | Hardcoded Firebase + Gemini API keys still committed in `firebase_config.dart` (currently unused at init, but the credentials remain in source control) |
| `auth` | No form/UI exists to set `UserProfile.department`/`jobTitle`/`phone`/`preferences` anywhere — "Edit Profile" is a stub toast |
| `notifications` | `NotificationService` is fully, correctly implemented with zero callers anywhere — no user can receive a real push or in-app notification |
| `ai_tools` | All 4 AI-chat tabs generate content (hazard report, RCA, safety flash) that is never saved anywhere — no "Save to Incident" action exists |
| `ai_tools` | `GEMINI_API_KEY` likely resolves empty as committed — no `--dart-define` evidence anywhere in the repo |
| `executive` | All KPI/alert data hardcoded; zero drill-down navigation despite the Executive persona's own defining "drill down via deep links" journey text |
| `safety` | `Incident` model exists but nothing actually parses documents through it — the form's field names/types (capitalized enums, ISO date strings) would throw if anything ever did |
| `safety` | `reporterName` hardcoded to the literal string `'Selected Employee'` regardless of who was actually picked |
| `field_service` | 4 structured `Map` fields (`address`, `scheduling`, `safetyRequirements`, `iotContext`, `financials`) rendered as raw hand-typed JSON text fields; malformed input throws an uncaught `FormatException` |
| `projects` | `timesheet_entry_screen.dart` has no Firestore call at all — own comment reads "Simulate timesheet submission" |
| `projects` | `revenue_recognition_screen.dart` is entirely fabricated data, not a partially-wired integration |
| `supply_chain` | Hub screen (`InventoryDashboard`, `WarehouseManagementScreen`, `AssetManagementScreen`) is hardcoded `ListTile`s with no `onTap` handlers — the first screens reached from the Supply Chain tile |
| `supply_chain` | 2 literal "Coming Soon" stub cards sit next to fully-written, unused `ScmService` CRUD for the same features |
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
