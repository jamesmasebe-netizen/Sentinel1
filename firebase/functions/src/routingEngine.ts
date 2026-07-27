import { onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

interface OptimizeRouteRequest {
  workOrderIds: string[];
  locations: string[];
}

interface OptimizeRouteResponse {
  optimizedOrder: string[];
  estimatedDuration: string;
  stops: number;
}

export const optimizeRoute = onCall<OptimizeRouteRequest, OptimizeRouteResponse>(
  async (request) => {
    const { workOrderIds, locations } = request.data;

    logger.info("optimizeRoute called", {
      workOrderCount: workOrderIds.length,
      locationCount: locations.length,
    });

    // Simulate a TSP solver by reversing the order of workOrderIds
    const optimizedOrder = [...workOrderIds].reverse();

    const result: OptimizeRouteResponse = {
      optimizedOrder,
      estimatedDuration: "4h 30m",
      stops: optimizedOrder.length,
    };

    logger.info("Route optimized", result);

    return result;
  }
);
