# 🌌 Sentinel Business OS: The Dynamics 365 Competitor

## Goal Description
Transform the existing application into a fully-fledged, modular Enterprise Business OS capable of competing directly with Microsoft Dynamics 365, SAP, and Salesforce. The app will open to a "Module Launchpad" featuring the 7 Core ERP/CRM pillars: Finance, Project Operations, Human Resources, Field Service, Customer Service, Sales, and Supply Chain Management. All existing features (Safety, Risk, Environment, etc.) will be seamlessly integrated as specialized operational extensions.

> [!IMPORTANT]
> **User Review Required**: Because this is a monumental shift in application scope, please review the proposed 7 Pillar UI Mapping and the Firestore Database Schema. A full ERP requires extensive data relationships; we have translated standard SQL ERP schemas into an optimized NoSQL structure for Firebase.

---

## 🏛️ 1. The Module Launchpad & UI Reorganization
When users log in, they will no longer land on a generic dashboard. They will land on the **Sentinel Business OS Launchpad**, greeting them with large tiles for the modules they are licensed for.

**Existing Code Mapping:**
- **Risk, Safety, Emergency, Environment**: Will be grouped under an "EHS & Risk Management" standalone module, directly integrated with *Project Operations* and *Field Service*.
- **Property & Equipment**: Migrates into the *Supply Chain & Asset Management* module.
- **AI Copilot**: Becomes an omnipresent floating overlay accessible across every module, evolving into a proactive business advisor.
- **Employee Hub**: Fuses completely into the *Human Resources* module.

---

## 🏗️ 2. The 7 Pillars of the Business OS (Dynamics 365 Killer Enhancements)

To outshine Dynamics 365, we must go beyond standard tables and add intelligent, modern capabilities that enterprise users complain are missing or too clunky in legacy systems.

### 1. Finance (Dynamics 365 Finance)
* **Standard Functionality**: General Ledger, Accounts Payable, Accounts Receivable, Fixed Assets, Bank Reconciliation, and Financial Reporting.
* **Sentinel Enhancements**: Multi-currency auto-reconciliation, dynamic Tax schedules (VAT/GST/Sales Tax auto-calc), AI-driven anomaly detection in Journal Entries, Subscription/Recurring billing engine, and instant Cash Flow Forecasting.
* **Core Screens**: CFO Command Center, Chart of Accounts, Journal Entries, Invoicing, Tax Configuration, Budget vs. Actuals.

### 2. Project Operations (Dynamics 365 Project Operations)
* **Standard Functionality**: Project Planning (Gantt), Resource Allocation, Time & Expense Tracking, Project Costing, and Billing.
* **Sentinel Enhancements**: Real-time Utilization/Realization rates, automated Expense Policy enforcement (OCR receipt scanning), Retainer & Milestone billing contracts, and predictive project overrun alerts.
* **Core Screens**: PMO Dashboard, Resource Scheduler, Timesheets, Project Budgets, Milestone Tracker.

### 3. Human Resources (Dynamics 365 Human Resources)
* **Standard Functionality**: Core HR, Competency Passports, Leave & Absence, Compensation, Benefits, Onboarding, Employee 360.
* **Sentinel Enhancements**: Integrated Applicant Tracking System (ATS), Shift Scheduling with conflict resolution, eSignatures for employee contracts, continuous Employee Pulse Surveys, and automated Payroll integrations.
* **Core Screens**: HR Director Dashboard, ATS Pipeline, Employee Roster, Leave Approvals, Performance Reviews, Shift Roster.

### 4. Field Service (Dynamics 365 Field Service)
* **Standard Functionality**: Work Orders, Dispatching, Route Optimization, Contractor Management, Remote Assist (Video).
* **Sentinel Enhancements**: IoT Integration for Predictive Maintenance (auto-generate work orders from sensor data), Geofencing alerts for customer ETA, and "Inventory on Truck" (Mobile Warehousing) management.
* **Core Screens**: Dispatcher Board, Work Order details, Technician Mobile View, Asset Maintenance, IoT Telemetry Hub.

