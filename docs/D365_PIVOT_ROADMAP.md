# D365 Pivot Roadmap

> **This is a draft proposal for review, not an approved plan or an executed one.** No code in
> this repository has been changed as a result of this document — see the Verification note at
> the bottom. It exists to answer one question: *given what Sentinel1 actually is today (not what
> it was when the two source docs below were written), what would a real "compete with Dynamics
> 365" push look like?*

## Relationship to the two source documents

`docs/dynamics_365_masterplan.md` and `docs/D365_COMPETITIVE_ANALYSIS.md` were written as a
from-scratch architectural pitch — a "15-Agent Swarm" rebuilding all 7 D365 pillars roughly
simultaneously, starting from an assumption that Sentinel1 has, e.g., "a basic pipeline deals
list" (Sales), "a simple ticketing queue" (Customer Service), "an employee directory and basic
onboarding form" (HR), and no BPF/workflow engine, no offline queue, and no route optimization.

That assumption was already wrong when those docs were written, and a full session of audits and
fixes since (`docs/testing/TEST_BACKLOG.md`, `docs/modules/_known_gaps_rollup.md`) has closed a
lot more ground. Re-proposing a ground-up rebuild on top of that reality would mean re-building
things that already work, correctly, today — a real waste, not a shortcut. This document replaces
the "rebuild everything" framing with "here's what's actually there, here's what's genuinely
missing, here's a realistic order to close the real gaps."

**Confidence key used below:** ✅ *Confirmed this session* — verified against current code,
file-cited. ⚠️ *Per the original audit docs, not re-verified this pass* — treat as uncertain, not
as fact. ❌ *Confirmed still missing* — checked, genuinely absent.

---

## Pillar-by-pillar: what's actually there

### 1. Finance
- ✅ Real `fin_*` collections (chart of accounts, cost centers, journal headers, AP/AR invoices,
  budget models), each with declared `firestore.rules`.
- ✅ Journal entry immutability enforced — `FinanceService._assertMutable()` blocks
  update/delete on `POSTED`/`REVERSED` entries.
- ✅ `LedgerPostingService.postJournalEntry` has a real, live call site
  (`journal_entry_form.dart`); `FinanceHubScreen` streams real journal/invoice data, not mocks.
- ✅ A real tax engine (`taxEngine.calculateTax`, Cloud Function) exists.
- ❌ No multi-currency reconciliation, no bank feed/reconciliation workflow, no fixed-asset
  depreciation, no multi-entity consolidation — the masterplan's "Sentinel Enhancements" for this
  pillar are genuinely not built.

### 2. Project Operations
- ✅ Canonical `Project` model with real sequential `PRJ-xxx` ids and PRINCE2-style stages,
  reachable from a real Projects Hub.
- ✅ Time tracking unified this pass onto one real collection (`time_entries`/`PmoService`),
  with a working create screen (`timesheet_entry_screen.dart`) feeding a real Time Entries tab.
- ✅ Revenue recognition (`revenue_recognition_screen.dart`) streams real journal entries
  filtered by `sourceModule == 'PROJECTS'` — not fabricated data, despite the competitive
  analysis doc's claim.
- ❌ No resource capacity planning or skills-based assignment, no expense-receipt OCR, no
  milestone/retainer billing automation — genuinely missing.

### 3. Human Resources
- ✅ A complete recruitment ATS pipeline (built this session): `JobRequisition` →
  approval/publish → public application (`job_applications`) → recruiter review → `Candidate` →
  Kanban pipeline. This closes most of the masterplan's "ATS" ask already.
- ✅ Payroll ledgers, compensation plans, performance reviews, benefit enrollments, and
  disciplinary records all have real models, services, and role-scoped rules with live Dart
  readers/writers (confirmed today while auditing the 2026-08-07 rules fix).
- ⚠️ Employee 360 profile — 2 tabs were flagged as mocked in the original audit; not re-verified
  this pass.
- ❌ No leave-accrual state machine, no org-chart visualization, no shift-scheduling
  conflict resolution.

### 4. Field Service
- ✅ `WorkOrder` shape unified across model/Cloud-Function/automation (fixed earlier this
  session); `WorkOrderDetailsScreen` now navigates with a real order id.
- ✅ **Route optimization already exists** and is genuinely tested: `routingEngine.ts` is a real
  haversine-distance + nearest-neighbor TSP heuristic, not the "no route optimization" gap the
  competitive analysis doc claims — it's just not traffic-aware or ML-based.
- ✅ IoT telemetry ingestion is real (`iotEngine.ts`, a live `onRequest` Cloud Function, tested
  against the emulator) — device lookup, `customer_assets` merge, predictive-maintenance work
  order creation on a temperature threshold.
- ✅ An app-wide offline mutation queue already exists (`FirestoreService`/`OfflineSyncService`),
  not field-service-specific, but it already serves the "offline-first mobile" need structurally.
- ❌ No digital signature capture, no dedicated "inventory on truck" mobile warehousing view.

### 5. Customer Service
- ✅ One real, Firestore-backed ticketing/SLA/knowledge-base implementation (the orphaned mock
  parallel implementation was deleted this session).
