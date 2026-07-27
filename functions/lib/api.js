"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.platformApi = void 0;
const functions = require("firebase-functions");
const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const app = express();
app.use(cors({ origin: true }));
app.use(express.json());
// Middleware to authenticate API keys or Bearer tokens
const authenticate = async (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).send('Unauthorized: Missing or invalid Bearer token');
        return;
    }
    const token = authHeader.split('Bearer ')[1];
    try {
        const decoded = await admin.auth().verifyIdToken(token);
        // Bind tenant context
        if (!decoded.tenantId) {
            res.status(403).send('Forbidden: No tenant context found');
            return;
        }
        req.tenantId = decoded.tenantId;
        next();
    }
    catch (error) {
        res.status(401).send('Unauthorized: Invalid token');
    }
};
app.use(authenticate);
// Example endpoint: Get all incidents for the tenant
app.get('/incidents', async (req, res) => {
    try {
        const tenantId = req.tenantId;
        const db = admin.firestore();
        const snap = await db.collection(`tenants/${tenantId}/incidents`).limit(50).get();
        const data = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        res.json({ success: true, data });
    }
    catch (err) {
        res.status(500).json({ success: false, error: 'Failed to fetch incidents' });
    }
});
exports.platformApi = functions.https.onRequest(app);
//# sourceMappingURL=api.js.map