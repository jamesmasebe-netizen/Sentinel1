# Sentinel1 Test Strategy

## Status
Phase 1 (this document + Tier 1 implementation) landed 2026-08-05. Testing infrastructure was previously **greenfield** — `test/widget_test.dart` was a 9-line boilerplate stub with no real assertions, no test packages beyond stock `flutter_test`, no Cloud Functions tests, and no CI. See [`TEST_BACKLOG.md`](./TEST_BACKLOG.md) for what's implemented vs. pending.

## 1. Scope & pyramid position (binding)

Two failure modes matter most for this app and drive everything below:
- **Silent data corruption** across the 27 tenant-scoped feature modules (a write that looks successful but produces data another screen can't read — this already happened once: `postJournalEntry` wrote Firestore field names the Dart `JournalEntry.fromJson` model didn't recognize).
- **Authorization drift** — `firestore.rules` has 116 `match` blocks; a rule that's too permissive silently leaks cross-tenant data, one that's too strict silently breaks a legitimate write. Both are invisible until someone hits them in production.

This sets a **binding rule** for where a test belongs:

| Test type | When to use | Tooling |
|---|---|---|
| Unit test (Dart) | Pure business/service logic — no Firestore reads needed to be *correct*, only to exist | `mocktail` + plain Dart |
| Provider/service test (Dart) | Riverpod providers, Firestore-backed services where correctness doesn't depend on rule enforcement | `fake_cloud_firestore` (does **not** enforce security rules — don't use it to test authorization) |
| Rules test (TS) | Anything where correctness *depends on* `firestore.rules` enforcement — tenant isolation, role gating | Firebase Emulator Suite + `@firebase/rules-unit-testing`, via `npm run test:rules` in `firebase/functions/` |
| Cloud Function test (TS) | `firebase/functions/src/*.ts` | `jest` + `ts-jest`; `firebase-functions-test` for `onCall` wrapping; emulator-backed (not deep admin-SDK mocking) for anything transactional |
| Widget test (Dart) | Screen/form rendering and interaction, deferred to Tier 3 | `flutter_test` + `ProviderScope` overrides |
| Integration test (Dart) | End-to-end golden paths, deferred to Tier 3 | `integration_test` (declared in `pubspec.yaml`, not yet used) |

**Do not use `fake_cloud_firestore` to assert anything about who is/isn't allowed to read or write something** — it has no concept of security rules and will report success on writes real rules would reject. That class of test always goes through the emulator.

## 2. Directory & naming convention

`test/` mirrors `lib/` path-for-path:
```
lib/features/finance/services/ledger_posting_service.dart
  -> test/features/finance/services/ledger_posting_service_test.dart
lib/core/bpf/bpf_orchestrator.dart
  -> test/core/bpf/bpf_orchestrator_test.dart
```
Cloud Functions unit tests are colocated: `firebase/functions/src/index.ts` -> `firebase/functions/src/index.test.ts` (same directory, `tsconfig.json` excludes `*.test.ts` from the deployed build). Rules tests live in `firebase/functions/test/rules/*.test.ts` (separate from `src/` on purpose — they require the emulator running, so they're excluded from the plain `npm test` run and only execute via `npm run test:rules`).

## 3. Riverpod override convention

Always construct a `ProviderContainer(overrides: [...])` — never instantiate a service/notifier class directly and never reach into a real `FirebaseFirestore.instance`. For `StreamProvider`-backed code (the majority of this app's data layer, per AGENTS.md's real-time-first rule), override the *provider the stream comes from* (typically `firestoreProvider`, overridden to a `fake_cloud_firestore` instance) rather than trying to fake the `StreamProvider` itself — this keeps the real provider logic (the `.tenantCollection(tenantId, ...)` calls, the `.map()` transforms) under test instead of bypassed.

```dart
final container = ProviderContainer(overrides: [
  firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
  currentTenantIdProvider.overrideWithValue('test-tenant'),
]);
addTearDown(container.dispose);
```

`tenantCollection(tenantId, path)` (`lib/core/utils/tenant_firestore_extension.dart`) resolves to `tenants/{tenantId}/{path}` — seed fixtures at that path, not at the collection root.

## 4. BPF engine testing

`lib/core/bpf/bpf_orchestrator.dart` is a pure state-transition engine (stage advancement, gating) that 14+ feature files depend on indirectly. Tier 1 covers its transition logic with in-memory fixtures — no Firestore involved, since the transition rules themselves don't touch persistence directly (the orchestrator's *callers* do the writes). The 6 domain-specific flow files (`lead_to_cash_bpf.dart`, `procure_to_pay_bpf.dart`, etc.) are Tier 2 — those need `fake_cloud_firestore` since they drive real collection writes per domain.

