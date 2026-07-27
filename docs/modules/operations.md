# operations — Module Journey Doc

**Path:** `lib/features/operations/`  |  **Compartment:** Project Operations  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`operations` is a mid-sized (19 files, 5 screens) grab-bag module bundling four largely-unrelated features under one hub: a cross-module **Action Tracker** (aggregates open items from six other collections), a **Universal Schedule Board** (drag-and-drop resource scheduling), a **Gateway Integrations** manager (webhook configs), and an **Inventory Dashboard** (warehouses/stock). `OperationsHubScreen` also acts as a meta-launcher, embedding side-sheet shortcuts into three *other* modules' own hub screens (`property`, `environment`, `contractors`) plus a `projects` dashboard shortcut, so its real UI footprint is broader than its own file count suggests.

**In scope:** cross-module action-item aggregation/status tracking, resource/task scheduling board, third-party webhook integration configuration, warehouse/inventory display.
**Out of scope:** the source records the Action Tracker aggregates (incidents, CAPAs, permits, BBS observations, DRAs, hazards — all owned by `safety`/`risk`), actual work-order dispatch (`field_service`), the supply-chain inventory system this module's own inventory screen actually reads from (see §5 — it borrows `supply_chain`'s models wholesale).
**IA placement:** Project Operations compartment (8-compartment taxonomy) per this doc set. See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
Neither assigned persona's shared-doc journey text names this module's specific features (Action Tracker, Schedule Board, Integrations, Inventory Dashboard) explicitly — stated plainly rather than stretched to fit, consistent with the precision `billing.md`/`emergency.md` established for similar cases.

