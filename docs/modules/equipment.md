# equipment — Module Journey Doc

**Path:** `lib/features/equipment/`  |  **Compartment:** Supply Chain Management  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`equipment` is Sentinel1's asset register: a single `EquipmentModel`/`equipment` collection covering plant/vehicles/tools, with an asset list + inspection-due view + maintenance-placeholder tab, a per-asset detail screen carrying the app's second real `BpfRibbonWidget` instance, and a LOTO (Lockout/Tagout) sub-flow. Code quality inside the module is comparatively strong (a genuinely well-built, defensive, correctly-widgeted create form; a real three-collection LOTO write path) — but the module's main entry point is **structurally unreachable from the launchpad**, the single most severe finding of this doc (§4).

**In scope:** equipment/asset register CRUD, upcoming-inspection tracking, LOTO lockout/release logging, an `EquipmentMultiSelector` reused by `projects` for resource allocation.
**Out of scope:** the `supply_chain`-owned `Asset`/`assets` (EAM) model (a structurally separate concept, see `supply_chain.md` §6), property/facility assets (`property`'s own `AssetInfo`), full maintenance work-order management (the "Maintenance" tab is a placeholder pointing at `field_service`'s `work_orders`, never actually querying it — §4).
**IA placement:** Supply Chain Management compartment (8-compartment taxonomy). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved). `docs/schema_scm.md`'s EAM section (`assets` + `maintenance_schedules`/`maintenance_work_orders` sub-collections, `financials`/depreciation fields) is the closest schema-doc match to this module's domain, but `EquipmentModel` implements only a small subset (no financials, no depreciation, no maintenance sub-collections) — the same "richer doc than code" pattern found in `supply_chain.md`.

