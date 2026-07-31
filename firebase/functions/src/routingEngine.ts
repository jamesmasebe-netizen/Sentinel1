import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

interface RouteLocation {
  workOrderId: string;
  lat: number;
  lng: number;
}

interface OptimizeRouteRequest {
  locations: RouteLocation[];
}

interface OptimizeRouteResponse {
  optimizedOrder: string[];
  estimatedDuration: string;
  totalDistanceKm: number;
  stops: number;
}

const EARTH_RADIUS_KM = 6371;
// Conservative urban/field-service average — used only to turn a real
// distance total into a human-readable duration estimate.
const AVG_SPEED_KMH = 35;

function haversineKm(a: RouteLocation, b: RouteLocation): number {
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const lat1 = (a.lat * Math.PI) / 180;
  const lat2 = (b.lat * Math.PI) / 180;

  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
}

/** Nearest-neighbor TSP construction heuristic, starting from the first stop. */
function nearestNeighborRoute(locations: RouteLocation[]): {
  order: RouteLocation[];
  totalDistanceKm: number;
} {
  if (locations.length <= 1) {
    return { order: [...locations], totalDistanceKm: 0 };
  }

  const remaining = [...locations];
  const order: RouteLocation[] = [remaining.shift()!];
  let totalDistanceKm = 0;

  while (remaining.length > 0) {
    const current = order[order.length - 1];
    let nearestIdx = 0;
    let nearestDist = Infinity;
    for (let i = 0; i < remaining.length; i++) {
      const d = haversineKm(current, remaining[i]);
      if (d < nearestDist) {
        nearestDist = d;
        nearestIdx = i;
      }
    }
    totalDistanceKm += nearestDist;
    order.push(remaining.splice(nearestIdx, 1)[0]);
  }

  return { order, totalDistanceKm };
}

function formatDuration(totalDistanceKm: number, stops: number): string {
  const travelHours = totalDistanceKm / AVG_SPEED_KMH;
  // Assume 30 min on-site per stop, matching this module's own scheduling convention.
  const onSiteHours = (stops * 30) / 60;
  const totalHours = travelHours + onSiteHours;
  const hours = Math.floor(totalHours);
  const minutes = Math.round((totalHours - hours) * 60);
  return `${hours}h ${minutes}m`;
}

export const optimizeRoute = onCall(async (request) => {
  const data = request.data as OptimizeRouteRequest;
  const locations = data.locations ?? [];

  if (locations.length === 0) {
    throw new HttpsError("invalid-argument", "At least one location is required.");
  }

  logger.info("optimizeRoute called", { stopCount: locations.length });

  const { order, totalDistanceKm } = nearestNeighborRoute(locations);

  const result: OptimizeRouteResponse = {
    optimizedOrder: order.map((l) => l.workOrderId),
    estimatedDuration: formatDuration(totalDistanceKm, order.length),
    totalDistanceKm: Math.round(totalDistanceKm * 10) / 10,
    stops: order.length,
  };

  logger.info("Route optimized", result);

  return result;
});
