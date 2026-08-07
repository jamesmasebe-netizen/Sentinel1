/**
 * Wave 2c — firestore.rules matrix, Finance/SCM cluster: 15 top-level collections plus 3
 * subcollections, every single one sharing the exact same shape (confirmed by reading the real
 * firestore.rules text directly, not assumed) — read open to any tenant member, create/update
 * gated to isManager(), delete gated to isAdmin(). No "distinctive" file needed for this cluster;
 * unlike HR/SHEQ and sensitive-data, nothing here has a different role combination.
 *
 * Note: fin_ap_invoices, fin_ar_invoices, fin_journal_headers, fin_chart_of_accounts,
 * fin_tax_codes, fin_budget_models, and fin_cost_centers are each declared TWICE in
 * firestore.rules (once under "Finance collections", once under "Finance" further down) — checked
 * both declarations are byte-for-byte identical in their access rules (harmless redundancy, not a
 * divergent-permissiveness bug like the catch-all's), so a single round of tests against the real
 * collection path exercises both blocks at once; no special-casing needed here.
 *
 * Binding rule (see TEST_STRATEGY.md §7): call `.firestore()` at most once per context object,
 * ever. Every context here uses a globally-unique uid and exactly one `.firestore()` call.
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc } from "firebase/firestore";
import { authedContext, getTestEnv, TENANT_A, TENANT_B } from "../helpers/rules_test_env";

describe("firestore.rules — Finance/SCM cluster (Wave 2c)", () => {
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

  const managerGated = [
    "fin_ap_invoices",
    "fin_ar_invoices",
    "fin_journal_headers",
    "fin_chart_of_accounts",
    "fin_tax_codes",
    "fin_budget_models",
    "fin_cost_centers",
    "assets",
    "sales_orders",
    "transfer_orders",
    "mrp_suggestions",
    "warehouseBinLocations",
    "vendorPerformanceMetrics",
    "boms",
    "purchase_orders",
  ];

  for (const collection of managerGated) {
    it(`${collection}: manager can create, employee cannot, admin can delete, manager cannot delete`, async () => {
      const manager = authedContext(testEnv, `manager-${collection}-1`, TENANT_A, "manager");
      const managerRef = doc(manager.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-a`);
      await assertSucceeds(setDoc(managerRef, { note: "seed" }));
      await assertFails(deleteDoc(managerRef));

      const employee = authedContext(testEnv, `employee-${collection}-1`, TENANT_A, "employee");
      await assertFails(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-deny`), {
          note: "should be denied",
        })
      );

      const admin = authedContext(testEnv, `admin-${collection}-1`, TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-a`))
      );
    });

    it(`${collection}: read is NOT role-gated — a plain employee can read, but a cross-tenant user cannot`, async () => {
      await seed(`tenants/${TENANT_A}/${collection}/${collection}-read`, { note: "seed" });
      const employee = authedContext(testEnv, `employee-${collection}-2`, TENANT_A, "employee");
      await assertSucceeds(
        getDoc(doc(employee.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-read`))
      );

      const outsider = authedContext(testEnv, `outsider-${collection}-1`, TENANT_B, "admin");
      await assertFails(
        getDoc(doc(outsider.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-read`))
      );
    });
  }

  describe("subcollections — all three inherit the same manager-gated shape as their parent", () => {
    it("purchase_orders/{poId}/po_lines: manager can create a line, employee cannot, admin can delete", async () => {
      await seed(`tenants/${TENANT_A}/purchase_orders/po-1`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-poline-1", TENANT_A, "manager");
      const lineRef = doc(manager.firestore(), `tenants/${TENANT_A}/purchase_orders/po-1/po_lines/line-1`);
      await assertSucceeds(setDoc(lineRef, { note: "seed" }));
      await assertFails(deleteDoc(lineRef));

      const employee = authedContext(testEnv, "employee-poline-1", TENANT_A, "employee");
      await assertFails(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/purchase_orders/po-1/po_lines/line-deny`), {
          note: "should be denied",
        })
      );

      const admin = authedContext(testEnv, "admin-poline-1", TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/purchase_orders/po-1/po_lines/line-1`))
      );
    });

    it("sales_orders/{orderId}/so_lines: manager can create a line, employee cannot, admin can delete", async () => {
      await seed(`tenants/${TENANT_A}/sales_orders/so-1`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-soline-1", TENANT_A, "manager");
      const lineRef = doc(manager.firestore(), `tenants/${TENANT_A}/sales_orders/so-1/so_lines/line-1`);
      await assertSucceeds(setDoc(lineRef, { note: "seed" }));
      await assertFails(deleteDoc(lineRef));

      const employee = authedContext(testEnv, "employee-soline-1", TENANT_A, "employee");
      await assertFails(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/sales_orders/so-1/so_lines/line-deny`), {
          note: "should be denied",
        })
      );

      const admin = authedContext(testEnv, "admin-soline-1", TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/sales_orders/so-1/so_lines/line-1`))
      );
    });

    it("fin_journal_headers/{entryId}/lines: manager can create a line, employee cannot, admin can delete", async () => {
      await seed(`tenants/${TENANT_A}/fin_journal_headers/je-1`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-jeline-1", TENANT_A, "manager");
      const lineRef = doc(manager.firestore(), `tenants/${TENANT_A}/fin_journal_headers/je-1/lines/line-1`);
      await assertSucceeds(setDoc(lineRef, { note: "seed" }));
      await assertFails(deleteDoc(lineRef));

      const employee = authedContext(testEnv, "employee-jeline-1", TENANT_A, "employee");
      await assertFails(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/fin_journal_headers/je-1/lines/line-deny`), {
          note: "should be denied",
        })
      );

      const admin = authedContext(testEnv, "admin-jeline-1", TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/fin_journal_headers/je-1/lines/line-1`))
      );
    });
  });
});
