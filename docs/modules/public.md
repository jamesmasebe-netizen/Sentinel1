# public — Module Journey Doc

**Path:** `lib/features/public/`  |  **Compartment:** System Administration  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`public` holds a two-file public-careers mini-flow: `PublicCareersScreen` (job listing) and `JobApplicationForm` (application submission side-sheet). Despite the name, **verification shows nothing in this module is actually reachable pre-authentication, or in fact reachable at all** — see §5 for the full chain. A near-duplicate screen, `PublicCareersPortal`, exists in `lib/features/people/screens/public_careers_portal.dart` — a genuinely different file, not a re-export or alias of this module's screen (confirmed: different class, different file, both import `app_providers.dart`/`tenant_firestore_extension.dart` independently). That file belongs to `people.md`, not this doc; noted here only for the duplication finding in §6.

**In scope:** `PublicCareersScreen`, `JobApplicationForm`.
**Out of scope:** `PublicCareersPortal` (`people` module — a separate, not-fully-audited-here file, see §6).
**IA placement:** System Administration compartment per the module assignment. Worth flagging directly: the shared doc's own [HR & Safety Officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer) journey text names this exact concept — *"Review Job Application (**Public**)"* as the first step of *Talent Acquisition & Onboarding* — not the External Contractor/Vendor persona this module is assigned to here. The module's actual content (public job applications) maps more naturally to HR's journey text than to Contractor/Vendor's ("Site Access & Compliance," which never mentions careers/applications). Stated plainly rather than smoothed over, matching this doc set's convention of surfacing persona-text mismatches (see `billing.md` for the same pattern).

