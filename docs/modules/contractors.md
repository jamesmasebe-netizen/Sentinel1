# contractors — Module Journey Doc

**Path:** `lib/features/contractors/`  |  **Compartment:** Supply Chain Management  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`contractors` is a single 3-tab screen (`ContractorManagementScreen`: Register / Compliance / Inductions) plus a nested drill-down path (`ContractorList` → `ContractorProjectsSheet` → `SafetyFileSubmissionView` → `DocumentReviewDialog`) implementing contractor registration and per-project safety-file document review, including a real AI pre-screen integration. Only 1 top-level screen exists, per this doc's brief — kept short accordingly.

**In scope:** contractor register CRUD, per-project safety file submission review, document review with findings + AI pre-screen flagging.
**Out of scope:** QR passport issuance (owned entirely by `safety` — §6), the compliance/inductions tabs' own stated scope (both are placeholders, §4).
**IA placement:** Supply Chain Management compartment. See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `contractors` | Entry screen(s) |
|---|---|---|---|
| [Supply Chain & Facilities Manager](_shared_personas_and_bpfs.md#persona-scm-facilities-manager) (primary) | Contractor register + safety file review | `ContractorManagementScreen` → `ContractorList` → `ContractorProjectsSheet` → `SafetyFileSubmissionView` → `DocumentReviewDialog` | Reachable, but not from its own launchpad tile — see below |
| External Contractor/Vendor (secondary) | "Upload Compliance Docs/Safety File" per [shared doc](_shared_personas_and_bpfs.md#persona-external-contractor) | No code hook found in this module — no contractor-facing upload UI exists here (consistent with that persona's `public`-module framing in the shared doc, not this internal-facing module) | — |
| Security/Gate Access Personnel (secondary) | QR passport verification | **No code relationship** — see §6 | — |

**Reachability:** `business_os_launchpad.dart`'s "Contractors" tile points at `route: '/contractors'`, which **does not exist anywhere in `router.dart`** (confirmed by full-file read) — the same defect pattern as `equipment.md`'s `/equipment` tile. Unlike `equipment`, however, `ContractorManagementScreen` is **not** an orphan: it's correctly constructed via `UIUtils.showSideSheet` from `lib/features/projects/screens/project_details_screen.dart` and `lib/features/projects/widgets/project_tabs/contractor_card.dart` (2 call sites), and via a module-card tap in `lib/features/operations/widgets/operations_hub_modules.dart`. So the module is reachable in practice, just not from the tile that specifically advertises it.

## 3. BPF Participation
| BPF | Stage(s) this module implements (narrative) | Code reference |
|---|---|---|
| [Procure to Pay](_shared_personas_and_bpfs.md#bpf-procure-to-pay) | Named in the BPF's "Modules" list | `procure_to_pay_bpf.dart` stages are all `expectedRecordType: 'purchase_order'`/`'invoice'` — no reference to `contractors` |
| [Project Concept to Close](_shared_personas_and_bpfs.md#bpf-project-concept-to-close) — Safety File & Resource Audit subprocess | Review Contractor Profile → Send Safety File Request → Receive & Review → Approve → Issue QR Passport | `project_lifecycle_bpf.dart`'s `planning` stage description literally reads *"Resource Allocation and SHEQ Safety File Request"* — the closest **textual** match to this module's actual function of any BPF stage checked in this session — but `expectedRecordType` remains `'project'`, never `'contractor'`, and no orchestrator method references this module (confirmed, per the [shared doc](_shared_personas_and_bpfs.md#business-process-flows-bpfs), Project Concept to Close has zero orchestrator wiring at all) |

`BpfRibbonWidget`/`BpfOrchestrator`: confirmed **absent** from `lib/features/contractors/` (grep, zero matches). The "Receive & Review" step of the narrative subprocess is the one part that's genuinely well-implemented in code (`SafetyFileSubmissionView`/`DocumentReviewDialog`, §5) — but as plain feature code, not as BPF-tracked stages.

## 4. Screens & UI Elements Inventory
`ContractorManagementScreen`'s 3 tabs:
| Tab | Widget | Wiring |
|---|---|---|
| Register | `ContractorList` + `AddContractorForm` | Real, reachable, defensive create form (§7) |
| Compliance | `ContractorComplianceCard` | **Fully static placeholder** — icon + "Insurance certificates, tax clearance, safety files" caption, no query, no data — despite the real thing (`SafetyFileSubmissionView`) existing and working one tap further into `ContractorList` → `ContractorProjectsSheet` |
| Inductions | inline `_inductionsTab()` | **Fully static placeholder** — "Site induction completion tracking per contractor" caption, no query, no data |

Both placeholder tabs are AGENTS.md §3 banned-stub violations, the same pattern found in every other module this session (`supply_chain`'s hub cards, `equipment`'s Maintenance tab, `property`'s fake incident panel). The `highlightId` deep-link handler is at least honest about its own gap: it shows `UIUtils.showSideSheet` with the literal text *"(Detail view not yet implemented)"* rather than pretending.

`ContractorProjectsSheet` (opened by tapping a contractor in the Register tab) drills into `SafetyFileSubmissionView` (real: streams `safety_file_submissions` + `contractor_documents`, shows `AiPreScreenBadge` per document, "Download Report" calls Cloud Function `generateSafetyFileReport`, unconfirmed to exist — not found in either Functions codebase by grep) and `DocumentReviewDialog` (real write path, §5).

## 5. Backend & Database

**Models:** `Finding`/`SafetyFileSubmission`/`ContractorDocument` (`models/safety_file_models.dart`) → `findings`/`safety_file_submissions`/`contractor_documents`; `CompliancePreScreenResult`/`ComplianceFlag` (`models/compliance_prescreen_models.dart`) → `compliance_prescreens`. `contractors` itself has no dedicated model class — `AddContractorForm`/`ContractorList` both work off raw `Map<String, dynamic>`.

**Firestore rules check — clean:** all 6 collections this module's code actually touches (`contractors`, `contractor_documents`, `compliance_prescreens`, `findings`, `safety_file_submissions`) are explicitly declared in `firestore.rules` with correct snake_case naming, no drift. (`contractor_safety_files` is also declared but used only by `safety/services/passport_compliance_checker.dart`, not by this module.)

**Three separate, verified naming/logic bugs, none of them rules issues — all in the app's own code:**
1. `AddContractorForm._submit()` writes the contact-person foreign key as `'contactPersonId'`; `ContractorList`'s card subtitle reads `d['contactPerson']` (no `Id` suffix) — a key that is never written. Every contractor's subtitle silently renders an empty contact-person segment.
2. `AddContractorForm` writes `status`/`complianceStatus` as `.toLowerCase()` (e.g. `'active'`), but `ContractorManagementScreen`'s status filter dropdown offers capitalized values (`'Active'`/`'Inactive'`/`'Suspended'`), and `ContractorList` filters via `data['status'] == widget.statusFilter` — a case-sensitive equality that can **never** match. Selecting any specific status filter always returns zero results, regardless of how many contractors actually have that status. (`riskRating` has no such mismatch — written and read with matching case.)
3. `ContractorProjectsSheet._fetchProjectsForContractor()` queries `.tenantCollection(..., 'safetyFileSubmissions')` (camelCase) — but the real collection, correctly used by `SafetyFileSubmissionView` one screen later and correctly declared in `firestore.rules`, is `safety_file_submissions` (snake_case). Nothing ever writes to `safetyFileSubmissions`, so this query always returns empty — every project card in `ContractorProjectsSheet` permanently shows "Not Submitted" / 0 "OHS Approved" even when real, approved submissions exist and are visible one tap further in.

**AI pre-screen integration (`services/ai_compliance_service.dart`), checked precisely per this doc's brief:** `AiComplianceService.triggerPreScreen()` calls `httpsCallable('preScreenComplianceDocument')`, and this function **does exist** — `functions/src/prescreen_compliance.ts` (the thin/legacy codebase), exported from that codebase's `index.ts`. But `triggerPreScreen` itself has **zero callers anywhere** (confirmed by grep) — only the read side (`AiPreScreenBadge` streaming any pre-existing `compliance_prescreens` result) is wired into the UI; nothing in this module ever triggers a *new* pre-screen.

**Findings pipeline is write-only:** `DocumentReviewDialog._submitReview()` really does write to `findings` (matching the rules-declared collection) — but omits the `Finding` model's own `requirementId`/`siteId` fields entirely (both `required` on the model, defensively defaulted to `0`/`''` by `fromFirestore`). More importantly: `FindingListItem` and `FindingUpdateDialog` — real, well-built list-display and status-update widgets for exactly this `findings` data — have **zero callers anywhere in the app** (confirmed by grep). A finding can be created via `DocumentReviewDialog` but never subsequently viewed or updated through any screen.

## 6. Cross-Module Links
- `ContractorQrPassportScreen` (the "Issue QR Passport" step of the narrative subprocess, per this doc's brief) exists at `lib/features/safety/screens/contractor_qr_passport_screen.dart` — entirely under `safety`, with **zero references to or from `lib/features/contractors/`** (confirmed by grep both directions). The subprocess's first four steps have real, working code in this module; the fifth (QR passport) is a completely separate, unconnected implementation elsewhere.
- `ContractorManagementScreen` is correctly consumed by `projects` (twice) and `operations` (once) via proper `UIUtils.showSideSheet`/module-card patterns — see §2.
- **AppEventBus:** zero usage anywhere in `lib/features/contractors/` (confirmed by grep).

## 7. Known Gaps

### Rules-vs-code gaps
- None — see §5. The one broken query (`safetyFileSubmissions`) is a code-level naming bug, not a rules gap.
- `BaseIncident`: checked directly per this doc's brief. `Finding` (majorNc/minorNc/observation/commendation) is a document-audit finding, not an incident report — structurally closer to a non-conformance record than to `safety`'s incident concept. `BaseIncident`'s absence (see [shared doc](_shared_personas_and_bpfs.md#related-rules-vs-code-gap-applicable-wherever-relevant-below)) is not a clear-cut gap for this specific model.

### DB-to-UI alignment audit
`add_contractor_form.dart` (the module's only create form) vs. the raw map it writes — no dedicated `Contractor` model exists to diff against, so audited against its own field choices:
| Field | Status | Note |
|---|---|---|
| `contactPersonId` | Correct widget, broken downstream | Uses `EmployeeSelector` correctly — the bug is in `ContractorList`'s read side, not this form (§5) |
| `riskRating`, `status`, `complianceStatus` | Correct widgets | All 3 are dropdowns with sensible fixed option sets; the `status`/`complianceStatus` bug (§5) is a case-mismatch with the *reader*, not a form defect |
| `contractStart` / `contractEnd` | Correct | Real `showDatePicker` for both |

### Other
- Two of the screen's three tabs (Compliance, Inductions) are static placeholders (§4).
- Three independent naming/case-sensitivity bugs, all fully verified (§5): broken contact-person display, a permanently-inert status filter, and a camelCase/snake_case collection typo that hides real, existing safety-file submissions from the project-summary view.
- AI pre-screen trigger path (`triggerPreScreen`) is unreachable; only the display side works.
- `Finding`/`FindingListItem`/`FindingUpdateDialog` form a write-only pipeline — created findings are never displayed or updatable anywhere.
- Launchpad's "Contractors" tile points at a nonexistent route (`/contractors`), though the module remains reachable via `projects`/`operations` (§2).
- **IA/taxonomy conflict**: see [shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Should `ContractorList`'s display read `contactPersonId` (and resolve it through `EmployeeSelector`'s underlying employee lookup for a name) instead of the never-written `contactPerson`?
- Should the status filter dropdown's values be lowercased before comparison, or should the write side stop lowercasing — either fixes the permanently-broken filter?
- Should `ContractorProjectsSheet`'s `safetyFileSubmissions` query simply be corrected to `safety_file_submissions`, given the correctly-named collection and its rules declaration already exist?
- Should `FindingListItem`/`FindingUpdateDialog` be wired into `SafetyFileSubmissionView` (e.g. as a findings list per document, alongside the existing "Review" button), given both widgets are already built and only need a call site?
- Is a code-level link between this module and `ContractorQrPassportScreen` planned, given the narrative subprocess treats QR passport issuance as its final step?
