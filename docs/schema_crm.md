# Enterprise CRM Database Schema (Firestore)

This document outlines an exhaustive, enterprise-grade NoSQL database schema designed for the Sales & CRM pillar (competing with platforms like Dynamics 365 Sales or Salesforce). It covers the full Lead-to-Opportunity flow, Quote generation, Sales forecasting, and Relationship insights.

## 1. Core CRM Entities

### Collection: `accounts`
Represents B2B companies or organizations.
- **`id`** (String): Unique identifier
- **`name`** (String): Company name
- **`industry`** (String): Sector (e.g., Technology, Healthcare)
- **`website`** (String): URL
- **`annualRevenue`** (Number): Yearly revenue in base currency
- **`employeeCount`** (Number): Number of employees
- **`billingAddress`** (Map): `{ street, city, state, postalCode, country }`
- **`shippingAddress`** (Map): `{ street, city, state, postalCode, country }`
- **`ownerId`** (String): Reference to `users` (Account Manager)
- **`territoryId`** (String, optional): Reference to `territories`
- **`parentAccountId`** (String, optional): For enterprise hierarchies
- **`status`** (String): `Active`, `Inactive`, `Prospect`
- **`relationshipHealth`** (String): `Green`, `Yellow`, `Red` (AI-derived)
- **`createdAt`** (Timestamp)
- **`updatedAt`** (Timestamp)

#### Sub-collection: `accounts/{accountId}/account_team`
Users assigned to this account with specific roles.
- **`userId`** (String)
- **`role`** (String): e.g., `Executive Sponsor`, `Solutions Architect`, `Customer Success`
- **`accessLevel`** (String): `Read`, `Write`, `Admin`

#### Sub-collection: `accounts/{accountId}/notes`
Contextual notes and attachments.
- **`authorId`** (String)
- **`content`** (String)
- **`pinned`** (Boolean)
- **`createdAt`** (Timestamp)

### Collection: `contacts`
Represents individual people associated with Accounts.
- **`id`** (String)
- **`accountId`** (String): Reference to `accounts`
- **`firstName`** (String)
- **`lastName`** (String)
- **`email`** (String)
- **`phone`** (String)
- **`mobile`** (String)
- **`jobTitle`** (String)
- **`department`** (String)
- **`leadSource`** (String): Origin of the contact
- **`isPrimary`** (Boolean): Is primary contact for the account
- **`ownerId`** (String): Reference to `users`
- **`createdAt`** (Timestamp)
- **`updatedAt`** (Timestamp)

## 2. Lead-to-Opportunity Flow

### Collection: `leads`
Unqualified prospects before they are converted into Accounts/Contacts/Opportunities.
- **`id`** (String)
- **`firstName`** (String)
- **`lastName`** (String)
- **`company`** (String)
- **`email`** (String)
- **`phone`** (String)
- **`leadSource`** (String): `Web`, `Referral`, `Trade Show`, `Cold Call`
- **`status`** (String): `New`, `Attempted Contact`, `Engaged`, `Qualified`, `Unqualified`
- **`rating`** (String): `Hot`, `Warm`, `Cold`
- **`aiLeadScore`** (Number): 0-100 probability of conversion
- **`sequenceId`** (String, optional): Reference to `sequence_trackers` (Active sales cadence)
- **`ownerId`** (String): Reference to `users`
- **`isConverted`** (Boolean): Flag for conversion state
- **`convertedAccountId`** (String, optional)
- **`convertedContactId`** (String, optional)
- **`convertedOpportunityId`** (String, optional)
- **`createdAt`** (Timestamp)
- **`updatedAt`** (Timestamp)

### Collection: `opportunities`
Qualified deals in the pipeline.
- **`id`** (String)
- **`name`** (String): Deal name (e.g., "Acme Corp - Q4 Enterprise License")
- **`accountId`** (String): Reference to `accounts`
- **`primaryContactId`** (String): Reference to `contacts`
- **`stage`** (String): `Prospecting`, `Discovery`, `Value Proposition`, `Proposal`, `Negotiation`, `Closed Won`, `Closed Lost`
- **`amount`** (Number): Total estimated value
- **`probability`** (Number): 0-100% based on stage
- **`expectedCloseDate`** (Timestamp)
- **`forecastCategory`** (String): `Pipeline`, `Best Case`, `Commit`, `Omitted`, `Closed`
- **`leadSource`** (String)
- **`nextStep`** (String): Text describing the immediate next action
- **`ownerId`** (String): Reference to `users`
- **`lossReason`** (String, optional): Reason if `Closed Lost`
- **`createdAt`** (Timestamp)
- **`updatedAt`** (Timestamp)

