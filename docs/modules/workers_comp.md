# workers_comp — Module Journey Doc

**Path:** `lib/features/workers_comp/`  |  **Compartment:** Human Resources  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`workers_comp` is a small, focused South African COIDA (Compensation for Occupational Injuries and Diseases Act) module: claims logging, Return-to-Work (RTW) status tracking, and a static COIDA compliance checklist. It is the smallest module in this batch — 5 files, 1 screen, 3 tabs, no `models/`, no `providers/`, no `services/`.

**In scope:** COIDA claim intake, claim status workflow (Submitted → Accepted/Rejected/Closed), RTW status tracking (Off Sick / Light Duty / Full Duty) for open claims, a reference checklist of COIDA regulatory obligations.
**Out of scope:** the underlying incident that triggered a claim (owned by `safety`), medical certification of fitness-for-duty (owned by `health`), any actual payment/reserve/ledger entry for a claim (see §6 — no code link to `finance` exists despite the persona mapping).
**IA placement:** Human Resources compartment (8-compartment taxonomy). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `workers_comp` | Entry screen(s) |
|---|---|---|---|
| [HR & Safety Officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer) | Incident Management | Log Workers Comp Claim | `claims_tab.dart` (inline form) |
| [HR & Safety Officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer) | Return-to-work oversight | Update RTW status per open claim | `rtw_tab.dart` |
| [Finance Controller](_shared_personas_and_bpfs.md#persona-finance-controller) | (narrative only) | — | No code path found linking this module to `finance`/`invoices`/`journal_entries` — see §6 |

## 3. BPF Participation
`workers_comp` is named in the [Hire to Retire](_shared_personas_and_bpfs.md#bpf-hire-to-retire) persona narrative's module list, but has no dedicated stage or `expectedRecordType` in `lib/core/bpf/hire_to_retire_bpf.dart`'s actual 4 stages (all `expectedRecordType: 'employee'`). No `BpfRibbonWidget` usage was found anywhere in `lib/features/workers_comp/` (confirmed by direct search) — narrative participation only, per the shared doc's caveat.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route or side-sheet | Purpose |
|---|---|---|
| `workers_comp_screen.dart` | `/workers-comp` **and** side-sheet (People Hub's "Worker's Comp" tile) — reachable both ways, unlike `training`/`compliance` | 3-tab shell: Claims / RTW Plans / Checklist |
| `claims_tab.dart` | tab | Claim list + inline create form (not a side-sheet — the form toggles inline within the tab) |
| `rtw_tab.dart` | tab | Open-claims list with tappable `ChoiceChip` RTW status update |
| `compliance_tab.dart` | tab | Static 10-item COIDA regulatory checklist with a progress ring |
| `rtw_badge.dart` | widget | Small color-coded status pill (Off Sick=error, Light Duty=warning, Full Duty=success) reused by `claims_tab.dart` |

## 5. Backend & Database

**Models:** none — no `models/` directory, no shared `core/models/` class for a claim. Both tabs work directly with `Map<String, dynamic>`.

**Collection:** `coida_claims` (single collection, under `tenants/{tenantId}/...`), written by `claims_tab.dart`'s inline form, updated (status / rtwStatus fields) by both `claims_tab.dart` and `rtw_tab.dart`, read by both tabs plus (cross-module) `people/screens/people_hub_screen.dart` for an "open claims" KPI count.

**Firestore rules cross-check:** `coida_claims` is not declared in `firestore.rules` (confirmed — absent from the full 238-line file) and falls through to the catch-all `allow write: if false` — same pattern documented in `safety.md`/`health.md`/`training.md`. Assuming this is the deployed ruleset, `claims_tab.dart`'s claim-submission form and both tabs' status-update calls would all fail with permission-denied in production.

**Cloud Functions:** `checkCoidaOverdue` (`firebase/functions/src/index.ts`, weekly Monday 09:00 SAST) — but it does **not** query this module's `coida_claims` collection at all. It queries a flat, top-level `db.collection("incidents")`, filtering `severity in ['Major','Critical','Fatal']` and `coidaSubmitted == false`. Two independent problems: (1) the flat/top-level path doesn't match where the app writes (`tenants/{tenantId}/incidents`, per `safety.md`'s equivalent finding), and (2) `coidaSubmitted` is a field `safety`'s `incident_report_form.dart` never sets (confirmed in `safety.md`'s DB-to-UI audit) — a query for `coidaSubmitted == false` matches nothing when the field is absent entirely, since Firestore equality filters exclude documents missing the field. So the one automated "did you submit COIDA paperwork on time" check in the codebase is checking a different collection than the one this module actually manages, via a query that can't match real documents even if the path were fixed. Source ambiguity: which Functions codebase is actually deployed is unclear (see shared doc).

## 6. Cross-Module Links
- `people/screens/people_hub_screen.dart` reads `coida_claims` directly for an "open claims" KPI stream.
- **No code link to `finance`** was found anywhere in this module — the Finance Controller secondary persona mapping for this module appears to be a narrative/cross-functional expectation (claims presumably having a cost/reserve implication) rather than anything implemented. No `invoices`, `journal_entries`, or other finance collection is referenced in `lib/features/workers_comp/`.
- No `AppEventBus` emit or listen usage found anywhere in this module (confirmed by direct search).

## 7. Known Gaps

### Rules-vs-code gaps
- `BaseIncident` — mandated by `.agents/AGENTS.md` §5, does not exist anywhere in the codebase (see [_shared doc](_shared_personas_and_bpfs.md#related-rules-vs-code-gap-applicable-wherever-relevant-below)). A COIDA claim is, conceptually, downstream of an incident — worth noting as a third candidate use site alongside `safety`/`health`.
- Catch-all rule denies all writes to `coida_claims` — see §5.

### DB-to-UI alignment audit
`claims_tab.dart`'s inline create form vs. its own (and `rtw_tab.dart`'s) read-side field usage — no model exists to audit against (see §5), so this compares write payload to what's actually displayed:
| Field | Status | Note |
|---|---|---|
| `employeeName` | **Wrong widget** | Free-text `TextFormField` (`_empCtrl`), not the `EmployeeSelector` lookup every other module in this batch uses for employee references (`bbs_observation_form.dart`, `medical_form.dart`, `record_form_sheet.dart`, etc.). No `employeeId` foreign key is captured at all — a claim can't be reliably linked back to a real `EmployeeProfile` document, only a free-typed name string. This is the exact "wrong widget" pattern the shared doc's audit methodology calls out by name. |
| `claimNumber`, `lostDays`, `incidentDate`, `status`, `rtwStatus` | Correct | Written and read under matching field names, consistently, across both `claims_tab.dart` and `rtw_tab.dart` — this module's internal read/write consistency is otherwise clean, in contrast to `health.md`/`training.md`'s findings. |

### Other
- **`compliance_tab.dart` is 100% hardcoded**: the entire "Checklist" tab — all 10 COIDA compliance items and their done/not-done booleans, and the resulting "60%" progress ring — is a literal Dart list (`items = [('Register with COIDA Fund (RAF)', true), ...]`), with zero Firestore reads. Every tenant sees the identical fixed checklist and fixed progress percentage regardless of their real compliance state. This is the single cleanest, most complete "No Hardcoded Data" (AGENTS.md §2/§3) violation found in this batch — unlike other modules' partial hardcoding (e.g. `health.md`'s `OHStatChip` percentages), this entire tab has no backing data model at all.
- IA/taxonomy conflict: see [_shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Should `claims_tab.dart`'s employee field be converted to `EmployeeSelector` (capturing a real `employeeId`), matching every other create form surveyed in this batch?
- Should `compliance_tab.dart`'s checklist become a real Firestore-backed collection with per-tenant checkable state, given every other tab in this module is already correctly live-streamed?
- Should `checkCoidaOverdue` query `coida_claims` directly instead of `incidents.coidaSubmitted`, given this module — not `safety` — is where COIDA claim status is actually tracked?
