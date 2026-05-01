import * as admin from "firebase-admin";
import {
  onCall,
  HttpsError,
  CallableRequest,
} from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";
import * as nodemailer from "nodemailer";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { defineString } from "firebase-functions/params";

// ─── Runtime Parameters ─────────────────────────────────────────────────────
const emailHost = defineString("EMAIL_HOST", { default: "" });
const emailPort = defineString("EMAIL_PORT", { default: "587" });
const emailUser = defineString("EMAIL_USER", { default: "" });
const emailPass = defineString("EMAIL_PASS", { default: "" });
const geminiKey = defineString("GEMINI_API_KEY", { default: "" });

// ─── Firebase Admin Init ────────────────────────────────────────────────────
admin.initializeApp();
const db = admin.firestore();

// ─── Helpers ─────────────────────────────────────────────────────────────────
function getTransporter() {
  return nodemailer.createTransport({
    host: emailHost.value(),
    port: Number(emailPort.value()) || 587,
    auth: { user: emailUser.value(), pass: emailPass.value() },
  });
}

function getGemini() {
  return new GoogleGenerativeAI(geminiKey.value());
}

// ============================================================================
// 1. SEND EMAIL
// ============================================================================
export const sendEmail = onCall(
  { region: "europe-west1" },
  async (request: CallableRequest<{ to: string; subject: string; text?: string; html?: string }>) => {
    const { to, subject, text, html } = request.data;
    if (!to || !subject) throw new HttpsError("invalid-argument", "Missing to/subject");

    if (!emailUser.value()) {
      logger.warn("Email credentials not configured — simulation mode");
      return { success: true, message: "Email simulated" };
    }

    try {
      await getTransporter().sendMail({
        from: `"XM System SHEQ" <${emailUser.value()}>`,
        to, subject, text, html,
      });
      logger.info(`Email sent to: ${to}`);
      return { success: true };
    } catch (e) {
      logger.error("Email failed:", e);
      throw new HttpsError("internal", "Failed to send email");
    }
  }
);

