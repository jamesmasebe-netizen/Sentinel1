# field_service — Module Journey Doc

**Path:** `lib/features/field_service/`  |  **Compartment:** Field Service  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`field_service` is Sentinel1's Field Service module: work orders, technician dispatching, route planning, and customer asset/IoT tracking, modeled after the Dynamics-365-Field-Service-style schema in `docs/schema_field_service.md`. It is the primary home of the Field Service & Emergency Responder persona's "Field Dispatch" journey and a narrative participant in both Issue to Resolution and Asset Lifecycle.

**In scope:** work order CRUD + task checklists, dispatcher board, route planning/"optimization", customer asset registry, IoT device registry.
**Out of scope:** the Safety PTW/HIRA gating logic the schema doc treats as mandatory before work can start (documented in the schema, unimplemented in code — see §5/§7), emergency response itself (owned by `emergency`), technician HR records (owned by `people`).
**IA placement:** Field Service compartment (8-compartment taxonomy). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `field_service` | Entry screen(s) |
|---|---|---|---|
| [Field Service & Emergency Responder](_shared_personas_and_bpfs.md#persona-field-service-responder) (primary) | Field Dispatch (persona journey: Receive Work Order → Optimize Dispatcher Route → Service Customer Asset → Complete Action Form) | `field_service_hub_screen.dart` → `dispatcher_board_screen.dart` / `work_order_list_screen.dart` / `route_optimization_screen.dart` | `field_service_hub_screen.dart` |
| Supply Chain & Facilities Manager (secondary, [_shared doc](_shared_personas_and_bpfs.md#persona-scm-facilities-manager)) | Asset Lifecycle (narrative — Scheduled Maintenance → Dispatch Route → On-Site SHEQ Check) | `customer_asset_detail_screen.dart` | unreachable in practice (see §4) |

Worth stating up front: the reachable path (hub → dispatcher board / work order list / route optimization) is entirely hardcoded mock UI. The persona journey's "Service Customer Asset" and "Complete Action Form" steps have no working screen path behind them in this codebase.

## 3. BPF Participation
| BPF | Stage(s) this module implements | Code reference |
|---|---|---|
| [Issue to Resolution](_shared_personas_and_bpfs.md#bpf-issue-to-resolution) | Work Order → Field Dispatch or Mitigation → Resolution & Close | Narrative only — confirmed directly: `lib/core/bpf/issue_to_resolution_bpf.dart`'s 4 stages are tagged only `expectedRecordType: 'incident'`/`'capa'`, none reference `field_service` or `work_orders` |
| [Asset Lifecycle](_shared_personas_and_bpfs.md#bpf-asset-lifecycle) | Dispatch Route → On-Site Field Tech SHEQ Check (LOTO, Permit to Work verification) | Narrative only — confirmed directly: `lib/core/bpf/asset_lifecycle_bpf.dart`'s 4 stages (`acquisition`/`deployment`/`maintenance`/`decommissioning`) are tagged only `expectedRecordType: 'equipment'`, none reference `field_service` or `work_orders`. Per the [_shared doc](_shared_personas_and_bpfs.md#business-process-flows-bpfs), this BPF's orchestrator method `deployEquipment()` is itself an explicit stub |

`BpfRibbonWidget` usage: confirmed **absent** from this module (repo-wide grep scoped to `lib/features/field_service/` returned zero matches).

A real (non-BPF) LOTO tie-in does exist in code: `lib/core/automation/loto_automation.dart`, outside this module, writes directly into the `work_orders` collection — see §5/§6 for why this is a data-shape problem rather than a clean integration.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route or side-sheet | Purpose / wiring |
|---|---|---|
| `field_service_hub_screen.dart` | `/field-service` | Hub — 5 cards; 2 open real screens via `Navigator.push`, 2 ("Emergency Response", "Safety PTW Registry") are `destination: null` placeholders that just show a toast, 1 links to the route-optimization top-level route |
| `dispatcher_board_screen.dart` | `Navigator.push` from hub (AGENTS.md §1 violation — should be `showSideSheet`) | Fully hardcoded: 5 fake "Team Alpha" units, 3 fake unassigned work orders, map area is a static placeholder graphic; filter/emergency-alert/Assign buttons all unconfigured |
| `work_order_list_screen.dart` | `Navigator.push` from hub | 4 hardcoded work orders (fake PTW-required/PTW-completed flags); tapping navigates to `WorkOrderDetailsScreen` using the fake string ID (e.g. `'WO-2026-101'`); FAB and search icon unconfigured |
| `work_order_details_screen.dart` | `Navigator.push` from `work_order_list_screen.dart`, but fed a fake ID in practice (see §7) | **Real:** streams a `WorkOrder` + its `WorkOrderTask`s from Firestore via `FieldServiceService`; the Tasks tab writes checkbox toggles back to Firestore |
| `route_optimization_screen.dart` | `/route-optimization` (top-level route) | Fully hardcoded: 5 fake work orders with Johannesburg addresses; "Optimize Route" reverses the local list — no Cloud Function call (see §5) |
| `dispatcher_route_detail_screen.dart` | **unreachable** — no call site anywhere in `lib/` | **Real:** streams a `DispatcherRoute` from `route_plans` |
| `customer_asset_detail_screen.dart` | **unreachable** — no call site anywhere in `lib/` | **Real:** streams a `CustomerAsset` from `customer_assets`, including an IoT-device tie-in section |
| `widgets/work_order_form.dart` (`WorkOrderForm`) | **unreachable** — never instantiated anywhere in `lib/` | **Real:** full-field create/edit form wired to `FieldServiceService.createWorkOrder`/`updateWorkOrder` |
| `widgets/dispatcher_route_form.dart` (`DispatcherRouteForm`) | **unreachable** — same pattern | Exists, not instantiated anywhere |
| `widgets/customer_asset_form.dart` (`CustomerAssetForm`) | **unreachable** — same pattern | Exists, not instantiated anywhere |

## 5. Backend & Database

**Duplicate model name, two incompatible shapes.** This module defines `WorkOrder` twice:
| | `models/work_order.dart` | `models/field_service_models.dart` |
|---|---|---|
| Shape | Simple: `id, title, description, status, permitId, riskAssessmentId, contractorId, actionItemId, scheduledDate` | Rich, schema-aligned: `work_order_number, status, priority, customer_id, scheduling{}, safetyRequirements{}, iotContext{}, financials{}, …` (snake_case Firestore keys) |
| Used by | `providers/field_service_providers.dart`'s `workOrdersProvider` (a `StateProvider<List<WorkOrder>>([])`, itself never watched by any screen — dead code); `lib/core/automation/loto_automation.dart` (writes to `work_orders`) | `services/field_service_service.dart` and the 3 real detail screens (§4) |

Both target the **same** `work_orders` Firestore collection with incompatible field-name casing and shapes — see §7 for the concrete consequence.

**Other models — `field_service_models.dart`:** `WorkOrderTask` (sub-collection `work_orders/{id}/tasks`), `DispatcherRoute` (→ `route_plans`), `CustomerAsset` (→ `customer_assets`), `IotDevice` (→ `iot_devices`). `models/dispatcher.dart`'s `Dispatcher` (id/name/region/contactNumber) is a separate, much simpler class — not the schema doc's rich `technicians` collection, which has no Dart model at all.

**Schema coverage:** `docs/schema_field_service.md` documents ~20 collections across 7 areas (work orders + tasks/parts/services, agreements, technicians, dispatch territories, requirement groups, route plans + waypoints, geofences + events, IoT devices/readings/alerts/commands, warehouses + inventory, inventory journals, purchase orders, RMAs, `safety_hiras`, `safety_ptws`, customer tracking links). Code implements only 4 of these: `work_orders` (+`tasks`), `route_plans`, `customer_assets`, `iot_devices`. The entire §6 Safety & Compliance section of the schema doc (PTW/HIRA gating that's supposed to block a work order from starting) is aspirational only — `work_order_list_screen.dart`'s PTW warning banner is driven by hardcoded dummy booleans (`requiresPtw`/`ptwCompleted`), not a real `safety_requirements` map or `safety_ptws`/`safety_hiras` document; no code under this module references either collection.

**Firestore rules check:** `work_orders` (+ its `tasks` subcollection) **is** explicitly declared in `firestore.rules` (managers can create/update). `route_plans`, `customer_assets`, and `iot_devices` are **not** declared — they fall to the catch-all (`allow write: if false`), so `FieldServiceService`'s create/update methods for routes, assets, and IoT devices would be rejected by the deployed rules. Same pattern as `customer_service.md`'s finding, here scoped to 3 of the module's 4 implemented collections rather than nearly the whole module.

**Cloud Functions:**
- `iotEngine.ts`'s `iotTelemetryIngest` (an HTTP-triggered `onRequest` function, not client-callable — expected to be hit by external IoT gateways, not Flutter) auto-creates a `work_orders` document when a temperature reading exceeds 90, but writes it in the **simple** camelCase shape (`id, title, description, status: 'OPEN', scheduledDate, assetId, customerId`) rather than the rich snake_case shape `WorkOrderDetailsScreen` actually reads. A work order created this way would render with a blank WO number, blank customer (the function writes `customerId`, the reader expects `customer_id`), a default `'LOW'` priority, and a `status` of `'OPEN'` — a value that isn't even one of the 8 documented status enum values (`DRAFT`/`SCHEDULED`/`DISPATCHED`/`TRAVELING`/`IN_PROGRESS`/`ON_HOLD`/`COMPLETED`/`CANCELED`).
- `routingEngine.ts`'s `optimizeRoute` callable — despite its name and interface (`OptimizeRouteRequest`/`OptimizeRouteResponse`) — is itself a stub: its own code comment reads "Simulate a TSP solver by reversing the order of workOrderIds," and the implementation is literally `[...workOrderIds].reverse()`. This mirrors `route_optimization_screen.dart`'s client-side mock almost exactly (see §4), independently. Neither function is referenced anywhere under `lib/features/field_service/` (confirmed by grep for `optimizeRoute`/`routingEngine`/`httpsCallable`/`FirebaseFunctions`, which only matched the screen's own local method of the same name).

## 6. Cross-Module Links
- `lib/core/automation/loto_automation.dart` (outside this module) creates `work_orders` documents using the **simple** `WorkOrder` model — a real, if narrow, code-level tie to the Asset Lifecycle BPF's narrative LOTO step, but it targets an incompatible shape relative to this module's own rich model and real UI (see §5).
- Ticket (`customer_service`) ↔ Work Order: no code link found (see `customer_service.md` §6).
- **AppEventBus:** no usage found anywhere under `lib/features/field_service/`.
- `field_service_hub_screen.dart`'s "Emergency Response" card is a dead `destination: null` placeholder even though a working `/emergency` route exists elsewhere in the app (see `emergency.md`) — the hub simply doesn't link out to it.

## 7. Known Gaps

### Rules-vs-code gaps
- `route_plans`, `customer_assets`, `iot_devices` are absent from `firestore.rules`' explicit list → writes via `FieldServiceService` for these three collections are blocked by the catch-all as deployed (see §5). `work_orders` itself is correctly declared.
- `BaseIncident` (AGENTS.md §5) is not implemented anywhere in the codebase (per the [_shared doc](_shared_personas_and_bpfs.md#related-rules-vs-code-gap-applicable-wherever-relevant-below)); flagged here since `field_service` is named as one of the modules whose domain is conceptually incident-adjacent.

### DB-to-UI alignment audit
`work_order_form.dart` vs the rich `WorkOrder` model (this module's primary create/edit form):
| Field | Status | Note |
|---|---|---|
| `customerId`, `assetId`, `territoryId`, `billingAccountId`, `agreementId`, `incidentTypeId`, `serviceTypeId`, `substatusId` | **Wrong widget** | All plain `TextFormField`s despite being FK-style references to other collections/catalogs — the same pattern `crm.md` flagged for `opportunity_form.dart`'s `accountId`/`primaryContactId` |
| `assignedTechnicianId`, `dispatcherId` | Correct | Both use `EmployeeSelector`, a proper lookup widget |
| `status`, `priority` | **Wrong widget** | Free-text `TextFormField`s, even though the model documents these as fixed enums (8 and 4 values respectively); inconsistent with this same codebase's `customer_service/widgets/ticket_form.dart`, which uses dropdowns for its analogous `status`/`priority` fields |
| `address`, `scheduling`, `safetyRequirements`, `iotContext`, `financials` | **Wrong widget** | Each is a structured `Map<String, dynamic>` on the model, rendered as a raw multi-line "(JSON)" text field the user must hand-type correctly; a malformed entry throws an uncaught `FormatException` from `jsonDecode` at save time |
| `location` | Correct (acceptable) | Two decimal lat/lng `TextFormField`s construct a `GeoPoint` — reasonable given no map-picker widget exists in this codebase |

### Other
- The duplicate `WorkOrder` model/shape collision (§5) is the single most concrete data-integrity risk found in this module — three different code paths (`FieldServiceService`, `iotTelemetryIngest`, `loto_automation.dart`) write to the same `work_orders` collection, and two of the three use a shape the module's own detail screen can't read correctly.
- Same "two parallel implementations" pattern as `customer_service.md`: 3 real Firestore-backed detail screens and 1 real form exist, but only `WorkOrderDetailsScreen` has any navigation path to it at all — and even that path feeds it a hardcoded fake ID from `work_order_list_screen.dart`'s dummy data, so in practice it will only ever render "Work Order not found."
- `RouteOptimizationScreen`'s client-side "Optimize Route" (list reversal) and the backend `optimizeRoute` Cloud Function (also a list reversal, per its own comment) independently implement the identical fake behavior without being connected to each other.
- AGENTS.md §1 Deep Sub-Navigation and §3 Banned Stubs violations are listed inline in §4's table rather than repeated here (dispatcher board's filter/alert/Assign buttons, work order list's search/FAB, hub's 2 placeholder cards).

## 8. Open Questions
- Which `WorkOrder` shape is meant to be canonical — should `models/work_order.dart` and its two producers (`loto_automation.dart`, `iotTelemetryIngest`) migrate to the rich schema-aligned shape, or is the rich model ahead of what the rest of the app actually writes?
- Were `WorkOrderDetailsScreen`/`DispatcherRouteDetailScreen`/`CustomerAssetDetailScreen` and the three forms ever connected to `work_order_list_screen.dart`'s real data, or built ahead of the list screen and never wired back in?
- Is `optimizeRoute` intended to eventually host a real TSP/VRP solver (`docs/schema_field_service.md` explicitly describes route optimization as a first-class capability), or is the reversal a deliberate placeholder pending a future milestone?
