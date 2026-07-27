# compliance — Module Journey Doc

**Path:** `lib/features/compliance/`  |  **Compartment:** Human Resources  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`compliance` is a regulatory document register: licenses/certificates/permits/policies/procedures/audits with owner, expiry, and review-date tracking, plus a static reference list of applicable South African/ISO legal frameworks. It is small (6 files, 1 screen, 3 tabs) — and, per §4/§7 below, is the **least reachable module in this entire 6-module batch**: its one screen is never instantiated anywhere in the app.

**In scope:** regulatory/compliance document registration and register, expiry tracking, a static legal-framework reference list.
**Out of scope:** AI-driven contractor "compliance pre-screening" — despite the name overlap, that is an entirely separate concept living in the `contractors` module (`ai_compliance_service.dart`, `compliance_prescreens` collection) — see §6.
**IA placement:** Human Resources compartment (8-compartment taxonomy), though its primary persona (QC & Compliance Manager) is arguably cross-cutting rather than HR-specific — see [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `compliance` | Entry screen(s) |
|---|---|---|---|
| [QC & Compliance Manager](_shared_personas_and_bpfs.md#persona-qc-compliance-manager) | Quality Assurance | Track ISO Certifications, licenses, permits; monitor expiries | `register_tab.dart` + `register_doc_form.dart`, `expiring_tab.dart` |
| [HR & Safety Officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer) | Safety Compliance | Register Compliance Document | `register_doc_form.dart` |

Both journeys are theoretical in the sense that neither has a confirmed way to reach the screen in the running app — see §4.

## 3. BPF Participation
`compliance` is named in the [Hire to Retire](_shared_personas_and_bpfs.md#bpf-hire-to-retire) persona narrative's module list, but has no dedicated stage or `expectedRecordType` in `lib/core/bpf/hire_to_retire_bpf.dart`'s actual 4 stages (all `expectedRecordType: 'employee'`). No `BpfRibbonWidget` usage was found anywhere in `lib/features/compliance/` (confirmed by direct search) — narrative participation only, per the shared doc's caveat.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route or side-sheet | Purpose |
|---|---|---|
| `compliance_docs_screen.dart` | **none found anywhere** | 3-tab shell: Register / Expiring / Framework |
| `register_tab.dart` + `register_doc_form.dart` + `doc_list_item.dart` | tab | Document register list + create form |
| `expiring_tab.dart` | tab | Documents expiring within 90 days |
| `legal_tab.dart` | tab | Static list of 9 SA/ISO legal & standards references (OHS Act, COIDA, GSR, NEMA, ISO 45001/14001/9001, etc.) |

**This module has no confirmed entry point in the running app.** Unlike this batch's other five modules, `ComplianceDocsScreen` is never instantiated anywhere in `lib/` outside its own class declaration (confirmed by repo-wide search — no route, no side-sheet call, no tab reference). Compounding this: `business_os_launchpad.dart`'s "Compliance" tile calls `context.go('/compliance')`, but `router.dart` defines no `/compliance` route — the launchpad tile that would be the obvious way to reach this module instead hits the app's `errorBuilder` "Page Not Found" screen (same broken-tile pattern documented in `training.md` for the "Training" tile, except `training` at least has a working secondary entry point via the People Hub; `compliance` has none found at all).

## 5. Backend & Database

**Models:** none — no `models/` directory, no shared `core/models/` class. All three tabs work with raw `Map<String, dynamic>`.

**Collection name mismatch (confirmed bug, same pattern as `health.md`'s `first_aid_log`/`first_aid_logs` finding):**
- `register_doc_form.dart` writes to **`compliance_documents`**.
- `register_tab.dart` and `expiring_tab.dart` both read from **`compliance_docs`**.

These are two different Firestore collections. Every document registered through this module's own form is invisible in both of this module's own list tabs.

**Stale computed field:** `register_doc_form.dart` computes `daysUntilExpiry` once, at write time (`_expiry.difference(DateTime.now()).inDays`), and stores it as a static integer rather than deriving it at read time from `expiryDate`. `expiring_tab.dart` then filters/sorts directly on this stored, never-updated value (`.where('daysUntilExpiry', isLessThanOrEqualTo: 90).orderBy('daysUntilExpiry')`). A document registered today with a 1-year expiry stores `daysUntilExpiry: 365` permanently — that number does not count down as real time passes, so both the "Expiring" tab's filter and `doc_list_item.dart`'s "`{days}d`" badge silently drift out of sync with the document's actual `expiryDate` the longer the record exists.

**Firestore rules cross-check:** neither `compliance_docs` nor `compliance_documents` is declared in `firestore.rules` (confirmed absent from the full 238-line file — the only rules-declared collection with "compliance" in its name is the unrelated `compliance_prescreens`, see §6). Both names fall through to the catch-all `allow write: if false` — same pattern as `safety.md`/`health.md`/`training.md`/`workers_comp.md`. Moot in production either way, given the collection-name mismatch above already breaks the read/write pairing at the application level.

**Cloud Functions:** none found in either `firebase/functions/src/` or `functions/src/` that reference `compliance_docs` or `compliance_documents`.

## 6. Cross-Module Links
- **Naming collision, not a real link:** `functions/src/prescreen_compliance` (exported from `functions/src/index.ts`, the thin/legacy Functions codebase per the shared doc) and the `compliance_prescreens` collection it presumably backs are used exclusively by `lib/features/contractors/services/ai_compliance_service.dart` — an AI-driven contractor safety-file pre-screening feature that is conceptually unrelated to this module's regulatory document register, despite the shared "compliance" name. `compliance_docs_screen.dart` has no reference to `compliance_prescreens` anywhere.
- No cross-module reader of `compliance_docs`/`compliance_documents` was found anywhere else in `lib/` (contrast `health.md`'s `medical_records` and `workers_comp.md`'s `coida_claims`, both of which are read by `people_hub_screen.dart` for KPI counts — this module has no equivalent).
- No `AppEventBus` emit or listen usage found anywhere in this module.

## 7. Known Gaps

### Rules-vs-code gaps
- Catch-all rule denies all writes to `compliance_docs`/`compliance_documents` — see §5.
- Launchpad "Compliance" tile points at a nonexistent `/compliance` route — see §4.

### DB-to-UI alignment audit
`register_doc_form.dart` (write) vs. `register_tab.dart`/`expiring_tab.dart`/`doc_list_item.dart` (read):
| Field | Status | Note |
|---|---|---|
| collection itself | **Mismatch** | Form writes `compliance_documents`; both read tabs query `compliance_docs`. Supersedes any field-level comparison — nothing written is ever visible. |
| `ownerId` | Correct (lookup) | Uses `EmployeeSelector`, unlike `workers_comp.md`'s free-text finding |
| `title`, `referenceNumber`, `documentType`, `status`, `expiryDate`, `reviewDate` | Correct (field names match what `doc_list_item.dart` reads) | Would work if the collection name were fixed |
| `daysUntilExpiry` | **Stale on write** | Computed once at creation, never refreshed — see §5 |

### Other
- **Fully unreachable module**: no route, no side-sheet caller, nothing — see §4. Of the six modules in this batch, this is the only one where the primary screen itself (not just a sub-screen like `safety.md`'s orphan QR passport screens) has zero confirmed entry point.
- **Dead external-link affordance**: `legal_tab.dart`'s 9 framework cards each render a trailing `Icons.open_in_new_rounded`, implying a tap-through to the actual regulation text, but no `onTap`/URL-launch handler exists on the `GCard` — purely decorative.
- IA/taxonomy conflict: see [_shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Is `ComplianceDocsScreen` mid-build (i.e. intentionally not yet wired into navigation), or a completed feature that lost its entry point during a refactor? Given the form, three tabs, and list rendering are all fully implemented and internally polished, this reads more like the latter.
- Is `compliance_docs` or `compliance_documents` the "correct" intended collection name? Given the read side (2 files) outnumbers the write side (1 file), `compliance_docs` looks like the more likely intended name, making `register_doc_form.dart` the file to fix.
- Should this module's regulatory-document concept and `contractors`' AI compliance-prescreening feature be renamed to reduce the "compliance" naming collision, given they share no code, data, or screens?
- Should `daysUntilExpiry` be dropped in favor of computing remaining days from `expiryDate` at query/render time, the way `safety.md`'s `ppe_compliance_screen.dart` does for its own expiry countdown?