// ============================================================================
// 2. SEND FCM PUSH NOTIFICATION
// ============================================================================
interface PushData {
  token?: string;
  tokens?: string[];
  topic?: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

export const sendPushNotification = onCall(
  { region: "europe-west1" },
  async (request: CallableRequest<PushData>) => {
    const { token, tokens, topic, title, body, data } = request.data;
    if (!title || !body) throw new HttpsError("invalid-argument", "Missing title/body");

    const msg = { notification: { title, body }, data: data || {} };

    if (topic) {
      await admin.messaging().send({ ...msg, topic });
      return { success: true, type: "topic" };
    } else if (tokens?.length) {
      const r = await admin.messaging().sendEachForMulticast({ ...msg, tokens });
      return { success: true, type: "multicast", successCount: r.successCount };
    } else if (token) {
      await admin.messaging().send({ ...msg, token });
      return { success: true, type: "single" };
    }
    throw new HttpsError("invalid-argument", "Provide token, tokens, or topic");
  }
);

// ============================================================================
// 3. REGISTER DEVICE TOKEN
// ============================================================================
export const registerDeviceToken = onCall(
  { region: "europe-west1" },
  async (request: CallableRequest<{ token: string; siteId?: string }>) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Must be authenticated");
    const { token, siteId } = request.data;
    if (!token) throw new HttpsError("invalid-argument", "Missing FCM token");

    const uid = request.auth.uid;
    await db.collection("fcm_tokens").doc(uid).set(
      { token, siteId: siteId || null, uid, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
    if (siteId) {
      await admin.messaging().subscribeToTopic([token], `site-${siteId.replace(/[^a-zA-Z0-9\-_.~%]/g, "-")}`);
    }
    await admin.messaging().subscribeToTopic([token], "all-users");
    return { success: true };
  }
);

// ============================================================================
// 4. WEEKLY SAFETY FLASH — every Monday 08:00 SAST
// ============================================================================
export const weeklyFlash = onSchedule(
  { schedule: "0 8 * * 1", timeZone: "Africa/Johannesburg", region: "europe-west1" },
  async () => {
    logger.info("🔔 Generating Weekly Safety Flash…");
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
    const cutoff = oneWeekAgo.toISOString();

    const [incSnap, capasSnap, nearMissSnap, permitsSnap] = await Promise.all([
      db.collection("incidents").where("createdAt", ">=", cutoff).get(),
      db.collection("capas").where("createdAt", ">=", cutoff).get(),
      db.collection("incidents").where("incidentType", "==", "Near Miss").where("createdAt", ">=", cutoff).get(),
      db.collection("permits").where("createdAt", ">=", cutoff).get(),
    ]);

    const incidents = incSnap.docs.map((d) => d.data());
    const capas = capasSnap.docs.map((d) => d.data());
    const criticalCount = incidents.filter((i) => i.severity === "Critical" || i.severity === "Fatal").length;

    let aiSummary = "";
    try {
      const model = getGemini().getGenerativeModel({ model: "gemini-2.0-flash" });
      const result = await model.generateContent(
        `You are an expert SHEQ manager. Generate a concise Weekly Safety Flash bulletin:\n` +
        `- Total incidents: ${incidents.length}\n- Critical/Fatal: ${criticalCount}\n` +
        `- Near misses: ${nearMissSnap.size}\n- CAPAs: ${capas.length}\n- Permits: ${permitsSnap.size}\n` +
        `Write 3-4 paragraphs: highlights, lessons learned, action focus, safety message.`
      );
      aiSummary = result.response.text();
    } catch {
      aiSummary = `${incidents.length} incidents (${criticalCount} critical), ${nearMissSnap.size} near misses, ${capas.length} CAPAs this week.`;
    }

    const dateStr = new Date().toLocaleDateString("en-ZA", { weekday: "long", year: "numeric", month: "long", day: "numeric" });
    const htmlBody = `<!DOCTYPE html><html><body style="font-family:Arial;max-width:600px;margin:0 auto">
<div style="background:linear-gradient(135deg,#0f172a,#1e3a5f);color:white;padding:24px;border-radius:8px 8px 0 0">
  <h1 style="margin:0;font-size:22px">⚡ XM System — Weekly Safety Flash</h1>
  <p style="opacity:.7;font-size:13px;margin-top:4px">${dateStr}</p>
</div>
<div style="display:flex;gap:12px;padding:20px;background:white">
  <div style="flex:1;text-align:center;padding:14px;background:${criticalCount > 0 ? "#fef2f2" : "#f0fdf4"};border-radius:8px">
    <div style="font-size:28px;font-weight:700;color:${criticalCount > 0 ? "#dc2626" : "#16a34a"}">${incidents.length}</div>
    <div style="font-size:11px;color:#6b7280">Incidents</div>
  </div>
  <div style="flex:1;text-align:center;padding:14px;background:#fffbeb;border-radius:8px">
    <div style="font-size:28px;font-weight:700;color:#d97706">${nearMissSnap.size}</div>
    <div style="font-size:11px;color:#6b7280">Near Misses</div>
  </div>
  <div style="flex:1;text-align:center;padding:14px;background:#f0fdf4;border-radius:8px">
    <div style="font-size:28px;font-weight:700;color:#16a34a">${capas.length}</div>
    <div style="font-size:11px;color:#6b7280">CAPAs</div>
  </div>
  <div style="flex:1;text-align:center;padding:14px;background:#eff6ff;border-radius:8px">
    <div style="font-size:28px;font-weight:700;color:#2563eb">${permitsSnap.size}</div>
    <div style="font-size:11px;color:#6b7280">Permits</div>
  </div>
</div>
<div style="background:white;padding:20px">
  <h2 style="color:#0f172a;font-size:16px">AI-Generated Safety Summary</h2>
  <div style="line-height:1.6;color:#374151;white-space:pre-wrap">${aiSummary}</div>
</div>
<div style="background:#0f172a;color:white;padding:16px;text-align:center;font-size:12px;border-radius:0 0 8px 8px">
  XM System SHEQ Platform · Powered by Gemini AI
</div></body></html>`;

    const teamsSnap = await db.collection("users").where("role", "in", ["safety_manager", "admin", "executive"]).get();
    const emails = teamsSnap.docs.map((d) => d.data().email as string).filter(Boolean);

    if (emails.length > 0 && emailUser.value()) {
      try {
        await getTransporter().sendMail({
          from: `"XM System SHEQ" <${emailUser.value()}>`,
          to: emails.join(", "),
          subject: `⚡ Weekly Safety Flash — ${new Date().toLocaleDateString("en-ZA")}`,
          html: htmlBody,
        });
        logger.info(`Safety Flash sent to ${emails.length} recipients`);
      } catch (e) {
        logger.error("Safety Flash email failed:", e);
      }
    }

    try {
      await admin.messaging().send({
        topic: "all-users",
        notification: {
          title: "⚡ Weekly Safety Flash Available",
          body: `${incidents.length} incidents this week. Tap to view the report.`,
        },
        data: { screen: "/ai" },
      });
    } catch (e) {
      logger.warn("FCM push for Safety Flash failed:", e);
    }
  }
);

// ============================================================================
// 5. EMERGENCY BROADCAST
// ============================================================================
interface BroadcastData { siteId: string; message: string; emergencyType?: string; }

export const sendEmergencyBroadcast = onCall(
  { region: "europe-west1" },
  async (request: CallableRequest<BroadcastData>) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Must be authenticated");
    const { siteId, message, emergencyType } = request.data;
    if (!siteId || !message) throw new HttpsError("invalid-argument", "siteId and message required");

    const topic = `site-${siteId.replace(/[^a-zA-Z0-9\-_.~%]/g, "-")}`;
    const title = `🚨 EMERGENCY: ${emergencyType || "Alert"}`;

    await admin.messaging().send({
      topic,
      notification: { title, body: message },
      android: { priority: "high", notification: { channelId: "emergency" } },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    });

    await db.collection("emergency_broadcasts").add({
      siteId, message,
      emergencyType: emergencyType || "General",
      sentBy: request.auth.uid,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      recipientTopic: topic,
    });

    logger.info(`🚨 Emergency broadcast sent to: ${topic}`);
    return { success: true, topic, title };
  }
);

// ============================================================================
// 6. INCIDENT CREATED TRIGGER — notify managers on Critical/Fatal
// ============================================================================
export const onIncidentCreated = onDocumentCreated(
  { document: "incidents/{incidentId}", region: "europe-west1" },
  async (event) => {
    const incident = event.data?.data();
    if (!incident) return;
    const { severity, siteId, incidentType, location } = incident as Record<string, string>;
    if (severity !== "Critical" && severity !== "Fatal") return;

    const managersSnap = await db.collection("users")
      .where("siteId", "==", siteId)
      .where("role", "in", ["safety_manager", "admin", "executive"])
      .get();

    const tokens: string[] = [];
    const emails: string[] = [];
    for (const doc of managersSnap.docs) {
      const u = doc.data();
      if (u.email) emails.push(u.email as string);
      const td = await db.collection("fcm_tokens").doc(doc.id).get();
      if (td.exists && td.data()?.token) tokens.push(td.data()!.token as string);
    }

    if (tokens.length > 0) {
      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: `🚨 ${severity} Incident — ${incidentType}`,
          body: `${location || "Unknown location"} requires immediate attention.`,
        },
        data: { screen: "/safety", incidentId: event.params.incidentId },
      });
    }

    if (emails.length > 0 && emailUser.value()) {
      await getTransporter().sendMail({
        from: `"XM System — SHEQ Alert" <${emailUser.value()}>`,
        to: emails.join(", "),
        subject: `🚨 ${severity} Incident — Immediate Action Required`,
        html: `<h2 style="color:#dc2626">⚠️ ${severity} Incident</h2>
<p><strong>Type:</strong> ${incidentType}</p><p><strong>Location:</strong> ${location || "N/A"}</p>
<p><strong>Site:</strong> ${siteId}</p><p><strong>Time:</strong> ${new Date().toISOString()}</p>`,
      }).catch((e: unknown) => logger.error("Incident alert email failed:", e));
    }
  }
);

