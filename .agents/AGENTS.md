# Sentinel Global Development Rules

These rules dictate the architecture, design patterns, and programming standards for the Sentinel application. You MUST follow these rules unconditionally when modifying or creating new features.

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

## 2. Data & State Strict Standards
- **Real-time First (Unified State):** All dashboard metrics, summary cards, and primary list views MUST be backed by Firestore streams (`snapshots()`) mapped to Riverpod `StreamProvider`s. Do NOT use `FutureProvider` or one-off `get()` calls for dynamic business data.
- **No Localized Business State:** Do NOT use raw `setState` to hold fragmented business logic or calculations that drive dashboards. Derivations must happen within the Riverpod providers based on the real-time stream.
- **Human Readable IDs:** When creating new master records (Projects, Incidents, CAPAs, Risks), generate a concise, human-readable ID (e.g., `PRJ-001`, `INC-045`) and use it explicitly as the Firestore document ID (`.doc(customId).set(...)`). Do NOT rely on auto-generated long strings for display purposes.
- **No Hardcoded Data:** Never use static, hardcoded, or placeholder data for business metrics. If a feature is incomplete, disable the relevant button or feature instead of faking the data.

## 3. Vibe Coding & Token Optimization (Context Limits)
- **The "200-Line Threshold":** No single UI file may exceed 200 lines of code. If a feature requires more, the agent MUST create a dedicated subdirectory and split the UI into modular component files (e.g., separating tabs into their own files).
- **Global Component Extraction:** Any UI component that is used across multiple modules (e.g., standard Metric Cards, Section Headers, status chips) MUST be extracted into the global `lib/core/widgets/ds_widgets.dart` library. Do NOT duplicate container decoration logic in local feature files.
- **Surgical Edits Only:** Agents must never re-write or output entire massive files if only a small section is changing. Always use chunk-based replacements.
- **Feature Manifests:** Maintain a brief `README.md` in every feature directory summarizing the data model and available widgets. Agents should read this manifest instead of parsing thousands of lines of Dart code.

## 4. Continuous Self-Improvement & Module Syncing
- **Auto-Sync Subagent Workflow:** Whenever an agent implements a new, highly optimized widget or state pattern in one module, the agent MUST explicitly trigger a background subagent (using the `auto-sync-refactor` skill) to automatically crawl the codebase and retrofit all other modules with the new standard.
- **Event-Driven Global State:** Modules must interact systemically. All modules must subscribe to the same Riverpod `StreamProvider`s acting as the Single Source of Truth (e.g., `employeesProvider`, `projectsProvider`). When one module modifies an entity, all connected modules must instantly and automatically react.
- **Automated Regression Hooks:** Every time a major structural change is completed, the agent MUST run `flutter analyze` and resolve any new cross-module warnings or errors before marking the task as complete.
