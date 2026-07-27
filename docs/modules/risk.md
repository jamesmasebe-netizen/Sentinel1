# risk — Module Journey Doc

**Path:** `lib/features/risk/`  |  **Compartment:** Project Operations  |  **README.md exists:** yes (`lib/features/risk/README.md` — brief agent-facing manifest. **Materially inaccurate, not just brief** — see §1/§5. This doc is the fuller companion but does not simply extend the README's claims; several are corrected below.)
**Last verified against:** 2026-07-27

## 1. Product Understanding
`risk` is Sentinel1's governance/risk-assessment module: baseline Hazard Identification & Risk Assessment (HIRA), on-the-spot Dynamic Risk Assessment (DRA), Bow-Tie barrier analysis, and a Strategic (enterprise-level) risk register, unified under a Command Center dashboard.

**The module's own README is confirmed inaccurate on its central architectural claims, verified by direct search rather than assumed.** It states: "State Management: Riverpod (`risk_providers.dart`)" and "Data Model: `RiskEntry` (used for both HIRA and strategic risks)." Repo-wide grep confirms **neither exists**: there is no `risk_providers.dart` anywhere in the codebase, and the string `RiskEntry` appears nowhere except inside the README's own text. The module has **no `models/`, `providers/`, or `services/` directory at all** (confirmed via directory listing — only `screens/` and `widgets/` exist under `lib/features/risk/`). Every one of the module's 4 sub-features writes and reads raw `Map<String, dynamic>` directly inside screen/widget `build()` methods (`firestoreServiceProvider.createDocument()` for writes, inline `StreamBuilder<QuerySnapshot>` for reads) — the same architectural pattern `emergency.md` documented for that module, but here spanning a much larger, more central 17-file module with no serialization layer anywhere. A real, well-formed model does exist in the codebase for this domain — `RiskAssessment` in `lib/core/models/safety_models.dart` (`fromFirestore`/`toFirestore`, `inherentRiskScore`/`residualRiskScore`) — but it is **not imported or used anywhere inside `lib/features/risk/`**; it appears to be built for and consumed elsewhere (not traced further in this pass; worth checking when a `safety`-adjacent doc revisits this).

**In scope:** HIRA (baseline hazard/risk register), DRA (task-level, on-the-spot), Bow-Tie threat/barrier/consequence analysis, strategic/enterprise risk register, cross-feature KPI dashboard.
**Out of scope:** incident reporting itself (`safety`), CAPA generation (`safety`), the Safety File & Resource Audit subprocess's document-upload/review workflow (`contractors`/`projects` — `risk`'s own collections are only *read from* by `projects`, not the reverse; see §6).
**IA placement:** Project Operations compartment (8-compartment taxonomy) per this doc set — though note the [shared doc](_shared_personas_and_bpfs.md#persona-qc-compliance-manager) also names this module under the QC & Compliance Manager persona's secondary focus, split across two compartments' personas depending on which journey is in view. See [IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `risk` | Entry screen(s) |
|---|---|---|---|
| [Project & Risk Manager](_shared_personas_and_bpfs.md#persona-project-risk-manager) (primary) | Risk Management: Conduct Dynamic Risk Assessment (DRA) for site tasks → Perform formal HIRA → Implement Bowtie Mitigations → Link to Strategic Risk Register | `dra_form.dart` → `hira_form.dart` → `bowtie_form.dart` → `strategic_risk_form.dart` | `risk_hub_screen.dart` and its 5 module tiles |
| [QC & Compliance Manager](_shared_personas_and_bpfs.md#persona-qc-compliance-manager) (secondary) | No named shared-doc journey step maps directly here — that persona's own journeys (ISO certifications, NCR/CAPA issuance, internal audits, training-record linkage) don't reference HIRA/DRA/Bowtie/Strategic Register by name | Domain-adjacency only (both are governance/compliance-flavored) — stated plainly rather than stretched, consistent with `operations.md`'s equivalent finding for its own secondary persona | — |

## 3. BPF Participation
| BPF | Stage(s) this module implements (narrative) | Code reference |
|---|---|---|
| [Issue to Resolution](_shared_personas_and_bpfs.md#bpf-issue-to-resolution) | Named in the shared doc's "Modules" list (`safety, risk, customer_service, field_service, emergency`) — narrative only | None found |
| [Project Concept to Close](_shared_personas_and_bpfs.md#bpf-project-concept-to-close) — Safety File & Resource Audit subprocess | Named in the shared doc's "Modules" list (`projects, operations, risk, finance, contractors`) — narrative only | None found |

**Confirmed zero code-level BPF participation, independently verified.** Grepping `lib/core/bpf/` for `"risk"` returns no matches, and `lib/features/risk/` contains no import of anything under `core/bpf/` and no `BpfRibbonWidget` usage. Same finding as `operations.md` for this same batch — narrative module-list membership, no code touchpoint at all (not even an unwired ribbon).

**Correction to this assignment's own working hypothesis, verified directly rather than assumed:** the brief for this batch flagged `risk` as "a strong candidate for `HighRiskIncidentReportedEvent` emission given its name." Checked directly: `HighRiskIncidentReportedEvent` (`lib/core/events/app_event_bus.dart`) is fired from exactly one place in the entire codebase — `lib/features/safety/screens/incident_report_form.dart` — not from anywhere in `lib/features/risk/`. `risk` itself has **zero `AppEventBus` usage** in either direction (confirmed by grep for both `AppEventBus` and `.fire(`) — it neither emits this event nor any other, and listens for nothing. The event's naming made it a reasonable thing to check, but the code places it in `safety`, not here.

## 4. Screens & UI Elements Inventory
| Screen | Route or entry point | Purpose / wiring |
|---|---|---|
| `risk_hub_screen.dart` | `/risk` (only top-level route) | Landing hub: 3 live `StreamMetricCard` KPIs + 5-tile module grid, all via `UIUtils.showSideSheet` |
| `risk_command_center_screen.dart` | Side-sheet from hub ("Command Center" tile) | Live KPI grid + risk-distribution matrix + recent-assessments list, all `dynamic_risk_assessments`-backed. **Real, not mocked** — but see §7 for field-mismatch bugs in what it reads |
| `hira_screen.dart` | Side-sheet from hub ("HIRA Register" tile) | Baseline HIRA register — real CRUD via `hira_form.dart`/`hira_card.dart` |
| `dynamic_risk_assessment_screen.dart` | Side-sheet from hub ("Dynamic RA" tile) | DRA register — real CRUD via `dra_form.dart`/`dra_card.dart` |
| `bowtie_screen.dart` | Side-sheet from hub ("Bow-Tie Analysis" tile) | Bow-tie register — real CRUD via `bowtie_form.dart`/`bowtie_card.dart`; **the one sub-feature with no confirmed field-mismatch** (§7) |
| `strategic_risk_register_screen.dart` | Side-sheet from hub ("Strategic Register" tile) | Enterprise risk register — real CRUD via `strategic_risk_form.dart`/`strategic_risk_card.dart` |

`hira_screen.dart` and `strategic_risk_register_screen.dart` both accept `initialSearch`/`highlightId` constructor parameters intended for deep-linking (presumably from a global search or AI copilot result), but neither is functional: `hira_screen.dart`'s `initState()` has a dead, commented-out assignment (`// _search = widget.initialSearch!;` — `_search` isn't even a declared field in that State class), and both screens' `highlightId` handling shows a literal `'(Detail view not yet implemented)'` placeholder. This isn't unique to `risk` — the identical string and pattern recur in `operations/screens/action_tracker_screen.dart`, `safety/screens/capa_screen.dart`, `safety/screens/permit_to_work_screen.dart`, `safety/screens/hazard_register_screen.dart`, `compliance/screens/compliance_docs_screen.dart`, `contractors/screens/contractor_management_screen.dart`, and `core/widgets/app_header_widgets.dart` (9 files repo-wide) — a systemic, cross-module incomplete-deep-link pattern worth flagging once here rather than treating as risk-specific.

## 5. Backend & Database

**No model layer** — see §1. All 5 collections below are written/read as raw maps.

**Collections (all under `tenants/{tenantId}/...` via the `tenantCollection()` extension, all correctly tenant-scoped):**
| Collection | Written by | Read by |
|---|---|---|
| `risk_assessments` | `hira_form.dart` | `hira_screen.dart` |
| `dynamic_risk_assessments` | `dra_form.dart` | `dynamic_risk_assessment_screen.dart`, `risk_command_center_screen.dart`, `risk_hub_screen.dart` |
| `strategic_risks` | `strategic_risk_form.dart` | `strategic_risk_register_screen.dart` |
| `bowtie_analyses` | `bowtie_form.dart` | `bowtie_screen.dart` |
| `hazards` | (no writer found inside this module — presumably `safety`) | `risk_hub_screen.dart` (Critical Risks KPI only) |

**Refines the reusable-context's suspected `riskAssessments`/`risk_assessments` camelCase-vs-snake_case drift — the actual picture is more specific.** `hira_form.dart`/`hira_screen.dart` correctly and consistently use the exact rules-declared snake_case name `risk_assessments` — there is no camelCase/snake_case drift on this particular collection. The real drift is elsewhere: (1) DRA uses an entirely separate, undeclared collection (`dynamic_risk_assessments`, not a casing variant of anything — a different name outright); (2) a *third* variant, `riskAssessments` (camelCase), does exist in the codebase as a per-project **subcollection** path (`tenants/{t}/projects/{id}/riskAssessments`, read by `projectRiskAssessmentsProvider` in `projects/providers/project_providers.dart` — see `projects.md` §5) — but nothing in `risk` module writes to that path; no code was found anywhere that populates a project's `riskAssessments` subcollection, from this module or otherwise, so `projects.md`'s "Risk Assessments" tab section is likely always empty regardless of how many real HIRA/DRA/strategic records exist.

**Firestore rules check:** `risk_assessments` and `hazards` are explicitly declared in `firestore.rules` (both SHEQ-officer-gated for writes). **`dynamic_risk_assessments`, `strategic_risks`, and `bowtie_analyses` — 3 of this module's 5 collections, covering 3 of its 4 create forms — are not declared anywhere in `firestore.rules`.** All three fall to the tenant-scoped catch-all (`allow read: if belongsToTenant(tenantId); allow write: if false;`), meaning **`dra_form.dart`, `strategic_risk_form.dart`, and `bowtie_form.dart`'s submit methods — 3 of this module's 4 primary create flows — would each be rejected by the deployed rules as committed.** Only `hira_form.dart`'s write path is actually permitted by the rules as written. This is a more severe version of the pattern `emergency.md` and `people.md` both flagged for their own modules — here it blocks the majority of the module's own data-entry surface, not a minority.

**Cloud Functions:** none — no file under `lib/features/risk/` references `httpsCallable` or `FirebaseFunctions` (confirmed by grep).

**Providers/Services:** none exist for this module (§1). `firestoreServiceProvider` and `firestoreProvider`/`currentTenantIdProvider` (all from `core/providers/app_providers.dart`) are used directly in every form/screen instead.

## 6. Cross-Module Links
- **projects**: the module's single most substantial cross-module relationship, and it runs in only one direction. `projects/widgets/project_tabs/safety_tab.dart` (via `safety_compliance_data_fetcher.dart`) and `projects/widgets/custom_gantt_chart/gantt_task_editor_sheet.dart` both read a project-linked risk by probing `risk_assessments` → `dynamic_risk_assessments` → `strategic_risks` in sequence. Nothing in `risk` reads or writes anything belonging to `projects` (confirmed by grep from this module's side — no `projectId` field written by any of the 4 forms, despite `projects`' own code clearly expecting risk records to be linkable to a project). See `projects.md` §6/§7 for the same finding from the other side, including a confirmed live bug (`safety_compliance_data_fetcher.dart` hardcodes an empty-string tenant ID for these exact lookups).
- **people**: `EmployeeSelector` (approver/owner pickers in `hira_form.dart`, `dra_form.dart`, `strategic_risk_form.dart`) and `employeesProvider` (team-member multi-select in `hira_form.dart`/`dra_form.dart`).
- **safety**: no code-level link found in either direction (confirmed by grep both ways) despite both modules sharing SHEQ/governance subject matter and both being named together under Issue to Resolution's narrative module list.
- **AppEventBus:** zero usage (§3).

## 7. Known Gaps

### Rules-vs-code gaps
- `dynamic_risk_assessments`, `strategic_risks`, `bowtie_analyses` undeclared in `firestore.rules` — see §5 for the full severity assessment (3 of 4 create forms blocked).
- `BaseIncident` (AGENTS.md §5, absent repo-wide per the [shared doc](_shared_personas_and_bpfs.md#related-rules-vs-code-gap-applicable-wherever-relevant-below)): flagged here as instructed at minimum, since this module's README claims a `RiskEntry` model that would have been a natural candidate to extend or parallel `BaseIncident` — but as established in §1, `RiskEntry` doesn't exist at all, so there is no model here to audit against the mandate one way or the other.

### DB-to-UI alignment audit
No Dart model exists for any of the 4 create forms (§1), so the standard model-vs-form methodology doesn't directly apply. Auditing form-to-display field consistency instead surfaces this pass's most concrete, precisely-verified finding:

**Confirmed cluster of field-name mismatches between `dra_form.dart`'s write payload and every screen that reads it back** — none of the other three sub-features (HIRA, Bowtie, Strategic) show this pattern; their write and read field names were checked and match correctly.
| Field read | Read by | Actually written by `dra_form.dart` as | Effect |
|---|---|---|---|
| `taskDescription` | `dra_card.dart` (title) | `activity` | Every DRA card's title always falls back to "Untitled Assessment" |
| `location` | `dra_card.dart` (location row) | `area` | The location row's `!= null` guard is always false; it never renders |
| `task` | `risk_command_center_screen.dart` ("Recent Assessments" title) | `activity` | Same "Untitled Assessment" fallback, independently, in a second screen |
| `riskLevel` | `risk_command_center_screen.dart` (Extreme/High/Medium/Low KPI grid) | *(never written — `dra_form.dart` has no risk-scoring logic at all, unlike `hira_form.dart`/`strategic_risk_form.dart`, which both compute and store a rating)* | Extreme/High/Medium/Low KPI counts are always 0 regardless of actual DRA content; only "Total Risks" and "Pending" are meaningful |
| `status` | `risk_hub_screen.dart` (Open Assessments / Control Strength KPIs) | *(never written — `dra_form.dart` stores `isSafeToProceed: bool`, not a `status` string)* | "Open Assessments" always counts every DRA as open; "Control Strength" always computes 0% once any DRA exists (floor of `'80%'` only applies when the collection is empty) |

Fields confirmed to work correctly end-to-end: `hazardsIdentified`, `controlsApplied`, `isSafeToProceed`, `createdAt`.

Widget-choice audit (the layer that *is* clean across all 4 forms): `approverId`/`_ownerId` consistently use `EmployeeSelector` (a proper lookup, not free text) in `hira_form.dart`, `dra_form.dart`, and `strategic_risk_form.dart`; `reviewDate` uses a real `showDatePicker` in both HIRA and DRA forms. No "foreign key rendered as a plain `TextFormField`" instances were found in this module, unlike the pattern `crm.md` and `people.md` both documented for their own forms — worth noting as a positive contrast, not just gaps.

### Other
- **`risk_matrix_widget.dart` ("Risk Distribution Matrix... Likelihood vs Impact assessment heat map," per its own caption in `risk_command_center_screen.dart`) is entirely decorative.** It's a fixed 4×5 grid of computed gradient colors and label numbers (`(row + col + 1)`), with no constructor parameters, no `ref`, and no query of any kind — it does not reflect the actual distribution of live assessments despite being captioned as if it does. Lower severity than the `revenue_recognition_screen.dart`/`schedule_board_screen.dart` findings in this batch's other two modules (it's a small presentational widget, not a full screen), but the same category of "looks like live data, isn't" issue.
- README inaccuracy — see §1.
- No models/providers/services layer for a 17-file, architecturally central module — see §1.
- **Cross-module systemic finding, consistent with what a sibling batch reportedly found for `safety`/`training`:** 3 of this module's 5 collections fall outside `firestore.rules`' explicit coverage — directly corroborates that the "many Firestore collections used across the app are absent from `firestore.rules`" finding extends into Project Operations, not just SHEQ/HR-flavored modules.
- **IA/taxonomy conflict**: see [_shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved) — this module is a further data point, split across two personas in two different compartments depending on which journey text is consulted.

## 8. Open Questions
- Should `dra_form.dart` be fixed to write `taskDescription`/`location`/`riskLevel`/`status` (matching what its own module's other screens already read), or should the readers be updated to match what the form actually writes (`activity`/`area`/computed-from-`isSafeToProceed`)? Either direction resolves the mismatch; the form's inconsistency with its own sibling forms (HIRA and Strategic both compute and store a risk rating; DRA doesn't) suggests the form may be the more likely candidate to fix.
- Was `RiskEntry`/`risk_providers.dart` ever actually built and later deleted during a refactor that didn't update the README, or was the README written ahead of implementation and the model/provider layer simply never followed? Either explanation fits an otherwise-functional module (raw-map CRUD works today) whose documented architecture doesn't match its code.
- Should `risk`'s forms write a `projectId` field so `projects`' own risk-linking UI (`safety_tab.dart`, Gantt task risk-linking) has something real to find, given `projects` clearly already expects this integration to exist?
- Is `core/models/safety_models.dart`'s unused `RiskAssessment` class intended for a future migration of this module onto a real model layer, or does it serve a different, already-live consumer elsewhere that a `safety`-focused pass should identify?
- Should `dynamic_risk_assessments`, `strategic_risks`, and `bowtie_analyses` be added to `firestore.rules` (mirroring `risk_assessments`' existing SHEQ-officer-gated pattern), given they currently block 3 of this module's 4 create flows outright?