### 5. Customer Service (Dynamics 365 Customer Service)
* **Standard Functionality**: Case/Ticket Management, Omnichannel Routing, SLAs, Knowledge Base, Customer Portals.
* **Sentinel Enhancements**: Seamless AI Chatbot to human handoffs, automated CSAT/NPS survey triggers upon resolution, Entitlements & Service Contracts management, and sentiment analysis on tickets.
* **Core Screens**: Agent Workspace, SLA Timers, Ticket Queue, Knowledge Articles, Contract Entitlements.

### 6. Sales (Dynamics 365 Sales)
* **Standard Functionality**: CRM, Leads, Opportunities, Accounts, Contacts, Forecasting, Quotes to Orders.
* **Sentinel Enhancements**: Native CPQ (Configure, Price, Quote) engine, intelligent Territory Management, unified Activity Timelines (emails, calls, meetings synced), and Competitor battlecards.
* **Core Screens**: Pipeline Kanban Board, Account 360, Advanced Quote Generator, Sales Forecasting, Activity Timeline.

### 7. Supply Chain Management (Dynamics 365 SCM)
* **Standard Functionality**: Procurement (Purchase Orders), Inventory Management, Warehousing, Vendor Portals.
* **Sentinel Enhancements**: Dynamic BOM (Bill of Materials), Manufacturing Routing workflows, Multi-Warehouse Transfers with transit tracking, Demand Forecasting (AI-based), and seamless Returns Management (RMA).
* **Core Screens**: Inventory Levels, PO Approvals, Vendor Database, Warehouse Flow, RMA Dashboard.

---

## 🗄️ 3. Granular Firestore Database Schema (Multi-Tenant & Enhanced)
To ensure we do not miss any "tables or columns", all data remains partitioned under `/tenants/{tenantId}`. We are expanding the schema to support the advanced features listed above.

### Core & Security (The Sentinel Edge over D365)
To truly outclass legacy ERPs in governance, compliance, and automation transparency, Sentinel1 introduces native, highly granular security and workflow observability at its core.

- **`/users`**: `id`, `name`, `email`, `role`, `tenantIds[]`, `preferences` (theme, timezone)
- **`/user_permissions` (Granular RBAC & ABAC)**: `id`, `userId`, `roleId`, `moduleAccess` (Map<String, String> - e.g., 'Finance': 'ReadWrite'), `rowLevelSecurityTags[]` (e.g., 'Region:EMEA'), `temporaryGrants` (Map<String, DateTime> for time-bound access), `delegatedTo`
- **`/audit_trail` (Immutable Compliance Ledger)**: `id`, `userId`, `action` (CREATE/UPDATE/DELETE/EXPORT), `entityId`, `entityType`, `timestamp`, `ipAddress`, `deviceInfo`, `changes` (old/new values with exact diffs), `cryptographicHash` (for non-repudiation)
- **`/automations`**: `id`, `triggerType`, `conditions[]`, `actions[]`, `isActive` (Zapier alternative)
- **`/workflow_logs` (Process Observability)**: `id`, `automationId`, `triggerEventId`, `executionStartTime`, `executionEndTime`, `status` (success, failed, retrying), `stepResults` (List of Map), `errorMessage`, `contextData` (snapshot of the payload that triggered the workflow)

### Finance
- **`finance_accounts` (Chart of Accounts)**: `id`, `accountCode`, `name`, `type` (asset, liability, equity, revenue, expense), `currency`, `currentBalance`, `isActive`
- **`finance_journals` (GL Entries)**: `id`, `date`, `description`, `status` (draft, posted), `createdBy`, `totalDebit`, `totalCredit`, `isRecurring`, `anomalyScore`
  - *Sub-collection* `lines`: `accountId`, `debit`, `credit`, `memo`, `projectId` (for cross-module tagging)
- **`finance_invoices` (AP/AR)**: `id`, `type` (payable, receivable), `accountId`, `customerId/vendorId`, `issueDate`, `dueDate`, `amount`, `status`, `subscriptionId`
  - *Sub-collection* `lineItems`: `description`, `quantity`, `unitPrice`, `taxRate`, `discount`