## 2. User Journeys
| Persona | Journey | Steps touching `equipment` | Entry screen(s) |
|---|---|---|---|
| [Supply Chain & Facilities Manager](_shared_personas_and_bpfs.md#persona-scm-facilities-manager) (primary) | Asset Lifecycle: Register Equipment/Asset → Track Maintenance Schedule | `EquipmentManagementScreen` (Assets/Inspections/Maintenance tabs) → `AssetDetailScreen` | **Unreachable from the launchpad — see §4, the headline finding of this doc** |
| Field Service & Emergency Responder (secondary, per module assignment) | LOTO release as part of on-site SHEQ check (per Asset Lifecycle's narrative flow step) | `LotoManagementScreen` — "Inspect & Release" | Real, but only reachable from the same unreachable `EquipmentManagementScreen`'s AppBar button (§4) |

## 3. BPF Participation
| BPF | Stage(s) this module implements | Code reference |
|---|---|---|
| [Asset Lifecycle](_shared_personas_and_bpfs.md#bpf-asset-lifecycle) | All 4 stages (`acquisition`/`deployment`/`maintenance`/`decommissioning`) | `asset_lifecycle_bpf.dart` — `expectedRecordType: 'equipment'` on every stage, confirmed the closest direct module-to-record-type match of any module in this session, exactly as the task brief anticipated |

**Implementation-depth confirmation, verified directly:** `AssetDetailScreen` (`asset_detail_screen.dart:57-62`) does contain a real `BpfRibbonWidget` (`bpfTypeId: 'asset_lifecycle'`, `recordType: 'equipment'`, `definition: assetLifecycleDefinition`) — confirmed exactly where the task brief asked to look. Two further findings sharpen this beyond what the brief already states:
1. `BpfOrchestrator.deployEquipment()` is confirmed a stub by its own code comment (per the [shared doc](_shared_personas_and_bpfs.md#business-process-flows-bpfs)) **and has zero call sites anywhere in the app** (confirmed by grep) — not merely a stub, but an unreachable stub.
2. **No code anywhere ever creates a `bpf_instances` document with `bpfTypeId: 'asset_lifecycle'`** (confirmed by grep across all of `lib/`) — so even if a user could reach `AssetDetailScreen` directly, `BpfRibbonWidget`'s own logic (`bpf_ribbon_widget.dart:31-33`: `if (bpfInstance == null) return const SizedBox.shrink();`) means the ribbon would render nothing. Combined with §4's reachability finding, this ribbon is inert for two independent reasons, not one.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route or entry point | Purpose / wiring |
|---|---|---|
| `equipment_management_screen.dart` (`EquipmentManagementScreen`) | **No route exists** — see finding below | 3-tab shell (Assets/Inspections/Maintenance) plus an AppBar button to LOTO Management |
| `screens/asset_detail_screen.dart` (`AssetDetailScreen`) | Pushed via `Navigator.push` from the Assets tab (only reachable if `EquipmentManagementScreen` itself is reachable) | Real Firestore fetch, real `BpfRibbonWidget` (§3), real `LotoBadge`. **Edit button is a literal empty stub**: `onPressed: () {}` — the single most blatant AGENTS.md §3 "unconfigured onPressed callback" violation found across this session's 4 modules, not even a toast |
| `widgets/equipment_asset_tab.dart` (`EquipmentAssetTab`) | Tab 1 | **Real and well-built**: inline create form (toggle via "+"), defensive `isLoading`/try-catch, correct `UIUtils.showToast`, `EmployeeSelector` for `assignedToId`, real `showDatePicker`, dropdowns for `category`/`status` — see DB-to-UI audit (§7) for the one gap found. Live `StreamBuilder` list with client-side search |
| `widgets/equipment_inspections_tab.dart` (`EquipmentInspectionsTab`) | Tab 2 | Real: queries `equipment` where `daysUntilInspection <= 30`, correctly ordered. View-only by design (derived from the same collection, not a separate one — not a gap) |
| `widgets/maintenance_log_dialog.dart` (`MaintenanceLogDialog`) | Tab 3 | **Fully static placeholder** despite its name — no Firestore query at all; "Open Work Orders" button is a `UIUtils.showToast`-only stub reading "Connecting to Work Order Management..." (correctly uses the toast utility, but performs no real action or navigation into `field_service`'s real, declared-in-rules `work_orders` collection) |
| `screens/loto_management_screen.dart` (`LotoManagementScreen`) | `/loto-management` (registered route) | Real: streams locked-out equipment, "Inspect & Release" calls `LotoAutomation.releaseLockout()` (real 2-collection write, §5). Raw `ScaffoldMessenger.showSnackBar` instead of `UIUtils.showToast` — inconsistent with `EquipmentAssetTab`'s correct usage in the same module |
| `widgets/equipment_list_item.dart`, `widgets/loto_badge.dart` | Presentational | Clean, no issues found |
| `widgets/equipment_multi_selector.dart` (`EquipmentMultiSelector`) | Reused widget | Real, filters out "Locked Out" items, genuinely consumed cross-module (§6) |

**Reachability — the headline finding for this module, verified by reading the complete 281-line `router.dart` in full:** `business_os_launchpad.dart`'s "Equipment" tile (`lib/features/dashboard/screens/business_os_launchpad.dart:83-86`) points at `route: '/equipment'`. **No `GoRoute` for `/equipment` exists anywhere in `router.dart`** — confirmed by reading the entire route list (38 routes total, none of them `/equipment`) and by grep (zero matches for `equip` in any `path:` string). `router.dart` does define a real `errorBuilder` showing "Page Not Found" / "Route not found: ${state.uri}" — so a user tapping the "Equipment" tile lands on that literal error screen, not a crash, but still a dead tile on the app's own main landing page. `EquipmentManagementScreen` is never imported or constructed anywhere in `lib/` outside its own file (confirmed by grep) — it is not reachable through any other path either (no side-sheet trigger, no other module's deep link). Consequently, `/loto-management` — a route that **does** exist and works — is also practically unreachable in the shipped UI, since its only trigger (the AppBar button inside `EquipmentManagementScreen`) never gets to render. This is a different failure mode from `supply_chain.md`'s orphaned screens (unreachable but not advertised) and from `property.md`'s rules gap (reachable but rejected on write) — here the app's own primary navigation surface advertises an entry point that its own router doesn't define.

## 5. Backend & Database

**Model — `lib/features/equipment/models/equipment_models.dart`:**
| Model | Key fields | Collection |
|---|---|---|
| `EquipmentModel` | equipmentName, assetTag, location, manufacturer, category, status, assignedToId?, nextInspectionDate, daysUntilInspection, authorId, createdAt, tenantId | `equipment` |

Single-model module — no separate maintenance/inspection model classes exist; "Inspections" is a filtered view of `equipment` itself, and "Maintenance" (§4) has no backing model at all.

**Firestore rules check — the one clean result across this session's 4 modules:** `equipment`, `work_orders`, and `loto_events` (all three collections this module's code actually touches, confirmed via `equipment_asset_tab.dart`, `loto_automation.dart`) **are all explicitly declared in `firestore.rules`** (lines 75-93: `equipment` and `loto_events` manager/SHEQ-gated, `work_orders` manager-gated) with no naming drift. Unlike `supply_chain`/`property`, this module's real write paths would actually succeed against the deployed rules — its problems are reachability and stub-depth, not rules coverage.

**Providers:** `equipment_providers.dart` → `equipmentListProvider` (real full-collection stream, correctly named `equipment`, matching rules exactly). `loto_providers.dart` → `lockedOutEquipmentProvider`, thin wrapper over `LotoAutomation.streamLockedOutEquipment()`.

**Cross-cutting automation — `lib/core/automation/loto_automation.dart` (outside this module, but this module's real business logic lives here):**
- `lockoutFailedEquipment()` — a genuinely well-built, three-collection write (updates `equipment.status`, creates a real `WorkOrder` via `field_service`'s own model in `work_orders`, logs to `loto_events`) — **but has zero call sites anywhere in the app** (confirmed by grep). No UI button anywhere ever locks out an item.
- `releaseLockout()` — same quality, and **is** reachable, from `LotoManagementScreen`'s "Inspect & Release" button.
- **Consequence, verified against the create form's own option list**: `EquipmentAssetTab`'s status dropdown offers exactly `['Operational', 'Under Maintenance', 'Out of Service', 'Decommissioned']` — **"Locked Out" is not one of the 4 options**, and `lockoutFailedEquipment()` (the only code path that ever writes `status: 'Locked Out'`) is itself unreachable. Since `LotoManagementScreen`'s screen only exists behind an already-unreachable parent, and no path exists to set `status: 'Locked Out'` in the first place, `lockedOutEquipmentProvider` will show an empty state in this app as shipped — not because there's no locked-out equipment, but because nothing in the running UI can ever produce one.

**Cloud Functions:** checked per this doc's brief for `mrpEngine`/`iotEngine` relevance — neither references `equipment`, `loto_events`, or `work_orders` (confirmed by grep of both engine files); not relevant to this module, same conclusion reached independently in `supply_chain.md`.

## 6. Cross-Module Links
- **`EquipmentMultiSelector` is genuinely consumed cross-module**: `lib/features/projects/widgets/pmo_project_form.dart` and `.../new_project_dialog/new_project_dialog_content.dart` both use it to populate `Project.allocatedAssetIds` — a real, verified implementation of the Project Concept to Close narrative's "physical assets/vehicles/tools" resource-allocation step (per the [shared doc](_shared_personas_and_bpfs.md#bpf-project-concept-to-close)), and the multi-selector correctly excludes "Locked Out" equipment from allocation.
- `LotoAutomation.lockoutFailedEquipment()` correctly imports and constructs `field_service`'s own `WorkOrder` model (`lib/features/field_service/models/work_order.dart`) — a real, if currently unreachable, cross-module dependency.
- No relationship found with `property` (no shared model, no cross-import) despite both being Asset-Lifecycle-adjacent — same conclusion `property.md` reached from its own side.
- **AppEventBus:** zero usage anywhere in `lib/features/equipment/` (confirmed by grep) — no event fires on lockout, release, or registration.

## 7. Known Gaps

### Rules-vs-code gaps
- None found — see §5. This module's 3 real collections are all correctly declared.
- `BaseIncident` — not applicable, no incident concept modeled in this module (LOTO events are operational logs, not incidents).

### DB-to-UI alignment audit
`equipment_asset_tab.dart`'s inline form vs `EquipmentModel` — the cleanest form found across this session's 4 modules; only one real gap:
| Field | Status | Note |
|---|---|---|
| `status` | **Wrong widget (incomplete enum)** | Correctly a `DropdownButtonFormField`, but its 4 options (`Operational`/`Under Maintenance`/`Out of Service`/`Decommissioned`) omit `'Locked Out'` — a value the rest of this same module actively checks for and renders specially (`LotoBadge`, `AssetDetailScreen`'s conditional badge, `lockedOutEquipmentProvider`'s filter). A user can never manually set this status through the form; only the unreachable `lockoutFailedEquipment()` can (§5) |
| All other fields (`equipmentName`, `assetTag`, `location`, `manufacturer`, `assignedToId`, `category`, `nextInspectionDate`) | Correct | `assignedToId` uses `EmployeeSelector` (proper lookup); `category` is a real dropdown; `nextInspectionDate` uses a real `showDatePicker`; `daysUntilInspection` is correctly computed at submit time rather than manually entered |

### Other
- **The module's main entry point is unreachable from its own launchpad tile** — `/equipment` has no matching route anywhere in `router.dart` (§4). This is the most severe single finding in this doc.
- **`AssetDetailScreen`'s edit button is a literal no-op** (`onPressed: () {}`) — a banned stub more blatant than the "coming soon" toast pattern seen elsewhere, since it gives no feedback at all.
- **`MaintenanceLogDialog` is entirely a static placeholder** misleadingly presented as a functional tab — AGENTS.md §3 banned-stub pattern.
- **The LOTO "lockout" write path is unreachable and the create form's status enum can't reach the one state the rest of the module is built to handle** — see §5's compound finding.
- Raw `ScaffoldMessenger.showSnackBar` in `loto_management_screen.dart` — AGENTS.md §1 violation, inconsistent with the correct `UIUtils.showToast` usage elsewhere in the same module.
- **IA/taxonomy conflict**: see [shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Was `/equipment` ever a registered route that got removed during a router refactor, or was the launchpad tile added ahead of the route and never followed up? Given `EquipmentManagementScreen` is otherwise complete and well-built, this reads as the single highest-value fix in this module — likely a one-line router addition.
- Should the create form's status dropdown include `'Locked Out'` (informational/read-only display state) or should it stay exclusively automation-driven via `lockoutFailedEquipment()` — and if the latter, where should that method actually be called from (a "Report Failure" button on `AssetDetailScreen`, perhaps, alongside fixing its empty edit button)?
- Should `MaintenanceLogDialog` be built out against the real `work_orders` collection it already gestures at, given `field_service` already owns a working `WorkOrder` model that `LotoAutomation` itself successfully writes to?
- Is `EquipmentManagementScreen`'s `initialSearch`/`highlightId` constructor support (deep-link-oriented, e.g. from a notification or search result) meant to be exercised by some other module or feature that doesn't exist yet, given nothing anywhere currently constructs the screen with those parameters?
