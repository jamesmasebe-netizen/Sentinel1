# copilot — Module Journey Doc

**Path:** `lib/features/copilot/`  |  **Compartment:** System Administration  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`copilot` is a single file, `copilot_panel.dart`, implementing `CopilotPanel` — a real, reachable, glassmorphic floating chat widget (`BackdropFilter` blur, neon purple/cyan theme) that calls a real Cloud Function directly from the widget. This matches the recovered plan's description of a "glassmorphic floating chat UI accessible from launchpad" precisely.

**Not the same feature as `ai_tools`'s AI surfaces** — see [ai_tools.md §1](ai_tools.md#1-product-understanding) for the full three-way comparison. In short: `AIChatScreen` (`ai_tools`, `/ai`) is a 4-tab hub calling Gemini directly from the client; `CopilotScreen` (also `ai_tools`) is a premium-gated chat screen with **zero instantiation sites anywhere in the app** (fully unreachable); `CopilotPanel` (this module, `/copilot`) is the only one of the three that calls a real Cloud Function server-side, and the only one of the three named "Copilot" that is actually reachable in the app today.

**In scope:** the floating Copilot chat panel and its one Cloud Function dependency.
**Out of scope:** everything under `ai_tools` (separate module, separate code, see above).
**IA placement:** System Administration compartment, Executive/C-Suite persona per the shared doc's own module-focus line for this persona ("dashboard, executive, ai_tools, copilot"). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `copilot` | Entry screen(s) |
|---|---|---|---|
| [Executive/C-Suite](_shared_personas_and_bpfs.md#persona-executive) / [IT/Systems Administrator](_shared_personas_and_bpfs.md#persona-it-systems-admin) (per module assignment) | No shared-doc journey text names a floating AI panel specifically; closest is the IT Admin's "Train AI Chatbot parameters" (no such parameter UI exists here either) | Open panel from Launchpad → ask a free-text question → receive a Gemini-generated answer with a confidence % | `copilot_panel.dart` (`/copilot`) |

## 3. BPF Participation
None. `copilot` is explicitly listed in the [shared doc's](_shared_personas_and_bpfs.md#business-process-flows-bpfs) "Modules with zero BPF participation, narratively or in code." Confirmed directly: zero references to `bpf_orchestrator.dart`/`BpfRibbonWidget`/any BPF stage file anywhere in `lib/features/copilot/`.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route | Purpose / wiring |
|---|---|---|
| `screens/copilot_panel.dart` (`CopilotPanel`) | `/copilot` (`router.dart:273-276`); Launchpad tile "Sentinel Copilot" (System Administration section) | Full-screen (routed, not an overlay despite the "floating panel" visual design) chat UI; calls Cloud Function directly from the widget's `_sendMessage()` — no service/provider layer at all (AGENTS.md §1 separation-of-concerns gap, a smaller-scale version of what `emergency.md` found for its whole module) |

## 5. Backend & Database
No models, no Firestore reads or writes anywhere in this module (confirmed by grep — zero `cloud_firestore` usage in `copilot_panel.dart`).

**Cloud Function:** `_sendMessage()` calls `FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('askCopilot')` with `{query, screenContext: widget.screenContext}`. This **is a real, deployed-looking implementation** — `firebase/functions/src/copilotEngine.ts`'s `askCopilot` (`onCall`, region `us-central1` — **regions match**, confirmed): validates `query`, requires a server-side `GEMINI_API_KEY` environment variable/secret (`process.env.GEMINI_API_KEY` — a Cloud Functions config value, unrelated to `ai_tools`'s client-side `String.fromEnvironment('GEMINI_API_KEY', ...)` compile-time define despite the identical name), calls Gemini (`gemini-1.5-flash`) with a short fixed prompt template, and returns `{answer, confidence}` (confidence derived from `avgLogprobs` when available, else a flat `0.92` placeholder). No Firestore access on the server side either — this is a stateless prompt-passthrough function.

**`screenContext` is never actually populated:** `CopilotPanel`'s constructor accepts `screenContext` (default `''`) specifically so callers can pass "the current screen / module so the Copilot can give more relevant answers" (its own doc comment). Its **only** instantiation site, `router.dart:275` (`const CopilotPanel()`), passes no argument — so every real invocation sends `screenContext: ''` to the Cloud Function, and the function's own prompt template (`"Context: ${screenContext.trim()}"`) renders an empty context clause on every call. The contextual-awareness feature is built on both ends but never actually wired through.

## 6. Cross-Module Links
- Calls `firebase/functions/src/copilotEngine.ts`'s `askCopilot` — confirmed region-matched and real, unlike most Cloud-Function findings elsewhere in this batch.
- **Not linked to `ai_tools`** in code (no shared imports, confirmed by grep in both directions) despite the near-identical naming and purpose — see [ai_tools.md](ai_tools.md) for the full comparison.
- **AppEventBus:** zero usage anywhere in `lib/features/copilot/` (confirmed by grep).

## 7. Known Gaps

### Rules-vs-code gaps
Not applicable — no Firestore access anywhere in this module (§5).

### DB-to-UI alignment audit
Not applicable — no model, no form.

### Other
- No service/provider layer — the Cloud Functions call sits directly inside the widget's State class (§4).
- `screenContext` is a fully-built but never-exercised contextual-awareness parameter (§5) — the panel always answers with zero knowledge of which screen it was opened from.
- Despite the "floating panel"/"side panel" framing in its own code comments, `CopilotPanel` is wired as a full routed screen (`/copilot`), not an overlay — it replaces the current screen rather than floating above it.

## 8. Open Questions
- Should `CopilotPanel` be converted to an actual overlay/side-sheet (per `UIUtils.showSideSheet`, the AGENTS.md-mandated pattern for this kind of contextual panel) rather than a full route, matching its own visual design intent?
- Should `router.dart` pass a real `screenContext` (e.g., the previous route name) into `CopilotPanel`, so the already-built prompt-context plumbing on both the client and `copilotEngine.ts` actually does something?
- Given `ai_tools`'s unreachable `RagService` already implements real Firestore-context retrieval that `askCopilot` lacks server-side, is merging the two a live consideration (see [ai_tools.md](ai_tools.md)'s matching open question)?
