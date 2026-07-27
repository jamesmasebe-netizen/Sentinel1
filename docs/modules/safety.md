# safety — Module Journey Doc

**Path:** `lib/features/safety/`  |  **Compartment:** Human Resources  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`safety` is Sentinel1's core SHEQ operations module: incident reporting, hazard register, CAPA (Corrective/Preventive Actions), Permit to Work, BBS (Behavior-Based Safety) observations, PPE compliance/issuance, safety analytics, and QR-code compliance passports (generation + gate-scanning). It is the largest of the 6 modules in this batch (49 Dart files) and the natural home of the "HR & Safety Officer" persona's day-to-day work.

**In scope:** incident intake and register, hazard reporting, CAPA lifecycle, permit-to-work workflow, BBS observations, PPE issuance/compliance tracking, safety KPI analytics, QR passport generation and gate-scanning.
**Out of scope:** Toolbox Talks (owned by `training` — `toolbox_talks_tab.dart`, `talk_form_sheet.dart`, despite being named in the HR & Safety Officer's "Safety Compliance" journey below), Workers' Comp claims (owned by `workers_comp`), formal HIRA/DRA risk-assessment authoring (owned by `risk` — `safety` only reads `risk_assessments`-adjacent IDs), baseline medical records (nominally `health`, but see §6 — `safety` actually reads medical-certificate data out of `training_records`).
**IA placement:** Human Resources compartment (8-compartment taxonomy). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved) — this module is the clearest illustration of the doc set's own flagged tension, since "safety" is filed under "Human Resources."

