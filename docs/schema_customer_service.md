# Firestore Database Schema: Customer Service

This document defines the highly granular, enterprise-grade NoSQL (Firestore) database schema for the Customer Service pillar. It is designed to scale and support capabilities found in leading solutions like Dynamics 365 Customer Service.

## Root Collections

- `cs_tickets` (Cases/Tickets tracking)
- `cs_customers` (Profiles/Accounts linked to CRM for support)
- `cs_agents` (Agent profiles, capacity, skills, presence)
- `cs_entitlements` (Service Level Agreements, Support Contracts)
- `cs_knowledge_articles` (Knowledge Base management)
- `cs_queues` (Omnichannel Routing Queues)
- `cs_routing_rules` (Logic for Omnichannel Routing)

---

### Collection: `cs_tickets`

The central entity for customer issues, queries, or requests.

**Document ID:** Auto-generated ID (`ticketId`)

**Fields:**
- `id` (string): Unique human-readable identifier (e.g., "CAS-10023-X9Y8")
- `customerId` (string): Reference to `cs_customers` document
- `contactId` (string): Reference to specific contact person (if B2B)
- `title` (string): Brief description of the issue
- `description` (string): Detailed problem statement
- `status` (string): `New`, `Assigned`, `In Progress`, `Waiting on Customer`, `Resolved`, `Closed`
- `priority` (string): `Low`, `Medium`, `High`, `Critical`
- `severity` (string): `1`, `2`, `3`, `4`
- `channel` (string): Origination channel (`Email`, `Phone`, `Chat`, `Web`, `Social`, `SMS`)
- `assignedTo` (string): Reference to `cs_agents` document (Agent ID)
- `queueId` (string): Reference to `cs_queues` document currently handling the ticket
- `entitlementId` (string): Reference to `cs_entitlements` document applied to this ticket
- `slaStatus` (string): `In Compliance`, `Nearing Noncompliance`, `Noncompliant`
- `slaTimers` (map):
  - `firstResponseBy` (timestamp): Deadline for first agent reply
  - `resolveBy` (timestamp): Deadline for issue resolution
  - `pausedTime` (number): Cumulative paused seconds (e.g., when Waiting on Customer)
- `tags` (array of strings): Categories, keywords, or issue types
- `customFields` (map): Tenant-specific custom attributes
- `firstResponseAt` (timestamp): Actual time of first response
- `createdAt` (timestamp): Ticket creation time
- `updatedAt` (timestamp): Last modification time
- `resolvedAt` (timestamp): Resolution time
- `closedAt` (timestamp): Permanent closure time

#### Sub-collection: `messages` (Omnichannel communication)

Records all interactions across different channels within the ticket.

**Document ID:** Auto-generated ID

**Fields:**
- `senderId` (string): Agent ID, Customer ID, or Bot ID
- `senderType` (string): `Agent`, `Customer`, `System`, `Bot`
- `channel` (string): `Email`, `Chat`, `SMS`, `WhatsApp`, `SocialDirectMessage`
- `content` (string): Message body (Text or HTML)
- `attachments` (array of maps):
  - `fileId` (string)
  - `fileName` (string)
  - `fileUrl` (string)
  - `mimeType` (string)
  - `size` (number)
- `isInternal` (boolean): True for internal agent notes/whispers (not visible to customer)
- `readReceipts` (map): `{ "userId": timestamp }`
- `timestamp` (timestamp): Time the message was sent/received

#### Sub-collection: `activities` (Audit trail & events)

Immutable log of all state changes for reporting and compliance.

**Document ID:** Auto-generated ID

**Fields:**
- `type` (string): `StatusChange`, `Assignment`, `SlaWarning`, `Escalation`, `LinkedArticle`
- `actorId` (string): User or System ID that triggered the event
- `details` (string): Description of the activity (e.g., "Assigned to Queue: High Priority Support")
- `previousValue` (any): State prior to the event
- `newValue` (any): State after the event
- `timestamp` (timestamp)

---

### Collection: `cs_customers`

Customer support profiles mapping back to the primary CRM data.

**Document ID:** Customer ID

**Fields:**
- `name` (string): Full name or Company Name
- `type` (string): `B2C`, `B2B`
- `tier` (string): `Standard`, `Gold`, `Platinum` (influences priority routing)
- `contactInfo` (map):
  - `email` (string)
  - `phone` (string)
  - `socialHandles` (map)
- `preferredChannel` (string): Customer's requested contact method
- `timezone` (string): Customer's local timezone
- `language` (string): ISO language code
- `activeEntitlements` (array of strings): References to `cs_entitlements`
- `sentimentScore` (number): AI-derived sentiment tracking (-1.0 to 1.0)
- `lifetimeTicketsCount` (number)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

---

### Collection: `cs_agents`

Profiles for support agents, managing their capacity, skills, and omnichannel presence.

**Document ID:** Agent ID (matches Identity/User ID)

**Fields:**
- `name` (string)
- `email` (string)
- `status` (string): `Available`, `Busy`, `Away`, `Offline`
- `capacity` (map):
  - `maxChats` (number): Maximum concurrent live chats
  - `currentChats` (number): Current active chats
  - `maxTickets` (number): Maximum assigned cases
  - `currentTickets` (number): Current assigned open cases
