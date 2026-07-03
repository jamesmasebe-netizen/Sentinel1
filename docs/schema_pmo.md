# Project Operations (PMO) Database Schema

This document outlines the Firestore database schema designed for an enterprise-grade Project Operations (PMO) pillar. The schema supports Work Breakdown Structure (WBS), Resource Skills-matching, Revenue Recognition, Time & Expense integration, Material Usage, Subcontracting, and Proforma Invoicing, rivalling platforms like Dynamics 365 Project Operations.

## Root Collections Overview

* `clients`: Organizations or entities for whom projects are executed.
* `contracts`: Commercial agreements governing the financial aspects of projects.
* `projects`: The core entity around which work, resources, and financials revolve.
* `resources`: Individuals available for staffing on projects, with detailed skill tracking.
* `skills`: A master taxonomy of skills and proficiencies.
* `time_entries`: Records of effort expended by resources on project tasks.
* `expenses`: Project-related costs incurred by resources.
* `material_usage_logs`: Records of materials consumed on projects.
* `resource_requests`: Requisitions for specific roles or skills for upcoming project work.
* `actuals`: Financial ledger of work performed (cost, unbilled sales, billed sales).
* `subcontracts`: External vendor agreements for project work.
* `vendor_invoices`: Invoices received from subcontractors for verification and payment.
* `proforma_invoices`: Draft invoices consolidating unbilled actuals for project manager review.

---

## 1. `projects` Collection

Represents the core work engagements.

**Path:** `/projects/{projectId}`

**Fields:**
* `projectId` (String, Primary Key)
* `clientId` (Reference: `/clients/{clientId}`)
* `contractId` (Reference: `/contracts/{contractId}`)
* `name` (String): Project name.
* `description` (String): Project charter or summary.
* `status` (String): e.g., `Draft`, `Active`, `OnHold`, `Completed`, `Cancelled`.
* `projectManagerId` (Reference: `/resources/{resourceId}`)
* `startDate` (Timestamp)
* `endDate` (Timestamp)
* `budget` (Map):
  * `totalBudgetAmount` (Number)
  * `currency` (String)
  * `consumedBudget` (Number)
* `revenueRecognitionMethod` (String): e.g., `FixedPrice_Milestone`, `TimeAndMaterials`, `PercentageOfCompletion`.
* `timestamps` (Map): `createdAt`, `updatedAt`

### 1.1 `wbs` (Sub-collection: Work Breakdown Structure)
Stores the hierarchical task structure of the project.

**Path:** `/projects/{projectId}/wbs/{taskId}`

**Fields:**
* `taskId` (String)
* `parentTaskId` (String, nullable): Enables N-level deep hierarchies.
* `name` (String): Task name.
* `description` (String)
* `taskType` (String): e.g., `Summary`, `Task`, `Milestone`.
* `status` (String): e.g., `NotStarted`, `InProgress`, `Completed`.
* `startDate` (Timestamp)
* `endDate` (Timestamp)
* `effort` (Map):
  * `estimatedHours` (Number)
  * `actualHours` (Number)
  * `remainingHours` (Number)
* `percentComplete` (Number: 0-100)
* `assignedResourceIds` (Array of References to `/resources`)
* `dependencies` (Array of Strings): List of `taskId`s that must precede this task.
* `isBillable` (Boolean)

### 1.2 `team_members` (Sub-collection)
Resources allocated to the project.

**Path:** `/projects/{projectId}/team_members/{allocationId}`

**Fields:**
* `allocationId` (String)
* `resourceId` (Reference: `/resources/{resourceId}`)
* `role` (String)
* `startDate` (Timestamp)
* `endDate` (Timestamp)
* `allocatedHours` (Number)
* `utilizationPercentage` (Number)
* `billRateOverride` (Number, nullable): Specific rate for this project if different from resource base rate.

### 1.3 `revenue_schedules` (Sub-collection)
Forecasted and actual revenue recognition events.

**Path:** `/projects/{projectId}/revenue_schedules/{scheduleId}`

