import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GoogleGenerativeAI } from "@google/generative-ai";

/**
 * askCopilot — Sentinel AI Copilot Cloud Function
 *
 * Accepts a user query and screen context, then returns a concise
 * Gemini-powered answer along with a confidence score.
 */
export const askCopilot = onCall(
  { region: "us-central1" },
  async (request) => {
    const { query, screenContext } = request.data as {
      query: string;
      screenContext: string;
    };

    // ── Validation ────────────────────────────────────────────────────────────
    if (!query || typeof query !== "string" || query.trim().length === 0) {
      throw new HttpsError("invalid-argument", "A non-empty 'query' is required.");
    }
    if (typeof screenContext !== "string") {
      throw new HttpsError("invalid-argument", "'screenContext' must be a string.");
    }

    // ── API Key ───────────────────────────────────────────────────────────────
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.error("GEMINI_API_KEY environment variable is not set.");
      throw new HttpsError(
        "internal",
        "AI service is not configured. Contact your administrator."
      );
    }

    // ── Gemini Call ───────────────────────────────────────────────────────────
    try {
      const genAI = new GoogleGenerativeAI(apiKey);
      const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

      const prompt = [
        "You are Sentinel Copilot, an enterprise ERP assistant.",
        `Context: ${screenContext.trim()}`,
        `User question: ${query.trim()}`,
        "Answer concisely in 2-3 sentences.",
      ].join(" ");

      const result = await model.generateContent(prompt);
      const response = result.response;
      const answer = response.text();

      if (!answer || answer.trim().length === 0) {
        throw new HttpsError("internal", "The AI returned an empty response.");
      }

      // Derive a simple confidence score from the candidate's avgLogprobs when
      // available; otherwise default to a high-confidence placeholder.
      const candidate = response.candidates?.[0];
      const rawScore: number =
        (candidate as any)?.avgLogprobs !== undefined
          ? Math.min(1, Math.max(0, 1 + (candidate as any).avgLogprobs / 10))
          : 0.92;

      const confidence = parseFloat(rawScore.toFixed(2));

      return { answer: answer.trim(), confidence };
    } catch (err: unknown) {
      // Re-throw known HttpsErrors directly
      if (err instanceof HttpsError) throw err;

      const message =
        err instanceof Error ? err.message : "Unknown error occurred.";
      console.error("Gemini API error:", message, err);
      throw new HttpsError(
        "internal",
        `Failed to get AI response: ${message}`
      );
    }
  }
);