## 5. Cloud Functions conventions

- Wrap `onCall` functions with `firebase-functions-test`'s `wrap()` rather than calling the exported handler directly, so the real `CallableRequest` shape is exercised.
- **Every test touching a Firestore write must assert field names explicitly against the Dart model's `fromJson` keys it corresponds to** — this is the direct, non-negotiable lesson from the `postJournalEntry` bug (it wrote `date`/`totalDebit`/camelCase line fields; `JournalEntry.fromJson`/`JournalLine.fromJson` read `transaction_date`/`total_debit`/snake_case — nothing caught this until a human read both sides side-by-side). Don't just assert "a document was written" — assert its exact keys.
- Prefer emulator-backed tests (`firebase-functions-test`'s emulator mode, or direct Admin SDK against `FIRESTORE_EMULATOR_HOST`) over deep `jest.mock('firebase-admin')` mocking for anything that runs a Firestore transaction (`db.runTransaction`) — a mock can't catch a transaction that reads stale data or double-increments a balance; the emulator can.

## 6. Fixture/builder conventions

Shared fixtures live in `test/helpers/` (Dart) and `firebase/functions/test/helpers/` (TS) — e.g. `buildTestIncident({...})`, `seedJournalEntry(db, {...})`. Prefer a builder function with sensible defaults + named-parameter overrides over duplicating a full object literal in every test.

## 7. Tenant-isolation test pattern

Every rules test that touches a tenant-scoped collection asserts **both** directions: an authenticated user with the right `tenantId`/role claim can do X (allow), and a user without it cannot (deny). A rules test that only checks the allow case is incomplete — the deny case is where the actual risk lives.

**Second binding rule, also found the hard way (2026-08-07): `firebase/functions/jest.rules.config.js` must keep `maxWorkers: 1`.** Every rules test file shares ONE Firestore emulator project (`PROJECT_ID` in `rules_test_env.ts`). With Jest's default parallelism, multiple test files run concurrently in separate workers — one file's `afterEach: testEnv.clearFirestore()` can wipe out a document a *different* file just seeded, mid-test, in an interleaved run. Symptom: intermittent `FirebaseError: 5 NOT_FOUND: no entity to update`, with a failure count that varies between runs (2, then 4, etc.) — genuine flakiness, unlike the deterministic bug below. Don't remove `maxWorkers: 1` to "speed things up" without re-verifying stability across several repeat runs first; the whole suite already completes in ~10s serialized, so there's little to gain.

**Third binding rule, found the hard way (2026-08-07): call `RulesTestContext.firestore()` at most once per context, ever.** Calling it a second time on the same `authedContext(...)`/`testEnv.unauthenticatedContext()` result — even for a second, harmless read/write with no different settings — throws `FirebaseError: Firestore has already been started and its settings can no longer be changed` from `@firebase/rules-unit-testing@3.0.4`'s underlying client SDK. This is fully deterministic (not flaky — same failing tests every run), and easy to trigger by accident: any test doing more than one operation as the same user (`setDoc` then `getDoc`, or building a doc ref then later calling `.firestore()` again to delete it) hits it. Fix: call `.firestore()` exactly once, store the result (or a `doc()`/`collection()` ref built from it) in a local variable, and reuse that for every subsequent operation in the test — never call `.firestore()` a second time on the same context object. This was root-caused after several wrong theories (worker parallelism, total context count, `unauthenticatedContext()` specifically) all failed to explain it; the real trigger is exactly and only "more than one `.firestore()` call on one context."

## 8. Definition of done, per tier

- **Tier 1**: the 5 targets in the backlog have real tests, `npm run test:rules` passes against the emulator, `flutter test` passes, backlog marked `[DONE]` with a dated note.
- **Tier 2**: remaining safety/regulatory + finance/billing service layers and Cloud Functions have unit coverage; full `firestore.rules` allow/deny matrix (all 116 blocks, not just the Tier 1 smoke sample); BPF domain flows covered.
- **Tier 3**: remaining 21 modules, widget tests for critical screens, `integration_test` golden paths, CI coverage thresholds enforced (not just run-and-report).

See [`TEST_BACKLOG.md`](./TEST_BACKLOG.md) for the full item-by-item tracking, using the same `[DONE]`/dated-resolved-note convention as `docs/fixes/FIX_LIST.md`.
