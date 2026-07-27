# people — Module Journey Doc

**Path:** `lib/features/people/`  |  **Compartment:** Human Resources  |  **README.md exists:** yes (`lib/features/people/README.md` — brief agent-facing manifest; this doc is the fuller human-facing companion, not a replacement)
**Last verified against:** 2026-07-27

## 1. Product Understanding
`people` is Sentinel1's HR & identity module: employee profiles, org structure, leave, compensation/benefits, performance, recruitment, statutory OHS appointments, and payroll. It is the **central identity source** other modules link into — `EmployeeSelector` (this module's shared lookup widget) is used across the app wherever another module needs to reference a person (managers, permit approvers, project resource allocation, etc.).

**In scope:** employee lifecycle (recruit → onboard → develop → offboard), leave & payroll, performance reviews, OHS statutory appointments, competency/skills tracking.
**Out of scope:** safety incident/permit content itself (owned by `safety`), training course *delivery* content (owned by `training` — `people` only tracks allocation via `training_lms_tab.dart`).
**IA placement:** Human Resources compartment (8-compartment taxonomy). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved) for the unresolved 4-Hub/7-pillar/8-compartment conflict this doc set doesn't attempt to resolve.

## 2. User Journeys
| Persona | Journey | Steps touching `people` | Entry screen(s) |
|---|---|---|---|
| [HR & Safety Officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer) | Talent Acquisition & Onboarding | Review Job Application → Send Invite → Create Employee Profile → Generate Competency Passport | `public_careers_portal.dart`, `invite_users_screen.dart`, `recruitment_dashboard_screen.dart`, `job_requisitions_screen.dart`, `employee_profiles_screen.dart`, `competency_passport_screen.dart` |
| [Employee (Self-Service)](_shared_personas_and_bpfs.md#persona-employee-self-service) | Daily Operations | Submit Leave Request → View personal Competency Passport | `leave_management_screen.dart`, `leave_request_detail_screen.dart`, `competency_passport_screen.dart` |
| [Executive/C-Suite](_shared_personas_and_bpfs.md#persona-executive) | Strategic Oversight (partial) | Drill into OKR/performance data | `okr_dashboard_screen.dart`, `performance_review_screen.dart` |
| [IT/Systems Administrator](_shared_personas_and_bpfs.md#persona-it-systems-admin) | System Management (partial) | Manage user role permissions via invites | `invite_users_screen.dart` |

## 3. BPF Participation
| BPF | Stage(s) this module implements (narrative) | Code reference |
|---|---|---|
| [Hire to Retire](_shared_personas_and_bpfs.md#bpf-hire-to-retire) | Job Application → Candidate Invite → Employee Profile Creation → Leave/Payroll Tracking → Offboarding (termination) | `lib/core/bpf/hire_to_retire_bpf.dart` (4 generic stages: recruitment/onboarding/active/offboarding, `expectedRecordType: 'employee'`); termination step fires `EmployeeTerminatedEvent` from `employee_360_profile_screen.dart` |

**Implementation-depth correction** (see [_shared doc](_shared_personas_and_bpfs.md#business-process-flows-bpfs)): `BpfOrchestrator.completeOnboarding()` is a **stub** — its own code comment states *"In a real implementation we would update EmployeeProfile to 'Active' via HR service"* — it only advances the `bpf_instances` tracking record and does not actually update `EmployeeProfile.employmentStatus`. The recruitment/candidate-invite/leave-tracking stages of this journey are real (backed by `hr_service.dart`/`invite_service.dart`), but the BPF *stage-tracking* layer specifically doesn't reflect them.

No `BpfRibbonWidget` usage was found inside `lib/features/people/` itself — the Hire-to-Retire flow's stage transitions are not visually surfaced on People screens the way Lead-to-Cash's ribbon is surfaced in `crm` (see `crm.md`). **Gap**, logged below.

## 4. Screens & UI Elements Inventory
21 screen files exist (module inventory originally estimated 22).

| Screen | Route or side-sheet | Purpose |
|---|---|---|
| `people_hub_screen.dart` | side-sheet launcher only | HR module landing/dashboard grid |
| `hr_hub_screen.dart` | `/hr` | Secondary HR hub |
| `employee_hub_screen.dart` | `/people` | Employee-centric hub, launches side-sheets |
| `employee_profiles_screen.dart` | side-sheet | List/search all personnel |
| `employee_profile_detail_screen.dart` | side-sheet | Single employee detail |
| `employee_360_profile_screen.dart` | side-sheet | Deep-dive profile incl. terminate action |
| `employee_activity_tab.dart` | tab (in 360 profile) | Cross-module activity (incidents/PTW/HIRA) — **mocked, not wired to real queries** |
| `employee_hr_tab.dart` | tab (in 360 profile) | Leave/payroll/disciplinary — **mocked** |
| `competency_passport_screen.dart` | side-sheet | Competency/certification record |
| `skills_matrix_screen.dart` | side-sheet | Org-wide skills matrix |
| `training_lms_tab.dart` | tab | Training/LMS allocation records |
| `ohs_appointments_screen.dart` | side-sheet | List of statutory OHS appointees |
| `ohs_appointments_tab.dart` | tab | Tab variant of OHS appointments |
| `leave_management_screen.dart` | side-sheet | Leave requests list/approval |
| `leave_request_detail_screen.dart` | side-sheet | Single leave request detail |
| `performance_review_screen.dart` | side-sheet | Performance review cycles |
| `okr_dashboard_screen.dart` | `/okr-dashboard` | OKR dashboard |
| `payroll_dashboard_screen.dart` | side-sheet | Payroll ledger dashboard |
| `job_requisitions_screen.dart` | side-sheet | Open job requisitions |
| `recruitment_dashboard_screen.dart` | side-sheet | Recruitment/candidate pipeline |
| `public_careers_portal.dart` | side-sheet (or public-facing, unauthenticated — verify) | External-facing careers page |
| `invite_users_screen.dart` | side-sheet | Invite/onboard new users |

Only 3 of 21 screens have a top-level route (`/hr`, `/people`, `/okr-dashboard`); the other 18 are reachable only via `UIUtils.showSideSheet` from the hub/dashboard screens — consistent with AGENTS.md's navigation rule, but means this table doubles as the module's real site map since `router.dart` alone undersells its size.

## 5. Backend & Database

**Models — `lib/features/people/models/hr_models.dart`:**
| Model | Key fields | Collection |
|---|---|---|
| `EmployeeProfile` | firstName, lastName, preferredName?, workEmail, personalEmail, phoneNumber, hireDate?, terminationDate?, employmentStatus, positionId, departmentId, managerEmployeeId, missingMandatorySafetyTraining | `employees` |
| `LeaveRequest` | leaveTypeId, startDate, endDate, totalHoursRequested, status, approverId, reason, medicalCertificateUrl?, employeeId, managerId, siteId | `leave_requests` |
| `CompensationPlan` | name, type, eligibilityRules(map), targetPercentage, vestingScheduleId? | `compensation_plans` |
| `BenefitEnrollment` | planId, planType, coverageTier, status, effectiveDate?, dependentsCovered(list), employeeContribution, employerContribution | `employees/{id}/benefit_enrollments` (subcollection) |
| `PerformanceReview` | cycleId, managerId, selfEvaluation(map), managerEvaluation(map), peerFeedback(list), overallRating, status, employeeId, reviewPeriod, score | `performance_reviews` (+ mirrored under `employees/{id}/performance_reviews`) |
| `Candidate` | requisitionId, name, title, email, department, stage, resumeUrl, appliedDate | `candidates` |
| `JobRequisition` | title, department, description, status, postedDate, siteId | `job_requisitions` |
| `PayrollLedger` | employeeId, baseSalary, bonuses, deductions, periodStart, periodEnd, status, siteId (+computed netPay) | `payroll_ledgers` |
| `OHSAppointment` | appointeeId, statutoryReference, appointedDate, status, siteId | `ohs_appointments` |

Also: `models/invite_model.dart` → `InviteModel` (email, role, status, createdAt, tenantId) → `invites`.

**Firestore naming/rules check:** `firestore.rules` explicitly lists `employees` and generic tenant sub-paths, but does **not** explicitly enumerate `leave_requests`, `compensation_plans`, `performance_reviews`, `candidates`, `job_requisitions`, `payroll_ledgers`, `ohs_appointments`, or `invites` — they fall through to the catch-all `{collection}` rule instead of getting purpose-built RBAC (e.g. payroll/compensation data arguably deserves stricter, role-scoped rules than a generic catch-all). Logged as a gap below.

**Cloud Functions:** none in `people` specifically call a named Cloud Function directly (HR-adjacent scheduled functions like `accrueLeave`, `checkTrainingExpiry` live in `firebase/functions/src/hrEngine.ts` and are triggered independently, not called from this module's UI code).

**Providers:**
- `providers/employee_providers.dart` — `employeesCollectionProvider`, `employeesProvider` (StreamProvider<List<Employee>>), `employeeServiceProvider`
- `providers/hr_provider.dart` — `employeeDetailProvider(id)`, `employeeLeaveRequestsProvider(id)`, `employeePerformanceReviewsProvider(id)`, `employeeBenefitsProvider(id)`, `leaveRequestDetailProvider(id)`, `hrServiceProvider`
- `providers/hr_providers.dart` — `leaveRequestsProvider`, `payrollLedgerProvider`, `jobRequisitionsProvider`, `candidatesProvider.family(requisitionId)`, `performanceReviewsProvider`, `ohsAppointmentsProvider`
- `providers/leave_providers.dart` — `leaveRequestsCollectionProvider`, `leaveRequestsProvider`, `leaveServiceProvider`

**Services:** `hr_service.dart` (CRUD for employees/leave/compensation/benefits/performance), `invite_service.dart` (invite CRUD/streams).

## 6. Cross-Module Links
- **AppEventBus:** emits `EmployeeTerminatedEvent(employeeId, employeeName)` from `employee_360_profile_screen.dart` on termination. No listener for this event was found inside `people` itself — it's presumably intended to be consumed elsewhere (e.g. to revoke Safety clearances, per AGENTS.md's own example), but no consuming module was confirmed during this pass; worth a follow-up check when auditing `safety.md`.
- `EmployeeSelector` widget is consumed across many other modules (safety permits, project resource allocation, etc.) — the module's single most-reused export.

## 7. Known Gaps

### Rules-vs-code gaps
- `BaseIncident` — see [_shared doc](_shared_personas_and_bpfs.md#related-rules-vs-code-gap-applicable-wherever-relevant-below). Not directly relevant to `people` itself (no incident model here), noted only for completeness since `employee_activity_tab.dart` surfaces incident data from other modules.

### DB-to-UI alignment audit
`employee_profile_form.dart` vs `EmployeeProfile` model:
| Field | Status | Note |
|---|---|---|
| `departmentId` | **Wrong widget** | `DropdownButtonFormField` with a hardcoded static item list (HR/IT/FIN/OPS/SALES/SHEQ) — not backed by any real Department collection/lookup |
| `positionId` | **Wrong widget** | Same pattern — hardcoded static list (Manager/Officer/Technician/Engineer/Specialist/Director), not a real JobRole lookup |
| `managerEmployeeId` | Correct | Uses `EmployeeSelector`, a proper type-ahead lookup |

### Other
- **Hire-to-Retire BPF orchestrator is stubbed**: see §3 — `completeOnboarding()` doesn't actually update employee status, only the BPF tracking record.
- **Possible model duplication**: `models/employee.dart` (`Employee`/`JobRole`) and `models/leave_request.dart` appear to define overlapping concepts alongside `hr_models.dart`'s `EmployeeProfile`/`LeaveRequest` — worth a follow-up to confirm whether both are actively used or one is dead code.
- **Mocked tabs**: `employee_activity_tab.dart` and `employee_hr_tab.dart` (inside the 360 profile) are not wired to real queries — they render mock/placeholder data, which directly violates AGENTS.md §2's "No Hardcoded Data" rule.
- **Sensitive-data RBAC gap**: payroll (`payroll_ledgers`), compensation (`compensation_plans`), and performance (`performance_reviews`) collections rely on the Firestore catch-all rule rather than purpose-built, role-scoped rules — see §5.
- **IA/taxonomy conflict**: see [_shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Should `employee_activity_tab.dart` and `employee_hr_tab.dart` be wired to live queries in a near-term pass, given they currently violate the "no hardcoded data" rule on one of the most-used screens in the app?
- Should `departmentId`/`positionId` become real lookups against dedicated `departments`/`job_roles` collections, or are the hardcoded enums an intentional short-term simplification?
- Is `models/employee.dart` (`Employee`/`JobRole`) still needed alongside `hr_models.dart`, or is it dead code from an earlier iteration?
