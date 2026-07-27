# billing — Module Journey Doc

**Path:** `lib/features/billing/`  |  **Compartment:** Finance  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
**Resolved directly from the code, not assumed:** this module is Sentinel1's own **SaaS tenant-subscription billing** — Sentinel1 charging its own tenants for their subscription to the platform — not AR/customer billing. Evidence: `TenantSubscription`'s fields (`tier`: free/pro/enterprise, `status`, `stripeCustomerId`, `stripeSubscriptionId`, `currentPeriodEnd`) describe a SaaS plan, not an invoice; the one screen is literally a "Free Tier vs Premium/Enterprise" paywall/upgrade surface; the one write path is a Stripe Checkout session keyed by `tenantId` (not a customer or invoice ID); the one read path is a single fixed per-tenant subscription-status document, not a growing invoices collection. This is structurally the opposite of the `finance` module's AR/AP invoicing (see `finance.md`) and shares no code with it (§6).

**In scope:** display the current tenant's subscription tier/status, launch a Stripe Checkout session to upgrade.
**Out of scope:** AR/customer invoicing (`finance`, entirely separate — zero code overlap confirmed both directions), Stripe webhook handling (exists in `functions/src/billing.ts` but is legacy/unexported — see §5), tax calculation (`taxEngine.ts` — unrelated despite the Stripe adjacency, see §5).
**IA placement:** Finance compartment (8-compartment taxonomy) per this doc set — grouped with `finance` under the Finance Controller persona, though the two share zero code (see §6). See [shared doc — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `billing` | Entry screen(s) |
|---|---|---|---|
| [Finance Controller](_shared_personas_and_bpfs.md#persona-finance-controller) (primary; shared-doc text: "Track Software Subscriptions") | Billing & AP/AR (partial — only this one sub-step maps here; "Generate & Send Invoice"/"Reconcile Accounts" belong to `finance`) | `BillingPortalScreen` (view tier/status, initiate upgrade) | Reachable **only** via `Navigator.push` from `ai_tools/screens/copilot_screen.dart`'s "Upgrade Now" button (see §4) — no dedicated route |
| Sales & Customer Success Agent (secondary, per module assignment) | — | No code hook found; this persona's shared-doc journeys (Lead to Cash, Support Resolution) don't reference subscriptions/billing/Stripe, and no `crm`/`customer_service` reference into `billing/` exists (grep, either direction) | — |

Worth flagging: the persona-journey text this module is meant to serve ("Track Software Subscriptions," under the Finance Controller's *Billing & AP/AR* journey) reads most naturally as the Finance Controller tracking the *company's own vendor SaaS spend* — an AP-style ledger. The code that actually exists implements the reverse: Sentinel1 metering and charging *its own tenant customers*. Both are plausibly described as "software subscription billing," but they're different business processes — the code resolves to the latter, not the journey text's more natural reading.

## 3. BPF Participation
None of the 6 BPFs' code (`lib/core/bpf/`) references this module — confirmed directly: grepping `lib/core/bpf/` for "billing"/"subscription" returns exactly two matches, both false positives unrelated to this module (a `Quote.billingAddress` field and the Lead-to-Cash `'billing_and_collection'` stage-ID string — both belong entirely to `finance`, see `finance.md` §3). `BpfRibbonWidget` usage: confirmed **absent** from `lib/features/billing/`.

The [shared doc](_shared_personas_and_bpfs.md#bpf-lead-to-cash)'s Lead to Cash entry lists `billing` in its "Modules" line (`crm, customer_service, finance, billing, projects`) — narrative grouping only, per the above. This module has **no code-level relationship with any BPF** — a clean, correct finding for what is structurally a standalone SaaS-metering screen, not a business-process participant.

## 4. Screens & UI Elements Inventory
| Screen | Route or entry point | Purpose |
|---|---|---|
| `billing_portal_screen.dart` (`BillingPortalScreen`) | **No dedicated route** in `router.dart` (confirmed — zero "billing" matches) and no `BusinessOsLaunchpad` tile (confirmed — zero matches); reachable **only** via `Navigator.push` from `ai_tools/screens/copilot_screen.dart`'s "Upgrade Now" button, itself an AI-feature paywall prompt | Shows current tier/status/period-end from a live stream; "Upgrade to Premium" (shown only if `!isPremium`) calls `BillingService.createStripeCheckoutSession` then launches the returned URL externally via `url_launcher` |

Only one screen, matching this module's assigned 4-file/1-screen inventory. Its error handler uses raw `ScaffoldMessenger.of(context).showSnackBar(...)` rather than `UIUtils.showToast` — an AGENTS.md §1 "Feedback Mechanisms" violation.

## 5. Backend & Database

**Models — duplicate class name, same pattern `field_service.md` flagged for `WorkOrder`:**
| | `subscription_model.dart` (singular) | `subscription_models.dart` (plural) |
|---|---|---|
| Shape | `status`, `currentPeriodEnd`, `tier: String`, `stripeSubscriptionId` | `id`, `tenantId`, `tier: SubscriptionTier` (enum: free/pro/enterprise), `status`, `stripeCustomerId?`, `stripeSubscriptionId?`, `currentPeriodEnd?` |
| Serialization | `fromJson`/`toJson` | `fromFirestore(DocumentSnapshot)`/`toFirestore()` |
| Used by | `billing_service.dart` — the module's only service, and its live wired shape | **Nothing** — confirmed dead code, zero references anywhere outside its own file |

**Collection:** `tenants/{tenantId}/subscription/status` — a single fixed document per tenant, not a growing collection. Read-only from the Dart side: `BillingService` has no create/update method for it at all, only `getSubscriptionStream()`. The module's only client-side write is the Stripe Checkout session call, which doesn't touch Firestore directly.

**Firestore rules check:** `subscription` (as a subcollection name under `tenants/{tenantId}`) is not explicitly declared in `firestore.rules`; it falls to the tenant-scoped catch-all (`firestore.rules:220-223`: `allow read: if belongsToTenant(tenantId); allow write: if false;`). The read this module depends on is allowed; there's no client write path to this document to be blocked in the first place.

**Cloud Functions — the headline finding for this module:**
- `BillingService.createStripeCheckoutSession()` calls `_functions.httpsCallable('createStripeCheckoutSession')` — **a function by this exact name does not exist anywhere in the repository.** Confirmed by grepping both Cloud Functions codebases in full: `firebase/functions/src/` (`aiEngine`, `copilotEngine`, `hrEngine`, `index`, `iotEngine`, `mrpEngine`, `revRecEngine`, `routingEngine`, `taxEngine`) and `functions/src/` (`api`, `billing`, `index`, `prescreen_compliance`). Neither defines it. **This module's only real user-facing action — "Upgrade to Premium" — would fail at runtime with a Cloud Functions "not-found" error against either codebase as committed.**
- `functions/src/billing.ts` defines `stripeWebhook` (`onRequest`) — a "basic webhook simulation" per its own code comment, explicitly *not* doing real Stripe signature verification. It handles `customer.subscription.{created,updated,deleted}` and writes to **`tenants/{tenantId}/billing/subscription`** (merge), defaulting `tier` to `'pro'` when Stripe metadata doesn't specify one. Confirmed directly: `stripeWebhook` is **not exported** from `functions/src/index.ts` (which only does `export * from './prescreen_compliance'`) — unreachable/undeployed in the legacy codebase as committed, independent of the point below.
- **Path mismatch, independent of the export problem:** `stripeWebhook` writes `tenants/{tenantId}/billing/subscription`; `BillingService.getSubscriptionStream()` reads `tenants/{tenantId}/subscription/status`. Different subcollection name (`billing` vs `subscription`) *and* different document ID (`subscription` vs `status`). Even fully exported, deployed, and genuinely receiving Stripe events, this function's writes would land somewhere the app never reads.
- `taxEngine.ts`/`revRecEngine.ts` (the rich/active codebase) — checked directly, per this module's brief, for relevance: neither is relevant. `taxEngine.calculateTax`'s only Stripe-adjacent content is its own comment ("Simulate Stripe Tax call," per `finance.md` §5) and has nothing to do with tenant subscriptions; `revRecEngine` watches `project_milestones`/writes `finance_journals`, entirely about project revenue recognition. Neither references tenant subscription tier/status/Stripe customer or subscription IDs.
- `functions/src/api.ts` (`platformApi`, also unexported per the reusable context) — checked directly: a generic authenticated Express REST API (`GET /incidents`, etc.), zero billing/subscription/Stripe references. Not relevant here.

**Providers:** `isPremiumProvider` (`lib/core/providers/subscription_provider.dart`, outside this module, importing directly from it) computes `subscription.tier == 'premium' || subscription.tier == 'enterprise'`. **Confirmed live bug:** grepping the entire repo (`lib/`, both Functions codebases) for the literal string `'premium'` returns exactly **one** match — this same comparison. Nothing anywhere ever produces a `'premium'` tier: the enum (`subscription_models.dart`, itself dead code) only defines free/pro/enterprise, and `stripeWebhook`'s own default is `'pro'`. A tenant on the `'pro'` tier — the webhook's own default — can **never** satisfy `isPremiumProvider`; `BillingPortalScreen` would show "Free Tier" and the upgrade card even for an already-paying tenant. Only `'enterprise'` can ever satisfy this check as the code stands.

## 6. Cross-Module Links
- **No code-level relationship with `finance`** was found in either direction (no shared imports, no shared models, confirmed by grep both ways) — independently confirms `finance.md` §6's own finding of the same thing. The two modules are grouped under one compartment and one persona but touch entirely separate Firestore namespaces (`fin_*`/`invoices`/`journal_entries` vs. `tenants/{t}/subscription/status`).
- `ai_tools/screens/copilot_screen.dart` is this module's sole caller — an "Upgrade Now" button on what reads as an AI-feature paywall screen. A real, if narrow and one-directional, cross-module dependency (`ai_tools` → `billing`) not mentioned in either module's persona journey text in the shared doc.
- **AppEventBus:** zero usage anywhere in `lib/features/billing/` (confirmed by grep) — no event fires on subscription downgrade/cancellation.
- No relationship found with `crm`/`customer_service` (the Sales & Customer Success Agent's own modules) despite that persona's secondary assignment here — confirmed by grep from this module's side.

## 7. Known Gaps

### Rules-vs-code gaps
- `subscription` is undeclared in `firestore.rules`, falling to the tenant-scoped catch-all. Not a practical blocker today since this module has no client write path to that document (§5) — flagged for completeness, unlike `emergency.md`'s parallel finding, which *does* block real writes.
- `BaseIncident` — not applicable, no incident concept in this module.

### DB-to-UI alignment audit
`BillingPortalScreen` has no create/edit form for `TenantSubscription` at all — the model is read-only from the client (§5) — so the standard form-vs-model audit doesn't apply. The one interactive control, "Upgrade to Premium," takes no user-entered fields and passes only `tenantId` to the (missing) Cloud Function; nothing to audit field-by-field.

### Other
- **The module's only real action targets a Cloud Function that doesn't exist** — `createStripeCheckoutSession` has zero matches in either Functions codebase (§5). More severe than `finance.md`'s "rules-blocked collection" findings or `field_service.md`'s "unreachable screen" findings: here the backend code itself was never written, not merely unwired or blocked.
- **Tier-name mismatch bug, confirmed live:** `isPremiumProvider` checks for `'premium'`, a value nothing in the codebase ever produces (§5).
- **Three-way path mismatch on the subscription document**, structurally the same shape as `finance.md`'s three-scheme GL/invoice finding: the app reads `tenants/{t}/subscription/status`; the legacy, unexported webhook writes `tenants/{t}/billing/subscription`; the dead plural model corresponds to neither concretely since it's never instantiated from a real stream.
- **Dead model:** `subscription_models.dart` (plural) — confirmed zero usage outside its own file.
- **AGENTS.md §1 violation:** `billing_portal_screen.dart` uses `ScaffoldMessenger.showSnackBar` directly instead of `UIUtils.showToast`.
- **IA/taxonomy conflict:** see [shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved) — this module is a further data point for it (grouped into "Finance" with zero code overlap with `finance`).

## 8. Open Questions
- Should `createStripeCheckoutSession` be written into `firebase/functions/src/` (the active codebase), or was it deployed out-of-band and never checked into either Functions codebase? Worth an urgent check given it's this module's only real user-facing action.
- Should `stripeWebhook` move to `firebase/functions/src/` (fixed to write `tenants/{t}/subscription/status` to match what the app reads), or should `BillingService` be re-pointed at `tenants/{t}/billing/subscription` to match the webhook? The same class of decision `finance.md`'s open questions raise for its own naming-scheme mismatches.
- Is `isPremiumProvider`'s `'premium'` check a typo for `'pro'`, or was a third tier name once planned and never implemented?
- Given the code resolves this module to tenant-subscription billing (Sentinel1 billing its own tenants), should the persona journey text ("Track Software Subscriptions" under the Finance Controller) be corrected to say so explicitly, since as worded it reads more naturally as the opposite (tracking vendor subscriptions the company itself pays for)?
- Should `schema_finance.md` (or a new schema doc) be extended to cover this module's actual domain (SaaS tier/Stripe subscription state)? Confirmed by grep: the existing schema doc's AR/AP/GL scope doesn't mention subscriptions or Stripe at all.
