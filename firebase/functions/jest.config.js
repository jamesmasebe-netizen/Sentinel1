/** Unit tests for Cloud Functions source, colocated as src/**\/*.test.ts. */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  roots: ["<rootDir>/src"],
  testMatch: ["**/*.test.ts"],
};