#### Sub-collection: `opportunities/{opportunityId}/opportunity_products`
Line items for the deal.
- **`productId`** (String)
- **`quantity`** (Number)
- **`salesPrice`** (Number)
- **`discount`** (Number)
- **`totalPrice`** (Number)

#### Sub-collection: `opportunities/{opportunityId}/competitors`
Tracking competing vendors.
- **`competitorId`** (String, optional): Reference to global `competitors` collection
- **`competitorName`** (String)
- **`strengths`** (String)
- **`weaknesses`** (String)

## 3. Products & Quoting

### Collection: `products`
The master catalog of items/services for sale.
- **`id`** (String)
- **`name`** (String)
- **`sku`** (String)
- **`description`** (String)
- **`family`** (String): `Software`, `Hardware`, `Services`
- **`isActive`** (Boolean)
- **`standardPrice`** (Number)
- **`createdAt`** (Timestamp)
- **`updatedAt`** (Timestamp)

### Collection: `quotes`
Formal pricing documents generated from Opportunities.
- **`id`** (String)
- **`opportunityId`** (String): Reference to `opportunities`
- **`accountId`** (String): Reference to `accounts`
- **`quoteNumber`** (String): Formatted sequential string (e.g., "Q-10042")
- **`status`** (String): `Draft`, `Needs Approval`, `Presented`, `Accepted`, `Rejected`, `Expired`
- **`expirationDate`** (Timestamp)
- **`subtotal`** (Number)
- **`discount`** (Number)
- **`tax`** (Number)
- **`grandTotal`** (Number)
- **`billingAddress`** (Map)
- **`shippingAddress`** (Map)
- **`termsAndConditions`** (String)
- **`isSyncing`** (Boolean): True if this quote drives the Opportunity amount
- **`ownerId`** (String)
- **`createdAt`** (Timestamp)
- **`updatedAt`** (Timestamp)

#### Sub-collection: `quotes/{quoteId}/quote_line_items`
- **`productId`** (String)
- **`productName`** (String)
- **`quantity`** (Number)
- **`unitPrice`** (Number)
- **`discountPercentage`** (Number)
- **`totalPrice`** (Number)

## 4. Activities & Relationship Insights

### Collection: `activities`
Interactions mapped to CRM records (polymorphic).
- **`id`** (String)
- **`type`** (String): `Email`, `Call`, `Meeting`, `Task`
- **`subject`** (String)
- **`description`** (String)
- **`status`** (String): `Open`, `Completed`, `Deferred`
- **`priority`** (String): `Low`, `Normal`, `High`
- **`dueDate`** (Timestamp)
- **`completedDate`** (Timestamp)
- **`ownerId`** (String): Reference to `users`
- **`relatedTo`** (Map): `{ entityType: "accounts"|"opportunities"|"quotes", entityId: String }` (What this is about)
- **`whoId`** (Map): `{ entityType: "contacts"|"leads", entityId: String }` (Who this is with)
- **`aiSentimentScore`** (Number): Derived from email/call transcripts (-1.0 to 1.0)
- **`conversationIntelligenceId`** (String, optional): Reference to `conversation_intelligence` for advanced call analytics
- **`createdAt`** (Timestamp)
- **`updatedAt`** (Timestamp)

## 5. Sales Forecasting

### Collection: `sales_forecasts`
Snapshot data for quarterly/monthly projections.
- **`id`** (String)
- **`ownerId`** (String): Reference to `users` (Rep or Manager)
- **`period`** (String): e.g., `Q3-2026`
- **`startDate`** (Timestamp)
- **`endDate`** (Timestamp)
- **`quota`** (Number): Target for the period
- **`closedRevenue`** (Number): Sum of Closed Won opportunities
- **`commitForecast`** (Number): Sum of Commit category
- **`bestCaseForecast`** (Number): Sum of Commit + Best Case + Pipeline
- **`pipelineCoverage`** (Number): Ratio of pipeline to quota
- **`managerAdjustedCommit`** (Number): Manager's override
- **`createdAt`** (Timestamp)
- **`updatedAt`** (Timestamp)

## 6. Advanced Sales Capabilities

### Collection: `territories`
Represents geographic or industry-based sales territories for advanced territory management.
- **`id`** (String)
- **`name`** (String): e.g., "North America - Enterprise"
- **`managerId`** (String): Reference to `users`
- **`parentTerritoryId`** (String, optional): For hierarchical rollups
- **`description`** (String)
- **`createdAt`** (Timestamp)
- **`updatedAt`** (Timestamp)

