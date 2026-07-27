# ai_tools — Module Journey Doc

**Path:** `lib/features/ai_tools/`  |  **Compartment:** System Administration  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`ai_tools` is the larger of two AI-branded modules in this batch (12 files vs. `copilot`'s 1). It contains two genuinely separate things under one folder: (a) `AIChatScreen`, a real, reachable 4-tab "SHEQ AI Hub" (SHEQ Chat / Hazard Photo / RCA Assistant / Safety Flash), all calling the Gemini API **directly from the client**; and (b) a second, unreachable stack — `CopilotScreen` → `CopilotChatWidget` → `CopilotService` → `RagService` — a premium-gated, Firestore-context-aware chat feature with zero instantiation sites anywhere in the app.

**Resolving the copilot-vs-ai_tools question this doc set was asked to settle:** there are **three**, not two, distinct AI-chat-shaped implementations across `ai_tools` and the separate `copilot` module, and none of them share code with each other:

| | `AIChatScreen` (this module) | `CopilotScreen` (this module) | `CopilotPanel` (**separate `copilot` module** — see [copilot.md](copilot.md)) |
|---|---|---|---|
| Reachable? | **Yes** — `/ai` route, Launchpad tile, header-bar icon | **No** — zero instantiation sites anywhere in `lib/` (confirmed by grep on `CopilotScreen\b`) | **Yes** — `/copilot` route, Launchpad tile |
| Gated? | No | Yes — `isPremiumProvider` paywall (see `billing.md`) | No |
| AI call path | Client-side `google_generative_ai` SDK, direct to Gemini, per-tab | Client-side `google_generative_ai` SDK, direct to Gemini, via `CopilotService.askCopilot()` | Server-side — `httpsCallable('askCopilot')`, a real Cloud Function (`firebase/functions/src/copilotEngine.ts`) |
| Context source | None (SHEQ Chat/RCA/Safety Flash) or an uploaded photo (Hazard Photo) | `RagService` — live Firestore reads (`leads`... `deals`/`invoices`/`employees`/`purchase_orders`, top 5 docs) stuffed into the prompt | None — `screenContext` param exists but is never populated (see §5) |

The `CopilotService.askCopilot()` Dart method and the Cloud Function named `askCopilot` that `CopilotPanel` calls are two **entirely unrelated** implementations that happen to share a name — worth stating explicitly since it reads like a refactor-in-progress but isn't (no shared code, no shared call graph). This also directly confirms and extends `billing.md`'s finding: the "Upgrade Now" → `BillingPortalScreen` button it documented inside `copilot_screen.dart` sits in a screen that is itself unreachable from anywhere in the app — so that broken paywall path is not just leading to a route-less destination (`billing.md`'s finding), its own entry point is equally disconnected.

**In scope:** Gemini-powered SHEQ chat, AI hazard-photo analysis, AI root-cause-analysis drafting, AI weekly safety-bulletin generation; the separate (unreachable) premium Copilot chat stack.
**Out of scope:** the real, reachable Copilot panel (`copilot` module, see [copilot.md](copilot.md)); billing/paywall mechanics (`billing.md`).
**IA placement:** System Administration compartment. See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `ai_tools` | Entry screen(s) |
|---|---|---|---|
| [IT/Systems Administrator](_shared_personas_and_bpfs.md#persona-it-systems-admin) (primary) | System Management — "Train AI Chatbot parameters" (loose match; no parameter-training UI actually exists, see §7) | Use SHEQ Chat / Hazard Photo / RCA / Safety Flash tabs | `ai_chat_screen.dart` (`/ai`) |
| [Executive/C-Suite](_shared_personas_and_bpfs.md#persona-executive) (secondary) | No shared-doc journey text names AI chat specifically | No code hook found beyond generic access to `/ai` like any other authenticated user | — |

## 3. BPF Participation
None. `ai_tools` is explicitly listed in the [shared doc's](_shared_personas_and_bpfs.md#business-process-flows-bpfs) "Modules with zero BPF participation, narratively or in code." Confirmed directly: zero references to `bpf_orchestrator.dart`/`BpfRibbonWidget`/any BPF stage file anywhere in `lib/features/ai_tools/`.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route / reachability | Purpose / wiring |
|---|---|---|
| `screens/ai_chat_screen.dart` (`AIChatScreen`) | `/ai` (`router.dart:215-218`); Launchpad tile "AI Chat"; header-bar icon (`Icons.smart_toy_outlined` → `context.go('/ai')`, `app_header_bar.dart:89-93`) | 4-tab shell, all real (not stubs), all Gemini-direct |
| `widgets/sheq_chat_tab.dart` (`SheqChatTab`) | Tab 1 | Multi-turn chat (`ChatSession`) with a hardcoded SHEQ-expert system prompt; quick-prompt chips |
| `widgets/hazard_photo_tab.dart` (`HazardPhotoTab`) + `hazard_photo_widgets.dart` | Tab 2 | Camera/gallery photo → Gemini multimodal (`Content.multi` with `DataPart('image/jpeg', bytes)`) → hazard/PPE/non-compliance report, display-only |
| `widgets/rca_assistant_tab.dart` (`RcaAssistantTab`) | Tab 3 | Form (incident/injuries/location/severity) → Gemini text prompt → 5-Why RCA report, display-only |
| `widgets/safety_flash_tab.dart` (`SafetyFlashTab`) | Tab 4 | One-tap Gemini-generated weekly safety bulletin; "copy" button is a stub (see §7) |
| `screens/copilot_screen.dart` (`CopilotScreen`) | **None — confirmed orphaned** (§1) | Premium paywall gate (`isPremiumProvider`) → `CopilotChatWidget` if premium, else "Upgrade Now" → `BillingPortalScreen` |
| `widgets/copilot_chat_widget.dart` (`CopilotChatWidget`) | Composed only into the orphaned `CopilotScreen` | Chat UI calling `CopilotService.askCopilot`; reuses `ChatMessage`/`ChatBubbleWidget`/`QuickPrompts` from `sheq_chat_widgets.dart` — the one piece of code genuinely shared between the reachable SHEQ Chat tab and the unreachable Copilot stack |

`SafetyFlashTab`'s "copy" `IconButton` calls only `UIUtils.showToast(context, 'Copied to clipboard')` — no `Clipboard.setData` call anywhere in the file (confirmed: no `package:flutter/services.dart` import). It reports success without performing the action — a banned-stub pattern (AGENTS.md §3), the same "claims to do X, doesn't do X" shape `emergency.md` found for the non-dialing phone button.

## 5. Backend & Database

**No `models/` directory** — this module produces AI text output, never a persisted record (see §7). **Providers:** `providers/gemini_provider.dart` (`geminiProvider`) — the single source the 4 `AIChatScreen` tabs and `CopilotService` all read from directly.

**`geminiProvider`'s API key — likely misconfigured as committed:**
```dart
const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
```
This is a Flutter **compile-time** define (`--dart-define=GEMINI_API_KEY=...`), not `flutter_dotenv`. Confirmed by repo-wide grep: no build script, CI config, or README anywhere in the repo passes `--dart-define` for this key — the only other match for the string `GEMINI_API_KEY` is a generic mention in `.agents/skills/saas-production-readiness/SKILL.md`. As committed, this provider resolves to an **empty-string API key** unless a build/run step outside this repo supplies it, meaning all 4 `AIChatScreen` tabs would fail their Gemini call the first time a user exercises them (caught by each tab's own `try/catch`, surfaced as an inline `"Error: ..."` message rather than a crash). Separately, `lib/config/firebase_config.dart` (see [auth.md](auth.md) §7) already hardcodes a *different*, unused `geminiApiKey` value — that field is never read by `geminiProvider` or anywhere else, so it does not help here even though a real-looking key sits right there in source.

**`CopilotService`/`RagService`** (used only by the orphaned `CopilotScreen`): `CopilotService.askCopilot(prompt, context)` fetches up to 5 raw documents via `RagService.fetchContextForDomain(context)` (`'CRM'`→`deals`, `'Finance'`→`invoices`, `'HR'`→`employees`, `'SCM'`→`purchase_orders`, scoped under the current `tenantDocProvider`) and stuffs them verbatim into the Gemini prompt as a crude RAG context. `deals` is confirmed as a real, populated collection elsewhere (`crm_service.dart`, `seed_production_data.dart`) — this targeting is accurate, not a dead reference, for what it's worth given the feature is unreachable regardless.

**Firestore rules check:** `RagService`'s reads go through `tenantDocProvider` → `belongsToTenant(tenantId)`, so they're subject to [auth.md](auth.md) §5's custom-claims finding like every other tenant read in the app. Not otherwise applicable — this module writes nothing to Firestore anywhere (confirmed by grep: no `.set(`/`.add(`/`.update(` call in any file under `lib/features/ai_tools/`).

**Cloud Functions:** none called from `AIChatScreen`'s tabs or `CopilotService` — both paths call the Gemini SDK directly from the client, bypassing Cloud Functions entirely (contrast with `copilot` module's `CopilotPanel`, which calls a real Cloud Function — see [copilot.md](copilot.md)). `aiEngine.ts` exists in `firebase/functions/src/` but has zero call sites from this module (not checked further — out of scope for this doc, it may serve a different module's AI feature).

## 6. Cross-Module Links
- `ai_tools/screens/copilot_screen.dart` → `billing/screens/billing_portal_screen.dart` ("Upgrade Now") — the exact link `billing.md` documents; confirmed here from the calling side, and confirmed that the calling screen itself is unreachable (§1).
- `core/providers/subscription_provider.dart` (`isPremiumProvider`) gates `CopilotScreen` — see `billing.md` for the `'premium'`-vs-`'pro'` tier-name bug that makes this gate practically un-satisfiable for any real tenant.
- **Not the same module as `copilot`** (`lib/features/copilot/`) — see [copilot.md](copilot.md) for the reachable, Cloud-Function-backed Copilot implementation; §1's table is the full comparison.
- `app_header_bar.dart` (core, outside this module) is the second entry point into `AIChatScreen`, alongside the Launchpad tile.
- **AppEventBus:** zero usage anywhere in `lib/features/ai_tools/` (confirmed by grep) — none of the 4 tabs' AI output triggers or listens for any cross-module event.

## 7. Known Gaps

### Rules-vs-code gaps
- No collection is written by this module at all (§5) — nothing to check against `firestore.rules` on the write side. Reads inherit [auth.md](auth.md)'s custom-claims finding.
- `BaseIncident` — not applicable; this module generates text about incidents/hazards but defines no incident model of its own.

### DB-to-UI alignment audit
Not applicable in the shared methodology's normal sense — there is no Firestore-backed model anywhere in this module to diff a form against. Worth stating as its own finding rather than a silent skip: **none of the 4 `AIChatScreen` tabs persists its AI output anywhere** — the Hazard Photo report, the RCA report, and the Safety Flash bulletin are all generated, displayed, and then lost on navigation away, with no "Save as Hazard," "Attach to Incident," or "Post to Safety Board" action anywhere in any of the three files. This is an AGENTS.md §3 ("End-to-End Vertical Slices") gap distinct from the safety_flash "copy" stub — the generation itself works, but no result is ever captured into the system of record.

### Other
- **`GEMINI_API_KEY` likely resolves to an empty string as committed** (§5) — the module's core dependency, with no evidence of the required `--dart-define` being supplied anywhere in the repo.
- **`SafetyFlashTab`'s "copy" button doesn't copy anything** — reports success via toast without calling `Clipboard.setData` (§4).
- **No AI output is ever saved** — all 4 tabs are generate-and-display only (DB-to-UI audit above).
- **`CopilotScreen`/`CopilotChatWidget`/`CopilotService`/`RagService` — a complete, unreachable feature.** Four files' worth of real implementation (premium gate, RAG-lite context fetch, chat UI) with zero path to reach it from anywhere in the app.

## 8. Open Questions
- Is `GEMINI_API_KEY` actually supplied via `--dart-define` in whatever CI/build pipeline deploys this app (outside this repo), or do all 4 `AIChatScreen` tabs fail in every real build?
- Was `CopilotScreen` meant to be pushed contextually from each module's hub screen (explaining its `moduleContext` parameter), and if so, why does `CopilotPanel` (the `copilot` module) exist as a seemingly competing, already-wired alternative?
- Should the Hazard Photo / RCA / Safety Flash tabs gain a "save to `hazards`/`findings`/wherever" action, or are they intentionally scoped as drafting aids only?
- Given `CopilotService`/`RagService` already implement a working Firestore-context RAG pattern that the Cloud-Function-based `askCopilot` (called by `copilot`'s `CopilotPanel`) does not (§5's Cloud Function reads no Firestore data at all), should the two be merged?