// ============================================================================
// 7. PERMIT EXPIRY CHECK — daily 07:00 SAST
// ============================================================================
export const checkPermitExpiry = onSchedule(
  { schedule: "0 7 * * *", timeZone: "Africa/Johannesburg", region: "europe-west1" },
  async () => {
    const in24h = new Date();
    in24h.setHours(in24h.getHours() + 24);
    const permitsSnap = await db.collection("permits")
      .where("status", "==", "Approved")
      .where("expiryDate", "<=", in24h.toISOString())
      .get();
    if (permitsSnap.empty) return;

    for (const doc of permitsSnap.docs) {
      const permit = doc.data() as Record<string, string>;
      const td = await db.collection("fcm_tokens").doc(permit.authorId).get();
      if (td.exists && td.data()?.token) {
        await admin.messaging().send({
          token: td.data()!.token as string,
          notification: {
            title: "⏰ Permit Expiring Soon",
            body: `${permit.permitType} at ${permit.workLocation || "unknown"} expires within 24h.`,
          },
          data: { screen: "/safety", permitId: doc.id },
        });
      }
    }
    logger.info(`Permit expiry check: ${permitsSnap.size} notifications sent`);
  }
);

// ============================================================================
// 8. COIDA OVERDUE CHECK — every Monday 09:00 SAST
// ============================================================================
export const checkCoidaOverdue = onSchedule(
  { schedule: "0 9 * * 1", timeZone: "Africa/Johannesburg", region: "europe-west1" },
  async () => {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const overdueSnap = await db.collection("incidents")
      .where("severity", "in", ["Major", "Critical", "Fatal"])
      .where("coidaSubmitted", "==", false)
      .where("createdAt", "<=", sevenDaysAgo.toISOString())
      .get();
    if (!overdueSnap.empty) {
      await admin.messaging().send({
        topic: "all-users",
        notification: {
          title: "⚠️ COIDA Submissions Overdue",
          body: `${overdueSnap.size} incident(s) require COIDA submission.`,
        },
        data: { screen: "/workers-comp" },
      });
    }
  }
);