#### Sub-collection: `territories/{territoryId}/postal_codes`
Zip/Postal codes mapped to this territory.
- **`code`** (String)

### Collection: `competitors`
Master repository of competitor profiles to enable battlecards and win/loss analysis.
- **`id`** (String)
- **`name`** (String)
- **`website`** (String)
- **`strengths`** (String)
- **`weaknesses`** (String)
- **`threatLevel`** (String): `Low`, `Medium`, `High`
- **`winLossRatio`** (Number): Historical win rate against this competitor
- **`createdAt`** (Timestamp)
- **`updatedAt`** (Timestamp)

### Collection: `sales_literature`
Centralized repository for sales collateral, battlecards, and brochures.
- **`id`** (String)
- **`title`** (String)
- **`subject`** (String)
- **`type`** (String): `Presentation`, `Whitepaper`, `Battlecard`, `Brochure`
- **`fileUrl`** (String): Link to cloud storage
- **`productId`** (String, optional): Reference to `products`
- **`competitorId`** (String, optional): Reference to `competitors` (for battlecards)
- **`expirationDate`** (Timestamp)
- **`createdAt`** (Timestamp)
- **`updatedAt`** (Timestamp)

## 7. Sales Engagement & Automated Sequences

### Collection: `sales_sequences`
Automated outreach cadences (sequences of emails, calls, and tasks) for high-velocity sales.
- **`id`** (String)
- **`name`** (String)
- **`description`** (String)
- **`ownerId`** (String): Reference to `users`
- **`isActive`** (Boolean)
- **`totalSteps`** (Number)
- **`createdAt`** (Timestamp)
- **`updatedAt`** (Timestamp)

#### Sub-collection: `sales_sequences/{sequenceId}/steps`
- **`stepNumber`** (Number)
- **`type`** (String): `AutoEmail`, `ManualEmail`, `PhoneCall`, `LinkedInMessage`, `Task`
- **`waitDays`** (Number): Days to wait before executing this step
- **`templateId`** (String, optional): Email or script template reference

### Collection: `sequence_trackers`
Tracks a Lead or Contact's progress through a sales sequence.
- **`id`** (String)
- **`sequenceId`** (String): Reference to `sales_sequences`
- **`targetId`** (Map): `{ entityType: "leads"|"contacts", entityId: String }`
- **`currentStep`** (Number)
- **`status`** (String): `Active`, `Paused`, `Completed`, `OptedOut`, `Bounced`, `Replied`
- **`enrolledBy`** (String): Reference to `users`
- **`enrolledAt`** (Timestamp)
- **`lastActionAt`** (Timestamp)
- **`updatedAt`** (Timestamp)

## 8. Sales Copilot & Conversation Intelligence

### Collection: `conversation_intelligence`
AI-generated analysis of calls and meetings.
- **`id`** (String)
- **`activityId`** (String): Reference to `activities`
- **`transcriptUrl`** (String): Link to full transcript
- **`summary`** (String): AI-generated summary of the meeting
- **`talkToListenRatio`** (Number): e.g., 0.45 (45% talking)
- **`longestMonologue`** (Number): In seconds
- **`competitorsMentioned`** (Array of Strings)
- **`keywordsMentioned`** (Array of Strings)
- **`customerSentiment`** (String): `Positive`, `Neutral`, `Negative`
- **`createdAt`** (Timestamp)

#### Sub-collection: `conversation_intelligence/{ciId}/action_items`
Extracted next steps from the call.
- **`description`** (String)
- **`assigneeId`** (String, optional): Reference to `users`
- **`dueDate`** (Timestamp, optional)
- **`isCompleted`** (Boolean)

### Collection: `ai_insights`
Contextual Sales Copilot recommendations surfaced on Accounts or Opportunities.
- **`id`** (String)
- **`relatedTo`** (Map): `{ entityType: "accounts"|"opportunities"|"leads", entityId: String }`
- **`insightType`** (String): `CrossSell`, `AtRisk`, `NextBestAction`, `AnomalyDetection`
- **`title`** (String): e.g., "Account at risk of churn" or "Suggest pitching Premium Support"
- **`description`** (String): Detailed AI reasoning
- **`confidenceScore`** (Number): 0-100%
- **`status`** (String): `New`, `Accepted`, `Dismissed`
- **`createdAt`** (Timestamp)
- **`updatedAt`** (Timestamp)
