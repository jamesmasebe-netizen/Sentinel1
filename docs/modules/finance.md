# finance — Module Journey Doc

**Path:** `lib/features/finance/`  |  **Compartment:** Finance  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`finance` is Sentinel1's General Ledger / AP / AR module: chart of accounts, dual-entry journal entries, AP & AR invoices, budget plans, cost centers, and tax codes. It is the **convergence point of the app's two most-implemented Business Process Flows** — Lead to Cash's terminal step and Procure to Pay's only wired step both land here via the identical `FinanceService.createInvoice()` call (confirmed by direct code read, see §3).

`docs/schema_finance.md` (494 lines, read in full for this doc) describes an aspirational enterprise GL schema built on four stated principles: **true dual-entry** (every transaction ≥2 balanced debit/credit lines), **immutability** (posted transactions can't be deleted/modified, only reversed), **auditability**, and **multi-currency**. It specifies a `fin_`-prefixed collection family (`fin_chart_of_accounts`, `fin_journal_headers`+`lines`, `fin_ap_invoices`, `fin_ar_invoices`, `fin_tax_codes`, `fin_budget_models`, `fin_fixed_assets`, etc.). The actual code in `lib/features/finance/models/finance_models.dart` implements a reasonably close subset of this (see §5) but **does not enforce immutability**: `FinanceService.updateJournalEntry()`/`deleteJournalEntry()` operate unconditionally on any journal entry regardless of `status`, with no guard against mutating a `POSTED` entry.

**In scope:** GL chart of accounts, journal entries (header + lines), AP/AR invoices, budget plans, cost centers, tax codes (model only).
**Out of scope:** tenant SaaS subscription billing (owned by `billing` — see that doc for the distinction), timesheet/expense capture (`projects`), purchase order creation (`supply_chain`), revenue-recognition UI (nominally finance's subject matter but the actual screen lives in `projects` — see §6).
**IA placement:** Finance compartment (8-compartment taxonomy). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `finance` | Entry screen(s) |
|---|---|---|---|
| [Finance Controller](_shared_personas_and_bpfs.md#persona-finance-controller) | Ledger Management | Create General Ledger Journal Entry → (Process Payroll Integrations lives in `people`, not here) | `finance_hub_screen.dart`, `chart_of_accounts_view.dart`, `journal_entry_form.dart` |
| [Finance Controller](_shared_personas_and_bpfs.md#persona-finance-controller) | Billing & AP/AR | (Receive Timesheet Data — `projects`) → Generate & Send Invoice → (Track Software Subscriptions — `billing`, see that doc) → Reconcile Accounts | `invoice_detail_screen.dart` (built, see §4 for reachability caveat) |
| [Executive/C-Suite](_shared_personas_and_bpfs.md#persona-executive) | Strategic Oversight (partial, unconfirmed) | No dedicated executive drill-down or BI rollup was found in this module — `finance_hub_screen.dart` shows only a raw account count and a permanently-empty journal-entry count (§5) | `finance_hub_screen.dart` |

Budget Plans and Cost Centers don't map cleanly to either persona's journey text in the shared doc — they appear to be code-level additions beyond the recovered roadmap's original narrative, similar to how `crm.md` flagged `lead_journey_timeline_screen.dart` as an enhancement beyond spec.

## 3. BPF Participation
| BPF | Stage(s) this module implements | Code reference |
|---|---|---|
| [Lead to Cash](_shared_personas_and_bpfs.md#bpf-lead-to-cash) | Terminal stage — Client Invoice Generation (`billing_and_collection`) | `BpfOrchestrator.createInvoiceFromProject()` in `lib/core/bpf/bpf_orchestrator.dart` |
| [Procure to Pay](_shared_personas_and_bpfs.md#bpf-procure-to-pay) | Only wired stage — AP Invoice Auto-Generation (`ap_invoice`) | `BpfOrchestrator.createInvoiceFromPurchaseOrder()`, same file |
| [Project Concept to Close](_shared_personas_and_bpfs.md#bpf-project-concept-to-close) | Client Billing step (narrative only) | No orchestrator method references this BPF's stage IDs at all (confirmed in shared doc) — `finance`'s participation here is descriptive text only, preserved from the recovered roadmap |

**Implementation-depth confirmation (code read directly, per the shared doc's methodology):** both real (non-stub) invoice-creation paths converge on one method:
- `createInvoiceFromProject(Project project, String bpfId)` builds an `Invoice(invoiceType: 'AR', customerId: project.clientId, id: 'INV-<millis>', ...)`, calls `financeService.createInvoice(invoice)`, then `bpfService.advanceStage(bpfId, 'billing_and_collection', newlyLinkedRecords: {'invoiceId': invoiceId})`.
- `createInvoiceFromPurchaseOrder(PurchaseOrder po, String bpfId)` builds an `Invoice(invoiceType: 'AP', vendorId: po.vendorId, grossAmount: po.totalAmount, id: 'AP-INV-<millis>', ...)`, calls the **same** `financeService.createInvoice(invoice)`, then `bpfService.advanceStage(bpfId, 'ap_invoice', newlyLinkedRecords: {'apInvoiceId': invoiceId})`.

Both take their input record type from another module (`Project` from `projects/models/pmo_models.dart`, `PurchaseOrder` from `supply_chain/models/scm_models.dart`) — confirming `finance` is genuinely the shared landing point for the app's two most-real BPFs, not just narratively grouped with them.

**`BpfRibbonWidget` is confirmed present** in `invoice_detail_screen.dart` — it renders for both `bpfTypeId: 'lead_to_cash'` (when `invoice.invoiceType == 'AR'`) and `bpfTypeId: 'procure_to_pay'` (when `== 'AP'`), each pointed at the correct stage-definition import (`leadToCashDefinition`, `procureToPayDefinition`). This is the same ribbon-integration strength `crm.md` found for Lead-to-Cash's earlier stages.

**Two qualifications this pass surfaced that go beyond what was asked but materially affect how "wired" this BPF chain really is:**
1. **No UI trigger found.** `bpfOrchestratorProvider` (the Riverpod provider exposing `BpfOrchestrator`) has **zero call sites anywhere in `lib/` outside its own definition file** — confirmed by repo-wide grep. That means `createInvoiceFromProject`/`createInvoiceFromPurchaseOrder` (and every other `BpfOrchestrator` method, app-wide) are real, correct Dart code that would execute as described if invoked, but no button, screen, or side-sheet in the current codebase actually calls them. This closes the open question `crm.md` left unresolved ("is Won Opportunity handled some other way that wasn't visible in this pass?") in the negative, at least for finance's two methods: no such trigger exists yet.
2. **The write itself targets a security-rules-blocked collection.** See §5/§7 — `FinanceService.createInvoice()` writes to `fin_ar_invoices`/`fin_ap_invoices`, which are not declared in `firestore.rules` and therefore fall through to a catch-all rule that denies all client writes. Even if a UI trigger existed, this call would fail against the committed security rules.

## 4. Screens & UI Elements Inventory
9 screens + 2 standalone form widgets, matching the assigned module's expected inventory.

| Screen | Route or entry point | Purpose |
|---|---|---|
| `finance_hub_screen.dart` | `/finance` (top-level route, `router.dart:105-107`) | GL overview hub: account count, journal entry count, links to Chart of Accounts and New Journal Entry |
| `chart_of_accounts_view.dart` | `Navigator.push` from `FinanceHubScreen` | GL account list (`DataTable`) + inline "New GL Account" dialog; "Multi-Entity Consolidation" toggle (see §7) |
| `journal_entry_form.dart` (screens/) | `Navigator.push` from `FinanceHubScreen` | Thin `Scaffold` wrapper around `widgets/journal_entry_form.dart`'s actual form widget |
| `invoice_detail_screen.dart` | **No confirmed entry point** (see §7) | AP/AR invoice detail; hosts the module's only `BpfRibbonWidget` usage |
| `journal_entry_detail_screen.dart` | **No confirmed entry point** | Journal entry header + live-streamed lines |
| `budget_plan_list_screen.dart` | **No confirmed entry point** | Budget plan list; FAB is an unconfigured stub (§7) |
| `budget_plan_detail_screen.dart` | `Navigator.push` from `BudgetPlanListScreen` (itself unreachable) | Single budget plan detail, one-shot fetch |
| `cost_center_list_screen.dart` | **No confirmed entry point** | Cost center list; FAB is an unconfigured stub (§7) |
| `cost_center_detail_screen.dart` | `Navigator.push` from `CostCenterListScreen` (itself unreachable) | Single cost center detail, one-shot fetch |

Supporting form widgets (not screens): `widgets/invoice_form.dart`, `widgets/journal_entry_form.dart` — the actual field-level forms; both are `ConsumerStatefulWidget`s taking an optional `initial*` record for edit mode.

**Navigation-pattern gap:** none of the 9 screens use `UIUtils.showSideSheet` — every transition found (`FinanceHubScreen` → `ChartOfAccountsView`/`JournalEntryForm`, `BudgetPlanListScreen` → `BudgetPlanDetailScreen`, `CostCenterListScreen` → `CostCenterDetailScreen`) is a classic `Navigator.push(MaterialPageRoute(...))`, including from `FinanceHubScreen`, which is a Hub screen — the exact pattern AGENTS.md §1 prohibits ("NEVER use `Navigator.push` to open detailed forms or sub-modules from a Hub screen"). This is a contrast with `crm`/`people`, which are side-sheet-first throughout.

**Orphaned screens:** `invoice_detail_screen.dart`, `journal_entry_detail_screen.dart`, `budget_plan_list_screen.dart`, `cost_center_list_screen.dart` — 4 of 9 screens — have **zero references anywhere in `lib/` outside their own file** (verified by grepping both the constructor call pattern and the bare class name). No router entry, no `Navigator.push`, no side-sheet call from any other screen points at them. This includes `invoice_detail_screen.dart`, the screen hosting the module's only `BpfRibbonWidget` — so while the ribbon code is correctly wired to the right BPF definitions, it currently has no confirmed way to become visible to a user.

## 5. Backend & Database

**Models — `lib/features/finance/models/finance_models.dart`** (single file, 7 models):
| Model | Key fields | Collection actually written by `FinanceService` |
|---|---|---|
| `GeneralLedgerAccount` | accountNumber, name, type, subType?, isActive, isReconciliationAccount, currencyCode?, financialStatementGroup? | `fin_chart_of_accounts` |
| `JournalEntry` | transactionDate, sourceModule, sourceReferenceId?, type, description, status, currencyCode, totalDebit, totalCredit, createdBy?, approvedBy?, postedAt?, reversesJournalId? | `fin_journal_headers` |
| `JournalLine` | accountId, costCenterId?, projectId?, debitAmount, creditAmount, taxCodeId? | `fin_journal_headers/{id}/lines` (subcollection) |
| `Invoice` | invoiceType ('AP'/'AR'), vendorId?/customerId?, invoiceNumber?, invoiceDate, dueDate, status, grossAmount, taxAmount, netAmount, amountPaidOrReceived?, journalEntryId? | `fin_ap_invoices` or `fin_ar_invoices` (chosen by `invoiceType`) |
| `TaxCode` | code, jurisdictionId, taxType, rate, glLiabilityAccountId?, glReceivableAccountId? | `fin_tax_codes` |
| `BudgetPlan` | name, fiscalYear, fiscalPeriod, plannedAmount, actualAmount, variance, variancePercentage, status | `budgetPlans` |
| `CostCenter` | code, name, departmentId?, managerId?, isActive, totalBudget, totalSpend | `costCenters` |

Two additional models exist but are **dead code** — zero usages anywhere outside their own definition file: `ChartOfAccounts` (`models/chart_of_accounts.dart` — a leaner id/name/code/type shape, fully superseded by `GeneralLedgerAccount`), and `TaxRate`/`CurrencyExchange` (`models/tax_model.dart` — scaffolded per what looks like the recovered plan's tax-engine ambition, never read or written by any screen).

**Firestore naming/rules check — the most consequential finding in this doc.** `firestore.rules` explicitly declares purpose-built rules for `invoices` (lines 140-144: manager create/update, admin delete) and `journal_entries` (lines 146-150, same pattern) — a naming choice the shared reusable context flagged as "a good sign for finance's security posture." Reading the actual code shows those declared names are never used:
- **Zero code anywhere in the repo** (`lib/` or `firebase/functions/`) writes to a collection literally named `invoices` or `journal_entries` (confirmed by grep).
- `FinanceService` instead writes to `fin_ap_invoices`, `fin_ar_invoices`, `fin_journal_headers`, `fin_chart_of_accounts`, `fin_tax_codes`, `budgetPlans`, `costCenters` — **none of which are declared anywhere in `firestore.rules`**.
- The rules file's catch-all, immediately before the tenant block closes (line ~233): `match /{collection}/{docId} { allow read: if belongsToTenant(tenantId); allow write: if false; }`. Every collection `FinanceService` actually uses falls through to this rule.

Net effect: **as committed, `FinanceService.createInvoice()`, `createJournalEntry()`, `createGeneralLedgerAccount()`, `createBudgetPlan()`, `createCostCenter()`, and `createTaxCode()` — i.e. essentially all of this module's client-side writes — would be rejected by Firestore under these security rules**, because they target undeclared collections and the catch-all explicitly sets `allow write: if false`. The purpose-built `invoices`/`journal_entries` rules are currently protecting collections nothing in the app uses. (This is scoped to *client* writes specifically — see the Cloud Functions row below for why server-side writes aren't affected the same way.)

**Cloud Functions reality check** (`firebase/functions/src/index.ts` unless noted; `firebase.json` has no `functions` key, so deployment is ambiguous — citations below describe code as committed, not confirmed-live behavior):

| Function | Type | Collection(s) touched | Dart-side caller | Caller wired to UI? |
|---|---|---|---|---|
| `postJournalEntry` | `onCall` | `tenants/{t}/finance_journals`, `tenants/{t}/finance_accounts` | Yes — `LedgerPostingService.postJournalEntry()` in `lib/features/finance/services/ledger_posting_service.dart` | **No** — zero references to `ledgerPostingServiceProvider`/`LedgerPostingService` anywhere else in `lib/` |
| `onInvoiceStatusChanged` | `onDocumentUpdated` trigger | Watches `tenants/{t}/finance_invoices/{id}`, auto-posts GL on status→`SENT` | N/A (trigger) | Nothing in the app ever writes to `finance_invoices` (the app writes `fin_ap_invoices`/`fin_ar_invoices` instead), so this trigger has no confirmed path to ever fire from this module's own UI |
| `taxEngine.calculateTax` | `onCall` | None (stateless) | **None found anywhere in `lib/`** | No — and its own code comment reads `// Simulate Stripe Tax call`, returning a hardcoded 8% flat rate, not real Stripe Tax API integration despite the framing |
| `revRecEngine.revenueRecognition` | `onDocumentUpdated` trigger | Watches `tenants/{t}/project_milestones/{id}` → `COMPLETED`, writes `tenants/{t}/finance_journals` | N/A (trigger) | See §6 — the conceptually-related screen (`revenue_recognition_screen.dart`) lives outside this module and is 100% mock data |

So `postJournalEntry` and `onInvoiceStatusChanged` are real, correctly-coded Cloud Functions — but they operate on a **third, separate naming scheme** (`finance_journals`/`finance_accounts`/`finance_invoices`) that overlaps with neither `FinanceService`'s collections (`fin_*`/`budgetPlans`/`costCenters`) nor the rules-declared names (`invoices`/`journal_entries`). All three schemes describe what should be one coherent GL/invoicing data model but currently never intersect.

**Services:**
- `finance_service.dart` (341 lines) — full CRUD + streams for all 7 models above; `_getInvoiceCollection(type)` is the single method that decides `fin_ap_invoices` vs `fin_ar_invoices`.
- `ledger_posting_service.dart` — thin wrapper around the `postJournalEntry` callable; correct implementation, unused (see table above).

**Providers — `finance_providers.dart`:**
- `glAccountsStreamProvider` — real `StreamProvider`, correctly used by `ChartOfAccountsView` and `FinanceHubScreen`.
- `journalEntriesProvider`, `invoicesProvider` — `StateProvider<List<T>>([])`, **never written to anywhere in the module** (confirmed by grep — no `.notifier.state =` assignment exists for either). `FinanceHubScreen` reads `journalEntriesProvider` directly, so its "Total Journal Entries" count and "Recent Journal Entries" list will **permanently show empty/zero** regardless of actual Firestore data. Unlike the same pattern flagged as unconfirmed in `crm.md`, this instance is confirmed live and screen-reachable.
- `journalEntryStreamProvider.family`, `journalLinesStreamProvider.family`, `invoiceStreamProvider.family` — real live streams, correctly consumed by `JournalEntryDetailScreen`/`InvoiceDetailScreen`.

## 6. Cross-Module Links
- **BPF convergence, picking up from `crm.md`:** `crm.md` traces Lead → Opportunity → Quote up to the Won-Opportunity → Project handoff. `finance` picks up the thread two steps later, at Project → Invoice: `createInvoiceFromProject(Project project, ...)` takes a `Project` from `projects/models/pmo_models.dart`. The Quote → Project step itself is outside this doc's scope (see `crm.md`'s own open question about whether that handoff is wired).
- `createInvoiceFromPurchaseOrder(PurchaseOrder po, ...)` takes a `PurchaseOrder` from `supply_chain/models/scm_models.dart` — `finance`'s other cross-module input type.
- **`revenue_recognition_screen.dart` lives in `lib/features/projects/screens/`, not `finance`** (verified directly — confirms the recovered plan's note on this). Despite representing GL journal entries for ASC 606 revenue recognition — conceptually finance's subject matter, and the same concept `revRecEngine.ts`'s `revenueRecognition` Cloud Function actually implements against `finance_journals` — the screen's data is **entirely mocked**: it defines a local `_JournalEntry` class and a hardcoded `_mockEntries` list in a `// ─── Mock Data Models ───` block, with no Firestore read at all. It is not wired to `project_milestones` (what the Cloud Function watches) or to `finance_journals`/`fin_journal_headers` (what it or `FinanceService` would write). A violation of AGENTS.md §2 ("No Hardcoded Data"), and worth flagging when `projects.md` is audited.
- **No `AppEventBus` usage anywhere in `finance`** (confirmed by grep) — despite `onInvoiceStatusChanged`'s auto-GL-posting being a natural candidate to notify `projects` or `crm` when an invoice is paid.
- **No code-level relationship with `billing`** was found in either direction (no shared imports, no shared models) despite both being grouped under the Finance persona/compartment in the shared doc — see `billing.md` for the full distinction.

## 7. Known Gaps

### Rules-vs-code gaps
- **Collection-name mismatch blocks client writes** — the headline finding of this doc. `FinanceService`'s write targets (`fin_ap_invoices`, `fin_ar_invoices`, `fin_journal_headers`, `fin_chart_of_accounts`, `fin_tax_codes`, `budgetPlans`, `costCenters`) are undeclared in `firestore.rules` and fall through to the catch-all `allow write: if false`, while the rules' purpose-built `invoices`/`journal_entries` declarations protect collections nothing in the app writes to. Full detail in §5.
- **Immutability principle not enforced.** `docs/schema_finance.md`'s stated core principle — "Posted transactions cannot be deleted or modified. Corrections require a reversing entry" — has no corresponding guard in `finance_service.dart`; `updateJournalEntry()`/`deleteJournalEntry()` act unconditionally regardless of `status`.
- **AGENTS.md §1 side-sheet rule** — violated module-wide; see §4.
- **AGENTS.md §3 banned-stubs rule** — `budget_plan_list_screen.dart` and `cost_center_list_screen.dart` both have a FAB `onPressed` containing only `// TODO: Implement Create Budget Plan` / `// TODO: Implement Create Cost Center` — literal, direct violations. `invoice_detail_screen.dart`'s "Linked Journal Entry" list tile has an `onTap` containing only a comment (`// Typically navigation to Journal Entry Detail Screen`) instead of real navigation — a non-functional tap target.
- **AGENTS.md §2 "Human Readable IDs"** — inconsistently followed: `Invoice`/`JournalEntry`/`JournalLine` IDs use readable prefixes (`INV-`, `AP-INV-`, `JE-`, `LINE-`), but `chart_of_accounts_view.dart`'s `_addAccount()` generates GL account IDs as a bare `DateTime.now().millisecondsSinceEpoch.toString()` with no prefix — inconsistent with `schema_finance.md`'s own example (`1000-Cash`).
- **AGENTS.md §2 "No Hardcoded Data"** — `chart_of_accounts_view.dart`'s Balance column renders `'\$0.00'` for every row regardless of actual balance; its "Multi-Entity Consolidation" toggle (`_isConsolidated`) has no filtering logic wired to it anywhere — flips a switch that does nothing.
- `BaseIncident` — not applicable, no incident concept in this module.

### DB-to-UI alignment audit
`invoice_form.dart` vs `Invoice` model:
| Field | Status | Note |
|---|---|---|
| `vendorId` / `customerId` | **Wrong widget** | Plain `TextFormField` — foreign key to vendor/customer records, no lookup |
| `journalEntryId` | **Wrong widget** | Plain `TextFormField` — foreign key to `fin_journal_headers`, no lookup |
| `invoiceType`, `status` | Correct | `DropdownButtonFormField` with appropriate closed item lists |

`journal_entry_form.dart` (widgets/) vs `JournalEntry`/`JournalLine` models:
| Field | Status | Note |
|---|---|---|
| `createdBy` / `approvedBy` | Correct | Uses `EmployeeSelector` |
| `sourceModule`, `type`, `status` | Correct | `DropdownButtonFormField` with closed item lists |
| Line `accountId` | **Wrong widget** | Plain `TextFormField` — FK to `fin_chart_of_accounts`, no lookup |
| Line `costCenterId` | **Wrong widget** | Plain `TextFormField` — FK to `costCenters`, no lookup |
| Line `projectId` | **Wrong widget** | Plain `TextFormField` — FK to `projects`, no lookup |
| Line `taxCodeId` | **Wrong widget** | Plain `TextFormField` — FK to `fin_tax_codes`, no lookup |

Four un-looked-up foreign keys on a single repeating line item — the densest concentration of this pattern found across the docs written so far.

`chart_of_accounts_view.dart`'s inline "New GL Account" dialog vs `GeneralLedgerAccount` model (not a `*_form.dart` file, but the only create path that exists for this model, so audited the same way):
| Field | Status | Note |
|---|---|---|
| `type` | **Wrong widget** | Plain `TextField`, no validation, though the model documents a closed 5-value set (ASSET/LIABILITY/EQUITY/REVENUE/EXPENSE) |
| `subType`, `isReconciliationAccount`, `financialStatementGroup`, `currencyCode` (beyond a hardcoded `'USD'`) | **Missing** | Present on the model, absent from the dialog entirely |

### Other
- **Dead models:** `ChartOfAccounts` (`chart_of_accounts.dart`) and `TaxRate`/`CurrencyExchange` (`tax_model.dart`) — all confirmed zero-usage outside their own file.
- **Dead provider, confirmed live impact:** `journalEntriesProvider`/`invoicesProvider` — see §5; `FinanceHubScreen` will always show an empty journal entries list.
- **`LedgerPostingService` exists but is unused** — correct implementation of the `postJournalEntry` dual-entry Cloud Function call, zero call sites from any screen.
- **`taxEngine.calculateTax` is a simulation, not real tax integration**, and has zero Dart-side callers.
- **`bpfOrchestratorProvider` has zero call sites anywhere in `lib/`** — applies app-wide, not just to finance, but is highly material here since it's the mechanism behind both of finance's "confirmed wired" BPF stages (see §3).
- **IA/taxonomy conflict:** see [_shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Are the `firestore.rules` in this repo the actual deployed rules? If so, `FinanceService`'s core create/update/delete methods would fail against production Firestore for every collection it uses except reads — this seems severe enough to warrant an urgent follow-up given the module's role as BPF convergence point.
- What screen or button was originally meant to call `createInvoiceFromProject`/`createInvoiceFromPurchaseOrder`? A "Generate Invoice" action on a Project or Purchase Order detail screen seems like the natural fit per the persona journeys — worth checking for during `projects.md`/`supply_chain.md` audits, including whether either module calls `FinanceService` directly and bypasses the BPF orchestrator (which would advance the invoice creation without ever advancing the BPF stage).
- Should `fin_ap_invoices`/`fin_ar_invoices`/`fin_journal_headers`/etc. be added to `firestore.rules` explicitly, or should `FinanceService` be re-pointed at the already-declared `invoices`/`journal_entries` names? Resolving this needs a decision on which naming scheme (the `schema_finance.md` enterprise design vs. the simpler declared names) is the intended long-term direction — and ideally also reconciling the Cloud Functions' third scheme (`finance_journals`/`finance_invoices`/`finance_accounts`) into the same decision.
- Is `revenue_recognition_screen.dart`'s placement under `projects` deliberate (triggered by project milestones) or should it move into `finance`? And should it be wired to real data at all, given it's currently fully mocked?
- Should `LedgerPostingService.postJournalEntry()` (the balanced, transactional Cloud Function path) replace `journal_entry_form.dart`'s current direct-to-Firestore write via `FinanceService.createJournalEntry()`, which has no server-side balance validation and targets a rules-blocked collection?
