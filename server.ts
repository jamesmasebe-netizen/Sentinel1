import express from "express";
import { createServer as createViteServer } from "vite";
import path from "path";
import nodemailer from "nodemailer";
import webpush from "web-push";
import dotenv from "dotenv";
import cron from "node-cron";
import { generateSafetyFlash } from "./src/scripts/generateSafetyFlash";

dotenv.config();

async function startServer() {
  const app = express();
  const PORT = 3000;

  app.use(express.json());

  // Schedule weekly safety flash report (every Monday at 8 AM)
  cron.schedule('0 8 * * 1', () => {
    console.log('Generating weekly safety flash report...');
    generateSafetyFlash().catch(console.error);
  });

  // VAPID keys should be generated and stored in environment variables
  const publicVapidKey = process.env.VITE_VAPID_PUBLIC_KEY || "";
  const privateVapidKey = process.env.VAPID_PRIVATE_KEY || "";

  if (publicVapidKey && privateVapidKey) {
    webpush.setVapidDetails(
      "mailto:example@yourdomain.org",
      publicVapidKey,
      privateVapidKey
    );
  }

  // Email Transporter (Placeholder - requires real credentials in .env)
  const transporter = nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: Number(process.env.EMAIL_PORT) || 587,
    secure: process.env.EMAIL_SECURE === "true",
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  // API Routes
  app.post("/api/notifications/subscribe", (req, res) => {
    const subscription = req.body;
    res.status(201).json({});
    // In a real app, you'd save this subscription to your database (e.g., Firestore)
    console.log("New push subscription received");
  });

  app.post("/api/notifications/send-email", async (req, res) => {
    const { to, subject, text, html } = req.body;

    if (!process.env.EMAIL_USER) {
      console.log("Email simulation (no credentials):", { to, subject });
      return res.json({ success: true, message: "Email simulated (no credentials set)" });
    }

    try {
      await transporter.sendMail({
        from: `"Safety Platform" <${process.env.EMAIL_USER}>`,
        to,
        subject,
        text,
        html,
      });
      res.json({ success: true });
    } catch (error) {
      console.error("Error sending email:", error);
      res.status(500).json({ success: false, error: "Failed to send email" });
    }
  });

  app.post("/api/notifications/send-push", async (req, res) => {
    const { subscription, title, body } = req.body;

    if (!publicVapidKey || !privateVapidKey) {
      return res.status(500).json({ error: "VAPID keys not configured" });
    }

    const payload = JSON.stringify({ title, body });

    try {
      await webpush.sendNotification(subscription, payload);
      res.json({ success: true });
    } catch (error) {
      console.error("Error sending push notification:", error);
      res.status(500).json({ success: false, error: "Failed to send push notification" });
    }
  });

  // Vite middleware for development
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

startServer();
