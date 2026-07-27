---
name: gemini-ai-integration
description: Enterprise-grade standard for integrating Gemini AI and other LLMs into the Sentinel platform. Focuses on structured output, robust error handling, and Firebase Extension/Vertex AI usage.
---

# Enterprise AI Integration Skill (Gemini & LLMs)

When tasked with adding AI features (e.g., automated CAPA generation, risk assessment summaries, chat interfaces) to the Sentinel platform, you MUST follow these enterprise-grade standards.

## 1. Firebase Vertex AI or Cloud Functions
- Do NOT embed raw API keys directly into the client app (Flutter).
- **Preferred Method:** Use the `firebase_vertexai` Flutter SDK which utilizes Firebase App Check to securely call Gemini directly from the client.
- **Alternative:** For complex multi-step agents or when using Claude/OpenAI, execute the logic in a Firebase Cloud Function (Node.js/Python) and call it from the app using the `cloud_functions` plugin.

## 2. Structured Outputs (JSON Schema)
- When querying Gemini for data extraction or generation, ALWAYS force structured JSON output using `responseMimeType: 'application/json'` and provide a clear JSON Schema in the prompt.
- In Dart, parse the response defensively using `jsonDecode` and robust `fromMap` factory constructors. Handle `FormatException` gracefully.

## 3. UI/UX for AI Operations
- AI requests can be slow. ALWAYS display a shimmering loading state or a clear progress indicator.
- Implement a "Streaming" UI where possible using `generateContentStream` to reduce perceived latency.
- Provide user feedback mechanisms (e.g., Thumbs Up/Down or a "Regenerate" button) for all AI-generated content.

## 4. Prompt Management
- Do not hardcode massive prompts directly in UI widgets.
- Extract prompts into a dedicated `ai_prompts.dart` utility file or fetch them remotely via Firebase Remote Config to allow prompt engineering without app updates.

## 5. Fallback Mechanisms
- If the AI service is down or returns a malformed response, catch the error and display a fallback UI, allowing the user to enter the data manually. Never crash the app due to an AI failure.