- **`finance_taxes`**: `id`, `taxName`, `rate`, `region`, `effectiveDate`
- **`finance_subscriptions`**: `id`, `customerId`, `planId`, `billingCycle`, `nextBillingDate`, `amount`, `status`

### Sales (CRM)
- **`crm_accounts`**: `id`, `name`, `industry`, `website`, `phone`, `billingAddress`, `shippingAddress`, `status`, `territoryId`
- **`crm_contacts`**: `id`, `accountId`, `firstName`, `lastName`, `email`, `phone`, `title`, `isPrimary`
- **`crm_opportunities`**: `id`, `accountId`, `title`, `stage` (prospecting, qualification, proposal, closed_won, closed_lost), `amount`, `probability`, `expectedCloseDate`, `assignedUserId`, `competitorIds[]`
- **`crm_quotes` (CPQ Enabled)**: `id`, `opportunityId`, `totalAmount`, `status`, `validUntil`, `termsAndConditions`
  - *Sub-collection* `quote_lines`: `productId`, `quantity`, `unitPrice`, `discountPercent`, `margin`
- **`crm_activities`**: `id`, `relatedTo` (accountId/opportunityId), `type` (call, email, meeting), `description`, `date`, `performedBy`

### Human Resources
- **`hr_employees`**: `id`, `userId`, `employeeId`, `department`, `managerId`, `hireDate`, `employmentType`, `baseSalary`, `payrollProviderId`
- **`hr_leave_requests`**: `id`, `employeeId`, `leaveType`, `startDate`, `endDate`, `status` (pending, approved, rejected), `managerId`
- **`hr_skills`**: `id`, `employeeId`, `skillName`, `proficiencyLevel`, `certificationExpiryDate`
- **`hr_applicants` (ATS)**: `id`, `jobId`, `firstName`, `lastName`, `email`, `resumeUrl`, `status` (applied, interviewing, offered, rejected)
- **`hr_shifts`**: `id`, `employeeId`, `startTime`, `endTime`, `locationId`, `status`

### Project Operations
- **`pm_projects`**: `id`, `name`, `customerId`, `projectManagerId`, `startDate`, `endDate`, `budget`, `status`, `billingType` (Time&Material, Fixed, Retainer)
- **`pm_tasks`**: `id`, `projectId`, `title`, `assignedToId`, `startDate`, `dueDate`, `estimatedHours`, `actualHours`, `status`, `milestoneId`
- **`pm_timesheets`**: `id`, `employeeId`, `periodStartDate`, `periodEndDate`, `status`
  - *Sub-collection* `entries`: `projectId`, `taskId`, `date`, `hours`, `description`, `billableStatus`
- **`pm_expenses`**: `id`, `employeeId`, `projectId`, `amount`, `category`, `receiptUrl`, `status`, `policyViolations[]`

### Field Service
- **`fs_work_orders`**: `id`, `title`, `customerId`, `serviceAddress`, `priority`, `status` (unassigned, scheduled, in_progress, completed), `scheduledDate`, `technicianId`, `iotAlertId`
- **`fs_assets`** (Customer Equipment): `id`, `customerId`, `name`, `serialNumber`, `installationDate`, `lastMaintenanceDate`, `telemetryEndpoint`
- **`fs_truck_inventory`**: `id`, `technicianId`, `productId`, `quantity`

### Customer Service
- **`cs_cases` (Tickets)**: `id`, `customerId`, `contactId`, `subject`, `description`, `priority`, `status` (new, working, waiting, resolved), `ownerId`, `createdDate`, `slaDeadline`, `sentimentScore`
- **`cs_knowledge_base`**: `id`, `title`, `content`, `category`, `tags`, `isPublished`
- **`cs_entitlements`**: `id`, `customerId`, `contractType`, `startDate`, `endDate`, `remainingHours`, `supportLevel`
- **`cs_feedback`**: `id`, `caseId`, `customerId`, `npsScore`, `comments`, `date`

