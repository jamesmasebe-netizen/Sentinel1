# Field Service Pillar - Firestore Database Schema

This document outlines the enterprise-grade NoSQL (Firestore) database schema designed for the Field Service pillar. This schema supports complex scenarios including Route Optimization, Dispatching, Work Orders, IoT Alerts, and strict integration with Safety compliance processes like Permits to Work (PTWs) and Hazard Identification and Risk Assessments (HIRAs). It has been vastly expanded to rival tier-1 enterprise platforms like Microsoft Dynamics 365 Field Service, incorporating advanced Connected Field Service, inventory tracking (including truck stock), predictive maintenance, agreements, and customer portal capabilities.

## Table of Contents
1. [Core Operations](#1-core-operations)
   - `work_orders`
   - `work_order_tasks` (Sub-collection)
   - `work_order_parts_used` (Sub-collection)
   - `work_order_services` (Sub-collection)
   - `agreements`
   - `agreement_booking_setups` (Sub-collection)
   - `customer_assets`
2. [Resource Management & Dispatching](#2-resource-management--dispatching)
   - `technicians`
   - `technician_schedules` (Sub-collection)
   - `time_entries`
   - `dispatch_territories`
   - `requirement_groups`
3. [Route Optimization](#3-route-optimization)
   - `route_plans`
   - `route_waypoints` (Sub-collection)
   - `geofences`
   - `geofence_events`
4. [IoT & Predictive Maintenance](#4-iot--predictive-maintenance)
   - `iot_devices`
   - `iot_device_readings` (Sub-collection)
   - `iot_alerts`
   - `iot_device_commands`
5. [Inventory, Warehousing & Purchasing](#5-inventory-warehousing--purchasing)
   - `warehouses`
   - `warehouse_inventory` (Sub-collection)
   - `inventory_journals`
   - `purchase_orders`
   - `rmas` (Return to Manufacturer Approvals)
6. [Safety & Compliance (PTW & HIRA)](#6-safety--compliance-ptw--hira)
   - `safety_ptws` (Permit to Work)
   - `safety_hiras` (Hazard ID & Risk Assessment)
7. [Customer Portal & Self-Service](#7-customer-portal--self-service)
   - `customer_tracking_links`

---

## 1. Core Operations

### Collection: `work_orders`
The central entity representing a field service job.

**Document ID**: Auto-generated or custom standard (e.g., `WO-100293`)
- `work_order_number` (String): Human-readable identifier.
- `status` (String): `DRAFT`, `SCHEDULED`, `DISPATCHED`, `TRAVELING`, `IN_PROGRESS`, `ON_HOLD`, `COMPLETED`, `CANCELED`.
- `substatus_id` (String): Reference to custom organizational substatuses (e.g., "Awaiting Parts", "Rescheduled").
- `priority` (String): `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`.
- `incident_type_id` (String): Reference to a template that pre-populates tasks, parts, and services.
- `service_type_id` (String): Reference to a service type catalog.
- `customer_id` (String): Reference to the CRM customer profile (Service Account).
- `billing_account_id` (String): The account responsible for the invoice (if different from customer_id).
- `agreement_id` (String): Link to a recurring maintenance agreement (if applicable).
- `asset_id` (String): Reference to the specific equipment/asset being serviced.
- `location` (GeoPoint): Lat/Long for routing and geofencing.
- `address` (Map):
  - `street` (String)
  - `city` (String)
  - `state` (String)
  - `zip_code` (String)
  - `country` (String)
- `scheduling` (Map):
  - `preferred_start_time` (Timestamp)
  - `preferred_end_time` (Timestamp)
  - `scheduled_start_time` (Timestamp)
  - `scheduled_end_time` (Timestamp)
  - `actual_start_time` (Timestamp)
  - `actual_end_time` (Timestamp)
  - `total_estimated_duration_mins` (Number)
- `assigned_technician_id` (String): Ref to `technicians` collection.
- `dispatcher_id` (String): Ref to the user who dispatched the order.
- `territory_id` (String): Ref to `dispatch_territories`.
- `description` (String): Detailed problem description.
- `resolution_notes` (String): Technician's notes upon completion.
- `safety_requirements` (Map):
  - `hira_required` (Boolean): Strict flag to mandate HIRA before work begins.
  - `ptw_required` (Boolean): Strict flag to mandate PTW.
  - `required_ptw_types` (Array of Strings): e.g., `['HOT_WORK', 'CONFINED_SPACE']`.
- `iot_context` (Map):
  - `triggered_by_iot` (Boolean)
  - `source_alert_id` (String)
- `financials` (Map):
  - `total_estimated_cost` (Number)
  - `total_actual_cost` (Number)
  - `total_billable_amount` (Number)
  - `not_to_exceed_amount` (Number)
- `is_mobile_offline_synced` (Boolean): Tracks if the payload has been synced to the technician's edge database.
- `created_at` (Timestamp)
- `updated_at` (Timestamp)

#### Sub-collection: `work_orders/{work_order_id}/tasks`
Granular steps required to complete the work order, often derived from the `incident_type_id`.

**Document ID**: Auto-generated
- `task_name` (String)
- `description` (String)
- `inspection_template_id` (String): Link to a dynamic form/survey for advanced data capture.
- `is_mandatory` (Boolean)
- `estimated_duration_mins` (Number)
- `actual_duration_mins` (Number)
- `percent_complete` (Number)
- `status` (String): `PENDING`, `IN_PROGRESS`, `COMPLETED`, `SKIPPED`.
- `completed_at` (Timestamp)
- `completed_by` (String): Ref to technician user.
- `sequence_order` (Number): For UI ordering.

#### Sub-collection: `work_orders/{work_order_id}/parts_used`
Inventory items consumed during the service.

**Document ID**: Auto-generated
- `product_id` (String): Reference to inventory catalog.
- `status` (String): `REQUESTED`, `ALLOCATED`, `USED`, `BILLED`.
- `quantity_required` (Number)
- `quantity_consumed` (Number)
- `warehouse_id` (String): Where the part was sourced (e.g., technician's truck).
- `unit_amount` (Number): Price per unit.
- `total_amount` (Number)

#### Sub-collection: `work_orders/{work_order_id}/services`
Billable labor or services applied to the work order.

**Document ID**: Auto-generated
- `service_id` (String): Ref to service catalog.
- `status` (String): `ESTIMATED`, `USED`, `BILLED`.
- `duration_mins` (Number)
- `hourly_rate` (Number)
- `total_amount` (Number)

### Collection: `customer_assets`
Maintains a history of equipment installed at customer locations, including maintenance schedules, warranty info, and hierarchical parent-child relationships.

**Document ID**: Auto-generated (Asset UUID)
- `asset_name` (String)
- `category_id` (String): e.g., `HVAC_UNITS`, `MRI_MACHINES`.
- `customer_id` (String)
- `parent_asset_id` (String): For complex assemblies.
- `status` (String): `ACTIVE`, `INACTIVE`, `IN_REPAIR`, `DECOMMISSIONED`.
- `installation_date` (Timestamp)
- `warranty_start_date` (Timestamp)
- `warranty_end_date` (Timestamp)
- `location` (GeoPoint)
- `iot_device_id` (String): Link to connected sensors.
- `created_at` (Timestamp)
- `updated_at` (Timestamp)

### Collection: `agreements`
Manages recurring service contracts, such as preventive maintenance, which automatically generate work orders based on predefined schedules.

**Document ID**: Auto-generated
- `customer_id` (String)
- `name` (String)
- `start_date` (Timestamp)
- `end_date` (Timestamp)
- `system_status` (String): `ESTIMATE`, `ACTIVE`, `EXPIRED`, `CANCELED`.
- `billing_frequency` (String): `MONTHLY`, `QUARTERLY`, `ANNUALLY`.

#### Sub-collection: `agreements/{agreement_id}/booking_setups`
Defines the rules for auto-generating work orders from this agreement.

**Document ID**: Auto-generated
- `incident_type_id` (String)
- `recurrence_pattern` (String): e.g., CRON expression or `EVERY_3_MONTHS`.
- `estimated_duration_mins` (Number)
- `preferred_technician_id` (String): Optional dedicated technician.
- `next_generation_date` (Timestamp): When the background worker should generate the next WO.

---

## 2. Resource Management & Dispatching

### Collection: `technicians`
Profiles of the field workforce used for capacity planning, matching, and dispatching.

**Document ID**: Technician User ID (matches Auth/Users collection)
- `first_name` (String)
- `last_name` (String)
- `resource_type` (String): `USER`, `CONTACT` (Vendor), `EQUIPMENT`, `CREW`.
- `vendor_id` (String): If resource is a 3rd party contractor.
- `status` (String): `AVAILABLE`, `ON_JOB`, `TRAVELING`, `OFF_DUTY`, `SICK_LEAVE`.
- `current_location` (GeoPoint): Continuously updated via mobile app background tracking.
- `last_location_update` (Timestamp)
- `home_base` (GeoPoint): Used as the start/end point for daily route optimization.
- `territory_ids` (Array of Strings): Territories this technician covers.
- `skills` (Array of Strings): e.g., `['HVAC_LEVEL_2', 'ELECTRICAL_HIGH_VOLTAGE']`. Used for skill-based routing.
- `certifications` (Array of Maps):
  - `cert_name` (String)
  - `issued_at` (Timestamp)
  - `expires_at` (Timestamp)
  - `is_valid` (Boolean)
- `hourly_rate` (Number): Cost to the business.
- `approval_manager_id` (String)
- `vehicle_id` (String): Reference to fleet management.
- `max_daily_hours` (Number): For schedule optimization.

#### Sub-collection: `technicians/{technician_id}/schedules`
Defines working hours and exceptions.

**Document ID**: `YYYY-MM-DD` (e.g., `2026-07-03`)
- `date` (Timestamp): Midnight of the specific day.
- `is_working_day` (Boolean)
- `shift_start` (Timestamp)
- `shift_end` (Timestamp)
- `pay_type` (String): `REGULAR`, `OVERTIME`, `HOLIDAY`.
- `breaks` (Array of Maps):
  - `start_time` (Timestamp)
  - `end_time` (Timestamp)
- `available_capacity_minutes` (Number)

### Collection: `time_entries`
Tracks actual time spent by technicians for payroll and cost accounting.

**Document ID**: Auto-generated
- `technician_id` (String)
- `work_order_id` (String): Optional (null for generic training/PTO).
- `type` (String): `TRAVEL`, `WORK`, `BREAK`, `TRAINING`, `PTO`.
- `start_time` (Timestamp)
- `end_time` (Timestamp)
- `duration_mins` (Number)
- `entry_status` (String): `DRAFT`, `SUBMITTED`, `APPROVED`, `REJECTED`.
- `approved_by` (String)

### Collection: `dispatch_territories`
Geographical or logical groupings for dispatchers.

**Document ID**: Auto-generated
- `name` (String): e.g., "Northwest Region".
- `manager_id` (String)
- `geofence_polygon` (Array of GeoPoints): Boundary coordinates.
- `timezone` (String): e.g., `America/Los_Angeles`.

### Collection: `requirement_groups`
Advanced dispatching rules representing complex scenarios (e.g., needing 2 technicians and 1 crane simultaneously).

**Document ID**: Auto-generated
- `work_order_id` (String)
- `name` (String)
- `is_strict_fulfillment` (Boolean): If true, all requirements must be met exactly.

---

## 3. Route Optimization

### Collection: `route_plans`
Daily itineraries generated by the Route Optimization engine (e.g., VRP solver).

**Document ID**: Auto-generated
- `technician_id` (String)
- `date` (Timestamp)
- `status` (String): `DRAFT`, `PUBLISHED`, `IN_PROGRESS`, `COMPLETED`.
- `start_location` (GeoPoint): Usually technician's home or depot.
- `end_location` (GeoPoint)
- `metrics` (Map):
  - `total_travel_distance_km` (Number)
  - `total_travel_time_mins` (Number)
  - `total_service_time_mins` (Number)
  - `optimization_score` (Number): Algorithm confidence/efficiency score.
- `generated_by` (String): `SYSTEM_AUTO`, `DISPATCHER_ID`.
- `created_at` (Timestamp)
- `updated_at` (Timestamp)

#### Sub-collection: `route_plans/{route_plan_id}/waypoints`
Ordered list of stops on the route.

**Document ID**: Auto-generated
- `sequence_number` (Number): 1, 2, 3...
- `waypoint_type` (String): `START_DEPOT`, `WORK_ORDER`, `BREAK`, `END_DEPOT`.
- `work_order_id` (String): Null if waypoint is a break or depot.
- `location` (GeoPoint)
- `estimated_arrival_time` (Timestamp)
- `estimated_departure_time` (Timestamp)
- `actual_arrival_time` (Timestamp)
- `actual_departure_time` (Timestamp)
- `travel_distance_from_previous_km` (Number)
- `travel_time_from_previous_mins` (Number)

### Collection: `geofences`
Virtual perimeters around customer sites or depots.

**Document ID**: Auto-generated
- `name` (String)
- `customer_id` (String)
- `center` (GeoPoint)
- `radius_meters` (Number)

### Collection: `geofence_events`
Triggered automatically when a technician's mobile device crosses a geofence. Used to auto-update Work Order statuses (e.g., moving from "Traveling" to "In Progress").

**Document ID**: Auto-generated
- `technician_id` (String)
- `work_order_id` (String)
- `geofence_id` (String)
- `event_type` (String): `ENTERED`, `EXITED`.
- `timestamp` (Timestamp)
- `processed_by_engine` (Boolean)

---

## 4. IoT & Predictive Maintenance

### Collection: `iot_devices`
Sensors and smart assets deployed in the field.

**Document ID**: Device UUID / MAC Address
- `asset_id` (String): Link to equipment catalog.
- `customer_id` (String)
- `device_type` (String): e.g., `TEMPERATURE_SENSOR`, `VIBRATION_MONITOR`.
- `provider_instance_id` (String): Ref to the IoT Hub instance.
- `location` (GeoPoint)
- `status` (String): `ONLINE`, `OFFLINE`, `MAINTENANCE`.
- `last_ping_at` (Timestamp)
- `firmware_version` (String)
- `telemetry_thresholds` (Map): Configuration for generating alerts (e.g., `max_temp: 85`).

#### Sub-collection: `iot_devices/{device_id}/readings`
Aggregated or anomaly telemetry readings (high-volume time-series data may be offloaded to BigQuery, but recent/actionable data is kept here).

**Document ID**: Auto-generated
- `timestamp` (Timestamp)
- `measurements` (Map): e.g., `{ temperature: 88, humidity: 45 }`

### Collection: `iot_alerts`
Anomalies detected by devices, potentially triggering automated Work Order creation.

**Document ID**: Auto-generated
- `device_id` (String)
- `alert_type` (String): e.g., `OVERHEATING`, `EXCESSIVE_VIBRATION`.
- `severity` (String): `INFO`, `WARNING`, `CRITICAL`.
- `timestamp` (Timestamp)
- `raw_payload` (Map): Full JSON payload from the IoT hub.
- `status` (String): `NEW`, `ACKNOWLEDGED`, `CONVERTED_TO_WO`, `DISMISSED`.
- `work_order_id` (String): Linked WO if converted.
- `action_taken_by` (String): System or User ID.

### Collection: `iot_device_commands`
Outbound commands sent from the Field Service application back to the connected device (e.g., "Reboot", "Reset Fault").

**Document ID**: Auto-generated
- `device_id` (String)
- `command_type` (String)
- `payload` (Map)
- `status` (String): `PENDING`, `SENT`, `DELIVERED`, `FAILED`.
- `sent_at` (Timestamp)
- `response_payload` (Map)

---

## 5. Inventory, Warehousing & Purchasing

### Collection: `warehouses`
Logical or physical locations storing inventory. In field service, a technician's truck is treated as a mobile warehouse.

**Document ID**: Auto-generated
- `name` (String)
- `type` (String): `MAIN_DEPOT`, `TRUCK_STOCK`, `VIRTUAL`.
- `technician_id` (String): Required if `type` is `TRUCK_STOCK`.
- `location` (GeoPoint)

#### Sub-collection: `warehouses/{warehouse_id}/inventory`
Current stock levels.

**Document ID**: `product_id`
- `quantity_available` (Number)
- `quantity_allocated` (Number): Reserved for scheduled work orders.
- `quantity_on_hand` (Number)
- `quantity_on_order` (Number)
- `reorder_point` (Number)

### Collection: `inventory_journals`
Immutable ledger of inventory movements (transfers, adjustments, usage).

**Document ID**: Auto-generated
- `transaction_type` (String): `TRANSFER`, `ADJUSTMENT`, `WORK_ORDER_USAGE`, `PURCHASE_RECEIPT`, `RMA_RECEIPT`.
- `source_warehouse_id` (String)
- `destination_warehouse_id` (String)
- `product_id` (String)
- `quantity` (Number)
- `work_order_id` (String): Optional.
- `timestamp` (Timestamp)
- `processed_by` (String)

### Collection: `purchase_orders`
Tracks parts ordered from vendors to restock warehouses or fulfill specific work orders.

**Document ID**: Auto-generated
- `vendor_id` (String)
- `status` (String): `DRAFT`, `SUBMITTED`, `PARTIALLY_RECEIVED`, `RECEIVED`, `CANCELED`.
- `expected_delivery_date` (Timestamp)
- `destination_warehouse_id` (String)

### Collection: `rmas`
Return to Manufacturer Approvals. Manages the process of returning defective customer assets or parts to the vendor for repair or credit.

**Document ID**: Auto-generated
- `work_order_id` (String)
- `customer_id` (String)
- `status` (String): `PENDING`, `APPROVED`, `SHIPPED`, `RECEIVED`, `CREDITED`.
- `processing_action` (String): `RETURN_TO_VENDOR`, `SCRAP`, `REPAIR_INTERNALLY`.
- `tracking_number` (String)

---

## 6. Safety & Compliance (PTW & HIRA)

To compete at an enterprise level, strict adherence to safety protocols is mandatory. Work orders are often locked until HIRAs and PTWs are completed and signed off.

### Collection: `safety_hiras`
Hazard Identification and Risk Assessment. Must often be completed by the technician *on-site* before the WO status can change to `IN_PROGRESS`.

**Document ID**: Auto-generated
- `work_order_id` (String)
- `technician_id` (String)
- `asset_id` (String)
- `status` (String): `DRAFT`, `SUBMITTED`, `APPROVED`, `REJECTED`.
- `assessment_date` (Timestamp)
- `location_context` (String): Notes on environmental conditions (e.g., "Raining, slippery floor").
- `hazards_identified` (Array of Maps):
  - `hazard_category` (String): e.g., `ELECTRICAL`, `CHEMICAL`, `FALL`.
  - `description` (String)
  - `initial_risk_score` (Number): Likelihood x Severity.
  - `control_measures` (String): Mitigation steps.
  - `residual_risk_score` (Number): Score after controls.
- `overall_risk_level` (String): `LOW`, `MEDIUM`, `HIGH`, `UNACCEPTABLE`.
- `requires_supervisor_approval` (Boolean): Triggered if residual risk is too high.
- `signatures` (Map):
  - `technician_signature_url` (String)
  - `technician_signed_at` (Timestamp)
  - `supervisor_signature_url` (String)
  - `supervisor_signed_at` (Timestamp)
- `created_at` (Timestamp)
- `updated_at` (Timestamp)

### Collection: `safety_ptws`
Permit to Work. Required for high-risk operations (e.g., Hot Work, Confined Space). These often require approval from safety officers before the technician can arrive or begin.

**Document ID**: Auto-generated (e.g., `PTW-2026-9081`)
- `work_order_id` (String)
- `permit_type` (String): `HOT_WORK`, `CONFINED_SPACE`, `WORKING_AT_HEIGHTS`, `LOTO` (Lockout/Tagout).
- `status` (String): `REQUESTED`, `UNDER_REVIEW`, `APPROVED`, `ACTIVE`, `SUSPENDED`, `CLOSED`, `REVOKED`.
- `requested_by` (String): Technician or Dispatcher ID.
- `requested_at` (Timestamp)
- `approved_by` (String): Safety Officer ID.
- `approved_at` (Timestamp)
- `validity_period` (Map):
  - `valid_from` (Timestamp)
  - `valid_to` (Timestamp)
- `location_specifics` (String)
- `prerequisite_hira_id` (String): Link to the HIRA that justifies this PTW.
- `safety_checklist` (Array of Maps):
  - `question` (String)
  - `is_checked` (Boolean)
  - `checked_by` (String)
- `equipment_required` (Array of Strings): e.g., `['GAS_DETECTOR', 'FIRE_EXTINGUISHER', 'HARNESS']`.
- `loto_details` (Map): For Lockout/Tagout specifically.
  - `isolation_points` (Array of Strings)
  - `lock_numbers` (Array of Strings)
- `signatures` (Array of Maps):
  - `role` (String): `ISSUER`, `RECEIVER`, `FIRE_WATCH`.
  - `user_id` (String)
  - `signature_url` (String)
  - `timestamp` (Timestamp)
- `closure_notes` (String): Details when the permit is closed and site is returned to normal.
- `created_at` (Timestamp)
- `updated_at` (Timestamp)

---

## 7. Customer Portal & Self-Service

### Collection: `customer_tracking_links`
Generates secure, time-bound URLs sent to customers via SMS/Email, allowing them to track technician arrival in real-time on a map (similar to ride-sharing apps).

**Document ID**: Tracking Token UUID
- `work_order_id` (String)
- `customer_id` (String)
- `status` (String): `ACTIVE`, `EXPIRED`.
- `expires_at` (Timestamp): Usually 2 hours after WO completion.
- `technician_location_shared` (Boolean): Determines if the customer sees the actual dot on the map or just the ETA.
- `estimated_arrival_time` (Timestamp)
- `communication_history` (Array of Maps):
  - `message_type` (String): `ETA_UPDATE`, `ARRIVAL_ALERT`.
  - `sent_at` (Timestamp)

---
*Note on Access Control (Security Rules):*
- *Technicians should only have read/write access to `work_orders` assigned to them, and only modify `actual` times and status fields, plus full write access to their own `time_entries` and `warehouse_inventory` (truck stock).*
- *Safety Officers require broad read access to `work_orders` and full write access to `safety_ptws` and `safety_hiras`.*
- *Customers access `customer_tracking_links` anonymously via the secure UUID token.*
- *Route Plans and IoT telemetry are typically generated by background Cloud Functions (Admin SDK) and are read-only for technicians.*
