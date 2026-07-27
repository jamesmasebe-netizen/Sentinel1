# customer_service — Module Journey Doc

**Path:** `lib/features/customer_service/`  |  **Compartment:** Customer Service  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`customer_service` is Sentinel1's post-sale support module: tickets/cases, omnichannel chat, and a knowledge base, modeled after the Dynamics-365-style schema in `docs/schema_customer_service.md`. It picks up where `crm`'s Lead-to-Cash flow leaves off and is named as a narrative participant module in the Issue to Resolution BPF alongside `field_service`/`emergency`.

**In scope:** ticket/case CRUD, ticket messaging, SLA KPI tracking, knowledge article authoring, omnichannel chat UI, customer asset registration.
**Out of scope:** pre-sale CRM (owned by `crm`), the actual field dispatch a ticket might trigger (owned by `field_service`), the `cs_agents`/`cs_entitlements`/`cs_workstreams`/`cs_routing_rules`/`cs_swarms`/`cs_surveys`/`cs_skills` layer the schema doc describes but that has no code representation at all (see §5).
**IA placement:** Customer Service compartment (8-compartment taxonomy). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `customer_service` | Entry screen(s) |
|---|---|---|---|
| [Sales & Customer Success Agent](_shared_personas_and_bpfs.md#persona-sales-cs-agent) (primary) | Support Resolution (narrative) | Receive Customer Ticket → (Dispatch Field Agent, handoff) → Publish KB Article | `customer_service_hub_screen.dart`, `omnichannel_chat_screen.dart`, `knowledge_base_screen.dart` |
| Field Service & Emergency Responder (secondary, [_shared doc](_shared_personas_and_bpfs.md#persona-field-service-responder)) | Support Resolution, receiving end | Dispatched from a ticket — no code path found (see §6) | n/a |

Worth stating plainly here rather than only in §7: the screens a user can actually reach (`customer_service_hub_screen.dart`, `omnichannel_chat_screen.dart`, `omnichannel_ticket_screen.dart`, `knowledge_base_screen.dart`) are 100% hardcoded mock UI with no Firestore reads at all, while a separate, genuinely Firestore-wired layer (`ticket_detail_screen.dart`, `knowledge_article_detail_screen.dart`, `ticket_form.dart`, `knowledge_article_form.dart`) exists but has no navigation path leading to it from anywhere in the app. Both facts recur throughout this doc rather than being one-off findings.

## 3. BPF Participation
| BPF | Stage(s) this module implements | Code reference |
|---|---|---|
| [Lead to Cash](_shared_personas_and_bpfs.md#bpf-lead-to-cash) | "Support Resolution" sub-journey (persona-journey text only: Receive Customer Ticket → Dispatch Field Agent → Publish KB Article) | Not a `lead_to_cash_bpf.dart` stage — that BPF's coded stages stop at Project auto-creation; this is narrative only |
| [Issue to Resolution](_shared_personas_and_bpfs.md#bpf-issue-to-resolution) | Customer Ticket or Safety Incident Report → Action Form/Hazard Log → Work Order → Field Dispatch or Mitigation → Resolution & Close | Narrative only — confirmed directly: `lib/core/bpf/issue_to_resolution_bpf.dart` defines 4 generic stages (`logged`/`investigation`/`capa`/`closure`), each tagged only `expectedRecordType: 'incident'` or `'capa'`; none reference `customer_service` or `cs_tickets`. Per the [_shared doc](_shared_personas_and_bpfs.md#business-process-flows-bpfs), this BPF's orchestrator method `createCapaFromIncident()` is itself an explicit stub ("Generates a mock CAPA ID... In a real implementation we would write to safetyService.createCapa(...)") |

`BpfRibbonWidget` usage: confirmed **absent** from all 6 screens in this module (repo-wide grep scoped to `lib/features/customer_service/` returned zero matches) — unlike `crm.md`, which found the ribbon rendered in 3 of its screens. This module has no visual BPF stepper anywhere.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route or side-sheet | Purpose / wiring |
|---|---|---|
| `customer_service_hub_screen.dart` | `/customer-service` | Hub — hardcoded SLA metric cards and a 10-item fake case list; no Firestore read |
| `omnichannel_chat_screen.dart` | `/omnichannel-chat` (top-level route) | Chat UI backed by a local `StateNotifierProvider` seeded with 5 hardcoded messages; "Suggest AI Reply" inserts a hardcoded string constant, not a real AI call (see §5) |
| `omnichannel_ticket_screen.dart` | **unreachable** — not imported by `router.dart`, not pushed from any other screen in `lib/` (confirmed via repo-wide grep) | Alternate ticket-queue-plus-chat mockup, 15 fake tickets, Resolve/Transfer/search all unconfigured `onPressed`; dead code |
| `knowledge_base_screen.dart` | Opened via `Navigator.push(MaterialPageRoute(...))` from the hub's app-bar icon | Category sidebar + 6 fake article cards, all `onTap: () {}`; no Firestore read |
| `ticket_detail_screen.dart` | **unreachable** — `TicketDetailScreen(` has no call site anywhere in `lib/` outside its own file | Real: properties/messages/SLA three-panel layout, live-streams `Ticket`, `TicketMessage`, `SlaInstance` via `customerServiceServiceProvider`; message-send button is an unconfigured stub |
| `knowledge_article_detail_screen.dart` | **unreachable** — no call site found | Real: streams a `KnowledgeArticle` by ID; Edit button is an unconfigured stub |
| `widgets/ticket_form.dart` (`TicketForm`) | **unreachable** — `TicketForm(` never instantiated anywhere in `lib/` | Real create/edit form, full defensive-CRUD pattern, calls `CustomerServiceService.createTicket`/`updateTicket` |
| `widgets/knowledge_article_form.dart` (`KnowledgeArticleForm`) | **unreachable** — same | Real create/edit form, calls `CustomerServiceService.createKnowledgeArticle`/`updateKnowledgeArticle` |

`/customer-service` and `/omnichannel-chat` are this module's only top-level `GoRoute`s (confirmed at `lib/config/router.dart:132` and `:169`).

## 5. Backend & Database

**Models — `lib/features/customer_service/models/customer_service_models.dart`:**
| Model | Key fields | Collection |
|---|---|---|
| `Ticket` | ticketId, customerId?, contactId?, assetId?, title, status, priority, severity, channel, assignedTo?, workstreamId?/queueId?/entitlementId?, isEscalated, slaTimers?, tags, copilotSummary?, sentimentTrend? | `cs_tickets` |
| `TicketMessage` (sub) | senderId?, senderType, channel, content?, sentimentScore?, aiSuggestions, copilotDraft?, attachments, isInternal | `cs_tickets/{id}/messages` |
| `SlaInstance` (sub) | kpiType, status, failureTime?, warningTime?, succeededOn?, elapsedTime? | `cs_tickets/{id}/sla_kpi_instances` |
| `KnowledgeArticle` | articleNumber, title, content?, summary?, categories, tags, status, approvalStatus, visibility, metrics, version | `cs_knowledge_articles` |
| `CsAsset` | name, customerId?, serialNumber?, productModel?, status, iotEnabled, lastHeartbeat? | `cs_assets` |

`docs/schema_customer_service.md` documents 14 root collections (`cs_tickets`, `cs_customers`, `cs_agents`, `cs_entitlements`, `cs_knowledge_articles`, `cs_workstreams`, `cs_queues`, `cs_routing_rules`, `cs_swarms`, `cs_surveys`, `cs_survey_responses`, `cs_assets`, `cs_iot_alerts`, `cs_skills`). Only 3 (`cs_tickets`, `cs_knowledge_articles`, `cs_assets`) have any Dart model or service method — the other 11, including the entire agent-capacity/routing/entitlement/swarm layer that gives the schema doc its Dynamics-365 framing, are undocumented-in-code.

**Firestore rules check (significant):** none of `cs_tickets`, `cs_knowledge_articles`, `cs_assets`, or any other `cs_*` collection appears in `firestore.rules`' explicit per-collection list (checked against the full file). All fall through to the tenant-scoped catch-all — `match /tenants/{tenantId}/{collection}/{docId} { allow read: if belongsToTenant(tenantId); allow write: if false; }`. Since `CustomerServiceService` writes directly via `_tenantDoc.collection('cs_tickets')…set()/.update()` etc., **every real write this module's service layer performs would be rejected by the deployed security rules** — a much stronger version of the `contacts`/`campaigns` gap `crm.md` flagged, because here it's essentially the whole module rather than a handful of secondary collections.

**Services:** `customer_service_service.dart` (`CustomerServiceService`) — full CRUD + streams for `Ticket`/`TicketMessage`/`KnowledgeArticle`/`SlaInstance`/`CsAsset`. Real-time-first compliant (every list read is a `Stream`, no `StateProvider` caches or one-shot `.get()` list reads) — genuinely well-built by AGENTS.md §2's standard, just unreachable from the UI and unwritable per rules.

**Cloud Functions:** none are called from this module. `aiSuggestReply` (`firebase/functions/src/aiEngine.ts`) is plausibly relevant to `omnichannel_chat_screen.dart`'s "Suggest AI Reply" button by domain — but that button sets `_controller.text` to a hardcoded constant (`_mockAiSuggestion`); a repo-wide grep for `aiSuggestReply`/`aiEngine`/`httpsCallable`/`FirebaseFunctions` under `lib/` returns zero matches anywhere, confirming no Cloud Function of any kind is invoked from this module.

## 6. Cross-Module Links
- Ticket → Work Order handoff ("Dispatch Field Agent" in the persona journey): no code link found. `Ticket` has no work-order reference field, `WorkOrder` (either variant, see `field_service.md`) has no ticket-reference field, and no service method bridges the two collections.
- **AppEventBus:** no usage found anywhere under `lib/features/customer_service/`.
- `aiSuggestReply`: plausibly relevant per the CS/AI-deflection framing `crm.md` flagged as worth checking here — confirmed not called (see §5).

## 7. Known Gaps

### Rules-vs-code gaps
- All `cs_*` collections are absent from `firestore.rules`' explicit list, so every write `CustomerServiceService` performs is blocked by the catch-all `write: if false` as deployed (see §5) — the single largest rules-vs-code gap found in this pass.
- `BaseIncident` (AGENTS.md §5) is not directly applicable to this module's own domain (tickets aren't modeled as incidents), noted only because the Issue-to-Resolution BPF's stub status touches this module narratively.

### DB-to-UI alignment audit
`ticket_form.dart` vs `Ticket` model (this module's primary create/edit form):
| Field | Status | Note |
|---|---|---|
| `customerId` | **Missing** | FK to `cs_customers` — no field on the form at all |
| `contactId` | **Missing** | same |
| `assetId` | **Missing** | FK to `cs_assets` — not on form |
| `assignedTo` | **Missing** | Agent reference — not on form (contrast: `field_service`'s `work_order_form.dart` does use `EmployeeSelector` for its analogous technician field) |
| `workstreamId` / `queueId` / `entitlementId` | **Missing** | none present on form |
| `status` / `priority` / `severity` / `channel` | Correct | dropdowns matching the model's documented enum values |

### Other
- **AGENTS.md §1 violations:** `ticket_form.dart` and `knowledge_article_form.dart` both call raw `ScaffoldMessenger.of(context).showSnackBar(...)` instead of the mandated `UIUtils.showToast`; `customer_service_hub_screen.dart` opens `KnowledgeBaseScreen` via `Navigator.push(MaterialPageRoute(...))` from a Hub screen instead of `UIUtils.showSideSheet`.
- **AGENTS.md §3 Banned Stubs:** `omnichannel_ticket_screen.dart`'s Resolve/Transfer/search actions, `knowledge_base_screen.dart`'s 6 article cards + 5 sidebar entries (`onTap: () {}`), `ticket_detail_screen.dart`'s message-send button, `knowledge_article_detail_screen.dart`'s Edit button — all unconfigured callbacks.
- `customer_service_hub_screen.dart` imports `omnichannel_ticket_screen.dart` twice (lines 2–3, duplicate import) while never actually instantiating `OmnichannelTicketScreen` — a small but concrete sign the hub screen was edited without the dead import being noticed.
- The central finding for this module: two complete, parallel implementations exist side by side — a real Firestore-backed one (models, service, 2 detail screens, 2 forms) that is completely unreachable from the app's navigation, and the actually-routed one (hub, chat, ticket-queue, KB) that is 100% hardcoded mock data with zero model or service usage.

## 8. Open Questions
- Were `TicketDetailScreen`/`TicketForm`/`KnowledgeArticleDetailScreen`/`KnowledgeArticleForm` ever connected to navigation and later orphaned by a hub-screen rewrite, or built and never wired up in the first place? Determines whether the fix is "add routes" or "rebuild the connecting UI."
- Is `cs_*` the intended production collection prefix, and if so, was its absence from `firestore.rules` ever caught before this pass?
- Does a real ticket → work-order handoff exist anywhere (e.g. a Cloud Function trigger not covered by this pass), or is "Dispatch Field Agent" purely a persona-journey aspiration with no implementation?