**Fields:**
* `scheduleId` (String)
* `period` (String): e.g., `2026-07`
* `amountToRecognize` (Number)
* `status` (String): e.g., `Pending`, `Recognized`, `Deferred`
* `recognizedDate` (Timestamp, nullable)
* `basis` (String): e.g., `MilestoneCompletion`, `CostsIncurred`, `HoursDelivered`
* `journalEntryId` (String, nullable): Link to ERP/GL posting.

### 1.4 `project_estimates` (Sub-collection)
Forecasted effort, expense, and materials for project actuals vs estimates tracking.

**Path:** `/projects/{projectId}/project_estimates/{estimateId}`

**Fields:**
* `estimateId` (String)
* `taskId` (Reference: `/projects/{projectId}/wbs/{taskId}`, nullable)
* `estimateType` (String): e.g., `Time`, `Expense`, `Material`
* `description` (String)
* `quantity` (Number)
* `unitPrice` (Map)
* `estimatedCost` (Map)
* `estimatedSales` (Map)
* `startDate` (Timestamp)
* `endDate` (Timestamp)

---

## 2. `resources` Collection

Employees, contractors, or generic roles available for project work.

**Path:** `/resources/{resourceId}`

**Fields:**
* `resourceId` (String)
* `userId` (String): Link to IAM/Authentication system.
* `type` (String): e.g., `Employee`, `Contractor`, `GenericRole`.
* `firstName` (String)
* `lastName` (String)
* `title` (String)
* `departmentId` (String)
* `managerId` (Reference: `/resources/{resourceId}`)
* `costRate` (Map):
  * `amount` (Number)
  * `currency` (String)
  * `effectiveDate` (Timestamp)
* `targetUtilization` (Number): e.g., 80%

### 2.1 `skills` (Sub-collection)
For complex resource skills-matching and capacity planning.

**Path:** `/resources/{resourceId}/skills/{resourceSkillId}`

**Fields:**
* `resourceSkillId` (String)
* `skillId` (Reference: `/skills/{skillId}`)
* `proficiencyLevel` (Number): e.g., 1 (Beginner) to 5 (Expert).
* `dateAssessed` (Timestamp)
* `lastUsedOnProject` (Timestamp)
* `isVerified` (Boolean)

### 2.2 `utilization_metrics` (Sub-collection)
Aggregated metrics to power Resource Utilization Dashboards.

**Path:** `/resources/{resourceId}/utilization_metrics/{metricId}`

**Fields:**
* `metricId` (String)
* `period` (String): e.g., `2026-07`
* `targetBillableHours` (Number)
* `actualBillableHours` (Number)
* `actualNonBillableHours` (Number)
* `utilizationPercentage` (Number)
* `variance` (Number)

---

## 3. `resource_requests` Collection

Requests raised by Project Managers for specific roles/skills.

**Path:** `/resource_requests/{requestId}`

**Fields:**
* `requestId` (String)
* `projectId` (Reference: `/projects/{projectId}`)
* `requestedRole` (String)
* `requiredSkills` (Array of Maps):
  * `skillId` (Reference: `/skills/{skillId}`)
  * `minimumProficiency` (Number)
  * `isMandatory` (Boolean)
* `startDate` (Timestamp)
* `endDate` (Timestamp)
* `requestedHours` (Number)
* `status` (String): e.g., `Draft`, `Submitted`, `PartiallyStaffed`, `Fulfilled`, `Cancelled`.
* `proposedResources` (Array of References: `/resources/{resourceId}`)
* `fulfilledBy` (Reference: `/resources/{resourceId}`)

---

## 4. `time_entries` Collection

Granular tracking of effort against the WBS.

**Path:** `/time_entries/{entryId}`

**Fields:**
* `entryId` (String)
* `resourceId` (Reference: `/resources/{resourceId}`)
* `projectId` (Reference: `/projects/{projectId}`)
* `taskId` (Reference: `/projects/{projectId}/wbs/{taskId}`)
* `date` (Timestamp)
* `hours` (Number)
* `description` (String): Work performed.
* `isBillable` (Boolean)
* `billingStatus` (String): e.g., `Unbilled`, `Billed`, `WrittenOff`.
* `approvalStatus` (String): e.g., `Draft`, `Submitted`, `Approved`, `Rejected`.
* `approverId` (Reference: `/resources/{resourceId}`)
* `rejectionReason` (String, nullable)
* `invoiceId` (String, nullable): Link to generated invoice.