// ============================================================================
// 9. TRAINING EXPIRY CHECK — daily 08:00 SAST
// ============================================================================
export const checkTrainingExpiry = onSchedule(
  { schedule: "0 8 * * *", timeZone: "Africa/Johannesburg", region: "europe-west1" },
  async () => {
    const in30days = new Date();
    in30days.setDate(in30days.getDate() + 30);
    const expiringSnap = await db.collection("training_records")
      .where("expiryDate", "<=", in30days.toISOString())
      .where("notificationSent", "!=", true)
      .limit(50)
      .get();

    const batch = db.batch();
    for (const doc of expiringSnap.docs) {
      const rec = doc.data() as Record<string, string>;
      const days = Math.ceil((new Date(rec.expiryDate).getTime() - Date.now()) / 86400000);
      const td = await db.collection("fcm_tokens").doc(rec.authorId).get();
      if (td.exists && td.data()?.token) {
        await admin.messaging().send({
          token: td.data()!.token as string,
          notification: {
            title: "📚 Training Expiring Soon",
            body: `"${rec.trainingName}" expires in ${days} day${days === 1 ? "" : "s"}.`,
          },
          data: { screen: "/people" },
        });
      }
      batch.update(doc.ref, { notificationSent: true });
    }
    if (!expiringSnap.empty) await batch.commit();
    logger.info(`Training expiry: ${expiringSnap.size} notifications`);
  }
);
