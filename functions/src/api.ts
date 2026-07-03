import * as functions from 'firebase-functions';
import * as express from 'express';
import * as cors from 'cors';
import * as admin from 'firebase-admin';

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Middleware to authenticate API keys or Bearer tokens
const authenticate = async (req: express.Request, res: express.Response, next: express.NextFunction) => {
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
    (req as any).tenantId = decoded.tenantId;
    next();
  } catch (error) {
    res.status(401).send('Unauthorized: Invalid token');
  }
};

app.use(authenticate);

// Example endpoint: Get all incidents for the tenant
app.get('/incidents', async (req, res) => {
  try {
    const tenantId = (req as any).tenantId;
    const db = admin.firestore();
    const snap = await db.collection(`tenants/${tenantId}/incidents`).limit(50).get();
    
    const data = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to fetch incidents' });
  }
});

export const platformApi = functions.https.onRequest(app);
