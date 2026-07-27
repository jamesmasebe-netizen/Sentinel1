# Sentinel Global Development Rules

These rules dictate the architecture, design patterns, and programming standards for the Sentinel application. You MUST follow these rules unconditionally when modifying or creating new features.

This is the single canonical rules file for every AI agent working on this repo (Antigravity/Gemini, Claude Code, or otherwise). `.agent/rules/GEMINI.md` is kept only as a pointer here — do not fork rules back into it.

## 1. UI & Navigation Strict Standards
- **Feedback Mechanisms:** NEVER use `ScaffoldMessenger.of(context).showSnackBar()` or error toasts natively. ALWAYS use `UIUtils.showToast(context, 'msg', type: ToastType.success)` or `ToastType.error` for standard user feedback.
- **Deep Sub-Navigation:** NEVER use `Navigator.push` to open detailed forms or sub-modules from a Hub screen. ALWAYS use context-preserving side-sheets via:
  ```dart
  UIUtils.showSideSheet(context: context, title: 'Title', builder: (ctx) => const YourScreen());
  ```
- **Form Submissions & Write Operations:** Every database write or form submission MUST be defensive.
  1. Define a local state variable `bool isLoading = false;`.
  2. Wrap the asynchronous operation in a `try-catch` block.
  3. Show a loading spinner on the submit button while `isLoading` is true and disable the button.
  4. Ensure `isLoading` is managed correctly across `StatefulBuilder` when used inside dialogs.
- **Micro-Widget Separation:** Massive layout files are prohibited. Break screens down into small, single-purpose, stateless or stateful widgets.
- **Predictable Separation of Concerns:** Keep UI files strictly visual. Business logic and direct Firestore query streams must reside entirely within the State Management Layer.

## 2. Data & State Strict Standards
- **Real-time First (Unified State):** All dashboard metrics, summary cards, and primary list views MUST be backed by Firestore streams (`snapshots()`) mapped to Riverpod `StreamProvider`s. Do NOT use `FutureProvider` or one-off `get()` calls for dynamic business data.
- **No Localized Business State:** Do NOT use raw `setState` to hold fragmented business logic or calculations that drive dashboards. Derivations must happen within the Riverpod providers based on the real-time stream.
- **Human Readable IDs:** When creating new master records (Projects, Incidents, CAPAs, Risks), generate a concise, human-readable ID (e.g., `PRJ-001`, `INC-045`) and use it explicitly as the Firestore document ID (`.doc(customId).set(...)`). Do NOT rely on auto-generated long strings for display purposes.
- **No Hardcoded Data:** Never use static, hardcoded, or placeholder data for business metrics. If a feature is incomplete, disable the relevant button or feature instead of faking the data.
- **Zero Flat Schemes:** Do not compress unrelated datasets into single catch-all Firestore documents. Data models must be granular, highly typed, and strictly normalized. For example, risk assessments, hazard identification logs, and non-conformance reports must be separate subcollections, not flat arrays within a main document.
- **Strict Schema Enforcement:** Every collection must have a corresponding, type-safe Dart model class with clear `fromFirestore` and `toFirestore` serialization logic.

## 3. Mandatory Completeness & Execution
- **Banned Stubs:** Never use `// TODO`, unconfigured `onPressed` callbacks, or static text strings representing "coming soon" states.
- **End-to-End Vertical Slices:** Every requested feature must be built fully functional. If a button is added (e.g., submitting an incident report), its complete data routing, state mutations, and backend schema transformations must be written entirely.
- **Resilient States:** Every network call or database query must handle three explicit states: Data/Success, Empty (no items found view), and Error (explicit error message).

## 4. Vibe Coding & Token Optimization (Context Limits)
- **The "200-Line Threshold":** No single UI file may exceed 200 lines of code. If a feature requires more, the agent MUST create a dedicated subdirectory and split the UI into modular component files (e.g., separating tabs into their own files).
- **Global Component Extraction:** Any UI component that is used across multiple modules (e.g., standard Metric Cards, Section Headers, status chips) MUST be extracted into the global `lib/core/widgets/ds_widgets.dart` library. Do NOT duplicate container decoration logic in local feature files.
- **Surgical Edits Only:** Agents must never re-write or output entire massive files if only a small section is changing. Always use chunk-based replacements.
- **Feature Manifests:** Maintain a brief `README.md` in every feature directory summarizing the data model and available widgets. Agents should read this manifest instead of parsing thousands of lines of Dart code.
- **Skip generated/dependency directories:** Never read or search `build/`, `.dart_tool/`, `functions/node_modules/`, or `.git/` — they are large and contain nothing hand-authored.

## 5. Continuous Self-Improvement & Module Syncing
- **Global Event Bus (Riverpod):** Modules must communicate via the central `AppEventBus` rather than direct hardcoded dependencies. When a state change in one module affects another (e.g. Employee Terminated -> Safety Clearances Revoked), broadcast it via the bus. All modules must also subscribe to the same Riverpod `StreamProvider`s acting as the Single Source of Truth (e.g., `employeesProvider`, `projectsProvider`) — when one module modifies an entity, all connected modules must instantly and automatically react.
- **Polymorphism for Shared Concepts:** Use base classes for shared entity types (e.g., `BaseIncident` for Safety and Environmental incidents) so that enhancements to the core automatically benefit all domains.
- **Auto-Sync Subagent Workflow:** Whenever an agent implements a new, highly optimized widget or state pattern in one module, the agent MUST explicitly trigger a background subagent (using the `auto-sync-refactor` skill) to automatically crawl the codebase and retrofit all other modules with the new standard.
- **Agentic Refactoring Loops:** Whenever an AI Agent (you) modifies a core data model, provider, or structural pattern, you MUST automatically search the codebase for all dependent modules and update them to match the new schema.
- **Automated Regression Hooks:** Every time a major structural change is completed, the agent MUST run `flutter analyze` and resolve any new cross-module warnings or errors before marking the task as complete.

## 6. Common Commands
- `flutter analyze` — run after any structural change, resolve new warnings before completing.
- `flutter test` — run when touching logic covered by existing tests.
- `flutter pub get` — after editing `pubspec.yaml`.
- `cd functions && npm run build` — compile Cloud Functions (TypeScript) after editing `functions/`.

## 7. Agent Workflow Primitives (Tool-Mapped)
The workflow intents below apply regardless of which agent tool is driving. Use whichever concrete primitive your tool exposes:

| Intent | Antigravity primitive | Claude Code equivalent |
|---|---|---|
| Design doc before complex features, get approval first | Markdown Artifact w/ `RequestFeedback: true` | Plan Mode |
| Never guess ambiguous requirements | `ask_question` | `AskUserQuestion` tool |
| Orchestrate large scaffolds via specialized subagents | `invoke_subagent` / `define_subagent` | `Agent` tool |

- **Design first:** When designing a complex new feature or module, first produce a design doc (Artifact, or a Plan Mode plan) outlining the data layer, UI components, and Riverpod structure, and get explicit approval before writing code.
- **Resolving ambiguity:** Never guess undefined requirements — ask via the primitive above.
- **Large scaffolds:** For large scaffolding tasks (e.g. a full new module), act as an orchestrator across specialized subagents (e.g. `UILayerAgent`, `DataLayerAgent`), or invoke existing swarm skills (like `sentinel-swarm-orchestrator`) rather than attempting a massive multi-file module in one shot.
