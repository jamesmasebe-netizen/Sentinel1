/** Unit tests for Cloud Functions source, colocated as src/**\/*.test.ts. */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  roots: ["<rootDir>/src"],
  testMatch: ["**/*.test.ts"],
  // T3-CI-COVERAGE: floor set a few points below the measured baseline (~41% lines/statements,
  // ~31% branches, ~36% functions as of 2026-08-09) as a regression gate, not an aspirational
  // target — this config only covers the fast, non-emulator unit tests (precondition/validation
  // guards; TEST_STRATEGY.md §2 deliberately keeps these separate from the emulator-backed
  // test/rules/*.test.ts suite, which exercises the real write-path logic and isn't included in
  // this number). Ratchet up as more unit-level coverage is added, don't lower it to pass a
  // failing PR.
  coverageThreshold: {
    global: {
      statements: 35,
      branches: 25,
      functions: 30,
      lines: 35,
    },
  },
};
