# supply_chain — Module Journey Doc

**Path:** `lib/features/supply_chain/`  |  **Compartment:** Supply Chain Management  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`supply_chain` is Sentinel1's inventory/warehouse/procurement/light-manufacturing module: inventory items, warehouses, purchase orders, transfer orders, sales orders (write-only, no UI), an Enterprise Asset Management (EAM) sub-area with its own `Asset` model, a Master Planning (MRP) engine, a WMS barcode scanner, and a Manufacturing (production order) screen. `docs/schema_scm.md` describes a much richer, Dynamics-365-competitive target schema (BOM versioning with sub-collection `bom_lines`, `warehouses/zones/locations` hierarchy, granular `inventory_levels` + append-only `inventory_transactions`, `mrp_runs`/`mrp_planned_orders`, `voyages`/`landed_costs`, `vendor_rebate_agreements`, `demand_forecasts`, `product_configurators`, `iot_devices`) — the actual Dart implementation covers only a subset, flattened into single collections rather than the doc's nested sub-collection design (details in §5).

**In scope:** inventory item CRUD, warehouse/PO/transfer-order CRUD, MRP shortage-suggestion generation, barcode scan UI, production order listing (mocked), EAM asset registry (`Asset`/`assets` — a second, `supply_chain`-owned asset concept distinct from the `equipment` module's `EquipmentModel`/`equipment` collection, see §6).
**Out of scope:** the actual equipment/maintenance domain (owned by `equipment`), property/facilities (owned by `property`), contractor-side procurement compliance (owned by `contractors`).
**IA placement:** Supply Chain Management compartment (8-compartment taxonomy). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `supply_chain` | Entry screen(s) |
|---|---|---|---|
| [Supply Chain & Facilities Manager](_shared_personas_and_bpfs.md#persona-scm-facilities-manager) (primary) | Procurement & Inventory: Generate Purchase Order → Approve Transfer Order → Update Inventory Item → Auto-generate AP Invoice | `supply_chain_hub_screen.dart` (reachable, `/supply-chain`) → `inventory_dashboard.dart`/`warehouse_management_screen.dart`/`asset_management_screen.dart` (all static placeholders, see §4) — the actual PO/inventory/transfer **create/edit forms and detail screens are unreachable from any navigation path** (confirmed by repo-wide grep, see §4/§7) |
| Finance Controller (secondary) | Procure to Pay's AP-invoice step | `BpfOrchestrator.createInvoiceFromPurchaseOrder()` exists but has zero call sites anywhere in the app (§3) |
| Environmental & Sustainability Officer (secondary) | "Conduct Waste Disposal Audits (cross-referenced with Supply Chain inventory)" per [shared doc](_shared_personas_and_bpfs.md#persona-environmental-officer) | **No code relationship found** — grepped both directions between `lib/features/environment/` and `lib/features/supply_chain/`, zero matches. Narrative-only |
| Field Service & Emergency Responder (via IoT) | n/a | `iotEngine.ts`'s `iotTelemetryIngest` (checked per this doc's brief) writes to `customer_assets`/`work_orders`, **not** to any `supply_chain` collection (`inventory_items`/`assets`/`warehouses`) — not actually relevant to this module despite the naming adjacency; more plausibly a `field_service`/`customer_service` concern |

The two real, working entry points into this module's live functionality are actually reached **directly from the launchpad**, not through the module's own hub: `/mrp-dashboard` ("Master Planning" tile) and `/wms-scanner` ("WMS Scanner" tile), both siblings of the "Supply Chain" tile itself under the launchpad's "Supply Chain Management" section (`business_os_launchpad.dart:58-81`). The "Supply Chain" tile's own hub screen does not link to either of them (§4).

## 3. BPF Participation
| BPF | Stage(s) this module implements (narrative) | Code reference |
|---|---|---|
| [Procure to Pay](_shared_personas_and_bpfs.md#bpf-procure-to-pay) | Purchase Order Creation → Goods Receipt (narrative only) → AP Invoice (partially wired, see below) | `lib/core/bpf/procure_to_pay_bpf.dart` (5 stages: requisition/purchase_order/goods_receipt/ap_invoice/payment, `expectedRecordType: 'purchase_order'`/`'invoice'`) |
| [Asset Lifecycle](_shared_personas_and_bpfs.md#bpf-asset-lifecycle) | Narrative module-list entry only | `asset_lifecycle_bpf.dart`'s 4 stages are all `expectedRecordType: 'equipment'` — this doesn't match `supply_chain`'s own `Asset`/`assets` model at all; `equipment` module is the real record-type owner (per this doc's brief), not `supply_chain` |

**Implementation-depth confirmation, verified directly:** `PurchaseOrderDetailScreen` (`purchase_order_detail_screen.dart:48-53`) does contain a real `BpfRibbonWidget` (`bpfTypeId: 'procure_to_pay'`, `recordType: 'purchase_order'`, `definition: procureToPayDefinition`) — so the ribbon-widget wiring the [shared doc](_shared_personas_and_bpfs.md#business-process-flows-bpfs) asks to check for genuinely exists in this module's code, unlike `emergency`'s confirmed-absent case. **But this is moot in practice**: `PurchaseOrderDetailScreen` itself has zero navigation call sites anywhere in `lib/` (confirmed by grep, see §4) — no route, no `Navigator.push`, no side-sheet trigger references it — so no user can ever see this ribbon render. Separately, `BpfOrchestrator.createInvoiceFromPurchaseOrder()` (the one method the shared doc credits as "partially wired") also has **zero call sites anywhere** outside its own definition — confirmed by grep of `bpfOrchestratorProvider`/`BpfOrchestrator` across all 4 of this session's modules, zero matches. So while the orchestrator method itself performs a real Firestore write when called, nothing in the shipped UI ever calls it — "wired in the orchestrator" and "reachable by a user" are two different claims here, and only the first is true.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route or entry point | Purpose / wiring |
|---|---|---|
| `supply_chain_hub_screen.dart` (`SupplyChainHubScreen`) | `/supply-chain` (launchpad "Supply Chain" tile) | 2x2+1 grid; each card uses `Navigator.push`/`MaterialPageRoute` directly to open a sub-screen — an AGENTS.md §1 "Deep Sub-Navigation" violation (rule requires `UIUtils.showSideSheet` from hub screens, not `Navigator.push`) |
| `inventory_dashboard.dart` (`InventoryDashboard`) | Hub card "Inventory / MRP" | **Fully static** `StatelessWidget` — 3 hardcoded `ListTile`s with fake numbers ("3 items below minimum threshold," "5 pending approval") and no `onTap` handlers at all. AGENTS.md §2 "No Hardcoded Data" violation |
| `warehouse_management_screen.dart` (`WarehouseManagementScreen`) | Hub card "Warehouse Mgmt" | **Fully static** `StatelessWidget` — 3 hardcoded `ListTile`s, no Firestore, no `onTap` |
| `asset_management_screen.dart` (`AssetManagementScreen`) | Hub card "Enterprise Asset Mgmt" | **Fully static** `StatelessWidget` — 4 hardcoded `ListTile`s, no Firestore, no `onTap` |
| (inline in hub) "Vendor Performance" / "Bin Locations" | Hub cards | Literal `Center(child: Text('... — Coming Soon'))` — AGENTS.md §3 banned-stub pattern |
| `mrp_dashboard_screen.dart` (`MrpDashboardScreen`) | `/mrp-dashboard` (launchpad "Master Planning" tile — **not** linked from the hub) | **Real**: streams `mrp_suggestions` live, "Run MRP Analysis" button calls Cloud Function `runMrp` via `httpsCallable`. Uses raw `ScaffoldMessenger.showSnackBar` (AGENTS.md §1 violation, not `UIUtils.showToast`). Each suggestion's "Create {type}" button is an explicit `// TODO: Convert to Purchase Order / Prod Order` banned-stub showing "Conversion to PO coming soon..." |
| `wms_scanner_screen.dart` (`WmsScannerScreen`) | `/wms-scanner` (launchpad "WMS Scanner" tile — not linked from the hub) | Real camera barcode scan (`mobile_scanner`); on detect, its own code comment says "Simulate fetching WMS logic," then shows a dialog reading "Perform picking or packing action here" — no Firestore read/write ever occurs |
| `production_order_screen.dart` (`ProductionOrderScreen`) | `/manufacturing` (launchpad "Manufacturing" tile — not linked from the hub) | **Mocked**: own code comment "In a real app, this would be a stream from Firestore," backed by a hardcoded `_mockProductionOrders` list, not the real `ProductionOrder` model (§5). "New Order" and "Complete Order" both just show toasts (raw `ScaffoldMessenger`) — "Complete Order" claims "Inventory updated" but performs no write |
| `inventory_item_detail_screen.dart` (`InventoryItemDetailScreen`) | **None** — zero call sites anywhere in `lib/` (confirmed by grep) | Orphaned; real Firestore stream wiring (`inventoryItemStreamProvider`), never reachable |
| `purchase_order_detail_screen.dart` (`PurchaseOrderDetailScreen`) | **None** — zero call sites anywhere in `lib/` | Orphaned; contains the module's only `BpfRibbonWidget` usage (§3), never reachable |
| `transfer_order_detail_screen.dart` (`TransferOrderDetailScreen`) | **None** — zero call sites anywhere in `lib/` | Orphaned |
| `widgets/inventory_item_form.dart` (`InventoryItemForm`) | **None** — zero call sites anywhere in `lib/` | Orphaned create/edit form, defensive-write pattern correctly implemented (`isLoading`, try/catch) but unreachable |
| `widgets/purchase_order_form.dart` (`PurchaseOrderForm`) | **None** — zero call sites anywhere in `lib/` | Orphaned, same pattern |
| `widgets/transfer_order_form.dart` (`TransferOrderForm`) | **None** — zero call sites anywhere in `lib/` | Orphaned, same pattern |

Net effect: of 12 screens/forms in this module, only 4 (`SupplyChainHubScreen`, `MrpDashboardScreen`, `WmsScannerScreen`, `ProductionOrderScreen`) are reachable from any in-app navigation path, and of those 4, only `MrpDashboardScreen` does real Firestore/Cloud-Function work. The 3 create/edit forms that would be this module's primary write paths are all unreachable dead code (audited anyway in §7 per this doc's brief, since they're the closest thing to "primary forms" this module has).

## 5. Backend & Database

**Models:**
| Model | File | Key fields | Collection |
|---|---|---|---|
| `InventoryItem` | `models/scm_models.dart` | sku, name, itemType, unitOfMeasure, valuationMethod, leadTimeDays, safetyStock, reorderPoint, isConfigurable, isActive, lifecycleStatus, stockLevel, warehouseId?, aisle?, rack?, bin? | `inventory_items` |
| `Warehouse` | `models/scm_models.dart` | name, code, type, address, managerId?, status | `warehouses` |
| `PurchaseOrder` + `PurchaseOrderLine` | `models/scm_models.dart` | poNumber, vendorId?, warehouseId?, status, orderDate?, expectedDeliveryDate?, currency, totalAmount | `purchase_orders` (+ subcollection `po_lines`) |
| `Asset` | `models/scm_models.dart` | assetTag, name, category, serialNumber, manufacturer, model, status, warehouseId?, locationId?, financials? | `assets` |
| `SalesOrder` | `models/scm_models.dart` | orderNumber, accountId, status, orderDate?, totalAmount | `sales_orders` |
| `TransferOrder` | `models/scm_models.dart` | orderNumber, sourceLocation, destinationLocation, status, orderDate? | `transfer_orders` |
| `WarehouseBinLocation` | `models/scm_models.dart` | warehouseId, binCode, aisle, rack, level, zone, itemId?, currentQuantity, maxCapacity, isActive | `warehouseBinLocations` |
| `VendorPerformanceMetric` | `models/scm_models.dart` | vendorId, vendorName, period, onTimeDeliveryRate, qualityRejectionRate, avgLeadTimeDays, totalSpend, rating | `vendorPerformanceMetrics` |
| `MrpSuggestion` | `models/scm_models.dart` | itemId, suggestedQuantity, type, status, reason | `mrp_suggestions` |
| `BillOfMaterials` + `BomLine` | `models/bom_model.dart` | finishedGoodItemId, name, lines[] (embedded array, **not** a Firestore sub-collection despite `docs/schema_scm.md` specifying `bom_lines` as one) | **No collection — confirmed dead**, no service/provider anywhere reads or writes `boms` |
| `ProductionOrder` | `models/production_order.dart` | bomId, finishedGoodItemId, quantityToProduce, quantityProduced, status, warehouseId | **No collection — confirmed dead**, no service/provider anywhere reads or writes `production_orders`; `ProductionOrderScreen` uses a hardcoded mock instead of this class (§4) |

**Reachability of `ScmService` CRUD, checked method-by-method via repo-wide grep:** `streamAssets`/`getAssets`/`createAsset`/`updateAsset`/`deleteAsset` (Asset), `streamWarehouses`/`getWarehouses`/`createWarehouse` (Warehouse), `streamVendorPerformanceMetrics`/`getVendorPerformanceMetrics`, `streamBinLocations`/`getBinLocations` — **all confirmed to have zero callers anywhere outside `scm_service.dart` itself.** (A `createAsset`/`streamAssets` match in `customer_service_service.dart` is an unrelated same-named method on a different class/`CsAsset` model — false positive, checked directly.) Only `createSalesOrder` has a real external caller: `LeadToCashAutomation.triggerOpportunityWon()` (§6) — itself also unreachable. Inventory item, purchase order, and transfer order CRUD are reachable only through the orphaned forms in §4.

**Firestore naming/rules check — the drift the task brief asked to verify, confirmed directly:** `ScmService._inventoryRef` (`scm_service.dart:19`) and `scm_streams_provider.dart:9` both hard-code `.collection('inventory_items')`. `firestore.rules` declares `match /inventory/{itemId}` (singular, no `_items` suffix) — **a different collection name.** Nothing in the Dart codebase ever queries `.collection('inventory')` (confirmed by grep) — the rules entry for `inventory` matches zero real code paths, while the collection the code actually uses (`inventory_items`) is undeclared and falls to the tenant-scoped catch-all (`allow write: if false`). **Net effect: if `InventoryItemForm` were ever wired up and reachable, its writes would be rejected by the deployed rules as committed** — compounding, not curing, its reachability problem from §4. `warehouses`, `assets`, `sales_orders`, `transfer_orders`, `mrp_suggestions`, `warehouseBinLocations`, `vendorPerformanceMetrics`, and `boms` are likewise all undeclared in `firestore.rules` — only `purchase_orders` (declared, manager-gated) matches between code and rules for this module.

**Cloud Functions (`firebase/functions/src/`):**
- `mrpEngine.ts`'s `runMrp` (exported via `index.ts:568`, real, called from `MrpDashboardScreen` per §4) reads `inventory_items` (agreeing with the Dart client on collection name, not with `firestore.rules`) and `sales_orders` (filtered `status in ['OPEN','CONFIRMED']`, expecting a `lines: [{itemId, quantity}]` array). **Three-way field-name mismatch, confirmed by reading all three sources directly:** the schema doc names the on-hand-quantity field `quantity_on_hand` (on a separate `inventory_levels` collection); the Dart `InventoryItem` model calls it `stock_level`/`stockLevel`; `runMrp` reads it off the same doc as `data.quantityOnHand` (camelCase, no such key ever written by Dart). Since `inventoryMap[itemId]` therefore always reads as `0`, and since no UI anywhere ever creates a `sales_orders` document with a `lines` array (`SalesOrder` model has no `lines` field at all, and `ScmService.createSalesOrder`'s only caller writes `totalAmount` with no line items — see §6), `runMrp`'s supply-vs-demand comparison is starved of correctly-shaped data on **both** sides — it is reachable and executes without error, but is structurally unable to produce a meaningful suggestion.
- `iotEngine.ts`'s `iotTelemetryIngest` — checked per this doc's brief for relevance: not relevant to this module. It's an `onRequest` HTTP webhook (not called via Dart `httpsCallable` at all) that writes to `customer_assets`/`work_orders`, neither of which is a `supply_chain`-owned collection.

## 6. Cross-Module Links
- `lib/core/bpf/bpf_orchestrator.dart` imports `ScmService`/`scm_models.dart` and defines `createInvoiceFromPurchaseOrder()` — real code, zero callers (§3).
- `lib/core/automation/lead_to_cash_automation.dart` — a **second, separate** "Won Opportunity" handler (distinct from both `BpfOrchestrator` and whatever `crm`'s own service does), calling `ScmService.createSalesOrder()` + `FinanceService.createInvoice()` directly from a `triggerOpportunityWon(Opportunity)` method. **Confirmed by grep: `triggerOpportunityWon`/`leadToCashAutomationProvider` have zero call sites anywhere** — a third, independently-built integration point for the same cross-module event, also never wired to a UI action (no "Mark Opportunity as Won" button calls it).
- `lib/features/operations/services/inventory_service.dart` defines its own unrelated `streamWarehouses()` on a same-named-but-different `Warehouse` concept — a second, `operations`-owned warehouse abstraction that doesn't share code with this module's `ScmService.Warehouse`. Not investigated further (out of scope — `operations` is not one of this doc's 4 assigned modules), flagged only as a naming collision worth knowing about.
- **AppEventBus:** zero usage anywhere in `lib/features/supply_chain/` (confirmed by grep) — no event fires on PO status change, inventory shortage, or asset registration, and this module listens for nothing either.
- No code relationship with `environment` despite the Environmental & Sustainability Officer's secondary persona assignment here (§2).

## 7. Known Gaps

### Rules-vs-code gaps
- `inventory_items` (the collection the code actually uses) vs `inventory` (what `firestore.rules` declares) — full detail in §5. The rules entry is effectively unused configuration; the real collection is unprotected/write-blocked by the catch-all.
- `warehouses`, `assets`, `sales_orders`, `transfer_orders`, `mrp_suggestions`, `warehouseBinLocations`, `vendorPerformanceMetrics`, `boms` — none declared in `firestore.rules`; all fall to the tenant catch-all's `allow write: if false` (§5).
- `BaseIncident` — not applicable, no incident concept in this module.

### DB-to-UI alignment audit
Audited per this doc's brief despite being unreachable (§4), since they're the module's only create/edit forms. `inventory_item_form.dart` vs `InventoryItem`:
| Field | Status | Note |
|---|---|---|
| `warehouseId` / `aisle` / `rack` / `bin` | **Missing** | All 4 bin-location fields exist on the model, none appear anywhere in the form — an item can never be assigned a storage location through this form |
| `itemType` | **Wrong widget** | Plain `TextFormField`; `docs/schema_scm.md` specifies this as an enum (`RAW_MATERIAL`/`COMPONENT`/`SUB_ASSEMBLY`/`FINISHED_GOOD`/`CONSUMABLE`/`ASSET`) — no dropdown, unlike `lifecycleStatus` in the same form which correctly uses one |
| `valuationMethod` | **Wrong widget** | Plain `TextFormField`; schema doc specifies enum (`FIFO`/`LIFO`/`AVERAGE_COST`/`STANDARD_COST`) — same gap |
| `lifecycleStatus` | Correct | `DropdownButtonFormField` with the schema doc's 3 (of 4) values (missing `OBSOLETE`, has an extra `In Development` not in the schema doc's enum — minor drift, not flagged as a full row) |

`purchase_order_form.dart` vs `PurchaseOrder`:
| Field | Status | Note |
|---|---|---|
| `vendorId` | **Wrong widget** | Plain `TextFormField` — foreign key to a vendor record, no lookup — the same pattern `crm.md` and `people.md` both flagged in their own forms |
| `warehouseId` | **Wrong widget** | Plain `TextFormField` — foreign key to `warehouses`, no lookup |
| `status` | Correct | `DropdownButtonFormField` |
| `orderDate` / `expectedDeliveryDate` | Correct | Real `showDatePicker` |
| PO line items | **Missing entirely** | No sub-form exists anywhere for `po_lines` — a Purchase Order can be created with a header only; `PurchaseOrderDetailScreen`'s "PO Lines" tab is read-only display, and no widget in this module ever writes to the `po_lines` sub-collection |

### Other
- **Module's own hub screen shows entirely static/fabricated content**: `InventoryDashboard`, `WarehouseManagementScreen`, `AssetManagementScreen` are hardcoded `ListTile`s with fake numbers and no `onTap` handlers at all — AGENTS.md §2 "No Hardcoded Data" violated by the very first screens a user reaches from the "Supply Chain" tile.
- **`SupplyChainHubScreen` uses `Navigator.push`/`MaterialPageRoute`** instead of `UIUtils.showSideSheet` — AGENTS.md §1 violation.
- **Two literal "Coming Soon" stub cards** (Vendor Performance, Bin Locations) on the hub screen — AGENTS.md §3 banned-stub pattern, despite both having full `ScmService` CRUD already written and unused (§5).
- **`ProductionOrderScreen` is fully mocked** with an explicit "would be a stream from Firestore" code comment, and its "Complete Order" action falsely claims "Inventory updated" via toast without writing anything.
- **MRP engine's supply and demand inputs are both structurally unreachable/mismatched** — see §5's three-way field-name mismatch (`quantity_on_hand`/`stock_level`/`quantityOnHand`) and the missing `sales_orders.lines` UI.
- **3 detail screens + 3 forms + `PurchaseOrderDetailScreen`'s BPF ribbon are all orphaned** — real, defensively-written code with zero navigation call sites (§3/§4).
- **`BillOfMaterials`/`BomLine`/`ProductionOrder` model classes are fully dead** — no service, provider, or screen anywhere reads or writes their collections (§5).
- **`LeadToCashAutomation` (a third "Won Opportunity" handler) is dead code** — zero call sites (§6).
- Raw `ScaffoldMessenger.showSnackBar` used directly in `mrp_dashboard_screen.dart` and `production_order_screen.dart` instead of `UIUtils.showToast` — AGENTS.md §1 violation, same pattern `billing.md` flagged.
- **IA/taxonomy conflict**: see [shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Were the 3 detail screens + 3 forms (`InventoryItemDetailScreen`, `PurchaseOrderDetailScreen`, `TransferOrderDetailScreen`, `InventoryItemForm`, `PurchaseOrderForm`, `TransferOrderForm`) ever wired to the hub screen and later disconnected, or built ahead of the hub UI and never connected? The hub screen's own cards route to entirely different, static placeholder widgets instead.
- Should `SupplyChainHubScreen`'s "Inventory / MRP" card link to the real `MrpDashboardScreen` (already built, already routed at `/mrp-dashboard`) instead of the static `InventoryDashboard`? They currently coexist as two unconnected "MRP" surfaces.
- Is the `inventory_items`/`inventory` naming drift a rules bug (rules should say `inventory_items`) or a code bug (code should say `inventory`)? Same class of question `billing.md`/`emergency.md` raised for their own path mismatches.
- Should `supply_chain`'s `Asset`/`assets` (EAM) be merged with `equipment`'s `EquipmentModel`/`equipment`, given both conceptually serve the Asset Lifecycle BPF's `expectedRecordType: 'equipment'` and neither is a clean match on its own?
- Is `docs/schema_scm.md`'s much richer schema (BOM sub-collections, `inventory_levels`, `mrp_runs`, `voyages`, vendor rebates, `demand_forecasts`, `product_configurators`, `iot_devices`) an aspirational roadmap for this module, or documentation that has drifted ahead of a deliberately simpler implementation?
