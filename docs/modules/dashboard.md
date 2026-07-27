# dashboard — Module Journey Doc

**Path:** `lib/features/dashboard/`  |  **Compartment:** System Administration  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`dashboard` is the app's landing/launchpad surface plus its OHS/safety metrics dashboard. It has two distinct responsibilities living under one folder: (a) `BusinessOsLaunchpad`, the app-wide root tile grid at `/launchpad`, and (b) `DashboardScreen`, a Firestore-driven safety/OHS metrics view at `/dashboard`. A third, closely related "landing surface" — `ControlTowerScreen` — lives in the separate `executive` module (see §6, boundary note).

**In scope:** app-wide navigation launchpad; OHS/safety KPI visualization (LTIFR, HIRA heatmap, CAPA resolution, training compliance, waste management); pending-approvals inbox.
**Out of scope:** executive/exec-suite KPIs across all 7 pillars (owned by `executive` — `control_tower_screen.dart`), any single module's own detail dashboards (e.g. `okr_dashboard_screen.dart` lives in `people`).
**IA placement:** System Administration compartment (8-compartment taxonomy) for the launchpad itself; the OHS dashboard content is arguably HR/SHEQ-flavored but the *screen* lives here. See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `dashboard` | Entry screen(s) |
|---|---|---|---|
| All personas | App entry | Land on `/launchpad` → select a module tile | `business_os_launchpad.dart` |
| [HR & Safety Officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer) | Safety oversight | View LTIFR/HIRA/CAPA/training/waste KPIs | `dashboard_screen.dart` |
| [Executive/C-Suite](_shared_personas_and_bpfs.md#persona-executive) | Strategic Oversight | View BI Dashboards (partial — see `executive.md` for the fuller Control Tower version of this journey) | `dashboard_screen.dart` |
| [HR & Safety Officer](_shared_personas_and_bpfs.md#persona-hr-safety-officer) (as approving manager) | Approve leave/requisitions | Open Approvals Inbox → approve/reject | `approvals_inbox_screen.dart` (side-sheet from `dashboard_header.dart`) |

This module is not the primary home of any single persona's journey — it's the shared entry point and a metrics-viewing surface, which is why its journey table is shorter than `people.md`/`crm.md`. That is the expected shape for a "landing surface" module, not a gap.

## 3. BPF Participation
None. `dashboard` does not implement a stage of any of the 6 BPFs, and no `BpfRibbonWidget` usage was found in `dashboard/` or `executive/` — confirmed by direct search. This is the expected, correct answer for a cross-cutting landing/metrics surface (see [_shared doc](_shared_personas_and_bpfs.md#business-process-flows-bpfs), "Modules with zero BPF participation").

## 4. Screens & UI Elements Inventory
| Screen/widget | Route or side-sheet | Purpose |
|---|---|---|
| `business_os_launchpad.dart` (`BusinessOsLaunchpad`) | `/launchpad` (initial app route) | Root tile grid — renders **all ~28 feature tiles** grouped under 6 static section headers (Finance, Supply Chain Management, Human Resources, Project Operations, Customer Engagement, System Administration) |
| `dashboard_screen.dart` (`DashboardScreen`) | `/dashboard` | OHS/safety metrics dashboard; also listens live to `AppEventBus` for alert toasts |
| `approvals_inbox_screen.dart` (`ApprovalsInboxScreen`) | side-sheet only (from `dashboard_header.dart`) | Pending-approvals list (leave requests, job requisitions) |
| `dashboard_header.dart` | — (widget) | Top header bar; launches Approvals Inbox |
| `dashboard_charts_grid.dart` | — (widget) | Layout grid composing the chart widgets below |
| `ltifr_history_chart.dart`, `hira_heatmap_chart.dart`, `incident_heatmap_scatter_plot.dart`, `incident_mapping_map.dart`, `incidents_category_chart.dart`, `capa_resolution_chart.dart`, `mandatory_training_chart.dart`, `ohs_compliance_chart.dart`, `waste_management_chart.dart` | — (widgets, composed into `dashboard_screen.dart`) | One metric chart each, backed by the matching provider in §5 |

**`BusinessOsLaunchpad` implementation note:** it is a plain `StatelessWidget` with a hardcoded `SliverChildListDelegate` tile list — no Riverpod watch, no RBAC filtering. An earlier planning artifact (the recovered roadmap, and `walkthrough.md` from the same Antigravity session) described a goal of showing "all 7 module tiles correctly based on mock user RBAC permissions" in testing — that RBAC filtering is **not implemented**; every tile is shown to every user regardless of role. Logged as a gap below.

## 5. Backend & Database

**Models:** no dedicated `models/` directory. Local-only data classes:
- `ApprovalItem` (in `providers/approvals_provider.dart`): id, type, title, subtitle, date, collectionPath, rawData.
- `_KpiData`/`_AlertData` (private, inside `executive/control_tower_screen.dart` — not this module, see §6): label, value, module, accent, icon — **statically hardcoded**, not Firestore-backed. Logged under `executive`'s future doc, referenced here for the boundary note.

**Providers — `lib/features/dashboard/providers/`:**
- `dashboard_providers.dart` — `dashboardLtifrHistoryProvider`, `dashboardOhsComplianceProvider`, `dashboardHiraMatrixProvider`, `dashboardTrainingProvider`, `dashboardCapaProvider`, `dashboardWasteProvider`, `dashboardIncidentHeatmapProvider` — all `StreamProvider`s, correctly real-time-first, aggregating cross-module collections: `incidents`, `competency_passports`, `risk_assessments`, `capas`, `waste_manifests`.
- `approvals_provider.dart` — `pendingApprovalsProvider` (**stub, empty body — unused**), `pendingApprovalsFutureProvider` (`FutureProvider.autoDispose`, one-shot `.get()` against `leave_requests`/`job_requisitions` filtered by manager) — this is a one-off fetch, not a stream, which is the same real-time-first pattern gap flagged in `crm.md`.

No Cloud Functions are called directly from this module.

## 6. Cross-Module Links
- **AppEventBus:** `dashboard_screen.dart` subscribes to the bus (`ref.read(appEventBusProvider).stream.listen`) to surface `HighRiskIncidentReportedEvent` and `EmployeeTerminatedEvent` as live alerts — this is the one confirmed *consumer* of `EmployeeTerminatedEvent`, which `people.md` noted had no confirmed listener; that's now resolved — `dashboard` is a listener, even if not the one AGENTS.md's own example (revoking Safety clearances) implied.
- Aggregates data from `safety`/`training`/`risk`/`environment`-adjacent collections (`incidents`, `competency_passports`, `risk_assessments`, `capas`, `waste_manifests`) without formally depending on those modules' code — a read-only cross-module coupling via shared collection names.

## 7. Known Gaps

### Module boundary
`ControlTowerScreen` (in the separate `executive` module) and `DashboardScreen`/`BusinessOsLaunchpad` (here) are two independently-implemented "landing/exec surface" screens that don't share code, models, or providers, despite serving overlapping purposes (both are metrics/oversight surfaces for the Executive persona). Worth flagging as a consolidation candidate rather than two parallel implementations — not fixed here, per the plan's "flag, don't resolve" instruction for structural findings of this kind.

### Other
- **No RBAC filtering on the Launchpad**: every one of the ~28 tiles is shown to every authenticated user; an earlier plan's stated intent (role-based tile visibility) is not implemented.
- **`pendingApprovalsProvider` is a dead stub**: empty body, unused — likely superseded by `pendingApprovalsFutureProvider`, which itself is a one-shot fetch rather than a live stream (real-time-first gap, same pattern as `crm.md`'s `accountStreamProvider.family`).
- **`_KpiData`/`_AlertData` hardcoding** lives in `executive`, not `dashboard`, but is closely related to this module's purpose — will be captured fully when `executive.md` is written; referenced here so the boundary note isn't orphaned.
- **IA/taxonomy conflict**: see [_shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Should `dashboard` (OHS metrics + launchpad) and `executive` (Control Tower) be merged into one module, given their overlapping purpose and audience?
- Was RBAC-filtered launchpad tile visibility ever actually a committed requirement, or just an aspirational note in an old test-plan description? Worth confirming before treating this as a real gap to fix versus a stale idea.
- Should `pendingApprovalsFutureProvider` be converted to a live `StreamProvider` given the rest of the dashboard is correctly real-time-first?
