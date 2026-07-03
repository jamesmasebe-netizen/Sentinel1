# Supply Chain & Manufacturing (SCM) Database Schema

This document outlines an exhaustive, enterprise-grade NoSQL (Firestore) database schema designed for the Supply Chain & Manufacturing pillar. It is structured to handle granular operations including MRP (Material Requirements Planning), Warehouse Management, BOMs (Bill of Materials), Inventory Tracking, and Asset Management, competitive with systems like Dynamics 365 SCM.

---

## 1. Inventory & Catalog Management

### Collection: `inventory_items`
Central catalog for all items moving through the supply chain (Raw Materials, WIP, Finished Goods, Consumables, Assets).

- **Document ID**: Auto-generated (or explicit SKU/UUID)
- **Fields**:
  - `sku` (string): Unique Stock Keeping Unit.
  - `name` (string): Item name.
  - `description` (string): Detailed description.
  - `item_type` (string/enum): `RAW_MATERIAL`, `COMPONENT`, `SUB_ASSEMBLY`, `FINISHED_GOOD`, `CONSUMABLE`, `ASSET`.
  - `unit_of_measure` (string): e.g., `EA`, `KG`, `L`, `M`.
  - `weight` (map): `{ value: double, unit: string }`
  - `dimensions` (map): `{ length: double, width: double, height: double, unit: string }`
  - `valuation_method` (string/enum): `FIFO`, `LIFO`, `AVERAGE_COST`, `STANDARD_COST`.
  - `standard_cost` (map): `{ value: double, currency: string }`
  - `lead_time_days` (int): Average lead time for procurement or production.
  - `safety_stock` (double): Minimum stock level required.
  - `reorder_point` (double): Stock level at which a replenishment order is triggered.
  - `is_active` (boolean): Active status.
  - `lifecycle_status` (string/enum): `DESIGN`, `ACTIVE`, `PHASE_OUT`, `OBSOLETE`.
  - `created_at` (timestamp)
  - `updated_at` (timestamp)

---

## 2. Bill of Materials (BOM) & Engineering

### Collection: `boms`
Defines the ingredients and quantities required to manufacture a product.

