# notifications — Module Journey Doc

**Path:** `lib/features/notifications/`  |  **Compartment:** System Administration  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`notifications` is a single file, `notifications_screen.dart` (`NotificationsScreen`) — an in-app notification center reached as a side-sheet from the global header bar. The screen's own source code contains an explicit admission that it is not real: `// In a real app, this would use a StreamProvider over a 'notifications' Firestore collection`, immediately followed by three hardcoded notification entries.

**In scope:** the in-app notification list UI.
**Out of scope:** `lib/core/services/notification_service.dart` (FCM registration + Cloud Function wrappers) — covered here only because it's this module's obvious intended backend and is otherwise undocumented elsewhere; it is core-level, not part of this module's own files.
**IA placement:** System Administration compartment. Per the module brief, this is a cross-cutting delivery mechanism rather than one persona's own tool — primary persona IT/Systems Administrator (owns the mechanism), secondary "all personas" (everyone is a notification recipient in principle).

## 2. User Journeys
| Persona | Journey | Steps touching `notifications` | Entry screen(s) |
|---|---|---|---|
| [IT/Systems Administrator](_shared_personas_and_bpfs.md#persona-it-systems-admin) (primary) | No shared-doc journey text names this screen specifically | View notification list | `notifications_screen.dart` (side-sheet only, see §4) |
| All personas (secondary, delivery mechanism) | Any journey that would normally end in "...and the user gets notified" | None, in practice — see §5/§7: nothing currently populates real notifications for any persona | — |

## 3. BPF Participation
None. `notifications` is explicitly listed in the [shared doc's](_shared_personas_and_bpfs.md#business-process-flows-bpfs) "Modules with zero BPF participation, narratively or in code." Confirmed directly: zero references to `bpf_orchestrator.dart`/`BpfRibbonWidget`/any BPF stage file anywhere in `lib/features/notifications/`.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route / reachability | Purpose / wiring |
|---|---|---|
| `screens/notifications_screen.dart` (`NotificationsScreen`) | **No `GoRoute`** — reached only via `UIUtils.showSideSheet` from the bell icon in `app_header_bar.dart:94-104` (`Icons.notifications_outlined`, tooltip "Notifications"), which is part of the global app shell and therefore reachable from every authenticated screen | Lists 3 hardcoded notifications (leave/training/action-item); "Mark all read" button and per-item tap both call `UIUtils.showToast(...)` only |

This is a genuinely good reachability pattern (correctly uses `UIUtils.showSideSheet` per AGENTS.md §1, unlike several other modules' screens in this batch that use raw `Navigator.push` or lack any entry point at all) — the problem is entirely in what the screen shows once reached, not how you get there.

## 5. Backend & Database

**No `models/`/`services/`/`providers/` subdirectory in this module.** `NotificationsScreen` builds a local `List<Map<String, dynamic>>` literal inline in `build()` — three fixed entries ("Leave Approved," "New Training Assigned," "Task Overdue"), none read from Firestore. No `notifications` collection is declared in `firestore.rules`; confirmed the app never queries one anywhere (repo-wide grep for a `.collection('notifications')` call returns nothing).

**"Mark all read" and per-item tap are both stubs:** `onPressed`/`onTap` call only `UIUtils.showToast(context, 'All marked as read')` / `UIUtils.showToast(context, 'Opening ${n['type']} details...')` — no state mutation, no navigation. Correct toast usage (AGENTS.md §1), but the actions themselves are banned-stub patterns (AGENTS.md §3) — same "reports success without doing anything" shape [ai_tools.md](ai_tools.md) found for the Safety Flash "copy" button.

**`lib/core/services/notification_service.dart` (`NotificationService`, core, not this module) — real, complete, and entirely unused.** It implements: FCM permission request + token fetch + `registerDeviceToken` Cloud Function call (with a Firestore direct-write fallback to `tenants/{siteId}/fcm_tokens/{uid}` if the callable fails), token-refresh re-registration, foreground/background message stream wrappers, and three callable-function wrappers — `sendEmail` (→ `sendEmail`), `sendPush` (→ `sendPushNotification`), `sendEmergencyBroadcast` (→ `sendEmergencyBroadcast`, the same function [emergency.md](emergency.md) documents as real-but-uncalled from its own module). All three target Cloud Functions are confirmed to exist in `firebase/functions/src/index.ts`. **Confirmed by repo-wide grep: `NotificationService.provider`, `.init(`, `.sendPush(`, and its `onForegroundMessage`/`onNotificationTap` streams all have zero references anywhere outside the file itself.** Nothing in the app ever constructs or reads this service — not at login, not anywhere. `main.dart` separately registers `FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler)` directly (not through this service), so the app *could* technically receive a background push at the OS level — but since `registerDeviceToken` is only ever called from inside this same unused service, no device token is ever actually registered, so nothing would be addressed to this app's install in the first place.

**Firestore rules check:** no `notifications` collection exists to check. `fcm_tokens` (the fallback-write target inside `NotificationService`, itself unreachable) is also undeclared in `firestore.rules`, falling to the tenant-scoped catch-all's `allow write: if false` — moot given the write path above it is never reached anyway.

## 6. Cross-Module Links
- `app_header_bar.dart` (core) is this module's sole entry point (§4).
- `NotificationService.sendEmergencyBroadcast` wraps the same Cloud Function [emergency.md §5](emergency.md#5-backend--database) documents as real-but-never-called from `emergency_broadcast_tab.dart` — two independent modules each hold one half of the same dead call chain (a working Cloud Function with no Dart caller that's actually exercised).
- **AppEventBus:** zero usage anywhere in `lib/features/notifications/` or `notification_service.dart` (confirmed by grep) — no module broadcasts an event that this screen (or the underlying service) listens for, and nothing here publishes one either.

## 7. Known Gaps

### Rules-vs-code gaps
- No `notifications` collection exists in `firestore.rules` — consistent with none existing in code either (§5), not a mismatch so much as a feature that was never built past its UI shell.
- `fcm_tokens` (referenced only in `NotificationService`'s unreachable fallback path) is undeclared, falling to the deny-by-default catch-all — moot in practice per §5.
- `BaseIncident` — not applicable, no incident concept in this module.

### DB-to-UI alignment audit
Not applicable — no Firestore-backed model exists; the screen's data is a hardcoded local literal, not a form over any model.

### Other
- **The screen's own source code admits it is a mock** (`// In a real app, this would use a StreamProvider over a 'notifications' Firestore collection`, §5) — an unusually direct, self-documented instance of AGENTS.md §2 ("No Hardcoded Data").
- **"Mark all read" and notification tap are both non-functional stubs** (§5).
- **`NotificationService` is a complete, correctly-implemented service with zero callers anywhere in the app** (§5) — the single largest finding for this module: real FCM registration, real Cloud Function wrappers, entirely unwired. Not initialized at login, not read via its own Riverpod provider, not called from any screen including this module's own.
- Combined effect: no user in this app can currently receive a real push notification, a real in-app notification, or a real device-token registration — every layer of the stack (UI list, backend service, token registration) is either mocked or orphaned.

## 8. Open Questions
- Should `NotificationService.init()` be called from `AuthService` (e.g., inside `_getOrCreateProfile` or right after `signInWithGoogle`/`signInWithSAML` succeed), which is the natural place to trigger FCM registration once a UID/tenant are known?
- Should `NotificationsScreen` be converted to a `StreamProvider` over a real `notifications` (or per-user `users/{uid}/notifications`) collection, and if so, which modules would need to start writing to it (leave approval, training assignment, and overdue-action-item events are exactly the three mocked categories already shown)?
- Is there a reason `sendPush`/`sendEmail` are never called from anywhere — are they meant to be invoked from other modules' write flows (e.g., `people` on leave approval) that simply haven't been connected yet?
