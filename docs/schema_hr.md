# Enterprise Human Resources (HCM) - Firestore Database Schema

## Overview
This document outlines the exhaustive, granular NoSQL (Firestore) database schema for the Human Resources (HCM) pillar, positioned to compete with enterprise solutions like Dynamics 365 HR. The schema scales to support complex organizational hierarchies, sophisticated leave accrual engines, comprehensive benefit administration, continuous performance management (OKRs), and an integrated learning ecosystem (Competency Passports and LMS).

---

## 1. Core Organizational Hierarchy

### Collection: `departments`
Represents the structural units of the organization, supporting deep nesting for complex hierarchies.
*   **Document ID:** `departmentId`
*   **Fields:**
    *   `name` (String): Department name (e.g., "Software Engineering").
    *   `code` (String): Unique department code.
    *   `parentDepartmentId` (String, nullable): Reference to the parent department (for hierarchical trees).
    *   `managerEmployeeId` (String, nullable): Reference to the `employees` collection for the department head.
    *   `costCenterCode` (String): Financial tracking code.
    *   `isActive` (Boolean): Active status.
    *   `createdAt` (Timestamp)
    *   `updatedAt` (Timestamp)

### Collection: `positions`
Represents job roles within the organization, independently of the individuals filling them.
*   **Document ID:** `positionId`
*   **Fields:**
    *   `title` (String): Job title (e.g., "Senior Backend Engineer").
    *   `jobCode` (String): Internal classification code.
    *   `departmentId` (String): Reference to `departments`.
    *   `reportsToPositionId` (String, nullable): Supervisor's position ID.
    *   `gradeLevel` (String/Number): Pay grade or band.
    *   `isFullTime` (Boolean)
    *   `flsaStatus` (String): "Exempt" or "Non-Exempt".
    *   `requiredCompetencies` (Array of Objects):
        *   `competencyId` (String)
        *   `minimumProficiencyLevel` (Number)

---

## 2. Employee Core Data

### Collection: `employees`
Central entity for all workforce personnel (employees, contractors).
*   **Document ID:** `employeeId`
*   **Fields:**
    *   `firstName` (String)
    *   `lastName` (String)
    *   `preferredName` (String, nullable)
    *   `workEmail` (String)
    *   `personalEmail` (String)
    *   `phoneNumber` (String)
    *   `hireDate` (Date)
    *   `terminationDate` (Date, nullable)
    *   `employmentStatus` (String): e.g., "Active", "Terminated", "On Leave", "Contractor".
    *   `positionId` (String): Current primary role.
    *   `departmentId` (String): Current department.
    *   `managerEmployeeId` (String): Direct supervisor.
    *   `workLocation` (Object):
        *   `type` (String): "Remote", "Office", "Hybrid".
        *   `officeId` (String, nullable)
    *   `compensation` (Object):
        *   `baseSalary` (Number)
        *   `currency` (String)
        *   `payFrequency` (String)

#### Sub-collection: `employees/{employeeId}/employment_history`
Tracks all role and compensation changes over time.
*   **Document ID:** `historyId` (auto-generated)
*   **Fields:**
    *   `effectiveDate` (Timestamp)
    *   `changeType` (String): "Promotion", "Transfer", "Pay Adjustment", "New Hire".
    *   `previousPositionId` (String, nullable)
    *   `newPositionId` (String)
    *   `previousSalary` (Number, nullable)
    *   `newSalary` (Number)
    *   `reason` (String)

---

## 3. Leave Accrual & Absence Management

### Collection: `leave_policies`
Defines the rules for how time off is earned and consumed.
*   **Document ID:** `policyId`
*   **Fields:**
    *   `name` (String): e.g., "Standard US PTO Accrual".
    *   `type` (String): "Vacation", "Sick", "Maternity", "Bereavement".
    *   `accrualRate` (Number): Hours earned per period.
    *   `accrualPeriod` (String): "Bi-weekly", "Monthly", "Annually".
    *   `maxBalance` (Number): Maximum hours allowed to bank.
    *   `carryoverLimit` (Number): Hours allowed to roll over at year-end.
    *   `eligibilityRules` (Map): e.g., minimum tenure required.

#### Sub-collection: `employees/{employeeId}/leave_balances`
Current state of the accrual engine for an individual.
*   **Document ID:** `leaveTypeId` (matches `leave_policies.type`)
*   **Fields:**
    *   `accruedHours` (Number): Total hours earned.
    *   `usedHours` (Number): Total hours taken.
    *   `pendingHours` (Number): Hours requested but not yet taken.
    *   `availableBalance` (Number): Calculated dynamically (accrued - used - pending).
    *   `lastAccrualDate` (Timestamp)

#### Sub-collection: `employees/{employeeId}/leave_requests`
Transactional records of time off.
*   **Document ID:** `requestId`
*   **Fields:**
    *   `leaveTypeId` (String)
    *   `startDate` (Timestamp)
    *   `endDate` (Timestamp)
    *   `totalHoursRequested` (Number)
    *   `status` (String): "Draft", "Submitted", "Approved", "Denied", "Cancelled".
    *   `approverId` (String): Employee ID of the manager.
    *   `reason` (String)
    *   `medicalCertificateUrl` (String, nullable)

---

## 4. Benefit Administration