- `skills` (map of arrays):
  - `languages` (array of strings): e.g., ["en-US", "es-ES"]
  - `products` (array of strings): e.g., ["Hardware_v2", "Software_Cloud"]
  - `certifications` (array of strings): e.g., ["Tier 1", "SME_Billing"]
- `queues` (array of strings): List of `queueId`s this agent is servicing
- `shiftStart` (string): Time in HH:MM format
- `shiftEnd` (string): Time in HH:MM format
- `timezone` (string): Agent's timezone
- `supervisorId` (string): Reference to `cs_agents`
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

#### Sub-collection: `agent_sessions`
Tracks login/logout and granular status changes for WFM (Workforce Management).

**Document ID:** Auto-generated ID

**Fields:**
- `status` (string): State entered (e.g., `Break`, `Available`)
- `startedAt` (timestamp)
- `endedAt` (timestamp)
- `durationSeconds` (number)

---

### Collection: `cs_entitlements`

Defines support contracts, SLAs, and exact terms a customer is entitled to.

**Document ID:** Auto-generated ID

**Fields:**
- `name` (string): e.g., "Premium 24/7 Support"
- `customerId` (string): The customer this entitlement belongs to
- `isDefault` (boolean): True if this is a default SLA for all non-contracted users
- `startDate` (timestamp)
- `endDate` (timestamp)
- `type` (string): `Incidents`, `Hours`, `Unlimited`
- `totalTerms` (number): Total incidents or hours allowed
- `remainingTerms` (number)
- `channelsAllowed` (array of strings): ["Phone", "Email", "Chat", "Portal"]
- `slaKpis` (array of maps):
  - `kpiType` (string): `FirstResponse`, `Resolution`
  - `priority` (string): The priority level this applies to (`High`)
  - `targetMinutes` (number): Business minutes to achieve KPI
  - `warningThresholdMinutes` (number): Trigger warnings when X minutes remain
- `businessHoursId` (string): Reference to an operating schedule configuration document
- `isActive` (boolean)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

---

### Collection: `cs_knowledge_articles`

Knowledge Base for self-service portals, bots, and agent assist.

**Document ID:** Auto-generated ID

**Fields:**
- `articleNumber` (string): Human-readable ID (e.g., "KB-00102")
- `title` (string)
- `content` (string): HTML, Markdown, or Block-based content
- `summary` (string): Short description for search results
- `language` (string): ISO language code
- `categories` (array of strings): Taxonomy paths
- `tags` (array of strings): SEO and search keywords
- `status` (string): `Draft`, `Review`, `Published`, `Archived`
- `authorId` (string): Reference to creator
- `reviewerId` (string): Reference to approver
- `visibility` (string): `Internal`, `Public`, `CustomerOnly`
- `relatedProducts` (array of strings)
- `metrics` (map):
  - `viewCount` (number)
  - `helpfulCount` (number)
  - `unhelpfulCount` (number)
  - `deflectionCount` (number): Times this article prevented a ticket creation
- `version` (number)
- `publishedAt` (timestamp)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

#### Sub-collection: `versions`
Maintains historical snapshots of article edits.

**Document ID:** Version Number (e.g., "1", "2")

**Fields:**
- `versionNumber` (number)
- `content` (string)
- `title` (string)
- `modifiedBy` (string)
- `modifiedAt` (timestamp)
- `changeSummary` (string)

---

### Collection: `cs_queues`

Omnichannel Routing Queues where unassigned work waits.

**Document ID:** Auto-generated ID

**Fields:**
- `name` (string): e.g., "Tier 2 Technical Support"
- `description` (string)
- `type` (string): `Messaging`, `Email`, `Voice`, `Entity`
- `routingMethod` (string): `RoundRobin`, `LongestIdle`, `SkillBased`, `Custom`
- `operatingHoursId` (string)
- `overflowAction` (string): `Voicemail`, `TransferQueue`, `Reject`
- `overflowThresholdMinutes` (number): Time before overflow triggers
- `maxQueueSize` (number): Maximum items allowed in queue
- `activeTicketsCount` (number): Current length of queue
- `isActive` (boolean)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

---

### Collection: `cs_routing_rules`

Rules engine for automatically classifying, prioritizing, and assigning tickets to queues or specific agents based on conditional logic.

**Document ID:** Auto-generated ID

**Fields:**
- `name` (string): e.g., "VIP Customer Escalation"
- `priority` (number): Execution order (lower number = evaluated first)
- `isActive` (boolean)
- `triggerEvent` (string): `OnCreate`, `OnUpdate`, `OnSLAWarning`
- `conditions` (array of maps):
  - `field` (string): Field path (e.g., "customer.tier" or "ticket.priority")
  - `operator` (string): `Equals`, `Contains`, `GreaterThan`, `InList`
  - `value` (any): Evaluation value (e.g., "Platinum")
  - `logic` (string): `AND`, `OR` (relative to the next condition)
- `actions` (array of maps):
  - `type` (string): `RouteToQueue`, `RouteToAgent`, `SetPriority`, `ApplySLA`, `AddTag`
  - `targetId` (string): ID of queue, agent, or SLA (if applicable)
  - `value` (string): Value to set (if `SetPriority` or `AddTag`)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)
