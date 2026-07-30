import { onRequest, onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import Stripe from "stripe";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || "sk_test_mock", {
  apiVersion: "2026-06-24.dahlia" as any,
});

export const createStripeCheckoutSession = onCall(async (request) => {
  const { tenantId, priceId } = request.data;
  
  if (!tenantId) {
    throw new HttpsError("invalid-argument", "The function must be called with a tenantId.");
  }

  try {
    // In a real app, look up the Stripe Customer ID for this tenant from Firestore.
    // For this mock, we just create a session assuming a new customer or standard flow.
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ["card"],
      line_items: [
        {
          price: priceId || "price_mock",
          quantity: 1,
        },
      ],
      mode: "subscription",
      success_url: "http://localhost:5000/success?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: "http://localhost:5000/cancel",
      metadata: {
        tenantId: tenantId,
      }
    });

    return { url: session.url };
  } catch (error) {
    logger.error("Failed to create Stripe Checkout session:", error);
    throw new HttpsError("internal", "Failed to create Stripe Checkout session.");
  }
});

export const createBillingPortalSession = onCall(async (request) => {
  const { tenantId } = request.data;

  if (!tenantId) {
    throw new HttpsError("invalid-argument", "The function must be called with a tenantId.");
  }

  try {
    const db = admin.firestore();
    const subscriptionDoc = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("subscription")
      .doc("status")
      .get();

    const stripeCustomerId = subscriptionDoc.data()?.stripeCustomerId;
    if (!stripeCustomerId) {
      throw new HttpsError(
        "failed-precondition",
        "No Stripe customer found for this tenant. Subscribe to a paid plan first."
      );
    }

    const session = await stripe.billingPortal.sessions.create({
      customer: stripeCustomerId,
      return_url: "http://localhost:5000/billing",
    });

    return { url: session.url };
  } catch (error) {
    logger.error("Failed to create Stripe Billing Portal session:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to create Stripe Billing Portal session.");
  }
});

// A webhook that listens to Stripe events (e.g. from Stripe CLI or live)
export const stripeWebhook = onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  
  if (!sig) {
    logger.error("Missing stripe-signature header");
    res.status(400).send("Webhook Error: Missing stripe-signature");
    return;
  }

  const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET || "whsec_mock";
  let event;

  try {
    // Verify signature using the raw body
    event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
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
    res.status(400).send(`Webhook Error: ${(err as Error).message}`);
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

  // Option 2 chosen by user: Tiers are free, pro, premium, enterprise. Default to premium for this example if not provided.
  const tier = subscription.metadata?.tier || "premium";

  await db.collection("tenants").doc(tenantId).collection("subscription").doc("status").set({
    tenantId: tenantId,
    tier: tier,
    status: status,
    stripeCustomerId: subscription.customer,
    stripeSubscriptionId: subscription.id,
    currentPeriodEnd: admin.firestore.Timestamp.fromDate(currentPeriodEnd),
  }, { merge: true });

  logger.info(`Updated subscription for tenant ${tenantId} to tier ${tier}`);
}

async function handleSubscriptionDeleted(subscription: any) {
  const tenantId = subscription.metadata?.tenantId;
  if (!tenantId) return;

  const db = admin.firestore();

  await db.collection("tenants").doc(tenantId).collection("subscription").doc("status").set({
    status: "canceled",
    tier: "free",
  }, { merge: true });

  logger.info(`Canceled subscription for tenant ${tenantId}`);
}