- **Document ID**: Auto-generated
- **Fields**:
  - `finished_good_id` (reference): Reference to `inventory_items` doc.
  - `version` (string): BOM version (e.g., "v1.0", "v1.1").
  - `status` (string/enum): `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `ARCHIVED`.
  - `approved_by` (reference): Reference to user doc.
  - `approved_at` (timestamp)
  - `effective_start_date` (timestamp)
  - `effective_end_date` (timestamp)
  - `created_at` (timestamp)
  - `updated_at` (timestamp)

#### Sub-collection: `bom_lines`
Specific components required within a BOM.
- **Document ID**: Auto-generated
- **Fields**:
  - `line_number` (int): Sequencing.
  - `component_id` (reference): Reference to `inventory_items` doc.
  - `quantity_required` (double)
  - `unit_of_measure` (string)
  - `scrap_percentage` (double): Expected scrap rate during production.
  - `lead_time_offset_days` (int): When this component is needed relative to the production start date.
  - `is_phantom` (boolean): If true, this is a transient sub-assembly not stocked in inventory.

---

## 3. Warehouse Management System (WMS) & Inventory Tracking

### Collection: `warehouses`
Physical and logical facilities.

- **Document ID**: Auto-generated
- **Fields**:
  - `name` (string)
  - `code` (string): e.g., "WH-NY-01".
  - `type` (string/enum): `MANUFACTURING_PLANT`, `DISTRIBUTION_CENTER`, `RETAIL_STORE`, `VIRTUAL`.
  - `address` (map): `{ street, city, state, zip, country, coordinates: geopoint }`
  - `manager_id` (reference): Reference to user doc.
  - `status` (string/enum): `ACTIVE`, `INACTIVE`.

#### Sub-collection: `zones`
Logical groupings within a warehouse.
- **Document ID**: Auto-generated
- **Fields**:
  - `name` (string)
  - `type` (string/enum): `RECEIVING`, `STORAGE`, `PICKING`, `PACKING`, `SHIPPING`, `QA`.
  - `climate_controlled` (boolean)

#### Sub-collection: `locations` (Bins/Aisles)
The most granular tracking level.
- **Document ID**: Auto-generated
- **Fields**:
  - `zone_id` (reference): Reference to parent `zones` doc.
  - `location_code` (string): Formatted code (e.g., "A-12-04-B" for Aisle A, Rack 12, Shelf 04, Bin B).
  - `barcode` (string): Scannable barcode/QR.
  - `aisle` (string)
  - `rack` (string)
  - `shelf` (string)
  - `bin` (string)
  - `capacity` (map): `{ max_weight: double, max_volume: double }`
  - `status` (string/enum): `AVAILABLE`, `FULL`, `LOCKED_FOR_COUNT`, `DAMAGED`.

### Collection: `inventory_levels`
Real-time tracking of item quantities at specific locations. To avoid write contention, these docs are highly granular.

- **Document ID**: Composite ID or Auto-generated
- **Fields**:
  - `item_id` (reference): Reference to `inventory_items`.
  - `warehouse_id` (reference): Reference to `warehouses`.
  - `location_id` (reference): Reference to `warehouses/{wh}/locations/{loc}`.
  - `batch_number` (string): For batch-tracked items.
  - `serial_number` (string): For serialized items.
  - `quantity_on_hand` (double): Physical count.
  - `quantity_allocated` (double): Reserved for orders.
  - `quantity_available` (double): `quantity_on_hand` - `quantity_allocated`.
  - `expiration_date` (timestamp): For perishable goods.
  - `last_counted_at` (timestamp): Last cycle count date.

### Collection: `inventory_transactions`
Append-only ledger for all inventory movements.

- **Document ID**: Auto-generated
- **Fields**:
  - `transaction_type` (string/enum): `RECEIPT`, `ISSUE`, `TRANSFER`, `ADJUSTMENT`, `CYCLE_COUNT`.
  - `item_id` (reference)
  - `quantity` (double)
  - `from_warehouse_id` (reference)
  - `from_location_id` (reference)
  - `to_warehouse_id` (reference)
  - `to_location_id` (reference)
  - `reference_document_type` (string): `SALES_ORDER`, `PURCHASE_ORDER`, `PRODUCTION_ORDER`.
  - `reference_document_id` (string)
  - `user_id` (reference): Who performed the transaction.
  - `timestamp` (timestamp)

---

## 4. Material Requirements Planning (MRP)

### Collection: `mrp_runs`
Records of planning algorithms executed.

- **Document ID**: Auto-generated
- **Fields**:
  - `run_date` (timestamp)
  - `horizon_start_date` (timestamp)
  - `horizon_end_date` (timestamp)
  - `status` (string/enum): `STARTED`, `COMPLETED`, `FAILED`.
  - `parameters` (map): Settings used during the run.

#### Sub-collection: `mrp_planned_orders`
The output of the MRP run: recommendations for purchasing, transferring, or manufacturing.
- **Document ID**: Auto-generated
- **Fields**:
  - `item_id` (reference)
  - `order_type` (string/enum): `PRODUCTION`, `PURCHASE`, `TRANSFER`.
  - `quantity_required` (double)
  - `required_date` (timestamp)
  - `suggested_start_date` (timestamp)
  - `status` (string/enum): `PLANNED`, `FIRM`, `CONVERTED`, `CANCELED`.
  - `source_demand_type` (string): What triggered this (e.g., `SALES_ORDER`, `SAFETY_STOCK_SHORTAGE`).
  - `source_demand_id` (string)
  - `converted_to_id` (string): ID of the PO or Production Order once firmed.

---

## 5. Manufacturing Execution & Production

### Collection: `production_orders`
Execution of manufacturing processes.

- **Document ID**: Auto-generated
- **Fields**:
  - `order_number` (string): Human-readable ID.
  - `bom_id` (reference): Reference to the specific `boms` version.
  - `item_id` (reference): The Finished Good being produced.
  - `warehouse_id` (reference): Where production occurs.
  - `quantity_planned` (double)
  - `quantity_produced` (double)
  - `quantity_scrapped` (double)
  - `status` (string/enum): `PLANNED`, `RELEASED`, `IN_PROGRESS`, `COMPLETED`, `CANCELED`.
  - `scheduled_start_date` (timestamp)
  - `scheduled_end_date` (timestamp)
  - `actual_start_date` (timestamp)
  - `actual_end_date` (timestamp)

#### Sub-collection: `routing_steps` (Operations)
Steps required to complete the production.
- **Document ID**: Auto-generated
- **Fields**:
  - `step_number` (int)
  - `operation_name` (string): e.g., "Cutting", "Assembly", "QA".
  - `work_center_id` (reference): Reference to `assets` or logical work center.
  - `estimated_time_minutes` (int)
  - `actual_time_minutes` (int)
  - `status` (string/enum): `PENDING`, `IN_PROGRESS`, `COMPLETED`.
  - `completed_by` (reference)

---

## 6. Enterprise Asset Management (EAM)

### Collection: `assets`
Absorbs Property, Plant, Equipment, Tooling, and Vehicles.

- **Document ID**: Auto-generated
- **Fields**:
  - `asset_tag` (string): Internal tracking number.
  - `name` (string)
  - `category` (string/enum): `MACHINERY`, `VEHICLE`, `IT_EQUIPMENT`, `FACILITY`, `TOOLING`.
  - `serial_number` (string)
  - `manufacturer` (string)
  - `model` (string)
  - `status` (string/enum): `AVAILABLE`, `IN_USE`, `UNDER_MAINTENANCE`, `RETIRED`.
  - `warehouse_id` (reference): Current location.
  - `location_id` (reference): Specific bin/zone if applicable.
  - `financials` (map):
    - `purchase_date` (timestamp)
    - `purchase_price` (map): `{ value, currency }`
    - `salvage_value` (map): `{ value, currency }`
    - `depreciation_method` (string/enum): `STRAIGHT_LINE`, `DOUBLE_DECLINING`.
    - `useful_life_months` (int)
  - `created_at` (timestamp)
  - `updated_at` (timestamp)

#### Sub-collection: `maintenance_schedules`
Preventative maintenance logic.
- **Document ID**: Auto-generated
- **Fields**:
  - `title` (string): e.g., "Monthly Oil Change".
  - `frequency_type` (string/enum): `TIME_BASED`, `USAGE_BASED`.
  - `interval_days` (int): If time-based.
  - `interval_usage_metric` (string): e.g., "Hours_Run", "Miles".
  - `interval_usage_value` (double): If usage-based.
  - `next_due_date` (timestamp)

#### Sub-collection: `maintenance_work_orders`
Records of preventative and corrective maintenance executed.
- **Document ID**: Auto-generated
- **Fields**:
  - `type` (string/enum): `PREVENTATIVE`, `CORRECTIVE`, `BREAKDOWN`.
  - `description` (string)
  - `reported_issue` (string)
  - `status` (string/enum): `OPEN`, `IN_PROGRESS`, `COMPLETED`, `CANCELED`.
  - `assigned_technician_id` (reference)
  - `scheduled_date` (timestamp)
  - `completed_date` (timestamp)
  - `cost` (map): `{ labor: double, parts: double, currency: string }`
  - `downtime_minutes` (int)