---

## 5. `expenses` Collection

Tracking project-related out-of-pocket or corporate card expenses.

**Path:** `/expenses/{expenseId}`

**Fields:**
* `expenseId` (String)
* `resourceId` (Reference: `/resources/{resourceId}`)
* `projectId` (Reference: `/projects/{projectId}`)
* `taskId` (Reference: `/projects/{projectId}/wbs/{taskId}`, nullable)
* `category` (String): e.g., `Airfare`, `Hotel`, `Meals`, `Mileage`, `Software`.
* `incurredDate` (Timestamp)
* `amount` (Map):
  * `value` (Number)
  * `currency` (String)
* `receiptUrl` (String): Link to Cloud Storage file.
* `isBillable` (Boolean)
* `approvalStatus` (String): e.g., `Draft`, `Submitted`, `Approved`, `Rejected`.
* `reimbursementStatus` (String): e.g., `Pending`, `Reimbursed`.
* `billingStatus` (String): e.g., `Unbilled`, `Billed`, `WrittenOff`.
* `invoiceId` (String, nullable)

---

## 6. `material_usage_logs` Collection

Records consumption of materials (stocked or non-stocked) on projects.

**Path:** `/material_usage_logs/{logId}`

**Fields:**
* `logId` (String)
* `projectId` (Reference: `/projects/{projectId}`)
* `taskId` (Reference: `/projects/{projectId}/wbs/{taskId}`, nullable)
* `resourceId` (Reference: `/resources/{resourceId}`)
* `materialId` (String): Catalog ID of the item.
* `description` (String)
* `quantity` (Number)
* `unitCost` (Map)
* `totalCost` (Map)
* `isStocked` (Boolean)
* `usageDate` (Timestamp)
* `approvalStatus` (String): e.g., `Draft`, `Submitted`, `Approved`.
* `billingStatus` (String): e.g., `Unbilled`, `Billed`.

---

## 7. `actuals` Collection

The core financial ledger for the project operations data model. Traces all approved time, expense, material, and vendor invoice data into financial records.

**Path:** `/actuals/{actualId}`

**Fields:**
* `actualId` (String)
* `projectId` (Reference: `/projects/{projectId}`)
* `transactionClass` (String): e.g., `Time`, `Expense`, `Material`, `Tax`.
* `transactionType` (String): e.g., `Cost`, `UnbilledSales`, `BilledSales`, `ResourcingUnitCost`.
* `documentDate` (Timestamp)
* `amount` (Map):
  * `value` (Number)
  * `currency` (String)
* `quantity` (Number)
* `unitPrice` (Map)
* `resourceId` (Reference: `/resources/{resourceId}`, nullable)
* `taskId` (Reference: `/projects/{projectId}/wbs/{taskId}`, nullable)
* `sourceDocumentType` (String): e.g., `TimeEntry`, `Expense`, `MaterialUsageLog`, `VendorInvoice`.
* `sourceDocumentId` (String): Polymorphic lookup to the original source.
* `billingStatus` (String): e.g., `ReadyToInvoice`, `CustomerInvoiced`.

---

## 8. `contracts` Collection

Financial agreements controlling billing rules and revenue recognition.

**Path:** `/contracts/{contractId}`

**Fields:**
* `contractId` (String)
* `clientId` (Reference: `/clients/{clientId}`)
* `name` (String)
* `type` (String): e.g., `TimeAndMaterials`, `FixedPrice`, `Retainer`.
* `totalValue` (Map):
  * `amount` (Number)
  * `currency` (String)
* `status` (String): e.g., `Draft`, `Signed`, `Active`, `Closed`.
* `effectiveDate` (Timestamp)

### 8.1 `billing_milestones` (Sub-collection)
For Fixed Price contracts.

**Path:** `/contracts/{contractId}/billing_milestones/{milestoneId}`