| Persona | Journey | Steps touching `operations` | Entry screen(s) |
|---|---|---|---|
| [Project & Risk Manager](_shared_personas_and_bpfs.md#persona-project-risk-manager) (primary) | No named shared-doc journey step maps directly here; closest is general project-execution oversight | Action Tracker gives a cross-module view of open safety/risk items that could plausibly belong to a PM's oversight duties, but this isn't named in the persona's own journey text | `operations_hub_screen.dart` → `action_tracker_screen.dart` |
| [Supply Chain & Facilities Manager](_shared_personas_and_bpfs.md#persona-scm-facilities-manager) (secondary) | Procurement & Inventory: "...Update Inventory Item..." | Closest textual match in either persona's journeys — but the screen that would serve it (`inventory_dashboard_screen.dart`) is unreachable from any navigation path in the app (§4) | `inventory_dashboard_screen.dart` (orphaned — see §4/§7) |

## 3. BPF Participation
| BPF | Stage(s) this module implements (narrative) | Code reference |
|---|---|---|
| [Project Concept to Close](_shared_personas_and_bpfs.md#bpf-project-concept-to-close) | Named in the shared doc's "Modules" list (`projects, operations, risk, finance, contractors`) — general adjacency only | None |

**Confirmed the weakest BPF link of this doc's three assigned modules, exactly as anticipated going in.** Repo-wide grep of `lib/core/bpf/` for the string `"operations"` returns zero matches; `lib/features/operations/` contains zero references to `BpfRibbonWidget` and zero imports of anything under `core/bpf/` at all (confirmed directly, not inferred). This is narrative-only participation in the fullest sense found across this doc's modules so far — not merely an unwired ribbon (which would still mean the module *imports* the BPF system), but the complete absence of any BPF-engine touchpoint, code or visual.

## 4. Screens & UI Elements Inventory
| Screen | Route or entry point | Purpose / wiring |
|---|---|---|
| `operations_hub_screen.dart` | `/operations` | Landing hub: live KPI row (`operations_hub_metrics.dart`) + 6-tile module grid (`operations_hub_modules.dart`) + FAB to Action Tracker |
| `action_tracker_screen.dart` | `/actions` (also reachable via hub FAB/tile side-sheet) | "Unified Action Item Tracker" — real, live aggregation of 6 collections. **Has a confirmed create/read split bug**, see §5/§7 |
| `schedule_board_screen.dart` | `/schedule-board` | Drag-and-drop resource/task board. **Confirmed 100% hardcoded mock data**, see §7 |
| `integrations_hub_screen.dart` | Side-sheet only, from `operations_hub_modules.dart`'s "Gateways & Integrations" tile — no top-level route | Real, live CRUD list of webhook integrations |
| `inventory_dashboard_screen.dart` | **Unreachable — no route, no side-sheet link, no reference anywhere outside its own file** (confirmed by repo-wide grep) | Warehouses + inventory items display; backend is real but built on borrowed `supply_chain` models (§5) |

`operations_hub_modules.dart`'s 6-tile grid: Projects (embeds `projects`' `ProjectDashboardScreen`), Action Tracker, Property Portfolio (embeds `property`'s hub), Environmental (embeds `environment`'s hub), Contractors (embeds `contractors`' management screen), Gateways & Integrations. Notably absent: any tile for Inventory or Schedule Board — the latter is only reachable by typing `/schedule-board` directly or via whatever external link points at it (not found from within this module's own UI in this pass).

## 5. Backend & Database

**Models:**
| Model | Key fields | Collection | Status |
|---|---|---|---|
| `ActionItem` (`models/action_tracker_models.dart`) | id, collectionName, type, title, status, dueDate, assignee | N/A — constructed ad hoc, not read via `fromJson` in practice (see below) | Real but under-used |
| `InventoryItem` (`models/inventory_models.dart`) | tenantId, name, sku, category, quantity, unit, locationId, reorderLevel, cost | — | **Dead — confirmed zero imports anywhere in `lib/`** |
| `Warehouse` (`models/inventory_models.dart`) | tenantId, name, location, managerId, capacity | — | **Dead — same file, same finding** |
| `IntegrationConfig` (`lib/core/services/integrations_service.dart` — shared core, not module-local) | name, type, isEnabled, webhookUrl, apiKey, tenantId | `tenants/{tenantId}/integrations` | Real, live |

**Confirmed dead model file, a cleaner case than the duplicate-model pattern found elsewhere in this doc set (`crm.md`'s `Deal`, `billing.md`'s plural `subscription_models.dart`, `people.md`'s possible `Employee`/`EmployeeProfile` overlap):** `models/inventory_models.dart` defines its own `InventoryItem` and `Warehouse` classes with full `fromFirestore`/`toFirestore` serialization — but grepping the entire `lib/` tree for any file importing `inventory_models.dart` returns **nothing**. `services/inventory_service.dart` — the only consumer of the module's inventory feature — imports `InventoryItem`/`Warehouse` from `../../supply_chain/models/scm_models.dart` instead (confirmed at the top of the file, plus its own doc comment: *"Uses the canonical models from supply_chain/models/scm_models.dart"*), a structurally different pair of classes (`sku`/`itemType`/`valuationMethod`/`leadTimeDays`/`safetyStock`/`reorderPoint` on `InventoryItem`; `code`/`type`/`address`/`status` on `Warehouse`, using `fromJson`/`toJson` not Firestore-snapshot constructors). This was caught concretely: `inventory_dashboard_screen.dart:52` renders `warehouse.code` — a field that exists on `supply_chain`'s `Warehouse` but not on `operations`' own same-named `Warehouse`. So `operations` doesn't actually own its inventory feature's data layer at all; it borrows `supply_chain`'s wholesale while carrying a same-named, fully-built, entirely-unused model file of its own.

**Collections used:**
- `actionItems` (camelCase) — written by `action_form.dart`, read by `operations_hub_metrics.dart`'s "Open Actions" KPI. **Not read by `action_tracker_screen.dart` itself** (see below).
- `incidents`, `capas`, `permits`, `bbs_observations`, `dynamic_risk_assessments`, `hazards` — the 6 collections `ActionTrackerScreen._collections` actually aggregates and displays.
- `inventory_items`, `warehouses` — `InventoryService`, correctly tenant-scoped (`_tenantDoc.collection(...)` directly, not the buggy root-escape pattern documented in `projects.md`'s `PmoService`).
- `integrations` — `IntegrationsService`, correctly tenant-scoped.
- `properties`, `contractors` — read by `operations_hub_metrics.dart`'s KPI row.

**Confirmed, high-value bug: the Action Tracker's own create flow writes to a collection its own list view never reads.** `ActionTrackerScreen._setupStreams()` subscribes to exactly 6 `CollSource`s (`incidents`, `capas`, `permits`, `bbs_observations`, `dynamic_risk_assessments`, `hazards`) — **`actionItems` is not among them.** But the screen's own "+" FAB opens `ActionForm`, whose `_submit()` writes a brand-new document straight into `tenantCollection(tenantId, 'actionItems')`. Net effect: a user who taps "+", fills in a title/assignee/due-date, and submits, sees a success toast — but the item they just created **never appears in the list they created it from**, because that collection isn't one of the six the screen aggregates. The only place `actionItems` is actually read back is `operations_hub_metrics.dart`'s unrelated "Open Actions" KPI counter on the hub screen one level up.

**Secondary model mismatch inside the same flow:** `ActionItem`'s own fields are `collectionName`/`assignee`; `ActionForm._submit()`'s write payload uses `assigneeId` (not `assignee`) and adds `description`/`createdAt`/`siteId`, none of which `ActionItem` declares, while never writing `collectionName` at all. In practice this doesn't surface as a visible bug today only because the read side never loads `actionItems` documents through `ActionItem.fromJson()` in the first place (§ above) — but it means fixing the aggregation gap by simply adding `actionItems` to `_collections` would immediately expose a second bug: assignee names would always render as `'Unassigned'` (the model's default), since the field the form actually wrote is named differently.

**Firestore rules check:** none of `actionItems`, `capas`, `bbs_observations`, `dynamic_risk_assessments`, `inventory_items`, `warehouses`, or `integrations` are declared in `firestore.rules`. All fall to the tenant-scoped catch-all (`allow read: if belongsToTenant(tenantId); allow write: if false;`). Concretely: `ActionForm`'s write to `actionItems`, `ActionTrackerScreen._updateStatus()`'s status-toggle writes when the source item came from `capas`/`bbs_observations`/`dynamic_risk_assessments`, `InventoryService`'s add/update/delete methods, and `IntegrationsService.saveIntegration()`/`deleteIntegration()` **would all be rejected by the deployed rules as committed** — this module's write paths are more broadly rules-blocked than either of its two sibling modules in this batch. `incidents`/`permits`/`hazards` status-toggles (the other 3 of the 6 aggregated collections) are rules-declared and instead subject to normal role gating (`isSheqOfficer()`), which is intentional, not a gap.

**Cloud Functions:** none of this module's screens or services call any Cloud Function (confirmed by grep for `httpsCallable`/`FirebaseFunctions` — no matches anywhere in `lib/features/operations/`).

**Providers/Services:** `services/action_tracker_service.dart` (`actionTrackerServiceProvider`, `actionItemsProvider`, `actionItemsByStatusProvider.family` — all correctly tenant-scoped, but **confirmed unused by `action_tracker_screen.dart`**, which builds its own inline Firestore subscriptions instead of consuming these providers — a second, independent piece of evidence that the module's `ActionItem`/`actionItems`-collection plumbing and its actual UI evolved apart from each other); `services/inventory_service.dart` (`inventoryServiceProvider`, `inventoryItemsProvider`, `warehousesProvider` — real, but see the borrowed-model finding above); `lib/core/services/integrations_service.dart` (`integrationsServiceProvider`, `integrationsProvider` — real, shared core rather than module-local, consumed by both `integrations_hub_screen.dart` and `integration_config_form.dart`).

## 6. Cross-Module Links
- **projects**: `ProjectDashboardScreen` embedded as a side-sheet tile inside `operations_hub_modules.dart` — a real cross-module UI embed in this direction (see `projects.md` §6 for the reverse-direction confirmation that no equivalent embed exists back into `operations`).
- **property, environment, contractors**: each module's own hub/management screen is embedded as a side-sheet tile from `operations_hub_modules.dart` — `operations` functions partly as a secondary launcher for these three modules rather than owning distinct functionality of its own for them.
- **supply_chain**: `InventoryService` imports `InventoryItem`/`Warehouse` directly from `supply_chain/models/scm_models.dart` rather than this module's own (dead) `inventory_models.dart` — see §5. This is a real, if one-directional and slightly unusual, model-level dependency not mentioned in either module's persona-journey text.
- **safety / risk**: `ActionTrackerScreen` reads live from `incidents`, `permits`, `hazards` (safety/risk-owned) and `capas`, `bbs_observations`, `dynamic_risk_assessments` (risk-owned or risk-adjacent) — the module's single most substantial real cross-module feature, aggregation caveats in §5 notwithstanding.
- **people**: `EmployeeSelector` used in `action_form.dart` for assignee selection.
- **AppEventBus:** zero usage anywhere in `lib/features/operations/` (confirmed by grep for both `AppEventBus` and `.fire(`) — no event fires when an action item's status changes or when a new one is created, despite this module being conceptually exactly the kind of cross-module status-change hub AGENTS.md §5 describes the bus for.

## 7. Known Gaps

### Rules-vs-code gaps
- `actionItems`, `capas`, `bbs_observations`, `dynamic_risk_assessments`, `inventory_items`, `warehouses`, `integrations` are all undeclared in `firestore.rules` and fall to the tenant-scoped catch-all's `allow write: if false` — see §5 for the specific write paths this blocks. This module has proportionally more of its own write paths rules-blocked than either `projects` or `risk` in this same batch.
- `BaseIncident` (AGENTS.md §5, absent repo-wide per the [shared doc](_shared_personas_and_bpfs.md#related-rules-vs-code-gap-applicable-wherever-relevant-below)): not directly applicable to this module's own models — `ActionItem` aggregates incident-shaped data from other modules but isn't itself an incident-domain model.

### DB-to-UI alignment audit
`action_form.dart` vs `ActionItem` model — an unusual case where the create form and its own model disagree with each other, not just with the database:
| Field | Status | Note |
|---|---|---|
| `collectionName` | **Missing** | Model field exists (needed to route `_updateStatus()` correctly); the form never writes it |
| `assignee` | **Missing (effectively)** | Model expects `assignee`; the form writes `assigneeId` instead — reading the created doc back through `ActionItem.fromJson()` would always yield the model's `'Unassigned'` default |
| `description`, `createdAt`, `siteId` | **Orphan** | Written by the form, absent from the `ActionItem` model entirely |

`integration_config_form.dart` vs `IntegrationConfig` model: no gaps found — `name`, `type` (dropdown, not free text), `webhookUrl`, `apiKey`, `isEnabled` (switch) all present with reasonable widgets; `tenantId` is correctly system-set from `currentTenantIdProvider` rather than user-entered. Included as a clean contrast to the `ActionItem` finding above, not as a gap.

### Other
- **`schedule_board_screen.dart` is entirely hardcoded mock data**, the same severity of AGENTS.md §2 violation as `projects.md`'s `revenue_recognition_screen.dart` finding. Its own comments say so directly: `// Mock data for resources (technicians/employees)` and `// Mock data for unassigned tasks`. Four hardcoded resource names (John Doe, Jane Smith, Mike Johnson, Sarah Connor) and three hardcoded tasks (`WO #101`, `WO #102`, `PMO-200` — the IDs suggest an intent to eventually pull real Work Orders and PMO tasks); drag-and-drop assignment only mutates local `setState`, with no Firestore write anywhere in the file — reassignments are lost on navigating away.
- **`inventory_dashboard_screen.dart` is fully built but completely unreachable** — no route, no side-sheet link from `operations_hub_modules.dart` or anywhere else (confirmed by repo-wide grep for the class name). Combined with the dead-model finding in §5, this feature is doubly orphaned: unreachable UI sitting on top of an unused model file, backed by a service that actually pulls its types from a different module.
- **Action Tracker create/read split** (§5) — the module's flagship feature has a real, user-visible gap between what its "+" button writes and what its own list displays.
- `action_tracker_service.dart`'s properly-modeled, tenant-scoped providers (`actionItemsProvider` etc.) are unused by the screen that would seem to be their natural consumer — a smaller-scale instance of the same "real backend, UI evolved separately" pattern as the inventory finding.

## 8. Open Questions
- Should `ActionTrackerScreen._collections` include `actionItems`, so manually-created action items actually appear in the tracker they were created from? If so, `action_form.dart`'s write payload would also need to align with `ActionItem`'s actual field names (`assignee` not `assigneeId`, plus a `collectionName` value).
- Was `models/inventory_models.dart` an earlier, module-local design later abandoned in favor of reusing `supply_chain`'s richer schema, with the file simply never deleted? Given neither model is referenced from anywhere except the dead file itself and its unreachable screen, it's hard to tell from the code alone which was meant to be canonical.
- Is `inventory_dashboard_screen.dart` meant to be reachable from `operations_hub_modules.dart`'s tile grid (an "Inventory" tile is conspicuously the one warehouse/stock-shaped gap in an otherwise-comprehensive 6-tile menu), or does `supply_chain` already own the intended production entry point for this data and this screen is a leftover?
- Is `schedule_board_screen.dart` meant to pull from `work_orders` (field_service) and the PMO/live `projects` task data, matching the hints in its own mock IDs, or was it built purely as a UI prototype?
- Should this module formally participate in Project Concept to Close (e.g., an operations-side stage or checklist item), or does its near-total absence from the BPF engine mean it was never intended as a BPF participant beyond the shared doc's narrative module list?
