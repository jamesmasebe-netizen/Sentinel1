# Sentinel1 Project Review (2026-10-12)

A whole-repository review at commit `25111ee`, done read-only. Every item was checked directly against code or tool output. A planned multi-agent pass with independent verification did not run, so treat medium and low items as a single reviewer's verified findings.

This repository is public. Security items below are written fix-first: what is wrong and how to fix it, without exploitation detail.

"Latent" means the issue only becomes live once Cloud Functions are deployed. That is blocked today by the Spark billing plan, so none of the latent items is exploitable right now.

## Baseline

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| Dart tests | 395 passing |
| Functions `tsc --noEmit` | Clean |
| Functions jest | 48 passing |
| Dart code in `lib/` | 494 files, ~85k lines, 27 feature modules |

## Critical

### C1. Role and tenant claims are derived from a user-writable document (latent)
- `firestore.rules` (the `users/{userId}` block) lets a signed-in user write any field on their own profile document, with no field validation.
- `firebase/functions/src/authClaims.ts` (`syncUserClaims`) copies `role` and `tenantId` from that document into auth custom claims. Every authorization helper in `firestore.rules` trusts those claims.
- Anonymous sign-in is enabled on the project. `firebase/functions/test/rules/auth_claims.test.ts` asserts the copy-through as intended behavior.
- **Fix.** In rules, deny client writes that create or change `role` or `tenantId` on `users/{uid}`. Assign roles only through an admin-only callable or the console, and add rules tests for the denial. Disable anonymous auth in production. **Do not upgrade to Blaze until this is fixed**, because deploying `syncUserClaims` activates it.

## High

### H1. IoT ingest endpoint is unauthenticated and trusts a caller-supplied tenant (latent)
- `firebase/functions/src/iotEngine.ts` (`iotTelemetryIngest`) is a public HTTPS endpoint. It accepts `tenantId` from the request body and writes tenant data with admin privileges.
- **Fix.** Require a per-device secret or signed token, and resolve the tenant only from the device registry.

### H2. `postJournalEntry` does not check tenant membership or role (latent)
- `firebase/functions/src/index.ts` (`postJournalEntry`) only checks that a caller is signed in. It then writes ledger entries for the payload's `tenantId` using admin privileges, which bypass rules.
- **Fix.** Require `request.auth.token.tenantId === tenantId` and a finance-capable role.

### H3. Callables without authentication (latent)
- `sendEmail` and `sendPushNotification` in `firebase/functions/src/index.ts`, and `askCopilot` in `copilotEngine.ts`, have no authentication check.
- **Fix.** Require auth, tenant match and an appropriate role on every callable. Add App Check, which is not used anywhere today.

### H4. Stripe webhook secret falls back to a hardcoded placeholder
- `firebase/functions/src/billing.ts` uses a literal fallback when `STRIPE_WEBHOOK_SECRET` is unset.
- **Fix.** Fail closed when the secret is missing, and load it with `defineSecret`.

### H5. Gemini API key would ship to every browser
- `pubspec.yaml` bundles `.env` as a Flutter asset. `lib/features/ai_tools/providers/gemini_provider.dart` reads `GEMINI_API_KEY` from it client-side.
- **Fix.** Make AI calls server-side through a callable, with the key set as a Functions secret, or use Firebase AI Logic with App Check. Keep only public Firebase config on the client.

### H6. Client calls functions that don't exist or are in the wrong region
- No server implementation exists for `createInvite`, `generateSafetyFileReport` or `prescreenContractorDocument`.
- `lib/core/services/notification_service.dart`, `lib/features/people/services/invite_service.dart` and `lib/features/contractors/services/contractor_prescreen_service.dart` use the default region, `us-central1`. The functions they call deploy to `europe-west1`.
- **Fix.** Add one shared `FirebaseFunctions.instanceFor(region: 'europe-west1')` provider. Implement or remove the three missing callables.

### H7. CI will likely fail on a clean runner
- `.env` is a declared Flutter asset but is gitignored, and no workflow step creates it. Flutter fails the build when a declared asset is missing.
- **Fix.** Stop bundling `.env`. Use `--dart-define` or a generated `firebase_options.dart`.

### H8. Backend runtime and dependencies are out of date
- Functions target Node 20, which reached upstream end-of-life on 2026-04-30.
- `npm audit --omit=dev` reports 21 production vulnerabilities, including 2 critical and 8 high.
- firebase-admin is at 12.7 against 14.5 latest. firebase-functions is at 6.6 against 7.4 latest.
- **Fix.** Move to Node 22, then upgrade both packages and re-run the audit.

## Medium