## 2. User Journeys
| Persona | Journey | Steps touching `safety` | Entry screen(s) |
|---|---|---|---|
| [HR & Safety Officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer) | Incident Management | Receive Incident Report → Log Safety Hazard → Trigger CAPA | `incident_report_form.dart`, `incidents_register_screen.dart`, `hazard_register_screen.dart` + `hazard_form_sheet.dart`, `capa_screen.dart` + `capa_form.dart` |
| [HR & Safety Officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer) | Safety Compliance | Issue Permit to Work → Issue PPE → Conduct BBS Observation | `permit_to_work_screen.dart` + `permit_form_sheet.dart`, `ppe_compliance_screen.dart` + `ppe_issuance_form.dart`, `bbs_observations_screen.dart` + `bbs_observation_form.dart` |
| [HR & Safety Officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer) | Contractor Safety Compliance (deep-linked) | Generate & Issue Contractor Personnel Safety Passport (QR) | `contractor_qr_passport_screen.dart` (orphan — see §7), `passport_compliance_checker.dart` |
| [Employee (Self-Service)](_shared_personas_and_bpfs.md#persona-employee-self-service) | Daily Operations | Conduct peer BBS Observation (optionally anonymous) | `bbs_observation_form.dart` |
| [QC & Compliance Manager](_shared_personas_and_bpfs.md#persona-qc-compliance-manager) | Quality Assurance | Issue Non-Conformance Reports (via CAPA form's `rca`/root-cause field) | `capa_screen.dart` + `capa_form.dart` |
| [Security / Gate Access Personnel](_shared_personas_and_bpfs.md#persona-security-gate-access) | Site Access Control | Scan Employee/Contractor QR → view compliance, scope, permits → grant/deny access | `qr_scanner_screen.dart` |

## 3. BPF Participation
| BPF | Stage(s) this module implements (narrative) | Code reference |
|---|---|---|
| [Issue to Resolution](_shared_personas_and_bpfs.md#bpf-issue-to-resolution) | Logged → Investigation → CAPA → Closure | `lib/core/bpf/issue_to_resolution_bpf.dart` — 4 stages; `logged`/`investigation`/`closure` carry `expectedRecordType: 'incident'`, the `capa` stage carries `expectedRecordType: 'capa'` (i.e. two distinct record types across the 4 stages, not a single blanket type) |

**Implementation-depth correction** (see [_shared doc](_shared_personas_and_bpfs.md#business-process-flows-bpfs)): `BpfOrchestrator.createCapaFromIncident()` is a **stub** — its own code comment states *"Generates a mock CAPA ID... In a real implementation we would write to safetyService.createCapa(...)"* — it only advances the `bpf_instances` tracking record with a fabricated `CAPA-<timestamp>` ID string.

**Two nuances not obvious from the stub alone:**
1. **The ribbon is actually wired here** — `incident_detail_sheet.dart` renders `BpfRibbonWidget(bpfTypeId: 'issue_to_resolution', recordType: 'incident', recordId: docId, definition: issueToResolutionDefinition)`. Unlike `people.md`'s Hire-to-Retire finding (zero ribbon usage), Issue-to-Resolution's ribbon **is** visually present on the Incident Detail sheet. However, a repo-wide search for `'issue_to_resolution'` found no code path anywhere that ever creates a `bpf_instances` document for it — so the ribbon has no real instance to track and would render an empty/default state on every incident.
2. **The real auto-CAPA behavior already exists — just not through the BPF engine.** `incident_report_form.dart` (lines ~147–171) directly writes a new document to the `capas` collection whenever severity is `'Major'` or `'Critical'`, in the same transaction as firing `HighRiskIncidentReportedEvent` on the `AppEventBus`. This is a real, working equivalent of the "Trigger CAPA" journey step — it just bypasses `BpfOrchestrator` entirely, using `FirestoreService.createDocument()` directly. (See §7 for why this specific write is also the one most likely to silently fail.)

## 4. Screens & UI Elements Inventory
| Screen | Route or side-sheet | Purpose |
|---|---|---|
| `safety_hub_screen.dart` | `/safety` | Hub — KPI header + grid of module tiles, each opened via `UIUtils.showSideSheet` |
| `incidents_register_screen.dart` | side-sheet (from hub) | List/filter incidents, status update |
| `incident_report_form.dart` | side-sheet (from hub header, and from register screen) | Primary incident intake form |
| `incident_detail_sheet.dart` | side-sheet (`showIncidentDetail()`, called from `incident_card.dart`) | Incident detail + status/cost edit + BPF ribbon |
| `hazard_register_screen.dart` | side-sheet (from hub) | List hazards |
| `permit_to_work_screen.dart` | side-sheet (from hub) | List/approve permits |
| `capa_screen.dart` | side-sheet (from hub) | CAPA register + status workflow |
| `bbs_observations_screen.dart` | side-sheet (from hub) | BBS observation feed |
| `ppe_compliance_screen.dart` | side-sheet (from hub) | PPE dashboard + issuance log |
| `safety_analytics_screen.dart` | side-sheet (from hub) | Client-side KPI/trend charts computed from `incidents` |
| `qr_scanner_screen.dart` | **`Navigator.push`/`MaterialPageRoute`** (from hub's "Scan Passport" button) | Gate-scan flow: decode QR → live compliance lookup → grant/deny |
| `contractor_qr_passport_screen.dart` | **none found** — never instantiated anywhere in `lib/` | Would generate a contractor's QR passport + compliance card |
| `employee_qr_passport_screen.dart` | **none found** — never instantiated anywhere in `lib/` | Would generate an employee's QR passport + compliance card |

Widgets not listed individually (35 files under `widgets/`): form-field partials for the incident form (`incident_basic_info_fields.dart`, `incident_type_severity_fields.dart`, `incident_location_date_fields.dart`, `incident_photo_capture_section.dart`, `incident_cost_tracking_fields.dart`, `incident_report_dynamic_fields.dart` — one file per `IncidentReportForm` section, consistent with AGENTS.md's 200-line/micro-widget rule), card/badge components (`incident_card.dart`, `capa_card.dart`, `hazard_card.dart`, `permit_card.dart`, `observation_card.dart`, `capa_status_badge.dart`, `incident_status_colors.dart`), and chart primitives reused only within this module (`bar_chart.dart`, `breakdown_card.dart`, `risk_zone.dart`, `kpi_card.dart`).

## 5. Backend & Database

**Models — split across three places, none of them the sole source of truth:**
| Location | Classes | Actually used by `safety`? |
|---|---|---|
| `lib/core/models/incident.dart` | `Incident`, `CAPA` | **No.** Repo-wide search found zero importers anywhere in `lib/` — fully dead code, not just unused by this module. |
| `lib/core/models/safety_models.dart` | `Permit`, `RiskAssessment`, `Contractor`, `ActionItem` | **No**, not by `safety` — the sole importer found is `lib/features/projects/providers/project_providers.dart`. |
| `lib/features/safety/providers/safety_providers.dart` | `SafetyIncident`, `WorkPermit` — the file's own comment calls these "Placeholder models or direct Firestore data" | Only for two narrow property-scoped providers (`propertyIncidentsProvider`, `propertyPermitsProvider`); not used by the main register/CAPA/permit screens. |

Every screen in `safety` (register, detail sheet, CAPA, hazards, permits, BBS, PPE, analytics) reads/writes `Map<String, dynamic>` straight off `DocumentSnapshot.data()` — none of the above classes are on the hot path. This explains why the field-shape drift documented in §7 has never surfaced as a runtime crash.

**Collections used (all under `tenants/{tenantId}/...` via `FirebaseFirestore.tenantCollection()`):** `incidents`, `hazards`, `permits`, `capas`, `bbs_observations`, `ppe_compliance`, `ppe_inventory`, plus cross-reads of `training_records`, `contractor_safety_files`, `contractors`, `contractor_documents`, `employees`, `projects`. Declared but seemingly low-traffic subcollection providers in `safety_providers.dart`: `incidents/{id}/attachments`, `incidents/{id}/witnesses`, `permits/{id}/hazards`, `permits/{id}/controlMeasures`, `permits/{id}/ppeRequired`, `permits/{id}/attachments`, `riskAssessments/{id}/hazards`, `contractors/{id}/certifications`, `actionItems/{id}/attachments`.

**Firestore rules cross-check (critical finding):** `firestore.rules` explicitly declares purpose-built rules for `incidents` (anyone in tenant can create; SHEQ officer/admin to update/delete), `permits` (SHEQ officer create/update, admin delete), and `hazards` (anyone can create, SHEQ officer update, admin delete) — all correctly permissive for their journeys. **But `capas`, `bbs_observations`, `ppe_compliance`, and `ppe_inventory` are not declared anywhere in `firestore.rules`.** They fall through to the file's catch-all:
```
match /{collection}/{docId} {
  allow read: if belongsToTenant(tenantId);
  allow write: if false;
}
```
Reads work; **all writes are denied**. Confirmed this is the live write path: `capa_form.dart`, `bbs_observation_form.dart`, and `ppe_issuance_form.dart` all write through `FirestoreService.createDocument()` / direct `.add()` calls against the same `tenants/{tenantId}/{collection}` path structure the rules match on, and `OfflineSyncService` (the queue `createDocument()` funnels through) ultimately calls the plain client-SDK `.set()`/`.add()`/`.update()` — i.e. rules-enforced writes, not an Admin-SDK bypass. Assuming these rules are the deployed ruleset, CAPA creation, BBS observation submission, and PPE issuance/compliance logging would all fail with permission-denied against real Firestore — including `incident_report_form.dart`'s auto-CAPA write on Major/Critical incidents (§3), which shares the same `try/catch` as the incident write itself, so a failure there surfaces as "Failed to report incident: ..." even though the incident document was very likely already created successfully by the earlier, separate `createDocument()` call.

**Cloud Functions** (source: `firebase/functions/src/index.ts` — the richer of the two Functions codebases per the shared doc; which codebase is actually deployed is ambiguous since `firebase.json` declares no `functions` key):
- `onIncidentCreated` — Firestore-create trigger, notifies `safety_manager`/`admin`/`executive` users (push + email) when `severity` is `"Critical"` or `"Fatal"`.
- `checkPermitExpiry` — daily 07:00 SAST scheduled function, pushes reminders for permits expiring within 24h.
- **Path mismatch:** both are declared against **flat, top-level** paths — `onDocumentCreated({document: "incidents/{incidentId}"})` and `db.collection("permits")` — not `tenants/{tenantId}/incidents` / `tenants/{tenantId}/permits`, which is where the app actually writes (confirmed via `tenant_firestore_extension.dart`'s `tenantCollection()` and the rules structure above). As written, neither function would trigger on/match data created through `incident_report_form.dart` or `permit_form_sheet.dart`. (The same file's Finance functions, e.g. `onInvoiceStatusChanged` on `tenants/{tenantId}/finance_invoices/{invoiceId}`, correctly use the tenant-scoped path — this is specifically a SHEQ-side inconsistency, also affecting `checkCoidaOverdue`/`checkTrainingExpiry`; see `workers_comp.md`/`training.md`.)

**Defensive-write pattern:** all six create forms in this module (`incident_report_form.dart`, `hazard_form_sheet.dart`, `capa_form.dart`, `bbs_observation_form.dart`, `permit_form_sheet.dart`, `ppe_issuance_form.dart`) correctly follow AGENTS.md §1 — local `isSubmitting`/`_isSubmitting` bool, try/catch/finally, disabled button while submitting.

## 6. Cross-Module Links
- **AppEventBus:** `incident_report_form.dart` fires `HighRiskIncidentReportedEvent(incidentId, projectId)` on Major/Critical severity — consumed by `dashboard_screen.dart` (confirmed in `dashboard.md`).
- **Reads `training_records`** (nominally `training`'s collection) inside `passport_compliance_checker.dart` and `qr_scanner_screen.dart`, filtering `type == 'medical_certificate'` / `type == 'induction'` to represent baseline-medical and induction compliance — i.e. `health`'s "Baseline Medical" concept has no dedicated collection read anywhere in `safety`; it's represented as a document *type* inside `training_records`. Worth double-checking against `health.md` whether `health`'s own medical form writes to that same collection/type.
- **Reads `employees`, `contractors`, `contractor_documents`, `contractor_safety_files`, `permits`, `projects`** directly from `qr_scanner_screen.dart` to build the Security/Gate-Access compliance view — this duplicates the compliance-scoring logic already implemented in `services/passport_compliance_checker.dart` rather than calling it.
- `EmployeeSelector` (from `people/widgets/employee_selector.dart`) is reused in `bbs_observation_form.dart`, `permit_form_sheet.dart`, `ppe_issuance_form.dart`, `capa_form.dart`.
- `operations/screens/action_tracker_screen.dart` and `risk/screens/risk_hub_screen.dart` both read `safety`'s collections (`capas`, `hazards`, `bbs_observations`) directly as cross-module rollups — same read-only coupling-by-collection-name pattern noted in `dashboard.md`.

## 7. Known Gaps

### Rules-vs-code gaps
- `BaseIncident` — mandated by `.agents/AGENTS.md` §5, does not exist anywhere in the codebase (see [_shared doc](_shared_personas_and_bpfs.md#related-rules-vs-code-gap-applicable-wherever-relevant-below)). `safety` is the module where this gap bites hardest: it owns the one real `Incident` concept in the app, that concept has a dedicated (if dead — see §5) `Incident` model already, and there is no environmental-incident sibling for it to poly­morphically share with, despite AGENTS.md naming exactly that pairing as its example.
- **`Navigator.push`/`MaterialPageRoute` from a Hub screen** — `safety_hub_screen.dart`'s "Scan Passport" button opens `QrScannerScreen` via `Navigator.push(context, MaterialPageRoute(...))`, not `UIUtils.showSideSheet`. This directly contradicts AGENTS.md §1's "Deep Sub-Navigation" rule ("NEVER use `Navigator.push` to open detailed forms or sub-modules from a Hub screen"). Every other module tile on the same hub correctly uses `showSideSheet`.
- Catch-all rule denies all writes to `capas`, `bbs_observations`, `ppe_compliance`, `ppe_inventory` — see §5 for full detail; this is the single most consequential finding in this doc.

### DB-to-UI alignment audit
`incident_report_form.dart` vs `core/models/incident.dart`'s `Incident` (nominal canonical model — see §5 caveat that nothing actually parses documents through it, which is precisely why this drift has never crashed anything):
| Field | Status | Note |
|---|---|---|
| `type`, `severity` | Value-mismatch | Form's dropdowns write capitalized display strings (`'Injury'`, `'Near Miss'`, `'Property Damage'`, `'Environmental'`; `'Minor'`/`'Moderate'`/`'Major'`/`'Critical'`) vs. the model's documented lowercase/snake_case enum (`injury`/`near_miss`/.../`fire`/`chemical`; `minor`/`major`/`moderate`/`critical`/`negligible`) |
| `status` | Value-mismatch | Form hardcodes `'Open'`; model default is lowercase `'open'` |
| `area` | Missing | Never collected by the form |
| `lostTimeInjury`, `daysLost` | Missing | Never collected anywhere in the form — these are exactly the fields an LTIFR calculation needs, and LTIFR is named as a KPI in this module's own analytics narrative and on the main `dashboard` |
| `rootCause`, `immediateAction`, `correctiveAction`, `assigneeId` | Missing | Reasonable to defer to investigation-time, but no other screen in `safety` was found writing them back onto the incident document either — `capa_form.dart`'s free-text `rca` field goes to the separate `capas` collection instead |
| `dateOfIncident`, `createdAt` | Wrong type | Form writes `DateTime.toIso8601String()`; model's `fromFirestore` does `(data['dateOfIncident'] as Timestamp?)?.toDate()` — would throw a cast error if anything ever actually parsed these documents through the model |
| `photoUrl`, `isAnonymous`, `directCosts`, `indirectCosts`, `totalCost`, `contractorId`, `reporterName`, `injuryDetails`/`environmentalDetails`/`propertyDamageDetails` | Orphan | Present in the real Firestore documents the form writes; absent from the `Incident` model entirely |

### Other
- **`reporterName` hardcoded bug**: `incident_report_form.dart` sets `'reporterName': 'Selected Employee'` — a literal placeholder string, not the display name of the employee chosen via `_selectedReporterId`. Every incident's stored `reporterName` is this same literal text regardless of who was actually selected.
- **Orphan QR passport screens**: `contractor_qr_passport_screen.dart` and `employee_qr_passport_screen.dart` are never instantiated anywhere in the app (confirmed by repo-wide search) — no route, no side-sheet call, nothing. The "Generate & Issue Contractor Personnel Safety Passport (QR code)" journey step has no confirmed UI entry point. Only the scanning side (`qr_scanner_screen.dart`) is reachable.
- **Duplicated compliance-check logic**: `qr_scanner_screen.dart` re-implements medical-cert/training/induction/PTW compliance checks inline rather than calling the already-written `services/passport_compliance_checker.dart`, which the two orphan passport screens (above) depend on.
- **Cloud Function path mismatch**: see §5 — `onIncidentCreated`/`checkPermitExpiry` listen on flat top-level collections that the app never writes to.
- IA/taxonomy conflict: see [_shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Should `core/models/incident.dart` (`Incident`, `CAPA`) be wired up and the raw-`Map` screens migrated to it, or deleted as dead code?
- Should `qr_scanner_screen.dart` be refactored to call `PassportComplianceChecker` instead of duplicating its logic?
- Is the missing `firestore.rules` coverage for `capas`/`bbs_observations`/`ppe_compliance`/`ppe_inventory` an oversight, or are these features intentionally write-blocked pre-launch? Worth confirming before this ships to real users, since three working create forms (CAPA, BBS, PPE) would otherwise fail silently in production.
- Are `ContractorQrPassportScreen`/`EmployeeQrPassportScreen` meant to be wired up as real navigation targets, or superseded by `qr_scanner_screen.dart`'s inline bottom-sheet approach and safe to delete?
- Should `safety_hub_screen.dart`'s QR scanner button be converted to `showSideSheet` for consistency with every other tile on the same hub?
