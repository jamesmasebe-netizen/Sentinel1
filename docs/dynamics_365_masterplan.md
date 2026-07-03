# 🌌 Sentinel Business OS: The Dynamics 365 Competitor

## Goal Description
Transform the existing application into a fully-fledged, modular Enterprise Business OS capable of competing directly with Microsoft Dynamics 365. The app will open to a "Module Launchpad" featuring the 7 Core ERP/CRM pillars: Finance, Project Operations, Human Resources, Field Service, Customer Service, Sales, and Supply Chain Management. All existing features (Safety, Risk, Environment, etc.) will be seamlessly integrated as specialized operational extensions.

> [!IMPORTANT]
> **User Review Required**: Because this is a monumental shift in application scope, please review the proposed 7 Pillar UI Mapping and the Firestore Database Schema. A full ERP requires extensive data relationships; we have translated standard SQL ERP schemas into an optimized NoSQL structure for Firebase.

---

## 🏛️ 1. The Module Launchpad & UI Reorganization
When users log in, they will no longer land on a generic dashboard. They will land on the **Sentinel Business OS Launchpad**, greeting them with large tiles for the modules they are licensed for.

**Existing Code Mapping:**
- **Risk, Safety, Emergency, Environment**: Will be grouped under an "EHS & Risk Management" standalone module, directly integrated with *Project Operations* and *Field Service*.
- **Property & Equipment**: Migrates into the *Supply Chain & Asset Management* module.
- **AI Copilot**: Becomes an omnipresent floating overlay accessible across every module.
- **Employee Hub**: Fuses completely into the *Human Resources* module.

---

## 🏗️ 2. The 7 Pillars of the Business OS (Dynamics 365 Counterparts)

### 1. Finance (Dynamics 365 Finance)
* **Functionality**: General Ledger, Accounts Payable, Accounts Receivable, Fixed Assets, Bank Reconciliation, and Financial Reporting.
* **Core Screens**: CFO Dashboard, Chart of Accounts, Journal Entries, Invoicing, Tax Configuration.

### 2. Project Operations (Dynamics 365 Project Operations)
* **Functionality**: Project Planning (Gantt), Resource Allocation, Time & Expense Tracking, Project Costing, and Billing.
* **Core Screens**: PMO Dashboard, Resource Scheduler, Timesheets, Project Budgets.

### 3. Human Resources (Dynamics 365 Human Resources)
* **Functionality**: Core HR, Competency Passports, Leave & Absence, Compensation, Benefits, Onboarding, Employee 360.
* **Core Screens**: HR Director Dashboard, Employee Roster, Leave Approvals, Performance Reviews.

### 4. Field Service (Dynamics 365 Field Service)
* **Functionality**: Work Orders, Dispatching, Route Optimization, Contractor Management, Remote Assist (Video).
* **Core Screens**: Dispatcher Board, Work Order details, Technician Mobile View, Asset Maintenance.

### 5. Customer Service (Dynamics 365 Customer Service)
* **Functionality**: Case/Ticket Management, Omnichannel Routing, SLAs, Knowledge Base, Customer Portals.
* **Core Screens**: Agent Workspace, SLA Timers, Ticket Queue, Knowledge Articles.

### 6. Sales (Dynamics 365 Sales)
* **Functionality**: CRM, Leads, Opportunities, Accounts, Contacts, Forecasting, Quotes to Orders.
* **Core Screens**: Pipeline Kanban Board, Account 360, Quote Generator, Sales Forecasting.

### 7. Supply Chain Management (Dynamics 365 SCM)
* **Functionality**: Procurement (Purchase Orders), Inventory Management, Warehousing, Vendor Portals.
* **Core Screens**: Inventory Levels, PO Approvals, Vendor Database, Warehouse Flow.

---

## 🗄️ 3. Granular Firestore Database Schema (Multi-Tenant)
To ensure we do not miss any "tables or columns", all data remains partitioned under `/tenants/{tenantId}`. We will use a hybrid approach of Root Collections for top-level entities, and Sub-Collections for high-volume nested data (like Journal Lines or Timesheets).

