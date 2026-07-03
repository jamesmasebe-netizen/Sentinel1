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
  - `is_configurable` (boolean): Flag for items driven by a Product Configurator (Configure-to-Order).
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
  - `is_ai_optimized` (boolean): Indicates if advanced ML demand forecasting was used.
  - `ml_model_reference` (string): e.g., "AzureML-Prophet-v2".

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

---

## 7. Procurement, Sourcing & Landed Cost Tracking

### Collection: `purchase_orders`
Tracks inbound procurement from vendors.

- **Document ID**: Auto-generated
- **Fields**:
  - `po_number` (string): Human-readable ID.
  - `vendor_id` (reference): Reference to `vendors` (CRM/ERP).
  - `warehouse_id` (reference): Destination warehouse.
  - `status` (string/enum): `DRAFT`, `APPROVED`, `CONFIRMED`, `IN_TRANSIT`, `RECEIVED`, `INVOICED`.
  - `order_date` (timestamp)
  - `expected_delivery_date` (timestamp)
  - `currency` (string)
  - `total_amount` (double)

#### Sub-collection: `po_lines`
Specific items ordered.
- **Document ID**: Auto-generated
- **Fields**:
  - `item_id` (reference): Reference to `inventory_items`.
  - `quantity_ordered` (double)
  - `quantity_received` (double)
  - `unit_price` (double)

### Collection: `voyages` (Landed Cost Tracking)
Groups multiple purchase orders or containers into a single transit voyage to accurately allocate complex overhead costs (freight, customs, insurance) down to the item level, enhancing margin visibility.

- **Document ID**: Auto-generated
- **Fields**:
  - `voyage_number` (string)
  - `vessel_name` (string)
  - `journey_template_id` (string): Predefined route (e.g., "Shanghai to LA").
  - `departure_port` (string)
  - `arrival_port` (string)
  - `eta` (timestamp)
  - `status` (string/enum): `CREATED`, `AT_PORT`, `SAILING`, `CUSTOMS`, `DELIVERED`.

#### Sub-collection: `landed_costs`
Overhead costs applied to the voyage to calculate true item profitability.
- **Document ID**: Auto-generated
- **Fields**:
  - `cost_type` (string/enum): `FREIGHT`, `DUTY`, `INSURANCE`, `HANDLING`.
  - `allocation_method` (string/enum): `BY_QUANTITY`, `BY_VALUE`, `BY_WEIGHT`, `BY_VOLUME`.
  - `amount` (double)
  - `currency` (string)
  - `vendor_id` (reference): Service provider for this cost.

---

## 8. Vendor Rebate Management

### Collection: `vendor_rebate_agreements`
Tracks complex supplier rebate programs (volume, value, or growth-based) to ensure maximum cost recovery and accurate profit margin calculations.

- **Document ID**: Auto-generated
- **Fields**:
  - `agreement_number` (string)
  - `vendor_id` (reference)
  - `type` (string/enum): `VOLUME`, `VALUE`.
  - `start_date` (timestamp)
  - `end_date` (timestamp)
  - `status` (string/enum): `DRAFT`, `ACTIVE`, `CLOSED`.
  - `cumulative_purchases` (double): Real-time rollup of purchases against this agreement.

#### Sub-collection: `rebate_tiers`
- **Document ID**: Auto-generated
- **Fields**:
  - `min_threshold` (double): Minimum quantity or value to hit the tier.
  - `max_threshold` (double)
  - `rebate_value` (double)
  - `rebate_type` (string/enum): `PERCENTAGE`, `FIXED_AMOUNT`.

### Collection: `rebate_claims`
System-generated claims to collect funds from vendors once tiers are reached.
- **Document ID**: Auto-generated
- **Fields**:
  - `agreement_id` (reference)
  - `claim_amount` (double)
  - `status` (string/enum): `CALCULATED`, `SUBMITTED`, `APPROVED`, `PAID`.
  - `generated_at` (timestamp)

---

## 9. Advanced Demand Forecasting (Master Planning AI)

### Collection: `demand_forecasts`
Stores machine-learning-driven predictions for inventory demand, directly feeding into MRP runs to optimize safety stock and purchasing.

- **Document ID**: Auto-generated
- **Fields**:
  - `item_id` (reference)
  - `warehouse_id` (reference)
  - `forecast_model` (string/enum): `ARIMA`, `PROPHET`, `AZURE_ML_CUSTOM`.
  - `period_start` (timestamp)
  - `period_end` (timestamp)
  - `predicted_quantity` (double)
  - `confidence_lower_bound` (double)
  - `confidence_upper_bound` (double)
  - `generated_at` (timestamp)

---

## 10. Product Configurators (Configure-to-Order)

### Collection: `product_configurators`
Rules engines allowing sales or customers to build dynamic BOMs and routings for custom products (Configure-to-Order workflows).

- **Document ID**: Auto-generated
- **Fields**:
  - `base_item_id` (reference): The configurable `inventory_item`.
  - `name` (string): e.g., "Custom Server Rack Configurator".
  - `status` (string/enum): `DRAFT`, `ACTIVE`.

#### Sub-collection: `configuration_attributes`
Questions or options presented during configuration.
- **Document ID**: Auto-generated
- **Fields**:
  - `attribute_name` (string): e.g., "Chassis Color", "Power Supply".
  - `attribute_type` (string/enum): `TEXT`, `NUMBER`, `BOOLEAN`, `OPTION_SET`.
  - `is_mandatory` (boolean)

#### Sub-collection: `configuration_rules`
Constraint logic to validate configurations.
- **Document ID**: Auto-generated
- **Fields**:
  - `rule_type` (string/enum): `REQUIREMENT`, `EXCLUSION`, `BOM_ADDITION`, `ROUTING_ADDITION`.
  - `condition_logic` (string): JSON expression of conditions (e.g., "If chassis == 1U").
  - `action_logic` (string): JSON expression of outcomes (e.g., "Add PSU-500W to BOM").

---

## 11. IoT Intelligence & Telemetry

### Collection: `iot_devices`
Tracks sensors embedded in manufacturing assets or logistics containers for real-time visibility.

- **Document ID**: Auto-generated
- **Fields**:
  - `device_id` (string): MAC address or hardware ID.
  - `linked_entity_type` (string/enum): `ASSET`, `VOYAGE`, `LOCATION`.
  - `linked_entity_id` (reference): E.g., reference to an `assets` doc.
  - `sensor_types` (array): `['TEMPERATURE', 'VIBRATION', 'HUMIDITY']`
  - `status` (string/enum): `ONLINE`, `OFFLINE`, `MAINTENANCE`.
  - `last_ping_at` (timestamp)

#### Sub-collection: `telemetry_alerts`
Actionable anomalies detected by AI on the telemetry streams.
- **Document ID**: Auto-generated
- **Fields**:
  - `alert_type` (string/enum): `HIGH_VIBRATION`, `TEMP_OUT_OF_BOUNDS`.
  - `severity` (string/enum): `LOW`, `MEDIUM`, `CRITICAL`.
  - `message` (string)
  - `triggered_at` (timestamp)
  - `work_order_id` (reference): Auto-generated preventative maintenance ticket.
