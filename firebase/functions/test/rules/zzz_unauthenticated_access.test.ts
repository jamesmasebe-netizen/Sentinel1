/**
 * Wave 2c — firestore.rules matrix: every `testEnv.unauthenticatedContext()` case in the whole
 * rules-test suite, isolated into this single file. Named `zzz_...` so it sorts and runs last
 * among test/rules/*.test.ts — see special_cluster_authed.test.ts's header comment for why:
 * mixing unauthenticatedContext() with the ~30+ authenticatedContext() calls spread across this
 * project's other rules test files intermittently threw "Firestore has already been started and
 * its settings can no longer be changed" (a @firebase/rules-unit-testing 3.0.4 SDK quirk, not a
 * rules-logic bug). Isolating every unauthenticated case into its own file, run last, resolved it
 * (confirmed 2026-08-07). Any FUTURE rules test needing an unauthenticated context (e.g. Wave 2c's
 * CRM cluster, for job_requisitions/job_applications' public-portal rules) should be added here,
 * not scattered into other files.
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc } from "firebase/firestore";
import { getTestEnv } from "../helpers/rules_test_env";

describe("firestore.rules — unauthenticated-context cases (Wave 2c)", () => {
  let testEnv: RulesTestEnvironment;

  beforeAll(async () => {
    testEnv = await getTestEnv();
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  afterEach(async () => {
    await testEnv.clearFirestore();
  });

  async function seed(pathStr: string, data: Record<string, unknown>) {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), pathStr), data);
    });
  }

  it("public_tenant_directory: allows a completely unauthenticated client to read", async () => {
    await seed("public_tenant_directory/acme-co", { tenantId: "tenant-a-rules-test" });
    const anon = testEnv.unauthenticatedContext();
    await assertSucceeds(getDoc(doc(anon.firestore(), "public_tenant_directory/acme-co")));
  });

  it("top-level fallback: denies a root-level (non-tenant-scoped) read/write for a fully unauthenticated client", async () => {
    const rootLevelPath = "some_root_level_collection_never_declared/doc-anon";
    const anon = testEnv.unauthenticatedContext();
    const ref = doc(anon.firestore(), rootLevelPath);
    await assertFails(getDoc(ref));
    await assertFails(setDoc(ref, { note: "anon root escape" }));
  });
});
