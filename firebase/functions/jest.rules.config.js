/**
 * Firestore security-rules tests, run against the Firebase emulator (see the
 * "test:rules" npm script, which wraps this in `firebase emulators:exec`).
 * Kept separate from jest.config.js so plain `npm test` doesn't require a
 * running emulator.
 */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  roots: ["<rootDir>/test/rules"],
  testMatch: ["**/*.test.ts"],
  testTimeout: 20000,
  // Every rules test file shares ONE Firestore emulator project (PROJECT_ID in
  // test/helpers/rules_test_env.ts). Jest's default parallelism runs multiple test files
  // concurrently in separate workers, so one file's `afterEach: testEnv.clearFirestore()` can
  // wipe out a document a DIFFERENT file just seeded, mid-test, in an interleaved run — surfaces
  // as intermittent "NOT_FOUND: no entity to update" (confirmed 2026-08-07: failure count varied
  // 2/4/etc. across repeat runs, unlike the earlier deterministic firestore()-call-count bug this
  // suite also had to fix — see TEST_STRATEGY.md §7). maxWorkers: 1 serializes every file so no
  // two ever run clearFirestore()/seed()/assert cycles against each other's in-flight data.
  maxWorkers: 1,
};
