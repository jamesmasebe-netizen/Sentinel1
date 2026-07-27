# training — Module Journey Doc

**Path:** `lib/features/training/`  |  **Compartment:** Human Resources  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`training` is Sentinel1's Training & Competency module: an LMS-style course catalog with a video-player-style course experience, a self-paced "My Learning" enrollment tracker, a compliance-oriented training/certification records register with expiry alerts, Toolbox Talks logging, and a manager-facing course-allocation dashboard. It is a small module (13 files) but — per the DB-to-UI audit in §7 — has the highest concentration of concrete, verifiable data-plumbing bugs found in this batch of six.

**In scope:** LMS course catalog + player, personal course enrollment/progress tracking, mandatory-course allocation by managers, training/certification records with expiry tracking, Toolbox Talks logging.
**Out of scope:** the actual safety content of a toolbox talk or course (owned conceptually by `safety`/`compliance`), workers' comp-adjacent return-to-work training (owned by `workers_comp`).
**IA placement:** Human Resources compartment (8-compartment taxonomy). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `training` | Entry screen(s) |
|---|---|---|---|
| [HR & Safety Officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer) | Talent Acquisition & Onboarding | Allocate Mandatory Course | `manager_training_dashboard.dart` + `allocate_course_form.dart` |
| [HR & Safety Officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer) | Safety Compliance | Host Toolbox Talk | `toolbox_talks_tab.dart` + `talk_form_sheet.dart` |
| [Employee (Self-Service)](_shared_personas_and_bpfs.md#persona-employee-self-service) | Daily Operations | Sign off on Toolbox Talk (as attendee); self-paced learning | `my_learning_tab.dart`, `course_catalog_tab.dart`, `course_player_screen.dart` |
| [QC & Compliance Manager](_shared_personas_and_bpfs.md#persona-qc-compliance-manager) | Quality Assurance | Link findings to Employee Training records (via `training_records`/expiry tracking) | `training_records_tab.dart` + `record_form_sheet.dart`, `expiry_alerts_tab.dart` |

## 3. BPF Participation
`training` is named in the [Hire to Retire](_shared_personas_and_bpfs.md#bpf-hire-to-retire) persona narrative ("Baseline Medical **& Training Allocation**"), but has no dedicated stage or `expectedRecordType` in `lib/core/bpf/hire_to_retire_bpf.dart`'s actual 4 stages (all `expectedRecordType: 'employee'`). No `BpfRibbonWidget` usage was found anywhere in `lib/features/training/` (confirmed by direct search) — narrative participation only, per the shared doc's caveat.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route or side-sheet | Purpose |
|---|---|---|
| `training_screen.dart` | **no dedicated route** — reachable via side-sheet from `people/screens/employee_hub_screen.dart` and `people/widgets/people_hub/people_hub_modules_grid.dart` | 6-tab shell: My Learning / Course Catalog / Records / Toolbox Talks / Expiry Alerts / Manager Hub |
| `my_learning_tab.dart` | tab | Personal enrollment list + progress bars, taps into `course_player_screen.dart` |
| `course_catalog_tab.dart` | tab | Course grid, "Start Course" → `course_player_screen.dart` |
| `course_player_screen.dart` | `Navigator.push` (from both tabs above) | Video-placeholder player + "Mark Complete" |
| `training_records_tab.dart` + `record_form_sheet.dart` | tab | Certification/training record register + create form |
| `toolbox_talks_tab.dart` + `talk_form_sheet.dart` | tab | Toolbox talk log + create form (topic, attendees, location) |
| `expiry_alerts_tab.dart` | tab | Derived view: `training_records` where status Active and expiring ≤60 days |
| `manager_training_dashboard.dart` + `allocate_course_form.dart` | tab | Manager view of allocated courses + allocation form |

**Broken Launchpad tile (confirmed):** `business_os_launchpad.dart`'s "Training" tile calls `context.go('/training')`, but `router.dart` defines no `/training` route — clicking it from the main Launchpad hits the app's `errorBuilder` "Page Not Found" screen. The module is only reachable via the People Hub's side-sheet entry points listed above.

## 5. Backend & Database

**Models:** `models/course.dart` (`Course` — id/title/description/thumbnailUrl/instructorId/category/contentUrl/durationMinutes) and `models/enrollment.dart` (`Enrollment` — id/courseId/employeeId/progressPercentage/status/enrollmentDate), both with `fromMap`/`toMap`. These are the only two model classes in the module — `training_records`, `training_enrollments`, and `toolbox_talks` are all handled as raw `Map<String, dynamic>`.

**Collections — four different ones, not obviously reconciled:**
| Collection | Written by | Read by |
|---|---|---|
| `courses` | (seed-only, see below) | `coursesProvider` (`training_providers.dart`) → `course_catalog_tab.dart`, `my_learning_tab.dart` |
| `enrollments` | `course_player_screen.dart` (`_markComplete()`) | `enrollmentsProvider` (`training_providers.dart`) → `my_learning_tab.dart` |
| `training_records` | `record_form_sheet.dart` | `training_records_tab.dart`, `expiry_alerts_tab.dart`, and (cross-module) `safety`'s `passport_compliance_checker.dart`/`qr_scanner_screen.dart` |
| `training_enrollments` | `allocate_course_form.dart` | `manager_training_dashboard.dart` |
| `toolbox_talks` | `talk_form_sheet.dart` | `toolbox_talks_tab.dart` |

**Critical bug — `coursesProvider`/`enrollmentsProvider` are hardcoded to a phantom empty-string tenant.** `providers/training_providers.dart`:
```dart
firestore.tenantCollection("", 'courses')       // literal "" — not ref.watch(currentTenantIdProvider)
firestore.tenantCollection("", 'enrollments')    // same
```
Every other stream in this module (and in the other 5 modules audited in this batch) correctly does `ref.watch(currentTenantIdProvider) ?? ""`, falling back to `""` only if no tenant is resolved yet. Here the empty string is hardcoded unconditionally, so `CourseCatalogTab` and the course-listing half of `MyLearningTab` always query `tenants/""/courses` and `tenants/""/enrollments` — a path with no relationship to the signed-in user's real tenant. Two compounding consequences:
1. **Firestore rules would deny even reads.** `belongsToTenant(tenantId)` requires `request.auth.token.tenantId == tenantId`; for any real user, their token's `tenantId` claim is never the literal empty string, so `belongsToTenant("")` is false and the read itself is denied — not just the write.
2. **The seed function makes it look like it's working in a dev/emulator context where rules aren't enforced.** `coursesProvider` calls `_seedDummyCourses()` whenever the (phantom-path) snapshot comes back empty, writing 3 hardcoded dummy courses (`'Safety Basics 101'`, etc.) straight into `tenants/""/courses`. This is itself a AGENTS.md §2/§3 violation ("No Hardcoded Data" / "Banned Stubs") independent of the tenant-scoping bug — the course catalog's fallback behavior on empty data is to fabricate business content, not show an empty state.
- Separately, `course_player_screen.dart`'s own writes to `enrollments` **do** correctly use `ref.watch(currentTenantIdProvider) ?? ""` — so completions are written to the *real* tenant path but can never be read back by `MyLearningTab`, since the read half is pinned to the phantom `""` tenant. Read and write paths for the same collection literally diverge.

**Firestore rules cross-check:** only `training_records` is explicitly declared in `firestore.rules` (managers/SHEQ officers can write). `courses`, `enrollments`, `training_enrollments`, and `toolbox_talks` are all absent from the rules file and fall through to the catch-all `allow write: if false` — same pattern documented in `safety.md`/`health.md`. Combined with the tenant-scoping bug above, the LMS half of this module (`courses`/`enrollments`) is broken two independent ways.

**Cloud Functions:** `checkTrainingExpiry` (`firebase/functions/src/index.ts`, daily 08:00 SAST) queries a **flat, top-level** `db.collection("training_records")` — not `tenants/{tenantId}/training_records`, which is where `record_form_sheet.dart` actually writes (via `tenantCollection()`). Same path-mismatch pattern as `safety.md`'s `onIncidentCreated`/`checkPermitExpiry` finding — as written, this function would never see documents created through this module's own form. It also filters on `notificationSent != true`, a field `record_form_sheet.dart` never sets (harmless given the path mismatch already makes the query moot, but worth noting as a second, independent reason it wouldn't match real data even if the path were fixed). Source ambiguity: which Functions codebase (`firebase/functions/src/` vs `functions/src/`) is actually deployed is unclear since `firebase.json` declares no `functions` key (see shared doc).

## 6. Cross-Module Links
- `safety`'s `passport_compliance_checker.dart` and `qr_scanner_screen.dart` both read this module's `training_records` collection directly (filtering `type == 'medical_certificate'` / `type == 'induction'`, and checking expiry generally) — see `safety.md` §6 and `health.md` §3 for the related finding that this is a *different* collection than `health`'s own medical records.
- `EmployeeSelector` and `SearchableStringMultiSelect` + `employeesProvider` (all from `people`) are reused across `record_form_sheet.dart`, `talk_form_sheet.dart`, `allocate_course_form.dart`.
- No `AppEventBus` emit or listen usage found anywhere in `lib/features/training/` (confirmed by direct search).

## 7. Known Gaps

### Rules-vs-code gaps
- Catch-all rule denies writes to `courses`, `enrollments`, `training_enrollments`, `toolbox_talks` — see §5.
- `business_os_launchpad.dart`'s "Training" tile points at a route (`/training`) that does not exist in `router.dart` — see §4.

### DB-to-UI alignment audit
Adapted per module size: comparing each create form's write payload against the field names its paired read-side view actually consumes (same spirit as the standard model-vs-form methodology; there is no dedicated model for `training_records`/`training_enrollments`/`toolbox_talks` to audit against — see §5).

| Form → collection | Read side | Status | Note |
|---|---|---|---|
| `record_form_sheet.dart` → `training_records` | `training_records_tab.dart`, `expiry_alerts_tab.dart` read `d['employeeName']` | **Missing on write** | Form only writes `employeeId`; `employeeName` is never set. Every record/expiry-alert card shows "Unknown Employee" or blank, regardless of who was selected. Same bug pattern as `health.md`'s `medical_form.dart` finding. |
| `allocate_course_form.dart` → `training_enrollments` | `manager_training_dashboard.dart` reads `d['employeeName']` | **Missing on write** | Same bug, third occurrence in this small batch. |
| `allocate_course_form.dart` → `training_enrollments` | `manager_training_dashboard.dart` queries `.orderBy('assignedAt', descending: true)` | **Missing on write** | The form never sets an `assignedAt` field (it sets `enrollmentDate` instead). Firestore's `orderBy` excludes documents that lack the ordered field entirely — so **every course allocated through this form is invisible on the Manager Hub tab that is supposed to list allocations**, independent of the rules-catch-all issue above. |
| `talk_form_sheet.dart` → `toolbox_talks` | `toolbox_talks_tab.dart` reads `topic`/`date`/`location`/`attendees` | Correct | This pairing is internally consistent — the one clean read/write match found in this module. |

### Other
- **Three-way collection split for "enrollment"**: `enrollments` (LMS player completions), `training_enrollments` (manager allocations), and `training_records` (compliance certifications) are three separate, mutually-unaware collections all representing some flavor of "an employee is/was assigned to/completed something." None of them reference each other. A manager allocating a course via `allocate_course_form.dart` has no way of knowing whether that same employee already completed it via `course_player_screen.dart`, since those two flows never touch the same collection.
- IA/taxonomy conflict: see [_shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Was `tenantCollection("", 'courses')` / `tenantCollection("", 'enrollments')` meant to read `ref.watch(currentTenantIdProvider)` like every other provider in this codebase, and simply never updated after being scaffolded? Given the identical correct pattern appears dozens of times elsewhere in this same file's sibling modules, this looks like the most likely single highest-value bug fix in this entire 6-module batch.
- Should `courses`/`enrollments`/`training_enrollments`/`training_records` be consolidated, or is a 3-way split (LMS content, manager assignment, compliance record) an intentional design that just needs cross-references added?
- Should `_seedDummyCourses()` be removed now that real course content presumably exists, per AGENTS.md §3's ban on placeholder business data?
- Should the Launchpad's "Training" tile be pointed at the People Hub's side-sheet (or a new `/training` route added), given the module is fully built but only reachable through a secondary entry point?
