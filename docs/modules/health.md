# health — Module Journey Doc

**Path:** `lib/features/health/`  |  **Compartment:** Human Resources  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`health` is Sentinel1's Occupational Health module: medical surveillance (fitness-for-duty exams), workplace hygiene/exposure surveys, a first-aid treatment log, and a static wellbeing/EAP info hub. It is small (12 files, no `models/`, no `providers/`, no `services/` subfolder — everything lives directly under `screens/` and `widgets/`) and structured as a single screen with 4 tabs.

**In scope:** medical exam records (pre-employment/annual/exit/baseline), fitness-for-duty status, occupational hygiene monitoring (noise/dust/chemical/ergonomic/illumination/thermal readings vs. legal limits), first-aid incident treatment log, static wellbeing/EAP content.
**Out of scope:** formal safety incident reporting (owned by `safety`), the "medical certificate" concept read by `safety`'s QR passport compliance checker (see §6 — that reads a *different* collection than this module writes to), workers' comp claims (owned by `workers_comp`).
**IA placement:** Human Resources compartment (8-compartment taxonomy). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `health` | Entry screen(s) |
|---|---|---|---|
| [HR & Safety Officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer) | Occupational Health | Log Baseline Medical → Record First Aid Incident → Log Workplace Hygiene Audit | `medical_tab.dart` + `medical_form.dart`, `first_aid_tab.dart` + `first_aid_form.dart`, `hygiene_tab.dart` + `hygiene_form.dart` |
| [Employee (Self-Service)](_shared_personas_and_bpfs.md#persona-employee-self-service) | Wellbeing awareness (read-only) | View EAP helpline / wellbeing campaign info | `wellbeing_tab.dart` (fully static — no employee-specific data, just informational cards) |

## 3. BPF Participation
`health` is named in the [Hire to Retire](_shared_personas_and_bpfs.md#bpf-hire-to-retire) persona narrative's "Baseline Medical & Training Allocation" step, but per the shared doc it has **no dedicated stage or `expectedRecordType`** in `lib/core/bpf/hire_to_retire_bpf.dart`'s actual 4 stages (`recruitment`/`onboarding`/`active`/`offboarding`, all `expectedRecordType: 'employee'`). No `BpfRibbonWidget` usage was found anywhere in `lib/features/health/` (confirmed by direct search).

This makes `health` the **weakest, most narrative-only BPF link of the six modules in this batch** — and the code confirms it's not just a documentation gap but a real data-silo problem: this module's own `medical_form.dart` writes fitness-for-duty exams to a `medical_records` collection, which is **entirely disconnected** from the *other* place "medical certificate" compliance is checked in this app — `safety/services/passport_compliance_checker.dart`'s `checkEmployeeCompliance()`, which instead queries `training_records` filtered by `type == 'medical_certificate'` (see `safety.md` §6). Neither piece of code reads the other's collection. So "Baseline Medical" as a concept currently has **two mutually-unaware implementations** in this codebase, not one, and the Hire-to-Retire BPF references neither.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route or side-sheet | Purpose |
|---|---|---|
| `occupational_health_screen.dart` | `/health` **and** side-sheet (People Hub's "Occupational Health" tile, `people_hub_modules_grid.dart`) — reachable both ways | 4-tab shell: Medicals / Hygiene / First Aid / Wellbeing |
| `medical_tab.dart` + `medical_form.dart` + `medical_list_item.dart` | tab | Medical exam list + create form |
| `hygiene_tab.dart` + `hygiene_form.dart` + `hygiene_list_item.dart` | tab | Hygiene survey list + create form |
| `first_aid_tab.dart` + `first_aid_form.dart` + `first_aid_list_item.dart` | tab | First-aid log list + create form |
| `wellbeing_tab.dart` | tab | Static EAP/wellbeing content — no Firestore reads at all |
| `oh_stat_chip.dart` | widget | Small colored stat pill, reused across tabs |

The Launchpad's own "Occupational Health" tile (`business_os_launchpad.dart`) correctly routes to `/health`, which is defined in `router.dart` — unlike this batch's `training`/`compliance` findings, this module's routing is not broken.

## 5. Backend & Database

**Models:** none. No `models/` directory exists in this module, and no shared `core/models/` class represents a medical/hygiene/first-aid record either. Every tab/form here works directly with `Map<String, dynamic>` — there is no `fromFirestore`/`toFirestore` pair anywhere in this module, which is a direct gap against AGENTS.md §2's "Strict Schema Enforcement: every collection must have a corresponding, type-safe Dart model class."

**Collections used** (all under `tenants/{tenantId}/...`): `medical_records`, `hygiene_surveys`, and — **inconsistently** — `first_aid_log` vs `first_aid_logs`:
- `first_aid_tab.dart` reads from `'first_aid_log'` (singular).
- `first_aid_form.dart` writes to `'first_aid_logs'` (plural).

These are two different Firestore collections. **Every first-aid entry submitted through this module's own form is invisible to this module's own list view.**

**Firestore rules cross-check (critical finding, same pattern as `safety.md`):** none of `medical_records`, `hygiene_surveys`, `first_aid_log`, or `first_aid_logs` are declared in `firestore.rules` (confirmed — grepped the full 238-line rules file). All four fall through to the catch-all:
```
match /{collection}/{docId} {
  allow read: if belongsToTenant(tenantId);
  allow write: if false;
}
```
Assuming this is the deployed ruleset, **all three of this module's create forms** (`medical_form.dart`, `hygiene_form.dart`, `first_aid_form.dart`) would fail with permission-denied in production — this module's entire write surface is blocked, not just part of it (contrast `safety`, where `incidents`/`permits`/`hazards` do have real rules and only `capas`/`bbs_observations`/`ppe_compliance` are blocked).

**Cloud Functions:** none found that reference `medical_records`, `hygiene_surveys`, or `first_aid_log(s)` in either `firebase/functions/src/` or `functions/src/`.

**Defensive-write pattern:** all three forms correctly use a local `_isSub` bool + try/catch/finally + disabled submit button, per AGENTS.md §1.

## 6. Cross-Module Links
- `people_hub_screen.dart` reads this module's `medical_records` collection directly (a KPI count on the People Hub landing screen) — confirmed the only cross-module reader.
- `safety`'s `passport_compliance_checker.dart` and `qr_scanner_screen.dart` both check "medical certificate" status, but against `training_records` (type-filtered), not against this module's `medical_records` — see §3. This is the module's single most important cross-module finding: two disconnected "medical" data stores.
- No `AppEventBus` emit or listen usage found anywhere in `lib/features/health/` (confirmed by direct search) — consistent with the shared doc's 2-event-type bus (`EmployeeTerminatedEvent`, `HighRiskIncidentReportedEvent`), neither of which is health-specific.
- `EmployeeSelector` (from `people`) is reused in `medical_form.dart` and `first_aid_form.dart`.

## 7. Known Gaps

### Rules-vs-code gaps
- `BaseIncident` — mandated by `.agents/AGENTS.md` §5, does not exist anywhere in the codebase (see [_shared doc](_shared_personas_and_bpfs.md#related-rules-vs-code-gap-applicable-wherever-relevant-below)). `first_aid_form.dart` records injury/treatment data that conceptually overlaps with `safety`'s `Incident` concept (both capture what happened, treatment/action taken, and whether escalation occurred) — a plausible second candidate for the polymorphic base class AGENTS.md calls for, alongside `safety`/environmental incidents.
- Catch-all rule denies all writes to `medical_records`, `hygiene_surveys`, `first_aid_log`, `first_aid_logs` — see §5.

### DB-to-UI alignment audit
No model exists to audit against (see §5), so this is adapted to compare each create form's write-side fields against its own list item's read-side fields — the same spirit as the standard methodology, applied to the closest available pairing.

`medical_form.dart` (write) vs `medical_list_item.dart` (read):
| Field | Status | Note |
|---|---|---|
| `employeeName` | **Missing on write** | `MedicalListItem` reads `data['employeeName']` to display the record's headline text, but `medical_form.dart`'s submit payload only ever writes `employeeId` (the raw ID string) — `employeeName` is never set. Every medical record card falls back to displaying literal "Unknown Employee," regardless of which employee was actually selected. |
| `medicalType`, `idNumber`, `status`, `nextDueDate` | Correct | Written and read under matching field names |

`first_aid_form.dart` (write) vs `first_aid_tab.dart` (read): see §5 — **collection name itself doesn't match** (`first_aid_logs` vs `first_aid_log`), which supersedes any field-level comparison; nothing written by the form is ever visible in the tab's list.

### Other
- **Hardcoded fitness-status percentages**: `medical_tab.dart` renders three `OHStatChip`s — `'Fit' 85%`, `'Restricted' 12%`, `'Unfit' 3%` — as literal hardcoded strings, not derived from the live `medical_records` stream the same tab queries a few lines below. Direct violation of AGENTS.md §2's "No Hardcoded Data" rule, same pattern as `people.md`'s `employee_activity_tab.dart`/`employee_hr_tab.dart` finding.
- IA/taxonomy conflict: see [_shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Should `medical_records` (this module) and the `training_records`-with-`type: 'medical_certificate'` documents (read by `safety`) be unified into one collection, or is the split intentional (e.g. "fitness-for-duty exam" vs. "medical certificate on file" are meant to be genuinely different records)? As it stands, neither `safety` nor the Hire-to-Retire BPF has any visibility into what this module actually captures.
- Is `first_aid_log` vs `first_aid_logs` a simple typo (one file needs a one-word fix), or did the tab and form drift apart over separate edits? Given they're adjacent files in the same small module, this looks like the easiest true bug to fix in this entire batch.
- Should a `HealthRecord`/`MedicalExam` model class be introduced, given this is the only module in the batch with zero model classes at all?
