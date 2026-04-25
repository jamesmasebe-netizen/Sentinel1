import { GoogleGenAI } from "@google/genai";

let aiClient: GoogleGenAI | null = null;

export function getGeminiClient(): GoogleGenAI {
  if (!aiClient) {
    // In Vite, it's import.meta.env.VITE_GEMINI_API_KEY, but we'll check both just in case
    // Note: process.env might be polyfilled or we might be in a Node environment
    const key = (typeof process !== 'undefined' && process.env.GEMINI_API_KEY) || 
                // @ts-ignore
                (typeof import.meta !== 'undefined' && import.meta.env && import.meta.env.VITE_GEMINI_API_KEY);
    
    if (!key) {
      console.warn('GEMINI_API_KEY environment variable is missing. AI features will not work.');
      // Return a dummy client that throws on use, so the app doesn't crash on load
      return new GoogleGenAI({ apiKey: 'dummy-key' });
    }
    aiClient = new GoogleGenAI({ apiKey: key });
  }
  return aiClient;
}