**Fields:**
* `milestoneId` (String)
* `name` (String)
* `amount` (Number)
* `targetDate` (Timestamp)
* `status` (String): e.g., `Pending`, `Met`, `Invoiced`, `Paid`.
* `linkedTaskId` (Reference: `/projects/{projectId}/wbs/{taskId}`): Triggers milestone completion.

### 8.2 `contract_lines` (Sub-collection)
Allows hybrid contracts by defining rules per line (e.g., T&M for travel, FP for delivery).

**Path:** `/contracts/{contractId}/contract_lines/{lineId}`

**Fields:**
* `lineId` (String)
* `name` (String)
* `billingMethod` (String): e.g., `TimeAndMaterial`, `FixedPrice`.
* `amount` (Number)
* `includedTransactionClasses` (Array of Strings): e.g., `['Time', 'Expense']`.

---

## 9. `subcontracts` Collection

Agreements with external vendors for project work.

**Path:** `/subcontracts/{subcontractId}`

**Fields:**
* `subcontractId` (String)
* `vendorId` (String)
* `projectId` (Reference: `/projects/{projectId}`)
* `description` (String)
* `status` (String): e.g., `Draft`, `Active`, `Closed`.
* `totalAmount` (Map)
* `currency` (String)
* `startDate` (Timestamp)
* `endDate` (Timestamp)

### 9.1 `subcontract_lines` (Sub-collection)
Itemizes purchases.

**Path:** `/subcontracts/{subcontractId}/subcontract_lines/{lineId}`

**Fields:**
* `lineId` (String)
* `transactionClass` (String): e.g., `Time`, `Expense`, `Material`.
* `roleOrItem` (String)
* `quantity` (Number)
* `unitPrice` (Map)

---

## 10. `vendor_invoices` Collection

Invoices from subcontractors, verified via three-way match against subcontracts and approved actuals.

**Path:** `/vendor_invoices/{invoiceId}`

**Fields:**
* `invoiceId` (String)
* `subcontractId` (Reference: `/subcontracts/{subcontractId}`)
* `vendorId` (String)
* `invoiceDate` (Timestamp)
* `totalAmount` (Map)
* `status` (String): e.g., `Draft`, `Matched`, `Approved`, `Paid`.

### 10.1 `vendor_invoice_lines` (Sub-collection)
**Path:** `/vendor_invoices/{invoiceId}/vendor_invoice_lines/{lineId}`

**Fields:**
* `lineId` (String)
* `subcontractLineId` (Reference: `/subcontracts/{subcontractId}/subcontract_lines/{lineId}`)
* `matchedActualIds` (Array of Strings): References to `actuals` representing approved time/materials.
* `amount` (Map)
* `isVerified` (Boolean)

---

## 11. `proforma_invoices` Collection

Draft invoices ("Billing Hub") consolidating 'Ready to Invoice' actuals for review before confirming final customer invoices.

**Path:** `/proforma_invoices/{invoiceId}`

**Fields:**
* `invoiceId` (String)
* `projectId` (Reference: `/projects/{projectId}`)
* `contractId` (Reference: `/contracts/{contractId}`)
* `invoiceDate` (Timestamp)
* `totalAmount` (Map)
* `status` (String): e.g., `Draft`, `UnderReview`, `Confirmed`, `Cancelled`.
* `confirmedDate` (Timestamp, nullable)

### 11.1 `proforma_invoice_lines` (Sub-collection)
**Path:** `/proforma_invoices/{invoiceId}/proforma_invoice_lines/{lineId}`

**Fields:**
* `lineId` (String)
* `contractLineId` (Reference: `/contracts/{contractId}/contract_lines/{lineId}`)
* `description` (String)
* `amount` (Map)
* `includedActualIds` (Array of Strings): Actuals currently in the billing backlog attached to this line.

---

## 12. `skills` Collection (Master Data)

Taxonomy of skills for standardization across the organization.

**Path:** `/skills/{skillId}`

**Fields:**
* `skillId` (String)
* `name` (String): e.g., `React.js`, `Project Management`, `Cloud Architecture`.
* `category` (String): e.g., `Frontend Development`, `Methodology`, `Infrastructure`.
* `description` (String)
* `isActive` (Boolean)
