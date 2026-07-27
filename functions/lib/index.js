"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.stripeWebhookHandler = exports.createStripeCheckoutSession = exports.platformApi = exports.createInvite = exports.onUserCreated = exports.syncUserClaims = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const functions = require("firebase-functions");
const Stripe = require("stripe");
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || 'sk_test_dummy', {
    apiVersion: '2023-10-16',
});
admin.initializeApp();
exports.syncUserClaims = (0, firestore_1.onDocumentWritten)("users/{userId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        logger.error("No data associated with the event");
        return;
    }
    const userId = event.params.userId;
    const afterData = snapshot.after.data();
    if (!afterData) {
        // Document was deleted
        logger.info(`User ${userId} deleted. Skipping custom claim update.`);
        return;
    }
    const tenantId = afterData.tenantId;
    const role = afterData.role;
    try {
        const currentRecord = await admin.auth().getUser(userId);
        const currentClaims = currentRecord.customClaims || {};
        if (currentClaims.tenantId === tenantId && currentClaims.role === role) {
            logger.info(`Claims for ${userId} are already up to date.`);
            return;
        }
        await admin.auth().setCustomUserClaims(userId, {
            ...currentClaims,
            tenantId,
            role,
        });
        logger.info(`Successfully updated claims for user ${userId}: tenantId=${tenantId}, role=${role}`);
    }
    catch (error) {
        logger.error(`Error updating custom claims for user ${userId}:`, error);
    }
});
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
    if (!user.email) {
        logger.info("User does not have an email, skipping invite check.");
        return;
    }
    const email = user.email;
    const invitesSnapshot = await admin.firestore().collection("invites").where("email", "==", email).get();
    if (invitesSnapshot.empty) {
        logger.info(`No invite found for email ${email}`);
        return;
    }
    const inviteDoc = invitesSnapshot.docs[0];
    const inviteData = inviteDoc.data();
    const { tenantId, role } = inviteData;
    try {
        // Assign custom user claims
        await admin.auth().setCustomUserClaims(user.uid, {
            tenantId,
            role,
        });
        // Mark the invite as accepted
        await inviteDoc.ref.update({ status: "accepted" });
        // Update their Firestore users document
        await admin.firestore().collection("users").doc(user.uid).set({
            tenantId,
            role,
            email
        }, { merge: true });
        logger.info(`Processed invite for user ${user.uid} (${email})`);
    }
    catch (error) {
        logger.error(`Error processing invite for user ${user.uid}:`, error);
    }
});
exports.createInvite = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "The function must be called while authenticated.");
    }
    const callerTenantId = context.auth.token.tenantId;
    if (!callerTenantId) {
        throw new functions.https.HttpsError("permission-denied", "Caller does not have a tenantId.");
    }
    const { email, role } = data;
    if (!email || !role) {
        throw new functions.https.HttpsError("invalid-argument", "The function must be called with email and role.");
    }
    try {
        const inviteRef = admin.firestore().collection("invites").doc();
        await inviteRef.set({
            email,
            role,
            tenantId: callerTenantId,
            status: "pending",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        logger.info(`Invite created for ${email} by user ${context.auth.uid}`);
        return { id: inviteRef.id, success: true };
    }
    catch (error) {
        logger.error("Error creating invite:", error);
        throw new functions.https.HttpsError("internal", "An error occurred while creating the invite.");
    }
});
__exportStar(require("./billing"), exports);
var api_1 = require("./api");
Object.defineProperty(exports, "platformApi", { enumerable: true, get: function () { return api_1.platformApi; } });
exports.createStripeCheckoutSession = functions.https.onCall(async (data, context) => {
    const { priceId, tenantId } = data;
    if (!priceId || !tenantId) {
        throw new functions.https.HttpsError("invalid-argument", "Missing priceId or tenantId.");
    }
    try {
        const session = await stripe.checkout.sessions.create({
            mode: 'subscription',
            line_items: [{ price: priceId, quantity: 1 }],
            client_reference_id: tenantId,
            success_url: 'https://example.com/success',
            cancel_url: 'https://example.com/cancel',
        });
        return { url: session.url };
    }
    catch (error) {
        logger.error("Stripe error:", error);
        throw new functions.https.HttpsError("internal", error.message);
    }
});
exports.stripeWebhookHandler = functions.https.onRequest(async (req, res) => {
    const sig = req.headers['stripe-signature'];
    const endpointSecret = 'whsec_dummy';
    let event;
    try {
        event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
    }
    catch (err) {
        logger.error(`Webhook Error: ${err.message}`);
        res.status(400).send(`Webhook Error: ${err.message}`);
        return;
    }
    try {
        if (event.type === 'checkout.session.completed') {
            const session = event.data.object;
            const tenantId = session.client_reference_id;
            const stripeSubscriptionId = session.subscription;
            if (tenantId && stripeSubscriptionId) {
                await admin.firestore().collection('tenants').doc(tenantId).collection('subscription').doc('status').set({
                    status: 'active',
                    tier: 'premium',
                    stripeSubscriptionId: stripeSubscriptionId
                }, { merge: true });
                logger.info(`Updated tenant ${tenantId} subscription status`);
            }
        }
        else if (event.type === 'customer.subscription.deleted') {
            logger.info('Subscription deleted:', event.data.object);
        }
        res.json({ received: true });
    }
    catch (error) {
        logger.error('Error handling webhook', error);
        res.status(500).send('Internal Server Error');
    }
});
//# sourceMappingURL=index.js.map