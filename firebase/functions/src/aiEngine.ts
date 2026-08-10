import { onCall, CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

/**
 * Renamed from `aiSuggestReply` (honesty fix — see docs/testing/TEST_BACKLOG.md's
 * "Flagged-not-fixed follow-up pass" entry): despite the old name, this has never called an LLM or
 * any external AI service — it's a fully deterministic keyword match (see the branches below)
 * wrapped in a templated sentence. Also confirmed to have zero call sites anywhere in the Flutter
 * app today (nothing in lib/ references this callable's name), so this isn't currently shown to any
 * real customer_service agent — but the misleading name was worth fixing regardless, since a
 * plausible future caller (or the next developer reading this file) would otherwise reasonably
 * assume it's model-backed. Compare `copilotEngine.ts`'s `askCopilot`, which genuinely does call
 * Gemini. If a real AI-backed reply suggester is ever wanted, build it as a new function rather than
 * reviving this one as "the AI version" — this one's whole design (fixed keyword branches, no model
 * call) is the wrong shape for that.
 */
interface SuggestReplyTemplateRequest {
  threadMessages: string[];
  caseSubject: string;
}

export const suggestReplyTemplate = onCall(
  async (request: CallableRequest<SuggestReplyTemplateRequest>) => {
    const { threadMessages, caseSubject } = request.data;

    logger.info("suggestReplyTemplate called", { caseSubject, messageCount: threadMessages.length });

    const lastMessage =
      threadMessages.length > 0
        ? threadMessages[threadMessages.length - 1]
        : "";

    // Mock logic: derive advice based on keywords in the last message
    let mockAdvice = "reviewing your case thoroughly";
    if (lastMessage.toLowerCase().includes("urgent") || lastMessage.toLowerCase().includes("asap")) {
      mockAdvice = "escalating this to our priority queue immediately";
    } else if (lastMessage.toLowerCase().includes("refund") || lastMessage.toLowerCase().includes("billing")) {
      mockAdvice = "connecting you with our billing specialist for a full review";
    } else if (lastMessage.toLowerCase().includes("error") || lastMessage.toLowerCase().includes("bug")) {
      mockAdvice = "filing a technical investigation with our engineering team";
    }

    const suggestedReply =
      `Thank you for contacting us about ${caseSubject}. ` +
      `Based on your message, I recommend ${mockAdvice}. ` +
      `Our team will follow up within 24 hours.`;

    logger.info("Suggested reply generated", { suggestedReply });

    return { suggestedReply };
  }
);
