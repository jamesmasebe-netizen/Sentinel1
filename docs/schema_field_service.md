# Field Service Pillar - Firestore Database Schema

This document outlines the enterprise-grade NoSQL (Firestore) database schema designed for the Field Service pillar. This schema supports complex scenarios including Route Optimization, Dispatching, Work Orders, IoT Alerts, and strict integration with Safety compliance processes like Permits to Work (PTWs) and Hazard Identification and Risk Assessments (HIRAs).

## Table of Contents
1. [Core Operations](#1-core-operations)
   - `work_orders`
   - `work_order_tasks` (Sub-collection)
   - `work_order_parts` (Sub-collection)
2. [Resource Management & Dispatching](#2-resource-management--dispatching)
   - `technicians`
   - `technician_schedules` (Sub-collection)
   - `dispatch_territories`
3. [Route Optimization](#3-route-optimization)
   - `route_plans`
   - `route_waypoints` (Sub-collection)
4. [IoT & Predictive Maintenance](#4-iot--predictive-maintenance)
   - `iot_devices`
   - `iot_alerts`
5. [Safety & Compliance (PTW & HIRA)](#5-safety--compliance-ptw--hira)
   - `safety_ptws` (Permit to Work)
   - `safety_hiras` (Hazard ID & Risk Assessment)

---

## 1. Core Operations

### Collection: `work_orders`
The central entity representing a field service job.

**Document ID**: Auto-generated or custom standard (e.g., `WO-100293`)
- `work_order_number` (String): Human-readable identifier.
- `status` (String): `DRAFT`, `SCHEDULED`, `DISPATCHED`, `TRAVELING`, `IN_PROGRESS`, `ON_HOLD`, `COMPLETED`, `CANCELED`.
- `priority` (String): `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`.
- `service_type_id` (String): Reference to a service type catalog.
- `customer_id` (String): Reference to the CRM customer profile.
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
- `created_at` (Timestamp)
- `updated_at` (Timestamp)

#### Sub-collection: `work_orders/{work_order_id}/tasks`
Granular steps required to complete the work order.

**Document ID**: Auto-generated
- `task_name` (String)
- `description` (String)
- `is_mandatory` (Boolean)
- `status` (String): `PENDING`, `COMPLETED`, `SKIPPED`.
- `completed_at` (Timestamp)
- `completed_by` (String): Ref to technician user.
- `sequence_order` (Number): For UI ordering.

#### Sub-collection: `work_orders/{work_order_id}/parts_used`
Inventory items consumed during the service.

**Document ID**: Auto-generated
- `product_id` (String): Reference to inventory catalog.
- `quantity_required` (Number)
- `quantity_consumed` (Number)
- `warehouse_id` (String): Where the part was sourced.
- `status` (String): `REQUESTED`, `ALLOCATED`, `USED`.

---

## 2. Resource Management & Dispatching

### Collection: `technicians`
Profiles of the field workforce used for capacity planning, matching, and dispatching.

**Document ID**: Technician User ID (matches Auth/Users collection)
- `first_name` (String)
- `last_name` (String)
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
- `vehicle_id` (String): Reference to fleet management.
- `max_daily_hours` (Number): For schedule optimization.

#### Sub-collection: `technicians/{technician_id}/schedules`
Defines working hours and exceptions.

**Document ID**: `YYYY-MM-DD` (e.g., `2026-07-03`)
- `date` (Timestamp): Midnight of the specific day.
- `is_working_day` (Boolean)
- `shift_start` (Timestamp)
- `shift_end` (Timestamp)
- `breaks` (Array of Maps):
  - `start_time` (Timestamp)
  - `end_time` (Timestamp)
- `available_capacity_minutes` (Number)

### Collection: `dispatch_territories`
Geographical or logical groupings for dispatchers.

**Document ID**: Auto-generated
- `name` (String): e.g., "Northwest Region".
- `manager_id` (String)
- `geofence_polygon` (Array of GeoPoints): Boundary coordinates.
- `timezone` (String): e.g., `America/Los_Angeles`.

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

---

## 4. IoT & Predictive Maintenance

### Collection: `iot_devices`
Sensors and smart assets deployed in the field.

**Document ID**: Device UUID / MAC Address
- `asset_id` (String): Link to equipment catalog.
- `customer_id` (String)
- `device_type` (String): e.g., `TEMPERATURE_SENSOR`, `VIBRATION_MONITOR`.
- `location` (GeoPoint)
- `status` (String): `ONLINE`, `OFFLINE`, `MAINTENANCE`.
- `last_ping_at` (Timestamp)
- `firmware_version` (String)
- `telemetry_thresholds` (Map): Configuration for generating alerts (e.g., `max_temp: 85`).

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

---

## 5. Safety & Compliance (PTW & HIRA)

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
*Note on Access Control (Security Rules):*
- *Technicians should only have read/write access to `work_orders` assigned to them, and only modify `actual` times and status fields.*
- *Safety Officers require broad read access to `work_orders` and full write access to `safety_ptws` and `safety_hiras`.*
- *Route Plans are typically generated by background Cloud Functions (Admin SDK) and are read-only for technicians.*
