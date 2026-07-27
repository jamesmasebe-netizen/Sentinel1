# crm — Module Journey Doc

**Path:** `lib/features/crm/`  |  **Compartment:** Sales  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`crm` is Sentinel1's Sales module: Lead capture and nurture, Opportunity/pipeline management, Quote generation, and Account/Contact/Campaign management. It is the entry point of the **Lead to Cash** business process flow — a Won Opportunity is meant to auto-create a Project in `projects`, handing off to Project Operations and eventually Finance.

**In scope:** lead capture/conversion, opportunity/pipeline tracking, quoting, account/contact records, campaigns, activity feed.
**Out of scope:** post-sale support (owned by `customer_service`), project execution once an Opportunity converts (owned by `projects`), invoicing (owned by `finance`/`billing`).
**IA placement:** Sales compartment (8-compartment taxonomy). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved) for the unresolved 4-Hub/7-pillar/8-compartment conflict.

## 2. User Journeys
| Persona | Journey | Steps touching `crm` | Entry screen(s) |
|---|---|---|---|
| [Sales & Customer Success Agent](_shared_personas_and_bpfs.md#persona-sales-cs-agent) | Lead to Cash (CRM) | Capture Lead → Nurture to Opportunity → Generate & Send Quote → (hand off) Auto-create Project on Won Opportunity | `crm_hub_screen.dart`, `lead_detail_screen.dart`, `pipeline_kanban_screen.dart`/`sales_pipeline_screen.dart`, `opportunity_detail_screen.dart`, `quote_generation_screen.dart`, `quote_detail_screen.dart` |
| [Executive/C-Suite](_shared_personas_and_bpfs.md#persona-executive) | Strategic Oversight (partial) | Drill into pipeline/campaign performance | `sales_pipeline_screen.dart`, `campaign_list_screen.dart` |

`lead_journey_timeline_screen.dart` and the `CustomerJourney` model exist specifically to visualize a lead's touchpoint history for this persona, beyond what the recovered roadmap's original journey description called out — noted as a module-specific enhancement.

## 3. BPF Participation
| BPF | Stage(s) this module implements | Code reference |
|---|---|---|
| [Lead to Cash](_shared_personas_and_bpfs.md#bpf-lead-to-cash) | Lead → Opportunity → Quote (up to Project auto-creation handoff) | `lib/core/bpf/lead_to_cash_bpf.dart`; `BpfRibbonWidget` is rendered directly in `lead_detail_screen.dart`, `opportunity_detail_screen.dart`, and `quote_detail_screen.dart` |

**Implementation-depth confirmation** (see [_shared doc](_shared_personas_and_bpfs.md#business-process-flows-bpfs)): this is the **one BPF confirmed fully wired end-to-end**, not just stage-tracked. `BpfOrchestrator.convertLeadToOpportunity()` and `createQuoteFromOpportunity()` (`lib/core/bpf/bpf_orchestrator.dart`) perform real Firestore writes via `CrmService` *and* call `BpfService.advanceStage()` — unlike Hire to Retire/Issue to Resolution/Asset Lifecycle, which are stage-tracking stubs. This is also the strongest BPF-ribbon integration found across the pilot modules so far — worth using as the reference example when auditing other BPF-participating modules for ribbon-widget presence.

## 4. Screens & UI Elements Inventory
| Screen | Route or side-sheet | Purpose |
|---|---|---|
| `crm_hub_screen.dart` | `/crm` | Main CRM landing hub |
| `account_list_screen.dart` | side-sheet | List of Accounts |
| `account_detail_screen.dart` | side-sheet | Single Account detail |
| `activity_feed_screen.dart` | side-sheet | Feed of Activity records (calls/tasks/emails) |
| `campaign_list_screen.dart` | side-sheet | List of Campaigns |
| `campaign_detail_screen.dart` | side-sheet | Single Campaign detail |
| `lead_detail_screen.dart` | side-sheet | Lead detail, incl. `BpfRibbonWidget` |
| `lead_journey_timeline_screen.dart` | side-sheet | Timeline of a Lead's `CustomerJourney` touchpoints |
| `opportunity_detail_screen.dart` | side-sheet | Opportunity detail, incl. `BpfRibbonWidget` |
| `pipeline_kanban_screen.dart` | side-sheet | Kanban board of Opportunities by stage |
| `sales_pipeline_screen.dart` | side-sheet | Sales pipeline view/summary |
| `quote_detail_screen.dart` | side-sheet | Quote detail, incl. `BpfRibbonWidget` |
| `quote_generation_screen.dart` | side-sheet | Quote builder/generation flow |

`/crm` is the module's only top-level route — confirmed at `lib/config/router.dart:127`. All 12 other screens are side-sheet-only, consistent with AGENTS.md's navigation rule.

## 5. Backend & Database

**Models — `lib/features/crm/models/crm_models.dart`** (single dedicated file):
| Model | Key fields | Collection |
|---|---|---|
| `Lead` | firstName, lastName, company, email, phone, leadSource, status, rating, aiLeadScore, ownerId, isConverted, convertedAccountId?/convertedContactId?/convertedOpportunityId? | `leads` |
| `Opportunity` | name, accountId, primaryContactId, stage, amount, probability, expectedCloseDate?, forecastCategory, leadSource, nextStep, ownerId, lossReason? | `opportunities` |
| `Quote` | opportunityId, accountId, quoteNumber, status, expirationDate?, subtotal, discount, tax, grandTotal, billingAddress?, shippingAddress?, termsAndConditions, isSyncing, ownerId | `quotes` |
| `Account` | name, industry, website, annualRevenue, employeeCount, billingAddress?, shippingAddress?, ownerId, territoryId?, parentAccountId?, status, relationshipHealth | `accounts` |
| `Campaign` | name, type, status, startDate?, endDate?, budget, actualSpend, targetAudience, expectedRevenue, actualRevenue, ownerId | `campaigns` |
| `Contact` | accountId, firstName, lastName, email, phone, mobile, jobTitle, department, leadSource, isPrimary, ownerId | `contacts` |
| `CustomerJourney` | leadId?, contactId?, campaignId?, touchpoints[], currentStage, totalScore, isConverted | `customerJourneys` |
| `Activity` | type, subject, description, regardingType/regardingId (polymorphic), ownerId, dueDate?, status, completedAt? | `activities` |
| `Deal` (legacy) | title, customerName, value, stage(`DealStage` enum) | `deals` |

`Deal`/`dealsStreamProvider` appears superseded by `Opportunity` but still has full service/provider support — likely dead/legacy code, flagged below.

**Firestore naming/rules check:** `firestore.rules` explicitly lists `leads`, `opportunities`, `quotes`, `accounts` — but not `contacts`, `campaigns`, `customerJourneys`, `activities`, or `deals`, which fall through to the catch-all rule. Consistent with the same pattern flagged in `people.md`.

**Providers — `lib/features/crm/providers/crm_providers.dart`:**
- `dealsStreamProvider` (legacy `deals` collection)
- `accountsProvider`, `contactsProvider`, `opportunitiesProvider`, `quotesProvider` — plain `StateProvider<List<T>>([])`, i.e. **local caches not wired to any stream** — a real-time-first violation of AGENTS.md §2 if these are what screens actually read from (needs confirmation which providers each screen actually watches)
- `opportunityStreamProvider.family`, `leadStreamProvider.family`, `quoteStreamProvider.family` — single-record live streams
- `opportunityQuotesStreamProvider.family` — quotes filtered by `opportunityId`
- `accountsStreamProvider`, `leadsStreamProvider`, `campaignsStreamProvider` — full-collection streams
- `accountStreamProvider.family` — single account via one-shot `.asStream()`, **not a live snapshot** — same real-time-first concern

**Services:** `crm_service.dart` — tenant-scoped CRUD/streams for all models above, plus `convertLeadToOpportunity()` (batched write: creates Account + Contact + Opportunity, marks Lead converted) — this is the concrete implementation of the Lead-to-Cash BPF's first transition.

## 6. Cross-Module Links
- `convertLeadToOpportunity()` is the code-level trigger point for the Lead-to-Cash BPF advancing past the Lead stage.
- Opportunity → Project handoff ("Auto-create Project upon Won Opportunity," per the persona journey and `lead_to_cash_bpf.dart`) — not confirmed as wired in this pass; verify when auditing `projects.md`.
- **AppEventBus:** no usage found anywhere under `lib/features/crm/` — despite AGENTS.md §5 mandating cross-module event-bus communication, and despite this module having an obvious cross-module trigger point (Won Opportunity should plausibly emit an event `projects` or `finance` could react to).

## 7. Known Gaps

### DB-to-UI alignment audit
`opportunity_form.dart` vs `Opportunity` model:
| Field | Status | Note |
|---|---|---|
| `accountId` | **Wrong widget** | Plain `TextFormField` (label "Account ID") — foreign key to `accounts`, no lookup |
| `primaryContactId` | **Wrong widget** | Plain `TextFormField` (label "Primary Contact ID") — foreign key to `contacts`, no lookup |
| `ownerId` | Correct | Uses `EmployeeSelector` |

`quote_form.dart` shows the identical pattern: `opportunityId` and `accountId` are plain `TextFormField`s while `ownerId` correctly uses `EmployeeSelector` — same gap repeated across two forms in this module.

### Other
- **Legacy `Deal` model**: `deals`/`dealsStreamProvider`/`DealStage` appear superseded by `Opportunity` but remain fully present in code — candidate for removal or an explicit migration note.
- **Real-time-first violations**: `accountsProvider`/`contactsProvider`/`opportunitiesProvider`/`quotesProvider` are static `StateProvider`s, and `accountStreamProvider.family` is a one-shot fetch, not a live stream — both patterns AGENTS.md §2 explicitly prohibits for business data ("Do NOT use `FutureProvider` or one-off `get()` calls"). Needs a follow-up to confirm which providers the screens actually bind to before treating this as confirmed-in-production versus dead code.
- **No AppEventBus usage** despite an obvious cross-module trigger (Won Opportunity) — see §6.
- **IA/taxonomy conflict**: see [_shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Do any CRM screens actually bind to the static `StateProvider`s (`accountsProvider` etc.), or are those dead code left over from before the `*StreamProvider`s were added? This materially changes whether the real-time-first gap is live or cosmetic.
- Should Won Opportunity emit an `AppEventBus` event to trigger Project auto-creation, or is that handled some other way (direct service call) that wasn't visible in this pass?
- Is `Deal`/`DealStage` safe to remove, or does something still depend on it?
