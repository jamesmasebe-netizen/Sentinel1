# settings — Module Journey Doc

**Path:** `lib/features/settings/`  |  **Compartment:** System Administration  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`settings` bundles two loosely related surfaces: (a) `SettingsScreen`, a small app-preferences page (dark mode toggle + two static/display-only "Security" info tiles + an About tile), and (b) `OfflineQueueScreen`, a viewer/retry UI for `lib/core/services/offline_sync_service.dart`'s local write queue. Both are thin UI shells over core-level state — this module owns no models, services, or providers of its own.

**In scope:** dark-mode toggle, read-only security/about info display, offline sync queue visibility + manual retry.
**Out of scope:** the offline sync engine itself (`OfflineSyncService`, `lib/core/services/`), tenant/integration configuration (no screen for this exists anywhere in the codebase — see §7), user role/permission management (same — no UI found).
**IA placement:** System Administration compartment, IT/Systems Administrator persona — directly confirmed by the shared doc's own journey text for this persona, "Monitor Background Sync Queues," which maps exactly to `OfflineQueueScreen`. See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `settings` | Entry screen(s) |
|---|---|---|---|
| [IT/Systems Administrator](_shared_personas_and_bpfs.md#persona-it-systems-admin) (primary) | System Management — "Monitor Background Sync Queues" (direct textual match) | View pending/failed offline operations → retry individual or all | `offline_queue_screen.dart` (`/offline-queue`) |
| [IT/Systems Administrator](_shared_personas_and_bpfs.md#persona-it-systems-admin) (primary) | System Management — no direct text match for theme/security display | Toggle dark mode; view (non-interactive) security/about info | `settings_screen.dart` (`/settings`) |

No secondary persona is assigned to this module (per module brief).

## 3. BPF Participation
None. `settings` is explicitly listed in the [shared doc's](_shared_personas_and_bpfs.md#business-process-flows-bpfs) "Modules with zero BPF participation, narratively or in code." Confirmed directly: zero references to `bpf_orchestrator.dart`/`BpfRibbonWidget`/any BPF stage file anywhere in `lib/features/settings/`.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route | Purpose / wiring |
|---|---|---|
| `settings_screen.dart` (`SettingsScreen`) | `/settings` (`router.dart:231-234`); also a "Global Settings" tile on `BusinessOsLaunchpad` (System Administration section) | Dark-mode `Switch` (real, wired to `isDarkModeProvider`); two static info tiles (see §7 for copy-accuracy issues); version/build text |
| `offline_queue_screen.dart` (`OfflineQueueScreen`) | `/offline-queue` (`router.dart:236-239`) — **no launchpad tile**, confirmed by reading the full tile list in `business_os_launchpad.dart` (System Administration section has only Command Center/AI Chat/Global Settings/Global Control Tower/Sentinel Copilot); only reachable by direct URL/deep link or in-app `context.go('/offline-queue')` from elsewhere (none found) | Lists queued/failed operations via `SyncStatusHeader` + a `ListView` of `QueuedOperation`s; per-item retry button on failed items |
| `widgets/offline_queue_widgets.dart` (`SyncStatusHeader`, `EmptyQueueView`, `StatusChip`) | — (widgets, composed into `OfflineQueueScreen`) | Status banner (synced/syncing/error) with a "Retry" action; empty-state illustration; small colored status chips |

`OfflineQueueScreen`'s "no launchpad tile" finding is the same reachability pattern `billing.md`/`crm.md` have both flagged elsewhere: a real route with no discoverable in-app entry point apart from the URL itself.

## 5. Backend & Database

**No `models/`/`services/`/`providers/` subdirectory exists inside `lib/features/settings/`** — both screens consume core-level state directly: `isDarkModeProvider` (`app_providers.dart`, a bare `StateProvider<bool>`) and `offlineSyncServiceProvider`/`pendingSyncCountProvider`/`syncStatusProvider` (same file, wrapping `lib/core/services/offline_sync_service.dart`).

**`isDarkModeProvider` is not persisted** — confirmed by grep, it's referenced only in `main.dart`, `app_providers.dart`, and `settings_screen.dart`, with no Hive box or `shared_preferences` write anywhere near it. The toggle works for the current app session only and resets to light mode on every restart.

**`OfflineSyncService` — this module's central finding.** Its own doc comment states "All writes go through OfflineSyncService," and `FirestoreService` (`lib/core/services/firestore_service.dart`, the shared write layer used across the app) routes `createDocument`/`updateDocument`/`deleteDocument` through `_offlineSync.queueOperation(...)`. `queueOperation()` and `getPendingOperations()` both read/write two Hive boxes, `_queueBox`/`_cacheBox`, declared `late Box<String>` and assigned **only** inside `OfflineSyncService.initialize()` (`Hive.openBox<String>(...)`, confirmed the only two `Hive.openBox` call sites in the entire `lib/` tree). **Confirmed by repo-wide grep: `OfflineSyncService.initialize()` has zero call sites anywhere in `lib/`** — it is never invoked from `main.dart`, `app_providers.dart`, or anywhere else. `Hive.initFlutter()` (called in `main.dart`) only bootstraps the Hive package itself; it does not open these specific boxes.

Consequence, verified against Dart's `late` semantics (deterministic, not speculative): any code path that reaches `_queueBox` before it's assigned throws `LateInitializationError: Field '_queueBox' has not been initialized`. This affects two things differently:
- **Writes:** `FirestoreService.createDocument(...)` is called from **27 files** across the codebase (confirmed by grep on `.createDocument(`) — every one of those calls `_offlineSync.queueOperation(...)` → `_queueBox.put(...)` directly, with no guard. As the app is currently wired, every form submission going through this — the officially-documented standard write path — would throw at the moment of submission, before ever reaching Firestore. (`updateDocument`/`deleteDocument`/`directCreate`/`directUpdate` — the queue-bypassing alternatives on the same service — have **zero call sites anywhere**; nothing in the app currently uses them.)
- **Reads (this module's own screen):** `pendingSyncCountProvider`/`syncStatusProvider` merely expose `_pendingCountController.stream`/`_syncStatusController.stream` — these controllers only ever `.add()` a value from inside `_updateStatus()`, which itself is only called by `initialize()`, `queueOperation()`, `retryOperation()`, or `removeOperation()`. Since `initialize()` never runs, these streams never emit at all (not an error — simply silent). Practical effect on `OfflineQueueScreen`: `pendingCount.when(...)` never leaves its `loading:` branch, so the screen shows a perpetual spinner and never calls `getPendingOperations()` (which would itself throw for the same reason) — the screen is inert rather than crashing. The same perpetual-loading effect applies to `AppHeaderBar`'s global `SyncIndicator` (§6).

**Firestore rules check:** not directly applicable — this module's own data (the sync queue) lives entirely in local Hive boxes, never in Firestore. The `collection` string stored on each `QueuedOperation` is only meaningful once `_executeOperation` actually issues the underlying Firestore call, which (per the above) is never reached in the current build.

## 6. Cross-Module Links
- **`FirestoreService`** (core, not this module) is the write path 27 files across essentially every other module rely on — this module's `OfflineQueueScreen` is the only UI in the app that would surface the failure mode described in §5, making the finding belong here even though the root cause (`initialize()` never called) sits in `lib/core/services/`, outside this module's own files.
- **`AppHeaderBar`** (`lib/core/widgets/app_header_bar.dart`, outside this module) renders a global `SyncIndicator` fed by the same `syncStatusProvider`/`pendingSyncCountProvider` on every authenticated screen — it would show the same stuck-loading behavior as `OfflineQueueScreen`, for the same reason, app-wide.
- `settings_screen.dart`'s "Biometric Authentication" tile states "Required to unlock session after **15m** of inactivity" — `lib/core/services/session_manager.dart`'s actual `_timeoutDuration` constant (owned by `auth.md`'s module, see [auth.md](auth.md)) is **`Duration(minutes: 30)`**. The displayed copy and the real value disagree.
- `settings_screen.dart`'s "Screen Capture Protection" tile states it is "Enabled on sensitive screens (Executive Dashboard, Action Tracker)" — confirmed by grep, `ScreenProtector.preventScreenshotOn()`/`protectDataLeakageWithBlur()` are called exactly once, unconditionally, in `main.dart` for the whole app (non-web platforms only) — there is no per-screen scoping anywhere in the codebase. The copy describes narrower, selective behavior than what the code actually does (global).
- **AppEventBus:** zero usage anywhere in `lib/features/settings/` (confirmed by grep).

## 7. Known Gaps

### Rules-vs-code gaps
- Not directly applicable — this module has no Firestore collection of its own (§5).
- `BaseIncident` — not applicable, no incident concept in this module.

### DB-to-UI alignment audit
Doesn't directly apply in the shared methodology's normal sense: `QueuedOperation` (§5) is a local Hive-serialized class, not a Firestore-backed model with a create/edit form, and `SettingsScreen`'s two "Security" tiles are read-only display (`trailing: Icon(Icons.check_circle)`, no `onTap`, no backing document at all) rather than a form over any model.

### Other
- **`OfflineSyncService.initialize()` is never called anywhere in `lib/`** — the offline-first write queue that `FirestoreService` (used by 27+ files) and this module's own `OfflineQueueScreen` both depend on is effectively inert: writes through the standard path throw `LateInitializationError`, and the queue-viewer UI (this module's reason for existing) spins forever instead of showing real data (full detail in §5). This is the headline finding for this module.
- **Two copy-vs-code mismatches on `SettingsScreen`'s static "Security" tiles** (§6): the stated inactivity timeout (15m) doesn't match `SessionManager`'s real value (30m), and the stated screen-protection scoping (two named screens) doesn't match its real scope (global, all non-web platforms).
- **`isDarkModeProvider` is not persisted** — resets to light mode every app restart.
- **`OfflineQueueScreen` has no `BusinessOsLaunchpad` tile** — reachable only by direct route.
- No settings UI exists anywhere in the codebase for the "Configure 3rd Party Integrations" or "Manage User Role Permissions" parts of the IT/Systems Administrator's shared-doc journey — only "Monitor Background Sync Queues" has a real, if broken, implementation. (`lib/core/services/integrations_service.dart` exists but confirmed to have no `settings`-module screen or any other UI screen calling it — out of scope for this module's own doc, noted here only because it's this persona's other named sub-journey.)

## 8. Open Questions
- Was `OfflineSyncService.initialize()` ever wired into `main.dart` and later removed, or has the offline queue never actually functioned end-to-end? Given `FirestoreService`'s doc comment states writes go through it as settled design, this looks like a regression rather than an intentional stub.
- Should `OfflineQueueScreen` get a `BusinessOsLaunchpad` tile, given the persona's shared-doc journey names "Monitor Background Sync Queues" as a first-class task?
- Should the two "Security" tiles' copy be corrected to match `SessionManager`'s real 30-minute timeout and `ScreenProtector`'s real global scope, or should the code be changed to match the copy (a 15-minute timeout, screen-scoped protection)?
- Should `isDarkModeProvider` be persisted (Hive or `shared_preferences`), consistent with the rest of the app's offline-first posture?
