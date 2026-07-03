# Project Operations (PMO) Database Schema

This document outlines the Firestore database schema designed for an enterprise-grade Project Operations (PMO) pillar. The schema supports Work Breakdown Structure (WBS), Resource Skills-matching, Revenue Recognition, and Time & Expense integration, rivalling platforms like Dynamics 365 Project Operations.

## Root Collections Overview

* `clients`: Organizations or entities for whom projects are executed.
* `contracts`: Commercial agreements governing the financial aspects of projects.
* `projects`: The core entity around which work, resources, and financials revolve.
* `resources`: Individuals available for staffing on projects, with detailed skill tracking.
* `skills`: A master taxonomy of skills and proficiencies.
* `time_entries`: Records of effort expended by resources on project tasks.
* `expenses`: Project-related costs incurred by resources.
* `resource_requests`: Requisitions for specific roles or skills for upcoming project work.

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

## 6. `contracts` Collection

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

### 6.1 `billing_milestones` (Sub-collection)
For Fixed Price contracts.

**Path:** `/contracts/{contractId}/billing_milestones/{milestoneId}`

**Fields:**
* `milestoneId` (String)
* `name` (String)
* `amount` (Number)
* `targetDate` (Timestamp)
* `status` (String): e.g., `Pending`, `Met`, `Invoiced`, `Paid`.
* `linkedTaskId` (Reference: `/projects/{projectId}/wbs/{taskId}`): Triggers milestone completion when the WBS task is marked 100% complete.

---

## 7. `skills` Collection (Master Data)

Taxonomy of skills for standardization across the organization.

**Path:** `/skills/{skillId}`

**Fields:**
* `skillId` (String)
* `name` (String): e.g., `React.js`, `Project Management`, `Cloud Architecture`.
* `category` (String): e.g., `Frontend Development`, `Methodology`, `Infrastructure`.
* `description` (String)
* `isActive` (Boolean)
