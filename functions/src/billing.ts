import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// A basic webhook simulation that listens to Stripe events (e.g. from Stripe CLI or live)
export const stripeWebhook = onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  
  if (!sig) {
    logger.error("Missing stripe-signature header");
    res.status(400).send("Webhook Error: Missing stripe-signature");
    return;
  }

  const payload = req.body; // In a real app, use the raw buffer and stripe.webhooks.constructEvent

  try {
    // Determine the event type. In a simple mock, we might just parse req.body directly
    const event = typeof payload === "string" ? JSON.parse(payload) : payload;
    logger.info(`Received Stripe event: ${event.type}`);

    switch (event.type) {
      case "customer.subscription.created":
      case "customer.subscription.updated":
        await handleSubscriptionUpdated(event.data.object);
        break;
      case "customer.subscription.deleted":
        await handleSubscriptionDeleted(event.data.object);
        break;
      default:
        logger.info(`Unhandled event type ${event.type}`);
    }

    res.json({ received: true });
  } catch (err) {
    logger.error("Webhook signature verification failed.", err);
    res.status(400).send("Webhook Error");
  }
});

async function handleSubscriptionUpdated(subscription: any) {
  // Normally you'd look up the tenantId associated with this Stripe customer
  // For simulation, we assume subscription.metadata.tenantId is set
  const tenantId = subscription.metadata?.tenantId;
  if (!tenantId) {
    logger.error("No tenantId in subscription metadata");
    return;
  }

  const db = admin.firestore();
  
  const currentPeriodEnd = new Date(subscription.current_period_end * 1000);
  let status = subscription.status; // e.g. active, past_due, trialing

  const tier = subscription.metadata?.tier || "pro";

  await db.collection("tenants").doc(tenantId).collection("billing").doc("subscription").set({
    tenantId: tenantId,
    tier: tier,
    status: status,
    stripeCustomerId: subscription.customer,
    stripeSubscriptionId: subscription.id,
    currentPeriodEnd: admin.firestore.Timestamp.fromDate(currentPeriodEnd),
  }, { merge: true });

  logger.info(`Updated subscription for tenant ${tenantId}`);
}

async function handleSubscriptionDeleted(subscription: any) {
  const tenantId = subscription.metadata?.tenantId;
  if (!tenantId) return;

  const db = admin.firestore();

  await db.collection("tenants").doc(tenantId).collection("billing").doc("subscription").set({
    status: "canceled",
    tier: "free",
  }, { merge: true });

  logger.info(`Canceled subscription for tenant ${tenantId}`);
}