### Shared Global Entities
- **`/users`**: `id`, `name`, `email`, `role`, `tenantIds[]`

### Finance
- **`finance_accounts` (Chart of Accounts)**: `id`, `accountCode`, `name`, `type` (asset, liability, equity, revenue, expense), `currency`, `currentBalance`, `isActive`
- **`finance_journals` (GL Entries)**: `id`, `date`, `description`, `status` (draft, posted), `createdBy`, `totalDebit`, `totalCredit`
  - *Sub-collection* `lines`: `accountId`, `debit`, `credit`, `memo`, `projectId` (for cross-module tagging)
- **`finance_invoices` (AP/AR)**: `id`, `type` (payable, receivable), `accountId`, `customerId/vendorId`, `issueDate`, `dueDate`, `amount`, `status`
  - *Sub-collection* `lineItems`: `description`, `quantity`, `unitPrice`, `taxRate`

### Sales (CRM)
- **`crm_accounts`**: `id`, `name`, `industry`, `website`, `phone`, `billingAddress`, `shippingAddress`, `status`
- **`crm_contacts`**: `id`, `accountId`, `firstName`, `lastName`, `email`, `phone`, `title`, `isPrimary`
- **`crm_opportunities`**: `id`, `accountId`, `title`, `stage` (prospecting, qualification, proposal, closed_won, closed_lost), `amount`, `probability`, `expectedCloseDate`, `assignedUserId`
- **`crm_quotes`**: `id`, `opportunityId`, `totalAmount`, `status`, `validUntil`

### Human Resources
- **`hr_employees`**: `id`, `userId`, `employeeId`, `department`, `managerId`, `hireDate`, `employmentType`, `baseSalary`
- **`hr_leave_requests`**: `id`, `employeeId`, `leaveType`, `startDate`, `endDate`, `status` (pending, approved, rejected), `managerId`
- **`hr_skills`**: `id`, `employeeId`, `skillName`, `proficiencyLevel`, `certificationExpiryDate`

### Project Operations
- **`pm_projects`**: `id`, `name`, `customerId`, `projectManagerId`, `startDate`, `endDate`, `budget`, `status`
- **`pm_tasks`**: `id`, `projectId`, `title`, `assignedToId`, `startDate`, `dueDate`, `estimatedHours`, `actualHours`, `status`
- **`pm_timesheets`**: `id`, `employeeId`, `periodStartDate`, `periodEndDate`, `status`
  - *Sub-collection* `entries`: `projectId`, `taskId`, `date`, `hours`, `description`

### Field Service
- **`fs_work_orders`**: `id`, `title`, `customerId`, `serviceAddress`, `priority`, `status` (unassigned, scheduled, in_progress, completed), `scheduledDate`, `technicianId`
- **`fs_assets`** (Customer Equipment): `id`, `customerId`, `name`, `serialNumber`, `installationDate`, `lastMaintenanceDate`

### Customer Service
- **`cs_cases` (Tickets)**: `id`, `customerId`, `contactId`, `subject`, `description`, `priority`, `status` (new, working, waiting, resolved), `ownerId`, `createdDate`, `slaDeadline`
- **`cs_knowledge_base`**: `id`, `title`, `content`, `category`, `tags`, `isPublished`

### Supply Chain Management (SCM)
- **`scm_products`**: `id`, `sku`, `name`, `description`, `category`, `unitCost`, `salePrice`, `stockQuantity`, `reorderLevel`
- **`scm_purchase_orders`**: `id`, `vendorId`, `status` (draft, submitted, received, paid), `totalAmount`, `orderDate`, `expectedDeliveryDate`
  - *Sub-collection* `lines`: `productId`, `quantity`, `unitCost`
- **`scm_vendors`**: `id`, `name`, `contactPerson`, `email`, `paymentTerms`

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