- **M1, downgraded from C2 after verification.** Every new sign-in gets `role: employee` in a hardcoded default tenant, `LDN-01`, in `lib/core/services/auth_service.dart`. That tenant has no data. Real data lives in a different tenant, so legitimate new users land somewhere empty. There is also no invite or approval gate on sign-up. **Fix.** Use invite-based onboarding that assigns the right tenant, and remove the hardcoded default.
- **M2. Standards drift against `.agents/AGENTS.md`.**
  - 110 screen or widget files exceed the 200-line limit. The largest is 941 lines.
  - There are 55 `Navigator.push` or `MaterialPageRoute` uses and 46 `ScaffoldMessenger` uses outside `ui_utils`.
  - 37 screen or widget files build Firestore streams in UI code.
  - The worst files are `gantt_task_editor_sheet.dart`, `revenue_recognition_screen.dart`, `okr_dashboard_screen.dart`, `project_detail_screen.dart` and `control_tower_screen.dart`.
- **M3. Unbounded live queries.** There are 205 `.snapshots()` calls but only 46 `.limit(` calls. Growing collections are streamed in full, including `incidents`, `fin_journal_headers`, `work_orders` and `time_entries`. Read cost grows with history.
- **M4. Thin UI test coverage.** Only 4 test files cover screens or widgets. `auth`, `ai_tools`, `copilot` and `settings` have no tests. Router redirects and login are untested.
- **M5. Dependency hygiene.** Most `pubspec.yaml` entries use `any`. `riverpod_annotation`, `riverpod_generator` and `build_runner` are unused, with zero `@riverpod` annotations, and `build_runner` pulls in two discontinued packages. Flutter 3.29.3 and Riverpod 2.6 are well behind current releases.
- **M6. Stale duplicate backend.** A tracked root `functions/` folder, with its own `billing.ts` and compiled JavaScript, sits beside the real `firebase/functions` that `firebase.json` deploys.
- **M7. Missing module manifests.** 24 of 27 feature folders lack the `README.md` that AGENTS.md requires.
- **M8. AppEventBus is barely used.** Only 5 files reference it, so cross-module reactions mostly don't happen as AGENTS.md intends.
- **M9. Empty catch blocks.** 12 empty `catch` blocks hide failures.
- **Already tracked in `docs/OUTSTANDING_WORK.md`:** Employee vs EmployeeProfile, HrHub vs PeopleHub, OkrDashboard mock data, the COIDA overdue query, and the PassportComplianceChecker permission gap.

## Low

- Leftover transcript-scraping files are tracked at the repo root: `get_plan*.py`, `found_*`, `full_*` and `extracted_last_plan.txt`. Two of them are empty.
- `.gitignore` lists `.env` twice. Both `.agent/` and `.agents/` exist. The app version is still `1.0.0+1`.
- `lib/scripts/seed_dummy_data.dart` sits inside `lib/` and ships with the app.
- Naming mixes "XM System" and "Sentinel1".
- The lint config is the default `flutter_lints`. Strict casts and `unawaited_futures` would catch real bug classes here.

## Owner actions

These need the account owner and are mirrored in `docs/NEEDS_YOUR_INPUT.md`.
- **Hold the Blaze upgrade** until C1 is fixed.
- **Don't put the Gemini key in `.env`.** See H5.
- **Confirm deletion of a service-account key** that was pasted into a chat on 2026-07-31.
- **Restrict the Firebase web API key** in the Google Cloud console by HTTP referrer and allowed APIs. The key appears in older public history, which is expected for Firebase web keys, but unrestricted keys can be used against other enabled Google APIs.
- **Consider making the repository private** while the latent security items are open.

## Strengths

- Firestore rules authorize from token claims rather than document lookups, are tenant-scoped, and have a large emulator-backed test suite.
- Project IDs come from a transactional counter, so `PRJ-xxx` IDs cannot collide.
- A real BPF engine, offline write queue and audit log are used across modules.
- The analyzer is clean, tests are green, and the CI and coverage gates are sensibly designed.
- The dev bypass login button is hidden in release builds.
- The Stripe webhook verifies signatures when the secret is configured.
- The tracker docs are honest and current.

## Suggested order

1. **Now:** Fix C1. Lock down H1 to H4 with tests.
2. **Next:** Fix H5 to H8 and M1. Add limits or pagination to growing collections, and add App Check.
3. **Later:** Pay down M2 module by module, add UI and router tests, upgrade Riverpod and Flutter, and clean up the repo.

## Corrections log

- **2026-10-12.** The first draft rated M1 as critical, claiming new sign-ins join the tenant holding real data. Verification showed the default tenant is an empty one, so it was downgraded to Medium.
- **2026-10-12.** The first draft also flagged that 104 commits existed only locally. That was resolved by pushing to GitHub alongside this review.