### Collection: `benefit_plans`
Master catalog of all available benefits.
*   **Document ID:** `planId`
*   **Fields:**
    *   `providerName` (String): e.g., "Blue Cross", "Fidelity".
    *   `planType` (String): "Medical", "Dental", "Vision", "401k", "Life".
    *   `planName` (String)
    *   `coverageTiers` (Array of Objects):
        *   `tierName` (String): "Employee Only", "Family", etc.
        *   `employeeCostPerPeriod` (Number)
        *   `employerCostPerPeriod` (Number)
    *   `openEnrollmentStart` (Timestamp)
    *   `openEnrollmentEnd` (Timestamp)

#### Sub-collection: `employees/{employeeId}/benefit_enrollments`
Specific benefits an employee is currently enrolled in.
*   **Document ID:** `enrollmentId`
*   **Fields:**
    *   `planId` (String): Reference to `benefit_plans`.
    *   `planType` (String)
    *   `coverageTier` (String)
    *   `status` (String): "Active", "Waived", "Pending Validation".
    *   `effectiveDate` (Timestamp)
    *   `dependentsCovered` (Array of Strings): References to dependent IDs.
    *   `employeeContribution` (Number)
    *   `employerContribution` (Number)

#### Sub-collection: `employees/{employeeId}/dependents`
Family members linked for benefit purposes.
*   **Document ID:** `dependentId`
*   **Fields:**
    *   `firstName` (String)
    *   `lastName` (String)
    *   `relationship` (String): "Spouse", "Child", "Domestic Partner".
    *   `dateOfBirth` (Timestamp)
    *   `isStudent` (Boolean)

---

## 5. Continuous Performance & OKR Tracking

### Collection: `performance_cycles`
Global timeframes for goal setting and reviews.
*   **Document ID:** `cycleId`
*   **Fields:**
    *   `name` (String): e.g., "Q3 2026 OKRs", "2026 Annual Review".
    *   `startDate` (Timestamp)
    *   `endDate` (Timestamp)
    *   `status` (String): "Planning", "Active", "Grading", "Closed".

#### Sub-collection: `employees/{employeeId}/okrs`
Objectives and Key Results for the employee.
*   **Document ID:** `okrId`
*   **Fields:**
    *   `cycleId` (String)
    *   `objective` (String): e.g., "Launch new HCM Mobile App".
    *   `weight` (Number): Percentage importance.
    *   `alignment` (String, nullable): Reference to parent OKR or company goal.
    *   `keyResults` (Array of Objects):
        *   `krId` (String)
        *   `description` (String)
        *   `targetValue` (Number)
        *   `currentValue` (Number)
        *   `unit` (String)
    *   `overallProgress` (Number): 0 to 100%.
    *   `status` (String): "On Track", "At Risk", "Behind".

#### Sub-collection: `employees/{employeeId}/performance_reviews`
Formal evaluations.
*   **Document ID:** `reviewId`
*   **Fields:**
    *   `cycleId` (String)
    *   `managerId` (String)
    *   `selfEvaluation` (Map): Q&A from the employee.
    *   `managerEvaluation` (Map): Q&A from the manager.
    *   `peerFeedback` (Array of Objects): 360-degree feedback references.
    *   `overallRating` (Number/String): e.g., 4.5 out of 5, or "Exceeds Expectations".
    *   `status` (String): "Draft", "Pending Approval", "Completed".

---

## 6. Competency Passports & LMS Training

### Collection: `competency_dictionary`
Global taxonomy of skills.
*   **Document ID:** `competencyId`
*   **Fields:**
    *   `category` (String): "Technical", "Leadership", "Soft Skill".
    *   `name` (String): e.g., "Cloud Architecture", "Conflict Resolution".
    *   `description` (String)
    *   `levels` (Array of Strings): Description of what level 1 through 5 means.

#### Sub-collection: `employees/{employeeId}/competency_passport`
The employee's verified skill profile.
*   **Document ID:** `passportEntryId` (matches `competencyId`)
*   **Fields:**
    *   `proficiencyLevel` (Number): Current skill level (1-5).
    *   `lastAssessedDate` (Timestamp)
    *   `assessedBy` (String, nullable): Manager or System ID.
    *   `evidence` (Array of Strings): Links to projects, reviews, or certificates proving this skill.

### Collection: `lms_courses`
Master catalog of internal/external training.
*   **Document ID:** `courseId`
*   **Fields:**
    *   `title` (String)
    *   `description` (String)
    *   `provider` (String): e.g., "Internal", "LinkedIn Learning", "Coursera".
    *   `format` (String): "Video", "Interactive", "In-Person".
    *   `durationMinutes` (Number)
    *   `grantsCompetencies` (Array of Objects):
        *   `competencyId` (String)
        *   `grantedLevel` (Number)
    *   `isMandatory` (Boolean) (e.g., Compliance training).

#### Sub-collection: `employees/{employeeId}/training_records`
Employee's progress through the LMS.
*   **Document ID:** `recordId`
*   **Fields:**
    *   `courseId` (String)
    *   `status` (String): "Not Started", "In Progress", "Completed", "Expired".
    *   `progressPercentage` (Number)
    *   `enrollmentDate` (Timestamp)
    *   `completionDate` (Timestamp, nullable)
    *   `score` (Number, nullable): Quiz/Test score.
    *   `certificateUrl` (String, nullable)