- ❌ No live chat/omnichannel routing, no AI case summarization or deflection. The one AI-adjacent
  piece (`aiEngine.ts`'s reply suggester) is an honestly-named deterministic template
  (`suggestReplyTemplate`), not a real model call, and currently has zero call sites from `lib/`.

### 6. Sales (CRM)
- ✅ A full, tested Lead → Opportunity → Quote → Project BPF flow, including real Account/Contact
  creation on conversion (fixed this session — previously always produced orphaned records).
  Quote PDF export and Campaign management were both built end-to-end this session, replacing
  banned stubs.
- ✅ CRM's list providers are real Firestore streams, not the static `StateProvider`s the
  original audit flagged (confirmed fixed).
- ❌ No sales forecasting, no CPQ pricing/configuration engine beyond flat quote lines, no
  competitor-battlecard feature.

### 7. Supply Chain Management
- ✅ Real Production Orders module (stock-incrementing transaction, not a mocked "Inventory
  updated" toast), MRP suggestions that correctly distinguish `PRODUCTION` vs `PURCHASE` and
  convert into real orders, and a real inventory-transaction ledger — all built this session.
- ✅ Asset Management's two previously-unwired tiles (Preventative Maintenance, Asset Lifecycle)
  were wired this pass onto real, previously-unreachable building blocks — an existing
  maintenance-work-order log and the existing (but previously unreachable) `asset_lifecycle` BPF.
- ❌ No bin/location-level warehouse tracking, no multi-level manufacturing routing beyond a
  single BOM level, no demand forecasting.

---

## Cross-cutting foundations the masterplan assumed didn't exist

The masterplan's Phase 1 ("DB Architect... implements the exact NoSQL schema... in Dart Models
and Repositories") and its 15-agent structure both implicitly assume Sentinel1 is starting from
near-zero. It isn't:

- **A real BPF (workflow-stage) engine already exists** (`core/bpf/`), generic across flow types,
  with gating (`BpfService` rejects unknown stage ids), a reusable stage-ribbon widget, and
  emulator-backed rules coverage. Lead-to-Cash, Procure-to-Pay, and (as of this pass)
  Asset Lifecycle all run through it live; Issue-to-Resolution has orchestrator code
  (`createCapaFromIncident`) not confirmed reachable this pass.
- **A real offline-queue + audit-log write path already exists** (`FirestoreService`), used by
  13+ modules.
- **A real, comprehensive Firestore rules matrix already exists** — every declared collection has
  explicit, role-scoped rules, backed by 300+ emulator-run tests (`npm run test:rules`).
- **The multi-tenant `/tenants/{tenantId}/...` structure the masterplan proposes already IS the
  live schema** — most of its "granular Firestore schema" section describes what already exists,
  under slightly different collection names.
- **A real automated test suite exists** (387 Dart tests, 350 Cloud Functions tests as of this
  pass) — any rebuild-in-place work has a real regression net, unlike a from-scratch swarm build.

A ground-up "Agent 1 (DB Architect) implements the schema" phase would be net-negative: it would
either duplicate this working foundation or require migrating real, tested, rules-protected data
onto a parallel schema for no functional gain.

---

## What's genuinely worth prioritizing

Ordered by (a) how much of the pillar's *stated* D365-competitive gap it actually closes, and (b)
how much it reuses already-built foundations rather than starting fresh:

1. **Module Launchpad / IA reorg** (masterplan §1) — the one part of the original pitch that's
   still a live, real gap: today's launchpad is a flat tile grid (`business_os_launchpad.dart`),
   not the proposed 7-pillar grouping. This is a genuinely scoped, mostly-UI exercise — group
   existing routes under new section headers — and doesn't require touching business logic at
   all. Good candidate for a focused first phase.
2. **Finance**: bank reconciliation + multi-currency — the largest *confirmed-missing* piece in
   the pillar with the most existing infrastructure to build on (`FinanceService`,
   `fin_*` collections, the tax engine).
3. **Customer Service**: a real AI reply/summarization path — `aiEngine.ts` already has the
   (deterministic, honestly-named) scaffolding and the file comment already recommends building
   a genuine model-backed version as a *new* function rather than reviving the old one.
4. **HR**: leave-accrual state machine — HR already has the heavier lifts done (ATS, payroll,
   compensation, performance, disciplinary); this is the largest remaining confirmed gap in the
   pillar.
5. **Field Service**: digital signature capture on `WorkOrderDetailsScreen` — small, and the
   module's other "D365 killer feature" claims (route optimization, IoT) turned out to already
   be real.
6. **Supply Chain**: bin/location-level WMS — the pillar with the most infrastructure already
   built this session (Production Orders, MRP, inventory ledger) to extend rather than rebuild.

Everything past this point in the original masterplan (CPQ, e-signatures/document vault,
vendor/customer portals, the "Autopilot" agentic UI) is real, substantial net-new product work —
worth a dedicated design pass each, not a line item here.

## What this document deliberately does not do

- It does not propose a swarm/multi-agent execution structure — most of what the swarm plan
  scoped as new-build work is already built; what's left is closer to a normal, sequential
  backlog than a 15-way parallel rebuild.
- It does not touch the Firestore schema — the masterplan's proposed schema and the live one
  already agree on shape far more than the source docs assumed.
- It does not commit to a timeline or a starting pillar — that's a product/business call for the
  user to make, not something to default into.

## Verification

This is a documentation-only deliverable. No `lib/`, `firebase/functions/`, or `firestore.rules`
files were changed to produce it. Confidence markers above should be spot-checked against current
code before being treated as still true, the same way this session treated the original two
source docs' claims.
