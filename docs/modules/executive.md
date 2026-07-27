# executive — Module Journey Doc

**Path:** `lib/features/executive/`  |  **Compartment:** System Administration  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`executive` is a single file, `control_tower_screen.dart` (`ControlTowerScreen`), a self-described "premium executive dashboard with live clock, KPI cards, and critical alerts." This doc picks up exactly where [dashboard.md §6](dashboard.md#module-boundary) leaves off — see that doc for the full boundary discussion between this screen and `DashboardScreen`/`BusinessOsLaunchpad`; it is not re-described here.

**In scope:** the Control Tower screen itself.
**Out of scope:** `BusinessOsLaunchpad`/`DashboardScreen` (see [dashboard.md](dashboard.md)); `ai_tools`/`copilot` (separate modules, see [ai_tools.md](ai_tools.md)/[copilot.md](copilot.md)).
**IA placement:** System Administration compartment; Executive/C-Suite persona per the shared doc's own module-focus line ("System Administration, Analytics (dashboard, executive, ai_tools, copilot)"). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `executive` | Entry screen(s) |
|---|---|---|---|
| [Executive/C-Suite](_shared_personas_and_bpfs.md#persona-executive) (primary) | Strategic Oversight: "View BI Dashboards → **Drill down via deep links** into specific Projects or High-Risk CAPAs → Monitor Corporate Strategic Risks → Review Corporate Compliance and Integration Configs" | View KPI cards + alert tiles | `control_tower_screen.dart` (`/control-tower`) |

The "drill down via deep links" half of this persona's defining journey is **not implemented** — see §7.

## 3. BPF Participation
None. `executive` is explicitly listed in the [shared doc's](_shared_personas_and_bpfs.md#business-process-flows-bpfs) "Modules with zero BPF participation, narratively or in code." Confirmed directly: zero references to `bpf_orchestrator.dart`/`BpfRibbonWidget`/any BPF stage file anywhere in `lib/features/executive/`.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route | Purpose / wiring |
|---|---|---|
| `screens/control_tower_screen.dart` (`ControlTowerScreen`) | `/control-tower` (`router.dart:270-272`); Launchpad tile "Global Control Tower" (System Administration section) | Live clock (real `Timer.periodic`, cosmetic only) + 6 KPI cards + 3 alert tiles, all entrance-animated |
| `_KpiCard` (private) | — | Hover/glow-animated card; **no `onTap`/`GestureDetector`/`InkWell` anywhere in the class** |
| `_AlertTile` (private) | — | Blurred alert card with a trailing "forward" chevron icon (`Icons.arrow_forward_ios_rounded`) that visually implies navigation; **no `onTap`/`GestureDetector`/`InkWell` anywhere in the class** — the chevron is decorative only |

## 5. Backend & Database
**No models, no providers, no `cloud_firestore` import, no `flutter_riverpod` import anywhere in this file** — confirmed by reading the full import list (`dart:async`, `dart:ui`, `flutter/material.dart`, `intl/intl.dart` only). `ControlTowerScreen` is a plain `StatefulWidget`; all of its state is the live clock and local animation controllers.

**`_KpiData`/`_AlertData` — both fully hardcoded `static const` lists** (confirmed already in [dashboard.md §5](dashboard.md#5-backend--database), expanded here):
- **`_kpis`** (6 entries, one labeled per pillar): Cash Position `$12.4M` (Finance), Open Work Orders `47` (Field Service), Active Projects `23` (PMO), Open Cases `156` (Customer Service), Inventory Value `$8.2M` (SCM), Headcount `1,847` (HR). Every value is a compile-time string literal — none is computed from any Firestore collection (`invoices`, `work_orders`, `projects`, `employees`, etc. are never queried here).
- **`_alerts`** (3 entries): "Low Cash Runway Detected," "SLA Breach Risk — 12 Cases," "Inventory Reorder Point Reached." The third alert's description text — *"Auto-PO draft created"* — reads as a factual system claim (a purchase order was automatically drafted), but this is static copy inside a hardcoded string; no PO is ever created anywhere by this file, and `lib/core/bpf/procure_to_pay_bpf.dart` (the module that would own real PO auto-drafting) has no connection to this screen.

Worth noting directly: `dashboard_screen.dart` (the sibling "landing surface" screen, see [dashboard.md](dashboard.md)) *does* back its charts with real `StreamProvider`s against live collections. This screen — the one branded "premium"/"Global Control Tower" and assigned to the Executive/C-Suite persona specifically — is the one with zero real data in this pair, the inverse of what the branding implies.

**Firestore rules check:** not applicable — no Firestore access anywhere in this file.

## 6. Cross-Module Links
- See [dashboard.md §6 "Module boundary"](dashboard.md#module-boundary) for the full discussion of this screen's overlap with `DashboardScreen`/`BusinessOsLaunchpad`.
- Confirmed by grep: `ControlTowerScreen` is referenced only by `router.dart` and its own file — nothing else in the app links to or from it.
- **AppEventBus:** zero usage anywhere in `lib/features/executive/` (confirmed by grep) — the live-alert pattern `dashboard_screen.dart` uses to surface `HighRiskIncidentReportedEvent`/`EmployeeTerminatedEvent` (see [dashboard.md §6](dashboard.md#6-cross-module-links)) is not used here; this screen's alerts are static instead.

## 7. Known Gaps

### Rules-vs-code gaps
Not applicable — no Firestore access anywhere in this module.

### DB-to-UI alignment audit
Not applicable — no Firestore-backed model exists for this screen to diff a form against; it has no form at all (view-only).

### Other
- **All KPI and alert data is hardcoded** (§5) — an AGENTS.md §2 "No Hardcoded Data" violation for what the file's own doc comment calls the C-suite's dashboard.
- **No drill-down navigation anywhere** — neither `_KpiCard` nor `_AlertTile` has a tap handler, despite the primary persona's own defining journey text ("Drill down via deep links into specific Projects or High-Risk CAPAs") and despite `_AlertTile`'s forward-chevron icon visually implying exactly this. This is the module's most direct gap against its own persona's stated need.
- One alert's static copy ("Auto-PO draft created") describes an automated action that never actually happens anywhere in the codebase.
- No live-data or `AppEventBus` integration at all, unlike its sibling landing screen (§6).

## 8. Open Questions
- Should `ControlTowerScreen`'s KPIs be wired to real `StreamProvider`s against `invoices`/`work_orders`/`projects`/`opportunities`/`inventory`/`employees` (mirroring `dashboard_screen.dart`'s already-real pattern for OHS metrics), or is this screen intentionally a static mockup/demo shell?
- Should `_KpiCard`/`_AlertTile` navigate somewhere (e.g., `context.go('/finance')`, or a specific record's detail route) to satisfy the "drill down via deep links" journey text, and if so, to what — module hub screens, or specific record IDs?
- Per [dashboard.md](dashboard.md)'s parallel open question: should this screen be merged with `DashboardScreen` rather than maintained as a second, fully-disconnected "landing surface" implementation?
