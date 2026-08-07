/**
 * Unit tests for `optimizeRoute` (T3-ENGINES).
 *
 * Unlike `copilotEngine`/`aiEngine`/`iotEngine`, this one is fully deterministic — a haversine
 * distance calculation plus a nearest-neighbor TSP construction heuristic, no external API, no
 * Firestore. TEST_STRATEGY.md's blanket "AI/IoT — lower unit-test ROI, contract/shape tests only"
 * guidance doesn't actually apply here despite living in the same "engines" cluster, so this file
 * tests real output correctness (distances, ordering, formatted duration), not just response
 * shape. No mocking needed at all.
 *
 * Expected distances/durations below are computed via an independently-written haversine
 * implementation (not imported from routingEngine.ts) so a bug in the production formula would
 * still be caught, rather than the test tautologically re-deriving the same numbers from the same
 * code under test.
 */
import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { optimizeRoute } from "./routingEngine";

const { wrap } = firebaseFunctionsTest();
const wrapped = wrap(optimizeRoute);

function buildRequest(data: unknown): CallableRequest {
  const req = {
    data,
    auth: { uid: "test-user-1", token: {} },
    rawRequest: {},
    acceptsStreaming: false,
  };
  return req as unknown as CallableRequest;
}

interface Loc {
  workOrderId: string;
  lat: number;
  lng: number;
}

const EARTH_RADIUS_KM = 6371;
function independentHaversineKm(a: Loc, b: Loc): number {
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const lat1 = (a.lat * Math.PI) / 180;
  const lat2 = (b.lat * Math.PI) / 180;
  const h =
    Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
}
function expectedDurationLabel(totalDistanceKm: number, stops: number): string {
  const travelHours = totalDistanceKm / 35;
  const onSiteHours = (stops * 30) / 60;
  const totalHours = travelHours + onSiteHours;
  const hours = Math.floor(totalHours);
  const minutes = Math.round((totalHours - hours) * 60);
  return `${hours}h ${minutes}m`;
}

type Result = {
  optimizedOrder: string[];
  estimatedDuration: string;
  totalDistanceKm: number;
  stops: number;
};

describe("optimizeRoute — validation", () => {
  it("rejects a call with zero locations", async () => {
    await expect(wrapped(buildRequest({ locations: [] }))).rejects.toMatchObject({
      code: "invalid-argument",
    });
  });

  it("rejects a call with no locations field at all", async () => {
    await expect(wrapped(buildRequest({}))).rejects.toMatchObject({
      code: "invalid-argument",
    });
  });
});

describe("optimizeRoute — single stop", () => {
  it("returns zero distance and a duration of just the on-site time", async () => {
    const result = (await wrapped(
      buildRequest({ locations: [{ workOrderId: "WO-1", lat: -26.2, lng: 28.0 }] })
    )) as Result;

    expect(result.optimizedOrder).toEqual(["WO-1"]);
    expect(result.stops).toBe(1);
    expect(result.totalDistanceKm).toBe(0);
    expect(result.estimatedDuration).toBe("0h 30m"); // 30 min on-site, 0 travel
  });
});

describe("optimizeRoute — two stops", () => {
  it("computes the correct haversine distance and duration between two real coordinates", async () => {
    const a: Loc = { workOrderId: "WO-A", lat: -26.2041, lng: 28.0473 }; // Johannesburg
    const b: Loc = { workOrderId: "WO-B", lat: -25.7479, lng: 28.2293 }; // Pretoria

    const result = (await wrapped(buildRequest({ locations: [a, b] }))) as Result;

    const expectedDistance = independentHaversineKm(a, b);
    expect(result.optimizedOrder).toEqual(["WO-A", "WO-B"]);
    expect(result.totalDistanceKm).toBeCloseTo(Math.round(expectedDistance * 10) / 10, 1);
    expect(result.estimatedDuration).toBe(
      expectedDurationLabel(Math.round(expectedDistance * 10) / 10, 2)
    );
  });
});

describe("optimizeRoute — nearest-neighbor ordering with 3+ stops", () => {
  it("visits the nearest unvisited stop at each step, not input order or true-optimal order", async () => {
    // Start (0,0). C (0, 0.1) is much closer to Start than B (0, 1) is — nearest-neighbor must
    // visit C before B even though B was listed second in the input.
    const start: Loc = { workOrderId: "START", lat: 0, lng: 0 };
    const far: Loc = { workOrderId: "FAR", lat: 0, lng: 1 };
    const near: Loc = { workOrderId: "NEAR", lat: 0, lng: 0.1 };

    const result = (await wrapped(
      buildRequest({ locations: [start, far, near] })
    )) as Result;

    expect(result.optimizedOrder).toEqual(["START", "NEAR", "FAR"]);
    expect(result.stops).toBe(3);

    const expectedTotal = independentHaversineKm(start, near) + independentHaversineKm(near, far);
    expect(result.totalDistanceKm).toBeCloseTo(Math.round(expectedTotal * 10) / 10, 1);
  });

  it("rounds totalDistanceKm to 1 decimal place", async () => {
    const result = (await wrapped(
      buildRequest({
        locations: [
          { workOrderId: "A", lat: 0, lng: 0 },
          { workOrderId: "B", lat: 0, lng: 0.123456 },
        ],
      })
    )) as Result;

    // A round-to-1-decimal number, when multiplied by 10, is an integer.
    expect(Number.isInteger(result.totalDistanceKm * 10)).toBe(true);
  });
});
