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
};