## 2. User Journeys
| Persona | Journey | Steps touching `public` | Entry screen(s) |
|---|---|---|---|
| [External Contractor/Vendor](_shared_personas_and_bpfs.md#persona-external-contractor) (primary, per module assignment) | Shared-doc journey text ("Site Access & Compliance") does not mention job applications — no direct textual hook | — | — |
| [Security/Gate Access Personnel](_shared_personas_and_bpfs.md#persona-security-gate-access) (secondary, per module assignment) | Shared-doc journey text ("Scan QR Code → Verify Compliance...") does not mention job applications either — no direct textual hook | — | — |
| *(Unassigned but textually closest)* [HR & Safety Officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer) | *Talent Acquisition & Onboarding*: "Review Job Application (Public) → Send Invite → ..." | A prospective hire would view postings and apply here, if reachable | `public_careers_screen.dart` |

Given §5's findings, this table is largely theoretical — no persona's journey through this module can currently complete end-to-end.

## 3. BPF Participation
None. `public` is explicitly listed in the [shared doc's](_shared_personas_and_bpfs.md#business-process-flows-bpfs) "Modules with zero BPF participation, narratively or in code." Worth noting: [Hire to Retire](_shared_personas_and_bpfs.md#bpf-hire-to-retire)'s own flow text opens with *"Job Application → Candidate Invite → ..."* — a direct narrative echo of this module's purpose — yet that BPF's "Modules" line (`people, training, health, workers_comp, compliance`) doesn't list `public` either, and `hire_to_retire_bpf.dart`'s code-level stages are confirmed (repo-wide grep) to carry zero reference to this module. Consistent with the shared doc's own finding pattern, not a new inconsistency introduced here.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route / reachability | Purpose / wiring |
|---|---|---|
| `screens/public_careers_screen.dart` (`PublicCareersScreen`) | **None — confirmed orphaned.** Zero references to `PublicCareersScreen` anywhere in `lib/` outside its own file (repo-wide grep); no `GoRoute`, no `BusinessOsLaunchpad` tile, no link from anywhere | Lists `job_requisitions` where `status == 'Published'`; "Apply Now" opens `JobApplicationForm` in a side-sheet (correct `UIUtils.showSideSheet` usage); an "Employee Login" button correctly calls `context.go('/login')` |
| `widgets/job_application_form.dart` (`JobApplicationForm`) | Only reachable from the screen above (itself unreachable) | Name/email/phone/resume-link form → writes to Firestore (see §5 for the exact, broken, path) |

## 5. Backend & Database

**No `models/`/`services/`/`providers/` subdirectory in this module** — both files query/write Firestore directly using raw `Map<String, dynamic>` literals; no Dart model class exists for either `job_requisitions` or `job_applications` anywhere in this module (an AGENTS.md §2 "Strict Schema Enforcement" gap).

**The full reachability chain — verified layer by layer, per the task's request to check this carefully:**

1. **Not routed.** Confirmed by repo-wide grep: `PublicCareersScreen` has no `GoRoute` in `router.dart` and no tile on `BusinessOsLaunchpad`. There is no way to navigate to it from inside the app.
2. **Even if routed, the router's redirect would block it anyway.** `router.dart`'s top-level `redirect` callback (see [auth.md §6](auth.md#6-cross-module-links)) is unconditional: `if (!isAuthenticated && !loggingIn) return '/login';` with no exemption list. `/login` and `/lock` are the *only* two routes exempted from this check. Adding a route for this screen today, without also touching the redirect callback, would still bounce an unauthenticated visitor straight to `/login` before this screen ever rendered — the opposite of "public."
3. **Even past that, the screen can't determine which tenant's jobs to show for a true anonymous visitor.** `PublicCareersScreen` resolves its query target via `ref.watch(currentTenantIdProvider) ?? ""` — and `currentTenantIdProvider` (`app_providers.dart`) is derived entirely from an authenticated user's custom claims or Firestore `users/{uid}` profile (see [auth.md §5](auth.md#5-backend--database)). A genuine pre-auth visitor has neither, so this resolves to `null` → `""`. There is no tenant-slug URL parameter or public lookup mechanism anywhere in this module — multi-tenancy and "public, no-login page" are structurally in tension here, and the code never resolves it.
4. **Even with a tenant ID somehow known, `firestore.rules` would reject the read for anyone unauthenticated.** `job_requisitions` is not among the explicitly-declared collections in `firestore.rules` (confirmed — full list re-checked: employees, projects, incidents, permits, training_records, equipment, loto_events, work_orders, contractors, contractor_documents, compliance_prescreens, findings, bpf_instances, invoices, journal_entries, leads, opportunities, quotes, accounts, risk_assessments, hazards, purchase_orders, inventory, safety_file_submissions, contractor_safety_files — no match). It falls to the tenant-scoped catch-all (`firestore.rules:220-223`): `allow read: if belongsToTenant(tenantId);` — and `belongsToTenant()` requires `isAuthenticated()`, i.e. `request.auth != null`. An anonymous visitor's read would be denied by the deployed rules themselves, independent of every problem above.
5. **The one write this module performs is unconditionally blocked, for everyone.** `JobApplicationForm._submit()` writes to `.tenantCollection("", 'job_applications')` — note this is a **literal hardcoded empty string**, not even attempting `currentTenantIdProvider` (unlike the parent screen). `TenantFirestore.tenantCollection` (`lib/core/utils/tenant_firestore_extension.dart`) resolves this to the exact path `tenants/(empty)/job_applications` — a single, wrong, tenant-less bucket that every application from every "tenant's" careers page would collide into, if this path were ever reached. It never is: `job_applications` is likewise undeclared in `firestore.rules`, falling to the same catch-all's `allow write: if false` — **unconditional, for authenticated and unauthenticated users alike.** This is this module's one and only write path, and it is blocked at the rules layer regardless of anything else being fixed.

Net finding: this module is blocked at every layer simultaneously — routing, the auth redirect, tenant resolution, the rules-level read, and the rules-level write. Fixing any one layer alone would not make it functional.

## 6. Cross-Module Links
- **`context.go('/login')`** ("Employee Login" button) is real, working navigation code — moot in practice since nothing reaches the screen it's on (§5).
- **`lib/features/people/screens/public_careers_portal.dart`** (`PublicCareersPortal`) is a structurally similar screen — job listing + inline application form, same `app_providers.dart`/`tenant_firestore_extension.dart` imports — confirmed via grep to be **equally unreferenced anywhere outside its own file**. Full audit of that file's internals belongs to `people.md`, not here, but its existence means the codebase has **two** independently-built, both-orphaned "public careers" screens rather than one.
- **`firestore.rules`** — see [auth.md §5](auth.md#5-backend--database) for the custom-claims finding this module's tenant resolution also depends on.
- **AppEventBus:** zero usage anywhere in `lib/features/public/` (confirmed by grep) — no event fires when an application is submitted (moot, since the write itself is rules-blocked).

## 7. Known Gaps

### Rules-vs-code gaps
- `job_requisitions` (read) and `job_applications` (write) are both undeclared in `firestore.rules`, falling to the tenant-scoped catch-all — the read requires auth (defeating "public"), and the write is unconditionally denied for everyone (§5, point 5). This is a more severe version of the pattern `emergency.md`/`billing.md` both flagged elsewhere: there, at least an authenticated user's writes were blocked; here, the write is blocked for every possible caller, authenticated or not.
- `BaseIncident` — not applicable, no incident concept in this module.

### DB-to-UI alignment audit
No Dart model exists for `JobRequisition` or `JobApplication` within this module (§5), so the standard model-vs-form diff doesn't directly apply. Auditing `JobApplicationForm`'s own field choices instead: `applicantName`/`email`/`phone` are plain text fields (reasonable); **`resumeLink` is a free-text URL field with no format validation beyond "required"** — no actual file upload despite `firebase_storage` being a used dependency elsewhere in the app (per `ANALYSIS.md`'s tech list) — a plausible **Missing** (file-upload widget) against what a "job application" conceptually needs, though this may be a deliberate scope choice rather than an oversight.

### Other
- **Nothing in this module is reachable, pre-authentication or otherwise** — the full 5-layer chain in §5 is this module's headline finding.
- **Hardcoded empty-string tenant ID in the one real write path** (`JobApplicationForm._submit()`) — even more directly broken than the parent screen's `?? ""` fallback, since it doesn't attempt tenant resolution at all.
- **Duplicate, equally-orphaned implementation in `people`** (§6) — two unconnected builds of the same idea.

## 8. Open Questions
- Was a public, tenant-scoped careers URL scheme (e.g., `/careers/:tenantSlug`) ever planned? Nothing in `router.dart` or either careers screen suggests a slug/lookup mechanism exists to solve §5's tenant-resolution problem.
- Should the router's `redirect` callback gain an explicit exemption list (like `/login`/`/lock`) for genuinely public routes, and should `job_requisitions`/`job_applications` be added to `firestore.rules` with unauthenticated-allowed rules, to make a public careers page possible at all?
- Should this module be merged with `people`'s `PublicCareersPortal` (§6) rather than maintained as two separate, both-broken implementations?
- Should this module's primary persona be HR & Safety Officer instead of External Contractor/Vendor, given the shared doc's own journey text names this exact concept under HR (§1)?
