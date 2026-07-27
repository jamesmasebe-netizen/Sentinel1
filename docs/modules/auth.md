# auth — Module Journey Doc

**Path:** `lib/features/auth/`  |  **Compartment:** System Administration  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`auth` holds the app's three login-adjacent screens (Google Sign-In + dev bypass, biometric re-lock, and an unreached SAML/SSO form). The actual auth *logic* — Firebase Auth calls, session state, tenant/role resolution — lives outside this folder in `lib/core/services/auth_service.dart` and `lib/core/providers/app_providers.dart`, which this module's screens call into. This doc treats both as in-scope since they're inseparable from what "auth" means functionally, while noting the module itself is UI-only.

**In scope:** `LoginScreen` (Google Sign-In + dev bypass), `LockScreen` (biometric re-auth after inactivity), `EnterpriseSSOScreen` (SAML), and the core auth/session state they drive.
**Out of scope:** per-user profile editing (no screen anywhere in the codebase does this — see §7), role/permission administration (no admin UI exists for assigning `role`/`tenantId` to a user).
**IA placement:** System Administration compartment, IT/Systems Administrator persona per the shared doc's own module-focus listing. See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `auth` | Entry screen(s) |
|---|---|---|---|
| All personas (universal, not persona-specific) | App entry / re-entry | Sign in with Google → (after 30 min inactivity) biometric unlock | `login_screen.dart` → `lock_screen.dart` |
| [IT/Systems Administrator](_shared_personas_and_bpfs.md#persona-it-systems-admin) (primary, per module assignment) | — | No journey step in the shared doc's own text ("Configure 3rd Party Integrations → Manage User Role Permissions → Monitor Background Sync Queues → Train AI Chatbot parameters") names login/auth specifically — the persona assignment here is structural (compartment/IA), not a direct journey-text hook | — |
| [Security/Gate Access Personnel](_shared_personas_and_bpfs.md#persona-security-gate-access) (secondary, per module assignment) | — | Same as above: shared-doc journey text ("Scan QR Code → Verify Compliance → Grant/Deny Access") doesn't reference this module's login/lock screens; no code hook found | — |

This module is infrastructural rather than a persona's own named journey — the same shape `dashboard.md` noted for the launchpad, not a gap.

## 3. BPF Participation
None. `auth` is explicitly listed in the [shared doc's](_shared_personas_and_bpfs.md#business-process-flows-bpfs) "Modules with zero BPF participation, narratively or in code." Confirmed directly: `lib/features/auth/` has zero references to `bpf_orchestrator.dart`/`BpfRibbonWidget`/any BPF stage file.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route / reachability | Purpose / wiring |
|---|---|---|
| `login_screen.dart` (`LoginScreen`) | `/login` (`router.dart:94`) — the only route reachable while unauthenticated | Google Sign-In button (`AuthService.signInWithGoogle`) + biometric auto-check on load (`_checkBiometric`) + a live "Bypass Login (Dev)" button (see §7) |
| `widgets/login_card.dart` (`LoginCard`) | — (widget, composed into `LoginScreen`) | Renders the two buttons above; purely presentational, callbacks passed in |
| `lock_screen.dart` (`LockScreen`) | `/lock` (`router.dart:95`) — shown when `isAppLockedProvider` is true | Biometric re-auth (`local_auth`) to call `SessionManager.unlockSession()`; falls back to auto-unlock with no credential check at all on devices with no biometric hardware (`if (canAuthenticate) {...} else { if (mounted && !auto) unlockSession(); }`); "Sign Out" link |
| `screens/enterprise_sso_screen.dart` (`EnterpriseSSOScreen`) | **None — confirmed orphaned.** Zero references to `EnterpriseSSOScreen` anywhere in `lib/` outside its own file (repo-wide grep); no route, no button/link from `LoginScreen` or anywhere else | A complete, working SAML sign-in form (provider-ID text field → `AuthService.signInWithSAML(providerId)`) with no entry point anywhere in the app |

Both `LockScreen`'s fallback branch and `EnterpriseSSOScreen` use raw `ScaffoldMessenger.of(context).showSnackBar(...)` (the latter, twice) instead of `UIUtils.showToast` — an AGENTS.md §1 violation, same pattern `billing.md` flagged.

## 5. Backend & Database

**No `models/`/`services/`/`providers/` subdirectory exists inside `lib/features/auth/` itself** — all three screens call directly into core-level code: `lib/core/services/auth_service.dart` (`AuthService`: `signInWithGoogle`, `signInWithSAML`, `devBypassLogin`, `authenticateWithBiometrics`, `signOut`, `_getOrCreateProfile`) and `lib/core/providers/app_providers.dart` (auth/session Riverpod providers). Expected for a cross-cutting module, noted for completeness per the shared audit methodology.

**Model:** `lib/core/models/user_profile.dart` (`UserProfile`) — `uid`, `email`, `displayName`, `photoURL`, `role` (comment: "admin, executive, safety_manager, contractor, employee"), `tenantId`, `department`, `jobTitle`, `phone`, `createdAt`, `lastLogin`, `preferences`. Correct `fromFirestore`/`toFirestore`.

**Collection:** `users/{uid}` (top-level, **not** tenant-scoped) — written only by `AuthService._getOrCreateProfile` (on first sign-in, role hardcoded to `'employee'`, `tenantId: FirebaseConfig.defaultSiteId`) and `AuthService.updateProfile` (generic `Map` update, no caller found anywhere in `lib/` — dead method).

**Firestore rules check (`firestore.rules:227-230`):** `match /users/{userId} { allow read: if isAuthenticated() && request.auth.uid == userId; allow write: if isAuthenticated() && request.auth.uid == userId; }` — strictly self-service, no admin/manager override to read or write another user's profile document. Confirmed no other rule block references `users`.

**Custom claims — the module's central finding.** `firestore.rules`' own `getUserRole()`/`getUserTenantId()` helpers (used by `belongsToTenant()`, `isManager()`, `isSheqOfficer()`, `isAdmin()` — i.e., nearly every tenant-scoped rule in the file) read `request.auth.token.role` / `request.auth.token.tenantId`, which are Firebase Auth **custom claims**. Custom claims can only be set server-side via the Admin SDK (`setCustomUserClaims`). Confirmed by repo-wide grep: **zero occurrences of `setCustomUserClaims` or `customClaims`** in `firebase/functions/src/`, `functions/src/`, or `lib/`. No code path in this repository, as committed, ever issues a token carrying `role`/`tenantId`. This means, as far as verifiable from code: a real user who signs in via Google or SAML would get `request.auth.token.role`/`tenantId` both undefined, and `belongsToTenant()` — the gate on almost every collection in `firestore.rules` — would evaluate `false` for them, server-side, regardless of what `currentTenantIdProvider`/`userRoleProvider` compute client-side from Firestore-document fallback data. (Whether claims are set out-of-band via the Firebase Console/Admin tooling outside this repo cannot be verified from code — flagged as a fact about the codebase, not a claim about the live production project.)

## 6. Cross-Module Links
- `lib/config/router.dart`'s top-level `redirect` callback is the sole gate for every other module: `if (!isAuthenticated && !loggingIn) return '/login';` plus the `isAppLockedProvider` check for `/lock`. Every other module in the app (all 27 others) is reachable only through this gate.
- `app_shell.dart` / `app_header_bar.dart` (outside this module) read `userProfileProvider` (avatar) and call `sessionManagerProvider.endSession()` on "Logout" — the header bar's profile-menu "Edit Profile" entry is a non-functional stub (`UIUtils.showToast(context, 'Edit profile opened')`, no navigation) — confirmed there is **no profile-editing screen anywhere in the codebase** that writes `department`/`jobTitle`/`phone`/`preferences` (§7).
- `project_details_screen.dart:51` reads `isMockLoggedInProvider` directly ("// For testing") — a second, unrelated consumer of the same dev-mock flag, outside this module.
- **AppEventBus:** zero usage anywhere in `lib/features/auth/` or `auth_service.dart`/`app_providers.dart` (confirmed by grep) — no event fires on sign-in/sign-out (e.g., nothing broadcasts when a user's session starts, unlike the `EmployeeTerminatedEvent` pattern `people.md`/`dashboard.md` document).

## 7. Known Gaps

### Rules-vs-code gaps
- **Custom claims never set anywhere in code** (§5) — the mechanism nearly all of `firestore.rules` depends on for tenant/role scoping has no code-level producer in either Cloud Functions codebase.
- `users/{userId}` is strictly self-uid read/write (§5) — no rule allows an admin to look up another user's profile by uid; any future "user management" admin screen would need a different read path (e.g., a Cloud Function) to list/edit other users.
- `BaseIncident` — not applicable; this module has no incident concept.

### DB-to-UI alignment audit
No create/edit form exists for `UserProfile` anywhere in the codebase — it's created implicitly (`_getOrCreateProfile`) with `department`/`jobTitle`/`phone`/`preferences` left `null`, and the one "Edit Profile" entry point found in this batch (`app_header_bar.dart`'s profile menu) is a stub toast, not a form (§6). Per the shared methodology, all four of those fields are effectively **Missing** — present on the model, no form anywhere writes them — but this is a single finding about the whole app, not a per-field pattern worth tabulating.

### Other — verification of `ANALYSIS.md`'s three claims (as requested)
`ANALYSIS.md` (repo root) is **stale on all three of its specific code claims** — each has since changed shape rather than being fixed outright:

1. **"`isAuthenticatedProvider`/`userProfileProvider`/`userRoleProvider` hardcoded to bypass auth, e.g. `return true`"** — **false as currently written.** Reading `app_providers.dart` directly: all three now branch on `isMockLoggedInProvider` (a `StateProvider<bool>` defaulting to `false`) and otherwise correctly derive from real `authStateProvider`/`authClaimsProvider`. However, a live, equivalent bypass exists one level up: `login_screen.dart`'s **"Bypass Login (Dev)"** button (visible on the production login screen, not gated by `kDebugMode` or any build flag) sets `isMockLoggedInProvider` to `true` directly — it does **not** call Firebase Auth at all (confirmed: `AuthService.devBypassLogin()`, the method that *does* call `signInAnonymously()`, has **zero call sites** anywhere in `lib/` — it's dead code). Net effect, verified: tapping this button makes `isAuthenticatedProvider` true and `userProfileProvider` yield a hardcoded `dev-admin-123`/`admin`/`sentinel-dev` profile **client-side only**, while `request.auth` server-side remains `null`. Per §5's rules reading, every real Firestore read/write attempted in this state would be rejected by `firestore.rules` (`isAuthenticated()` requires `request.auth != null`) — the UI would render as a logged-in admin while backend calls silently fail. This is a different, and in one sense more actionable, finding than ANALYSIS.md's — not a hardcoded `true`, but a live, unguarded, unauthenticated-looking-authenticated UI button.
2. **"Hardcoded Firebase API key in `lib/main.dart`... `'AIzaSy...LI7Q'`"** — **false for `lib/main.dart` specifically**, confirmed by direct read: both `main()` and the background FCM handler build `FirebaseOptions` from `dotenv.env['FIREBASE_API_KEY']` etc. (`flutter_dotenv`, loaded from a git-ignored `.env`; confirmed `.env` is untracked via `git ls-files .env` returning nothing, only `.env.example` is committed). **But the underlying finding is still true elsewhere**: `lib/config/firebase_config.dart` hardcodes `apiKey = 'AIzaSyCqAZ_Vkmbqqp6z_JlsCVnVGEskNDWLI7Q'` (the exact key ANALYSIS.md's `...LI7Q` fragment matches) plus a separate hardcoded `geminiApiKey = 'AIzaSyDj7ABaHG6_jU4T8NVelw5dQ4EGxReHY8w'`. Confirmed by grep that `FirebaseConfig` is referenced exactly once anywhere in `lib/` (`auth_service.dart:160`, `FirebaseConfig.defaultSiteId` only) — none of its key/secret fields are actually read by Firebase/Gemini initialization as currently wired, but the raw credential values remain committed to source control regardless of whether runtime code consumes them.
3. **"`seedAllDummyData(firestore)` called unconditionally on startup"** — **false as written**: the `seedProductionData(firestore)` call block in `main.dart` is fully commented out ("Seeding complete. Commented out to prevent accidental runs."), so nothing seeds automatically at startup today. The function name in ANALYSIS.md's claim (`seedAllDummyData`) is a different function from the one `main.dart` ever called (`seedProductionData`) — and `seedAllDummyData` (`lib/scripts/seed_dummy_data.dart`) is instead wired to a manual "Seed Data" button inside `dashboard_screen.dart` (outside this module), triggered only on explicit user tap, not on startup.

### Other — additional findings
- `EnterpriseSSOScreen` is a complete, working SAML form with no entry point anywhere in the app (§4) — a fully-built vertical slice that's simply unreachable, not a stub.
- `SessionManager`'s 30-minute inactivity auto-lock is entirely disabled under `kDebugMode` (`userInteracted()` and `_startTimer()` both early-return) — reasonable for local development, but means the lock screen cannot be exercised in a debug build at all, only in release/profile builds.
- `LockScreen`'s no-biometric-hardware fallback unlocks the session with no credential check whatsoever (`if (mounted && !auto) unlockSession();`) — on a device that reports no biometric capability, tapping "Unlock" once succeeds unconditionally.

## 8. Open Questions
- Is `role`/`tenantId` custom-claims assignment handled entirely out-of-band (Firebase Console, an external admin tool, a Cloud Function not present in this repo), or is it genuinely missing end-to-end? This determines whether §5's finding is a documentation gap or a live production blocker.
- Should the "Bypass Login (Dev)" button be wrapped in a `kDebugMode`/flavor check, given it's currently reachable in any build of the app including a production release build?
- Is `EnterpriseSSOScreen` intended to be wired up (e.g., an "Enterprise SSO" link from `LoginScreen`), or is SAML support abandoned in favor of Google Sign-In only?
- Should `lib/config/firebase_config.dart` be deleted now that `main.dart` sources Firebase config from `.env`, keeping only `defaultSiteId` (its one live consumer) elsewhere?