### Supply Chain Management (SCM)
- **`scm_products`**: `id`, `sku`, `name`, `description`, `category`, `unitCost`, `salePrice`, `stockQuantity`, `reorderLevel`, `isManufactured`
  - *Sub-collection* `bom_lines`: `componentProductId`, `quantityRequired`
- **`scm_purchase_orders`**: `id`, `vendorId`, `status` (draft, submitted, received, paid), `totalAmount`, `orderDate`, `expectedDeliveryDate`
  - *Sub-collection* `lines`: `productId`, `quantity`, `unitCost`
- **`scm_vendors`**: `id`, `name`, `contactPerson`, `email`, `paymentTerms`
- **`scm_warehouses`**: `id`, `name`, `location`, `managerId`
- **`scm_transfers`**: `id`, `fromWarehouseId`, `toWarehouseId`, `status`, `dispatchDate`, `receiptDate`
  - *Sub-collection* `items`: `productId`, `quantity`

---

## 🤖 4. The 15-Agent Swarm Execution Plan

To execute a project of this magnitude quickly and flawlessly, a massive Swarm Orchestration is required. I will act as the **Head Agent (Orchestrator)** and spawn 15 highly specialized agents across multiple phases.

### Phase 1: Database & Architecture Foundation
* **Agent 1 (DB Architect)**: Implements the exact NoSQL schema outlined above in Dart Models and Repositories.
* **Agent 2 (Router Specialist)**: Re-architects `app_router.dart` to feature the new Root Launchpad and dynamically load the 7 new core modules.
* **Agent 3 (Auth/Identity)**: Ensures strict RBAC across these new modules (e.g., HR sees HR, Finance sees Finance).

### Phase 2: Finance & Project Operations
* **Agent 4 (Finance Lead)**: Builds General Ledger, Chart of Accounts, and Journal Entry UIs.
* **Agent 5 (AP/AR Specialist)**: Builds the Invoicing, Billing, and AP/AR dashboards.
* **Agent 6 (PMO Architect)**: Builds Project, Task, and Gantt interfaces.
* **Agent 7 (Time/Expense Dev)**: Builds Timesheets and Expense report workflows.

### Phase 3: CRM (Sales & Customer Service)
* **Agent 8 (Sales CRM Dev)**: Builds the Lead/Opportunity Kanban pipeline, Accounts, and Quotes UI.
* **Agent 9 (Customer Service Dev)**: Builds the Ticketing system, SLA timers, and Knowledge Base.

### Phase 4: SCM, Field Service & HR
* **Agent 10 (Supply Chain Dev)**: Builds Inventory Management and Purchase Order workflows.
* **Agent 11 (Field Service Dev)**: Builds the Dispatcher Board, Work Orders, and Technician Mobile views.
* **Agent 12 (HR Systems Dev)**: Retrofits our existing Employee Hub into the new HR Core and builds Compensation/Benefits screens.

### Phase 5: Integration & Polish
* **Agent 13 (Legacy Migrator)**: Refactors the existing EHS/Risk modules to hook into the new Project & Field Service modules.
* **Agent 14 (AI Integrator)**: Upgrades the Copilot to comprehend the massive new schema, allowing prompts like "What is our current Accounts Receivable total?" or "Who is the best technician for Work Order #412?".
* **Agent 15 (QA/UX Polish)**: Sweeps the entire UI to ensure it feels like a cohesive, $1M+ ARR Enterprise Business OS.

---

## Open Questions for the User
1. **Module Prioritization**: Do you want the Swarm to build all 7 pillars simultaneously, or should we focus on a specific combination first (e.g., Finance + CRM)?
2. **Third-Party Integrations**: Do you foresee immediate integration requirements (e.g., Plaid/Stripe for Finance, Twilio for Customer Service) that the Swarm should configure *during* the build?
3. **Approval**: If you are satisfied with this architecture and the 15-Agent plan, approve this document, and the Head Agent will initialize the Swarm immediately!
